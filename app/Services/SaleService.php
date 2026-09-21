<?php

namespace App\Services;

use App\Models\Order;
use App\Models\ProcessedProduct;
use App\Models\Sale;
use App\Models\StockTransaction;
use Illuminate\Support\Facades\DB;

class SaleService
{
    public function __construct(
        private readonly ProcessedProductService $processedProductService
    ) {}

    /**
     * Create confirmed sale record(s) from a completed order.
     * Strictly called only when an order is transitioned to completed.
     * Handles:
     *  1. ProcessedProductService::decrementStock (which locks and decrements stock safely)
     *  2. Sale creation with order_id, snapshot prices, owner_id
     *  3. StockTransaction audit trail recording
     */
    public function createSaleFromOrder(Order $order, int $superAdminUserId): Sale
    {
        $order->loadMissing('items.processedProduct');

        if ($order->items->isEmpty()) {
            throw new \DomainException('Pesanan tidak memiliki item produk.');
        }

        return DB::transaction(function () use ($order, $superAdminUserId) {
            $firstSale = null;

            foreach ($order->items as $item) {
                $product = $item->processedProduct;
                if (!$product) {
                    $product = ProcessedProduct::findOrFail($item->processed_product_id);
                }

                // Decrement stock atomically via ProcessedProductService (checks sufficiency and locks row)
                $updatedProduct = $this->processedProductService->decrementStock($product, $item->quantity);

                $sale = Sale::create([
                    'user_id'              => $product->owner_id,
                    'order_id'             => $order->id,
                    'created_by'           => $superAdminUserId,
                    'product_type'         => 'processed',
                    'processed_product_id' => $product->id,
                    'season_id'            => null,
                    'date'                 => now()->toDateString(),
                    'buyer_name'           => $order->customer_name,
                    'buyer_phone'          => $order->customer_phone,
                    'buyer_address'        => $order->customer_address,
                    'weight_kg'            => $item->quantity,
                    'price_per_kg'         => $item->price_snapshot,
                    'total'                => $item->subtotal,
                    'payment_status'       => 'paid',
                    'notes'                => 'Penjualan otomatis dari Pesanan ' . $order->order_code . ($order->notes ? ' (' . $order->notes . ')' : ''),
                ]);

                // Record StockTransaction audit trail
                StockTransaction::recordProcessedProductTransaction(
                    $updatedProduct,
                    'out',
                    $item->quantity,
                    'Penjualan Produk Olahan: ' . $product->name . ' (Pesanan ' . $order->order_code . ')',
                    'sale_' . $sale->id,
                    $product->owner_id
                );

                if (!$firstSale) {
                    $firstSale = $sale;
                }
            }

            return $firstSale;
        });
    }

    /**
     * Normalize field aliases coming from different client versions.
     * Maps: quantity→weight_kg, price_per_unit→price_per_kg, sale_date→date, status→payment_status
     */
    public function normalizeData(array $data): array
    {
        $productType = $data['product_type'] ?? (!empty($data['processed_product_id']) ? 'processed' : 'harvest');

        return [
            'product_type'         => $productType,
            'processed_product_id' => $data['processed_product_id'] ?? null,
            'weight_kg'            => $data['weight_kg'] ?? $data['quantity'] ?? 0,
            'price_per_kg'         => $data['price_per_kg'] ?? $data['price_per_unit'] ?? 0,
            'date'                 => $data['date'] ?? $data['sale_date'] ?? now()->toDateString(),
            'payment_status'       => $this->resolvePaymentStatus($data),
            'season_id'            => $data['season_id'] ?? null,
            'buyer_name'           => $data['buyer_name'],
            'buyer_phone'          => $data['buyer_phone'] ?? null,
            'buyer_address'        => $data['buyer_address'] ?? null,
            'notes'                => $data['notes'] ?? null,
        ];
    }

    /**
     * Determine payment status from either payment_status or legacy status field.
     */
    private function resolvePaymentStatus(array $data): string
    {
        if (isset($data['payment_status'])) {
            return $data['payment_status'];
        }
        if (isset($data['status'])) {
            return in_array(strtolower($data['status']), ['paid', 'completed']) ? 'paid' : 'unpaid';
        }
        return 'paid';
    }

