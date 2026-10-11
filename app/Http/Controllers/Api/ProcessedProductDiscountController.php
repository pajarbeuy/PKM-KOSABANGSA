<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProcessedProductDiscount;
use App\Services\ProcessedProductDiscountService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class ProcessedProductDiscountController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly ProcessedProductDiscountService $discountService
    ) {}

    /**
     * Get paginated discounts.
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'processed_product_id' => 'nullable|integer|exists:processed_products,id',
            'status'               => 'nullable|string|in:active,upcoming,expired',
            'search'               => 'nullable|string|max:255',
            'per_page'             => 'nullable|integer|min:1|max:100',
        ]);

        $filters = $request->only(['processed_product_id', 'status', 'search']);
        $perPage = (int) $request->input('per_page', 15);

        $discounts = $this->discountService->listDiscounts($filters, $perPage);

        return $this->successResponse([
            'discounts'    => $discounts->items(),
            'pagination'   => [
                'current_page' => $discounts->currentPage(),
                'last_page'    => $discounts->lastPage(),
                'per_page'     => $discounts->perPage(),
                'total'        => $discounts->total(),
            ],
            'data'         => $discounts->items(),
            'current_page' => $discounts->currentPage(),
            'last_page'    => $discounts->lastPage(),
            'per_page'     => $discounts->perPage(),
            'total'        => $discounts->total(),
        ], 'Daftar diskon produk olahan berhasil dimuat.');
    }

    /**
     * Create a new discount for a processed product (Super Admin only).
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak membuat diskon produk olahan.');
        }

        $validated = $request->validate([
            'processed_product_id' => 'required|integer|exists:processed_products,id',
            'discount_percentage'  => 'required|numeric|gt:0|lte:100',
            'start_date'           => 'required|date',
            'end_date'             => 'required|date|after_or_equal:start_date',
        ], [
            'discount_percentage.gt'            => 'Persentase diskon harus lebih besar dari 0%.',
            'discount_percentage.lte'           => 'Persentase diskon maksimal 100%.',
            'end_date.after_or_equal'           => 'Tanggal berakhir diskon harus sama atau setelah tanggal mulai.',
            'processed_product_id.exists'       => 'Produk olahan tidak ditemukan.',
        ]);

        try {
            $discount = $this->discountService->createDiscount($validated, $user->id);
            $discount->load(['processedProduct:id,name,price,stock,unit,owner_id', 'creator:id,name']);

            try {
                $ownerId = $discount->processedProduct?->owner_id;
                if ($ownerId) {
                    $prodName = $discount->processedProduct?->name ?? 'Produk Olahan';
                    $pct = $discount->discount_percentage;
                    $notifService = app(\App\Services\NotificationService::class);
                    $notifService->notifyUser(
                        $ownerId,
                        'discount',
                        'Promosi Diskon Diterapkan',
                        "Diskon {$pct}% diterapkan pada produk '{$prodName}' Anda periode {$discount->start_date} s/d {$discount->end_date}."
                    );
                }
            } catch (\Throwable $e) {}

            return $this->successResponse($discount, 'Diskon produk olahan berhasil ditambahkan.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors(), $e->validator->errors()->first());
        }
    }

    /**
     * Show a discount detail.
     */
    public function show(int $id): JsonResponse
    {
        $discount = ProcessedProductDiscount::with([
            'processedProduct:id,name,price,stock,unit',
            'creator:id,name',
        ])->find($id);

        if (!$discount) {
            return $this->notFoundResponse('Data diskon tidak ditemukan.');
        }

        return $this->successResponse($discount, 'Detail diskon berhasil dimuat.');
    }

    /**
     * Update an existing discount (Super Admin only).
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak memperbarui diskon produk olahan.');
        }

        $discount = ProcessedProductDiscount::find($id);
        if (!$discount) {
            return $this->notFoundResponse('Data diskon tidak ditemukan.');
        }

        $validated = $request->validate([
            'processed_product_id' => 'nullable|integer|exists:processed_products,id',
            'discount_percentage'  => 'nullable|numeric|gt:0|lte:100',
            'start_date'           => 'nullable|date',
            'end_date'             => 'nullable|date|after_or_equal:start_date',
        ], [
            'discount_percentage.gt'  => 'Persentase diskon harus lebih besar dari 0%.',
            'discount_percentage.lte' => 'Persentase diskon maksimal 100%.',
            'end_date.after_or_equal' => 'Tanggal berakhir diskon harus sama atau setelah tanggal mulai.',
        ]);

        try {
            $updated = $this->discountService->updateDiscount($discount, $validated);

            return $this->successResponse($updated, 'Diskon produk olahan berhasil diperbarui.');
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors(), $e->validator->errors()->first());
        }
    }

    /**
     * Delete a discount (Super Admin only).
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak menghapus diskon produk olahan.');
        }

        $discount = ProcessedProductDiscount::find($id);
        if (!$discount) {
            return $this->notFoundResponse('Data diskon tidak ditemukan.');
        }

        $this->discountService->deleteDiscount($discount);

        return $this->successResponse(null, 'Diskon produk olahan berhasil dihapus.');
    }
}
