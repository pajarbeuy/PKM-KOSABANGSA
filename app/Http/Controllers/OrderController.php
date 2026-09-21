<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Services\OrderService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class OrderController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly OrderService $orderService) {}

    /**
     * Public endpoint: Customer places an order from public catalog.
     * Status is set to 'pending'. Stock is NOT decremented.
     */
    public function storePublic(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'customer_name'        => 'required|string|max:255',
                'customer_phone'       => 'required|string|max:50',
                'customer_address'     => 'nullable|string|max:1000',
                'notes'                => 'nullable|string|max:1000',
                'processed_product_id' => 'required_without:items|nullable|integer|exists:processed_products,id',
                'quantity'             => 'required_without:items|nullable|integer|min:1',
                'items'                => 'nullable|array|min:1',
                'items.*.processed_product_id' => 'required_with:items|integer|exists:processed_products,id',
                'items.*.quantity'             => 'required_with:items|integer|min:1',
            ], [
                'customer_name.required'  => 'Nama lengkap wajib diisi.',
                'customer_phone.required' => 'Nomor telepon / WhatsApp wajib diisi.',
                'quantity.min'            => 'Jumlah pesanan minimal 1 unit.',
            ]);

            $order = $this->orderService->createPublicOrder($validated);

            return $this->successResponse([
                'order'      => $this->orderService->formatPublicTracking($order),
                'order_code' => $order->order_code,
            ], 'Pesanan berhasil dibuat. Silakan konfirmasi pesanan Anda via WhatsApp.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        } catch (\DomainException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        } catch (\Throwable $e) {
            return $this->errorResponse('Gagal membuat pesanan: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Public endpoint: Customer tracks order status via order code.
     * Masked for privacy protection.
     */
    public function trackPublic(string $code): JsonResponse
    {
        $order = Order::where('order_code', trim($code))->first();

        if (!$order) {
            return $this->notFoundResponse('Pesanan dengan kode tersebut tidak ditemukan.');
        }

        return $this->successResponse(
            $this->orderService->formatPublicTracking($order),
            'Informasi status pesanan.'
        );
    }

    /**
     * Super Admin: List all orders with filters and search.
     */
    public function index(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak mengakses data pesanan.');
        }

        $perPage = (int) $request->input('per_page', 15);
        $filters = [
            'status' => $request->input('status'),
            'search' => $request->input('search'),
        ];

        $orders = $this->orderService->listForSuperAdmin($filters, $perPage);
        $items = collect($orders->items())->map(fn ($o) => $this->orderService->formatOrderForAdmin($o));

        return $this->successResponse([
            'orders'     => $items,
            'pagination' => [
                'total'        => $orders->total(),
                'per_page'     => $orders->perPage(),
                'current_page' => $orders->currentPage(),
                'last_page'    => $orders->lastPage(),
            ],
        ], 'Daftar pesanan pelanggan.');
    }

    /**
     * Super Admin: View detail of a single order.
     */
    public function show(Request $request, Order $order): JsonResponse
    {
        if ($request->user()->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak mengakses data pesanan.');
        }

        return $this->successResponse(
            $this->orderService->formatOrderForAdmin($order),
            'Detail pesanan.'
        );
    }

    /**
     * Super Admin: Update operational status (confirmed or processing).
     * Strictly CANNOT complete order (must use complete endpoint).
     */
    public function updateStatus(Request $request, Order $order): JsonResponse
    {
        if ($request->user()->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak mengubah status pesanan.');
        }

        $validated = $request->validate([
            'status' => 'required|string|in:confirmed,processing',
        ], [
            'status.in' => 'Status yang dapat dipilih hanya confirmed atau processing.',
        ]);

        try {
            $updated = $this->orderService->updateStatus($order, $validated['status']);

            return $this->successResponse(
                $this->orderService->formatOrderForAdmin($updated),
                'Status pesanan berhasil diperbarui menjadi ' . $validated['status'] . '.'
            );
        } catch (\DomainException|\InvalidArgumentException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        } catch (\Throwable $e) {
            return $this->errorResponse('Gagal memperbarui status: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Super Admin: Complete order and create confirmed Sale + decrement stock atomically.
     * Protected by idempotency guard.
     */
    public function complete(Request $request, Order $order): JsonResponse
    {
        if ($request->user()->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak menyelesaikan pesanan.');
        }

        try {
            $completed = $this->orderService->completeOrder($order, $request->user()->id);

            return $this->successResponse(
                $this->orderService->formatOrderForAdmin($completed),
                'Pesanan berhasil diselesaikan. Transaksi penjualan dan pengurangan stok telah tercatat.'
            );
        } catch (\DomainException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        } catch (\Throwable $e) {
            return $this->errorResponse('Gagal menyelesaikan pesanan: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Super Admin: Cancel order.
     */
    public function cancel(Request $request, Order $order): JsonResponse
    {
        if ($request->user()->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak membatalkan pesanan.');
        }

        try {
            $cancelled = $this->orderService->cancelOrder($order);

            return $this->successResponse(
                $this->orderService->formatOrderForAdmin($cancelled),
                'Pesanan berhasil dibatalkan.'
            );
        } catch (\DomainException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        } catch (\Throwable $e) {
            return $this->errorResponse('Gagal membatalkan pesanan: ' . $e->getMessage(), 500);
        }
    }
}