    /**
     * Check if sufficient stock exists for either raw harvest or processed product.
     */
    public function hasSufficientStock(array $normalized, int $farmerUserId): bool
    {
        if (($normalized['product_type'] ?? 'harvest') === 'processed') {
            if (empty($normalized['processed_product_id'])) {
                return false;
            }
            $product = ProcessedProduct::find($normalized['processed_product_id']);
            return $product && $product->stock >= $normalized['weight_kg'];
        }

        return StockTransaction::getCurrentBalance($farmerUserId) >= $normalized['weight_kg'];
    }

    /**
     * Get current stock balance for either raw harvest or processed product.
     */
    public function getCurrentStock(array $normalized, int $farmerUserId): float
    {
        if (($normalized['product_type'] ?? 'harvest') === 'processed') {
            if (empty($normalized['processed_product_id'])) {
                return 0.0;
            }
            $product = ProcessedProduct::find($normalized['processed_product_id']);
            return (float) ($product?->stock ?? 0);
        }

        return StockTransaction::getCurrentBalance($farmerUserId);
    }

    /**
     * Create a sale and deduct appropriate stock.
     */
    public function createSale(array $normalized, int $farmerUserId, ?int $createdBy = null): Sale
    {
        if (($normalized['product_type'] ?? 'harvest') === 'processed') {
            $product = ProcessedProduct::findOrFail($normalized['processed_product_id']);
            // Owner of the processed product is the farmer
            $farmerUserId = $product->owner_id;
            $quantity = (int) $normalized['weight_kg'];
            $total = $quantity * $normalized['price_per_kg'];

            return DB::transaction(function () use ($normalized, $farmerUserId, $createdBy, $product, $quantity, $total) {
                // Atomic stock decrement with state transition handling
                $updatedProduct = $this->processedProductService->decrementStock($product, $quantity);

                $sale = Sale::create([
                    'user_id'              => $farmerUserId,
                    'created_by'           => $createdBy,
                    'product_type'         => 'processed',
                    'processed_product_id' => $product->id,
                    'season_id'            => null,
                    'date'                 => $normalized['date'],
                    'buyer_name'           => $normalized['buyer_name'],
                    'buyer_phone'          => $normalized['buyer_phone'],
                    'buyer_address'        => $normalized['buyer_address'],
                    'weight_kg'            => $quantity,
                    'price_per_kg'         => $normalized['price_per_kg'],
                    'total'                => $total,
                    'payment_status'       => $normalized['payment_status'],
                    'notes'                => $normalized['notes'],
                ]);

                // Record StockTransaction audit trail
                StockTransaction::recordProcessedProductTransaction(
                    $updatedProduct,
                    'out',
                    $quantity,
                    'Penjualan Produk Olahan: ' . $product->name,
                    'sale_' . $sale->id,
                    $farmerUserId
                );

                return $sale;
            });
        }

        $total = $normalized['weight_kg'] * $normalized['price_per_kg'];

        return DB::transaction(function () use ($normalized, $farmerUserId, $createdBy, $total) {
            $sale = Sale::create([
                'user_id'              => $farmerUserId,
                'created_by'           => $createdBy,
                'product_type'         => 'harvest',
                'processed_product_id' => null,
                'season_id'            => $normalized['season_id'],
                'date'                 => $normalized['date'],
                'buyer_name'           => $normalized['buyer_name'],
                'buyer_phone'          => $normalized['buyer_phone'],
                'buyer_address'        => $normalized['buyer_address'],
                'weight_kg'            => $normalized['weight_kg'],
                'price_per_kg'         => $normalized['price_per_kg'],
                'total'                => $total,
                'payment_status'       => $normalized['payment_status'],
                'notes'                => $normalized['notes'],
            ]);

            StockTransaction::addTransaction(
                'out',
                $normalized['weight_kg'],
                'Penjualan',
                'sale_' . $sale->id,
                $farmerUserId
            );

            return $sale;
        });
    }

