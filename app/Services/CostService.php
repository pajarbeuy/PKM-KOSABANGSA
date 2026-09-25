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
        $cost = ProductionCost::create(array_merge($data, ['user_id' => $userId]));
        return $cost->load(['season', 'season.commodity']);
    }

    /**
     * Update a production cost.
     */
    public function updateCost(ProductionCost $cost, array $data): ProductionCost
    {
        $cost->update($data);
        return $cost->load(['season', 'season.commodity']);
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
            'id'             => $cost->id,
            'season_id'      => $cost->season_id,
            'season_name'    => $cost->season?->name,
            'commodity_id'   => $cost->season?->commodity_id,
            'commodity_name' => $cost->season?->commodity?->name,
            'date'           => $cost->date,
            'category'       => $cost->category,
            'amount'         => (float) $cost->amount,
            'notes'          => $cost->notes,
        ];
    }
}
