<?php

namespace App\Services;

use App\Models\ProductionCost;

class CostService
{
    /**
     * Create a new production cost.
     */
    public function createCost(array $data, int $userId): ProductionCost
    {
        return ProductionCost::create(array_merge($data, ['user_id' => $userId]));
    }

    /**
     * Update a production cost.
     */
    public function updateCost(ProductionCost $cost, array $data): ProductionCost
    {
        $cost->update($data);
        return $cost;
    }

    /**
     * Delete a production cost (soft delete).
     */
    public function deleteCost(ProductionCost $cost): void
    {
        $cost->delete();
    }

    /**
     * Format a cost for API response.
     */
    public function formatCost(ProductionCost $cost): array
    {
        return [
            'id'       => $cost->id,
            'date'     => $cost->date,
            'category' => $cost->category,
            'amount'   => $cost->amount,
            'notes'    => $cost->notes,
        ];
    }
}