    /**
     * Update a sale and adjust stock if weight changed.
     */
    public function updateSale(Sale $sale, array $data, int $userId): Sale
    {
        $dbData = [];

        if (isset($data['season_id']))                      $dbData['season_id']     = $data['season_id'];
        if (isset($data['buyer_name']))                     $dbData['buyer_name']    = $data['buyer_name'];
        if (isset($data['buyer_phone']))                    $dbData['buyer_phone']   = $data['buyer_phone'];
        if (array_key_exists('buyer_address', $data))       $dbData['buyer_address'] = $data['buyer_address'];
        if (isset($data['notes']))                          $dbData['notes']         = $data['notes'];

        $newDate = $data['date'] ?? $data['sale_date'] ?? null;
        if ($newDate) $dbData['date'] = $newDate;

        $weightKg = $data['weight_kg'] ?? $data['quantity'] ?? null;
        if ($weightKg !== null) $dbData['weight_kg'] = $weightKg;

        $pricePerKg = $data['price_per_kg'] ?? $data['price_per_unit'] ?? null;
        if ($pricePerKg !== null) $dbData['price_per_kg'] = $pricePerKg;

        // Recalculate total if weight or price changed
        if (isset($dbData['weight_kg']) || isset($dbData['price_per_kg'])) {
            $w = $dbData['weight_kg'] ?? $sale->weight_kg;
            $p = $dbData['price_per_kg'] ?? $sale->price_per_kg;
            $dbData['total'] = $w * $p;
        }

        // Resolve payment status
        if (isset($data['payment_status'])) {
            $dbData['payment_status'] = $data['payment_status'];
        } elseif (isset($data['status'])) {
            $dbData['payment_status'] = in_array(strtolower($data['status']), ['paid', 'completed']) ? 'paid' : 'unpaid';
        }

        $oldWeight = $sale->weight_kg;

        return DB::transaction(function () use ($sale, $dbData, $oldWeight) {
            $sale->update($dbData);

            // Adjust stock if weight changed
            if (isset($dbData['weight_kg']) && $oldWeight != $dbData['weight_kg']) {
                $difference = $oldWeight - $dbData['weight_kg'];

                if ($sale->product_type === 'processed' && $sale->processed_product_id) {
                    $product = ProcessedProduct::find($sale->processed_product_id);
                    if ($product) {
                        $product->stock += (int) $difference;
                        $product->save();
                    }
                } else {
                    StockTransaction::addTransaction(
                        $difference > 0 ? 'in' : 'out',
                        abs($difference),
                        'Penjualan diupdate',
                        'sale_' . $sale->id,
                        $sale->user_id
                    );
                }
            }

            return $sale;
        });
    }

    /**
     * Delete a sale and return the weight/stock.
     */
    public function deleteSale(Sale $sale): void
    {
        DB::transaction(function () use ($sale) {
            $oldWeight = $sale->weight_kg;

            if ($sale->product_type === 'processed' && $sale->processed_product_id) {
                $product = ProcessedProduct::find($sale->processed_product_id);
                if ($product) {
                    $product->stock += (int) $oldWeight;
                    $product->save();
                }
            } else {
                StockTransaction::addTransaction(
                    'in',
                    $oldWeight,
                    'Penjualan dihapus',
                    'sale_deleted',
                    $sale->user_id
                );
            }

            $sale->delete();
        });
    }

    /**
     * Format a sale model for API response.
     */
    public function formatSale(Sale $sale, string $event = 'created'): array
    {
        $base = [
            'id'                   => $sale->id,
            'order_id'             => $sale->order_id,
            'user_id'              => $sale->user_id,
            'created_by'           => $sale->created_by,
            'product_type'         => $sale->product_type ?? 'harvest',
            'processed_product_id' => $sale->processed_product_id,
            'product_name'         => $sale->processedProduct?->name,
            'season_id'            => $sale->season_id,
            'sale_date'            => $sale->date->toDateString(),
            'date'                 => $sale->date->toDateString(),
            'buyer_name'           => $sale->buyer_name,
            'buyer_phone'          => $sale->buyer_phone,
            'buyer_address'        => $sale->buyer_address,
            'quantity'             => (float) $sale->weight_kg,
            'weight_kg'            => (float) $sale->weight_kg,
            'price_per_unit'       => (float) $sale->price_per_kg,
            'price_per_kg'         => (float) $sale->price_per_kg,
            'total_price'          => (float) $sale->total,
            'total'                => (float) $sale->total,
            'notes'                => $sale->notes,
            'status'               => $sale->payment_status === 'paid' ? 'completed' : 'pending',
            'payment_status'       => $sale->payment_status,
        ];

        if ($event === 'created') {
            $base['created_at'] = $sale->created_at->toIso8601String();
        } else {
            $base['updated_at'] = $sale->updated_at->toIso8601String();
        }

        return $base;
    }
}
