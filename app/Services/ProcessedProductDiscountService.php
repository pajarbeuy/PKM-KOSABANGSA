<?php

namespace App\Services;

use App\Models\ProcessedProduct;
use App\Models\ProcessedProductDiscount;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Validation\ValidationException;

class ProcessedProductDiscountService
{
    /**
     * Get paginated discounts with relationships.
     */
    public function listDiscounts(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = ProcessedProductDiscount::with([
            'processedProduct:id,name,price,stock,unit',
            'creator:id,name',
        ])->latest('start_date');

        if (!empty($filters['processed_product_id'])) {
            $query->where('processed_product_id', $filters['processed_product_id']);
        }

        $today = now()->toDateString();

        if (!empty($filters['search'])) {
            $search = $filters['search'];
            $query->whereHas('processedProduct', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%");
            });
        }

        if (!empty($filters['status'])) {
            if ($filters['status'] === 'active') {
                $query->whereDate('start_date', '<=', $today)->whereDate('end_date', '>=', $today);
            } elseif ($filters['status'] === 'upcoming') {
                $query->whereDate('start_date', '>', $today);
            } elseif ($filters['status'] === 'expired') {
                $query->whereDate('end_date', '<', $today);
            }
        }

        return $query->paginate($perPage);
    }

    /**
     * Create a new discount. Rejects if overlapping discount exists for the same product.
     */
    public function createDiscount(array $data, int $userId): ProcessedProductDiscount
    {
        $productId = (int) $data['processed_product_id'];
        $startDate = $data['start_date'];
        $endDate   = $data['end_date'];

        if ($this->hasOverlap($productId, $startDate, $endDate)) {
            throw ValidationException::withMessages([
                'start_date' => ["Terdapat diskon yang sedang aktif atau bertumpukan (overlap) pada periode {$startDate} s/d {$endDate} untuk produk ini."],
            ]);
        }

        return ProcessedProductDiscount::create([
            'processed_product_id' => $productId,
            'discount_percentage'  => (float) $data['discount_percentage'],
            'start_date'           => $startDate,
            'end_date'             => $endDate,
            'created_by'           => $userId,
        ]);
    }

    /**
     * Update an existing discount. Rejects if overlapping with other discounts.
     */
    public function updateDiscount(ProcessedProductDiscount $discount, array $data): ProcessedProductDiscount
    {
        $productId = isset($data['processed_product_id']) ? (int) $data['processed_product_id'] : $discount->processed_product_id;
        $startDate = $data['start_date'] ?? $discount->start_date->toDateString();
        $endDate   = $data['end_date'] ?? $discount->end_date->toDateString();

        if ($this->hasOverlap($productId, $startDate, $endDate, $discount->id)) {
            throw ValidationException::withMessages([
                'start_date' => ["Terdapat diskon lain yang bertumpukan (overlap) pada periode {$startDate} s/d {$endDate} untuk produk ini."],
            ]);
        }

        $discount->update([
            'processed_product_id' => $productId,
            'discount_percentage'  => isset($data['discount_percentage']) ? (float) $data['discount_percentage'] : $discount->discount_percentage,
            'start_date'           => $startDate,
            'end_date'             => $endDate,
        ]);

        return $discount->fresh(['processedProduct', 'creator']);
    }

    /**
     * Delete discount.
     */
    public function deleteDiscount(ProcessedProductDiscount $discount): void
    {
        $discount->delete();
    }

    /**
     * Check if an overlapping discount period exists for the product.
     * Formula: (start_date <= existing.end_date) AND (end_date >= existing.start_date)
     */
    public function hasOverlap(int $productId, string $startDate, string $endDate, ?int $ignoreDiscountId = null): bool
    {
        return ProcessedProductDiscount::where('processed_product_id', $productId)
            ->when($ignoreDiscountId, fn($q) => $q->where('id', '!=', $ignoreDiscountId))
            ->where(function ($query) use ($startDate, $endDate) {
                $query->whereDate('start_date', '<=', $endDate)
                      ->whereDate('end_date', '>=', $startDate);
            })
            ->exists();
    }
}
