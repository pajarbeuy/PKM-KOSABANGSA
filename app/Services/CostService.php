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
        return $cost->load(['season', 'season.commodity', 'processedProduct', 'rawMaterialHarvest']);
    }

    /**
     * Update a production cost.
     */
    public function updateCost(ProductionCost $cost, array $data): ProductionCost
    {
        $cost->update($data);
        return $cost->load(['season', 'season.commodity', 'processedProduct', 'rawMaterialHarvest']);
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
            'id'                      => $cost->id,
            'cost_type'               => $cost->cost_type ?? 'farm',
            'season_id'               => $cost->season_id,
            'season_name'             => $cost->season?->name,
            'commodity_id'            => $cost->season?->commodity_id,
            'commodity_name'          => $cost->season?->commodity?->name,
            'processed_product_id'    => $cost->processed_product_id,
            'processed_product_name'  => $cost->processedProduct?->name,
            'raw_material_harvest_id' => $cost->raw_material_harvest_id,
            'raw_material_weight_kg'  => $cost->raw_material_weight_kg !== null ? (float) $cost->raw_material_weight_kg : null,
            'item_name'               => $cost->item_name,
            'quantity'                => $cost->quantity !== null ? (float) $cost->quantity : null,
            'unit'                    => $cost->unit,
            'price_per_unit'          => $cost->price_per_unit !== null ? (float) $cost->price_per_unit : null,
            'date'                    => $cost->date,
            'category'                => $cost->category,
            'amount'                  => (float) $cost->amount,
            'notes'                   => $cost->notes,
        ];
    }
}
