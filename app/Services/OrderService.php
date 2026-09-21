<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\ProcessedProduct;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class OrderService
{
    public function __construct(
        private readonly SaleService $saleService,
        private readonly ProcessedProductService $processedProductService
    ) {}

    /**
     * Create an order from public catalog (guest checkout).
     * Strictly records the order with 'pending' status and snapshots current prices.
     * DOES NOT MUTATE STOCK.
     */
    public function createPublicOrder(array $data): Order
    {
        // Support either single-product checkout (direct landing modal) or item list
        $rawItems = [];
        if (!empty($data['items']) && is_array($data['items'])) {
            $rawItems = $data['items'];
        } elseif (!empty($data['processed_product_id'])) {
            $rawItems = [[
                'processed_product_id' => $data['processed_product_id'],
                'quantity'             => $data['quantity'] ?? 1,
            ]];
        } else {
            throw new \InvalidArgumentException('Produk olahan wajib dipilih.');
        }

        return DB::transaction(function () use ($data, $rawItems) {
            $totalAmount = 0.0;
            $preparedItems = [];

            foreach ($rawItems as $itemData) {
                $productId = (int) $itemData['processed_product_id'];
                $quantity  = (int) ($itemData['quantity'] ?? 1);

                if ($quantity <= 0) {
                    throw new \InvalidArgumentException('Jumlah pesanan harus minimal 1 unit.');
                }

                $product = ProcessedProduct::findOrFail($productId);

                // Business Rule: Inactive products cannot be ordered
                if ($product->status === 'inactive') {
                    throw new \DomainException("Produk '{$product->name}' sedang tidak aktif dan tidak dapat dipesan.");
                }

                // Business Rule: Out of stock or insufficient stock products cannot be ordered
                if ($product->status === 'out_of_stock' || $product->stock <= 0) {
                    throw new \DomainException("Produk '{$product->name}' sedang habis (stok 0).");
                }

                if ($quantity > $product->stock) {
                    throw new \DomainException("Jumlah pesanan untuk '{$product->name}' ({$quantity} unit) melebihi stok yang tersedia ({$product->stock} unit).");
                }

                // Mandatory Price Snapshot
                $priceSnapshot = (float) $product->price;
                $subtotal = $quantity * $priceSnapshot;
                $totalAmount += $subtotal;

                $preparedItems[] = [
                    'processed_product_id' => $product->id,
                    'quantity'             => $quantity,
                    'price_snapshot'       => $priceSnapshot,
                    'subtotal'             => $subtotal,
                ];
            }

            $order = Order::create([
                'order_code'       => Order::generateOrderCode(),
                'customer_name'    => trim($data['customer_name']),
                'customer_phone'   => trim($data['customer_phone']),
                'customer_address' => isset($data['customer_address']) ? trim($data['customer_address']) : null,
                'status'           => Order::STATUS_PENDING,
                'total_amount'     => $totalAmount,
                'notes'            => $data['notes'] ?? null,
            ]);

            foreach ($preparedItems as $item) {
                $order->items()->create($item);
            }

            return $order->load(['items.processedProduct.owner']);
        });
    }

    /**
     * List orders for Super Admin dashboard with filters and search.
     */
    public function listForSuperAdmin(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = Order::with(['items.processedProduct.owner', 'sale'])->latest();

        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (!empty($filters['search'])) {
            $search = trim($filters['search']);
            $query->where(function ($q) use ($search) {
                $q->where('order_code', 'like', "%{$search}%")
                  ->orWhere('customer_name', 'like', "%{$search}%")
                  ->orWhere('customer_phone', 'like', "%{$search}%");
            });
        }

        return $query->paginate($perPage);
    }

    /**
     * Update operational status of an order (Super Admin).
     * Strictly restricted to 'confirmed' or 'processing'.
     * CANNOT set 'completed' (must use completeOrder).
     * DOES NOT MUTATE STOCK.
     */
    public function updateStatus(Order $order, string $newStatus): Order
    {
        if ($newStatus === Order::STATUS_COMPLETED) {
            throw new \InvalidArgumentException("Penyelesaian pesanan hanya dapat dilakukan melalui fungsi complete.");
        }

        if (!in_array($newStatus, [Order::STATUS_CONFIRMED, Order::STATUS_PROCESSING])) {
            throw new \InvalidArgumentException("Status {$newStatus} tidak valid untuk pembaruan status biasa.");
        }

        if ($order->status === Order::STATUS_COMPLETED) {
            throw new \DomainException("Pesanan yang sudah selesai (completed) tidak dapat diubah statusnya.");
        }

        if ($order->status === Order::STATUS_CANCELLED) {
            throw new \DomainException("Pesanan yang sudah dibatalkan (cancelled) tidak dapat diubah statusnya.");
        }

        $order->status = $newStatus;
        $order->save();

        return $order->fresh(['items.processedProduct', 'sale']);
    }

    /**
     * Complete an order atomically (Super Admin).
     * The ONLY flow that triggers Sale creation and stock decrement via SaleService.
     * Protected by idempotency guard to prevent double sale / double stock deduction.
     */
    public function completeOrder(Order $order, int $superAdminUserId): Order
    {
        // Idempotency Guard: Prevent completing an order twice
        if ($order->status === Order::STATUS_COMPLETED || $order->sale()->exists()) {
            throw new \DomainException("Pesanan {$order->order_code} sudah pernah diselesaikan. Penjualan ganda dicegah.");
        }

        if ($order->status === Order::STATUS_CANCELLED) {
            throw new \DomainException("Pesanan {$order->order_code} telah dibatalkan dan tidak dapat diselesaikan.");
        }

        return DB::transaction(function () use ($order, $superAdminUserId) {
            // Lock order row
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->firstOrFail();

            if ($lockedOrder->status === Order::STATUS_COMPLETED || $lockedOrder->sale()->exists()) {
                throw new \DomainException("Pesanan {$lockedOrder->order_code} sudah pernah diselesaikan.");
            }

            // Delegate Sale creation, stock decrement, and StockTransaction strictly to SaleService
            $this->saleService->createSaleFromOrder($lockedOrder, $superAdminUserId);

            // Mark order as completed
            $lockedOrder->status = Order::STATUS_COMPLETED;
            $lockedOrder->save();

            return $lockedOrder->fresh(['items.processedProduct.owner', 'sale']);
        });
    }

    /**
     * Cancel an order (Super Admin or customer pre-confirmation).
     * Cannot cancel an order that has already been completed.
     */
    public function cancelOrder(Order $order): Order
    {
        if ($order->status === Order::STATUS_COMPLETED || $order->sale()->exists()) {
            throw new \DomainException("Pesanan {$order->order_code} yang sudah selesai tidak dapat dibatalkan.");
        }

        $order->status = Order::STATUS_CANCELLED;
        $order->save();

        return $order->fresh(['items.processedProduct', 'sale']);
    }

    /**
     * Format an order for public tracking with privacy protection.
     * Mask customer name, phone number, and address so personal data is not leaked.
     */
    public function formatPublicTracking(Order $order): array
    {
        $order->loadMissing('items.processedProduct');

        return [
            'order_code'       => $order->order_code,
            'status'           => $order->status,
            'customer_name'    => $this->maskName($order->customer_name),
            'customer_phone'   => $this->maskPhone($order->customer_phone),
            'customer_address' => 'Alamat terlindungi untuk privasi pelanggan',
            'total_amount'     => (float) $order->total_amount,
            'notes'            => $order->notes,
            'created_at'       => $order->created_at->toIso8601String(),
            'items'            => $order->items->map(function ($item) {
                return [
                    'product_name'   => $item->processedProduct?->name ?? 'Produk Olahan',
                    'quantity'       => (int) $item->quantity,
                    'price_snapshot' => (float) $item->price_snapshot,
                    'subtotal'       => (float) $item->subtotal,
                ];
            })->values(),
        ];
    }

    /**
     * Format an order for Super Admin view (full administrative data).
     */
    public function formatOrderForAdmin(Order $order): array
    {
        $order->loadMissing(['items.processedProduct.owner', 'sale']);

        return [
            'id'               => $order->id,
            'order_code'       => $order->order_code,
            'customer_name'    => $order->customer_name,
            'customer_phone'   => $order->customer_phone,
            'customer_address' => $order->customer_address,
            'status'           => $order->status,
            'total_amount'     => (float) $order->total_amount,
            'notes'            => $order->notes,
            'has_sale'         => $order->sale !== null,
            'sale_id'          => $order->sale?->id,
            'created_at'       => $order->created_at->toIso8601String(),
            'updated_at'       => $order->updated_at->toIso8601String(),
            'items'            => $order->items->map(function ($item) {
                return [
                    'id'                   => $item->id,
                    'processed_product_id' => $item->processed_product_id,
                    'product_name'         => $item->processedProduct?->name ?? 'Produk Olahan',
                    'product_photo_url'    => $item->processedProduct?->photo_url,
                    'owner_name'           => $item->processedProduct?->owner?->name ?? 'Petani',
                    'quantity'             => (int) $item->quantity,
                    'price_snapshot'       => (float) $item->price_snapshot,
                    'subtotal'             => (float) $item->subtotal,
                ];
            })->values(),
        ];
    }

    /**
     * Mask customer name: e.g. "Budi Santoso" -> "Budi S****".
     */
    private function maskName(string $name): string
    {
        $parts = explode(' ', trim($name));
        if (count($parts) === 1) {
            $word = $parts[0];
            return mb_substr($word, 0, 1) . str_repeat('*', max(1, mb_strlen($word) - 1));
        }

        $first = array_shift($parts);
        $maskedRest = array_map(function ($word) {
            return mb_substr($word, 0, 1) . str_repeat('*', max(2, mb_strlen($word) - 1));
        }, $parts);

        return $first . ' ' . implode(' ', $maskedRest);
    }

    /**
     * Mask phone number: e.g. "081234567890" -> "0812****7890".
     */
    private function maskPhone(string $phone): string
    {
        $clean = preg_replace('/[^0-9+]/', '', $phone);
        $len = strlen($clean);
        if ($len <= 6) {
            return substr($clean, 0, 2) . '****';
        }

        $prefix = substr($clean, 0, 4);
        $suffix = substr($clean, -4);
        return $prefix . '****' . $suffix;
    }
}
