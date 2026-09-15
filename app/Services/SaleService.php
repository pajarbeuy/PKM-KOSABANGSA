<?php

namespace App\Services;

use App\Models\Sale;
use App\Models\StockTransaction;

class SaleService
{
    /**
     * Normalize field aliases coming from different client versions.
     * Maps: quantity→weight_kg, price_per_unit→price_per_kg, sale_date→date, status→payment_status
     */
    public function normalizeData(array $data): array
    {
        return [
            'weight_kg'      => $data['weight_kg'] ?? $data['quantity'] ?? 0,
            'price_per_kg'   => $data['price_per_kg'] ?? $data['price_per_unit'] ?? 0,
            'date'           => $data['date'] ?? $data['sale_date'] ?? now()->toDateString(),
            'payment_status' => $this->resolvePaymentStatus($data),
            'season_id'      => $data['season_id'] ?? null,
            'buyer_name'     => $data['buyer_name'],
            'buyer_phone'    => $data['buyer_phone'] ?? null,
            'buyer_address'  => $data['buyer_address'] ?? null,
            'notes'          => $data['notes'] ?? null,
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
     * Check if sufficient stock exists for a given quantity.
     */
    public function hasSufficientStock(float $weightKg, int $userId): bool
    {
        return StockTransaction::getCurrentBalance($userId) >= $weightKg;
    }

    /**
     * Get current stock balance for a user.
     */
    public function getCurrentStock(int $userId): float
    {
        return StockTransaction::getCurrentBalance($userId);
    }

    /**
     * Create a sale and deduct stock.
     */
    public function createSale(array $normalized, int $userId): Sale
    {
        $total = $normalized['weight_kg'] * $normalized['price_per_kg'];

        $sale = Sale::create([
            'user_id'        => $userId,
            'season_id'      => $normalized['season_id'],
            'date'           => $normalized['date'],
            'buyer_name'     => $normalized['buyer_name'],
            'buyer_phone'    => $normalized['buyer_phone'],
            'buyer_address'  => $normalized['buyer_address'],
            'weight_kg'      => $normalized['weight_kg'],
            'price_per_kg'   => $normalized['price_per_kg'],
            'total'          => $total,
            'payment_status' => $normalized['payment_status'],
            'notes'          => $normalized['notes'],
        ]);

        StockTransaction::addTransaction(
            'out',
            $normalized['weight_kg'],
            'Penjualan',
            'sale_' . $sale->id,
            $userId
        );

        return $sale;
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
        $sale->update($dbData);

        // Adjust stock if weight changed
        if (isset($dbData['weight_kg']) && $oldWeight != $dbData['weight_kg']) {
            $difference = $oldWeight - $dbData['weight_kg'];
            StockTransaction::addTransaction(
                $difference > 0 ? 'in' : 'out',
                abs($difference),
                'Penjualan diupdate',
                'sale_' . $sale->id,
                $userId
            );
        }

        return $sale;
    }

    /**
     * Delete a sale and return the weight to stock.
     */
    public function deleteSale(Sale $sale, int $userId): void
    {
        $oldWeight = $sale->weight_kg;
        $sale->delete();

        StockTransaction::addTransaction(
            'in',
            $oldWeight,
            'Penjualan dihapus',
            'sale_deleted',
            $userId
        );
    }

    /**
     * Format a sale model for API response.
     */
    public function formatSale(Sale $sale, string $event = 'created'): array
    {
        $base = [
            'id'            => $sale->id,
            'sale_date'     => $sale->date->toDateString(),
            'buyer_name'    => $sale->buyer_name,
            'buyer_phone'   => $sale->buyer_phone,
            'buyer_address' => $sale->buyer_address,
            'quantity'      => (int) $sale->weight_kg,
            'price_per_unit' => (int) $sale->price_per_kg,
            'total_price'   => (int) $sale->total,
            'notes'         => $sale->notes,
            'status'        => $sale->payment_status === 'paid' ? 'completed' : 'pending',
        ];

        if ($event === 'created') {
            $base['created_at'] = $sale->created_at->toIso8601String();
        } else {
            $base['updated_at'] = $sale->updated_at->toIso8601String();
        }

        return $base;
    }
}
