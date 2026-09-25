<?php

namespace App\Services;

use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Season;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * FarmerEconomicResultService — Phase 6
 *
 * Formula:
 *   Revenue = weight_kg × Historical Market Price Snapshot
 *   Harvest Allocated Cost = (harvest.weight_kg / total_season_harvest_weight_kg) × season_total_cost
 *   Harvest Profit/Loss = Harvest Revenue - Harvest Allocated Cost
 *
 * Aturan:
 *   Jika market_price_snapshot = NULL:
 *     Revenue = NULL
 *     Profit/Loss = NULL
 *   (Jangan dianggap Revenue = 0)
 *
 * Untuk season:
 *   Season Revenue = Σ harvest revenue yang valid
 *   Season Production Cost = total biaya produksi musim
 *   Season Profit/Loss = Season Revenue - Season Production Cost
 *
 * Catatan penting:
 *   Harga yang digunakan tetap harga pada snapshot panen (Phase 5), bukan harga pasar terbaru.
 */
class FarmerEconomicResultService
{
    // ─── Per-Harvest Economic Result ──────────────────────────────────────────

    /**
     * Hitung hasil ekonomi untuk satu catatan panen.
     *
     * @param  Harvest  $harvest
     * @return array
     */
    public function getHarvestEconomicResult(Harvest $harvest): array
    {
        $weightKg      = (float) $harvest->weight_kg;
        $priceSnapshot = $harvest->market_price_snapshot !== null
            ? (float) $harvest->market_price_snapshot
            : null;

        // Aturan:
        // Jika market_price_snapshot = NULL:
        //   Revenue = NULL
        //   Profit/Loss = NULL
        //   Jangan dianggap Revenue = 0.
        $revenue = null;
        if ($priceSnapshot !== null) {
            $revenue = round($weightKg * $priceSnapshot, 2);
        }

        // Harvest Allocated Cost = (harvest.weight_kg / total_season_harvest_weight_kg) × season_total_cost
        $allocatedCost = null;
        if ($harvest->season_id) {
            $allocatedCost = $this->allocateCostToHarvest($harvest);
        }

        // Harvest Profit/Loss = Harvest Revenue - Harvest Allocated Cost
        $profitLoss = null;
        if ($revenue !== null && $allocatedCost !== null) {
            $profitLoss = round($revenue - $allocatedCost, 2);
        }

        return [
            'harvest_id'                  => $harvest->id,
            'harvest_date'                => $harvest->date?->toDateString(),
            'season_id'                   => $harvest->season_id,
            'season_name'                 => $harvest->season?->name ?? 'N/A',
            'commodity_id'                => $harvest->commodity_id,
            'commodity_name'              => $harvest->commodity?->name ?? null,
            'weight_kg'                   => (float) $weightKg,
            'quantity'                    => (float) ($harvest->quantity ?? 0),
            'unit'                        => $harvest->unit ?? 'kg',
            'market_price_snapshot'       => $priceSnapshot !== null ? (float) $priceSnapshot : null,
            'market_price_effective_date' => $harvest->market_price_effective_date?->toDateString(),
            'revenue'                     => $revenue !== null ? (float) $revenue : null,
            'gross_harvest_value'         => $revenue !== null ? (float) $revenue : null,
            'allocated_production_cost'   => $allocatedCost !== null ? (float) $allocatedCost : null,
            'profit_loss'                 => $profitLoss !== null ? (float) $profitLoss : null,
            'profit_loss_status'          => $profitLoss === null ? null : ($profitLoss >= 0 ? 'profit' : 'loss'),
        ];
    }

    // ─── Per-Season Economic Summary ──────────────────────────────────────────

    /**
     * Hitung ringkasan ekonomi per musim tanam.
     *
     * Season Revenue = Σ harvest revenue yang valid
     * Season Production Cost = total biaya produksi musim
     * Season Profit/Loss = Season Revenue - Season Production Cost
     *
     * @param  Season  $season
     * @param  int     $userId
     * @return array
     */
    public function getSeasonEconomicSummary(Season $season, int $userId): array
    {
        $harvests = Harvest::where('season_id', $season->id)
            ->where('user_id', $userId)
            ->with(['commodity', 'marketPrice'])
            ->get();

        $totalWeightKg   = (float) $harvests->sum('weight_kg');
        $totalSeasonCost = (float) ProductionCost::where('season_id', $season->id)
            ->where('user_id', $userId)
            ->sum('amount');

        $harvestResults    = [];
        $validRevenueSum   = 0.0;
        $validRevenueCount = 0;
        $totalAllocated    = 0.0;
        $hasAllPrices      = true;

        foreach ($harvests as $h) {
            $result = $this->getHarvestEconomicResult($h);
            $harvestResults[] = $result;

            if ($result['revenue'] !== null) {
                $validRevenueSum += $result['revenue'];
                $validRevenueCount++;
            } else {
                $hasAllPrices = false;
            }

            if ($result['allocated_production_cost'] !== null) {
                $totalAllocated += $result['allocated_production_cost'];
            }
        }

        // Season Revenue = Σ harvest revenue yang valid
        $seasonRevenue = $validRevenueCount > 0 ? round($validRevenueSum, 2) : null;

        // Season Profit/Loss = Season Revenue - Season Production Cost
        $seasonProfitLoss = $seasonRevenue !== null ? round($seasonRevenue - $totalSeasonCost, 2) : null;

        return [
            'season_id'                 => $season->id,
            'season_name'               => $season->name,
            'season_start'              => $season->start_date?->toDateString(),
            'season_end'                => $season->end_date?->toDateString(),
            'commodity_id'              => $season->commodity_id,
            'commodity_name'            => $season->commodity?->name ?? null,
            'total_weight_kg'           => (float) $totalWeightKg,
            'harvest_count'             => $harvests->count(),
            'season_revenue'            => $seasonRevenue !== null ? (float) $seasonRevenue : null,
            'total_gross_harvest_value' => $seasonRevenue !== null ? (float) $seasonRevenue : null,
            'season_production_cost'    => (float) $totalSeasonCost,
            'total_production_cost'     => (float) $totalSeasonCost,
            'season_profit_loss'        => $seasonProfitLoss !== null ? (float) $seasonProfitLoss : null,
            'total_profit_loss'         => $seasonProfitLoss !== null ? (float) $seasonProfitLoss : null,
            'profit_loss_status'        => $seasonProfitLoss === null ? null : ($seasonProfitLoss >= 0 ? 'profit' : 'loss'),
            'has_complete_price_data'   => $hasAllPrices,
            'harvests'                  => $harvestResults,
        ];
    }

    // ─── Per-Farmer All Seasons Summary ───────────────────────────────────────

    /**
     * Ringkasan ekonomi keseluruhan untuk satu petani (semua musim).
     *
     * @param  int  $userId
     * @return array
     */
    public function getFarmerEconomicSummary(int $userId): array
    {
        $seasons = Season::where('user_id', $userId)
            ->with(['commodity'])
            ->orderByDesc('start_date')
            ->get();

        $seasonSummaries    = [];
        $grandTotalRevenue  = 0.0;
        $grandTotalCost     = 0.0;
        $grandTotalWeightKg = 0.0;
        $hasAnyValidRevenue = false;

        foreach ($seasons as $season) {
            $summary = $this->getSeasonEconomicSummary($season, $userId);
            $seasonSummaries[] = $summary;

            if ($summary['season_revenue'] !== null) {
                $grandTotalRevenue += $summary['season_revenue'];
                $hasAnyValidRevenue = true;
            }

            $grandTotalCost     += $summary['season_production_cost'];
            $grandTotalWeightKg += $summary['total_weight_kg'];
        }

        $farmerRevenue   = $hasAnyValidRevenue ? round($grandTotalRevenue, 2) : null;
        $grandProfitLoss = $farmerRevenue !== null ? round($farmerRevenue - $grandTotalCost, 2) : null;

        return [
            'total_weight_kg'           => (float) $grandTotalWeightKg,
            'revenue'                   => $farmerRevenue !== null ? (float) $farmerRevenue : null,
            'total_gross_harvest_value' => $farmerRevenue !== null ? (float) $farmerRevenue : null,
            'total_production_cost'     => (float) $grandTotalCost,
            'total_profit_loss'         => $grandProfitLoss !== null ? (float) $grandProfitLoss : null,
            'profit_loss_status'        => $grandProfitLoss === null ? null : ($grandProfitLoss >= 0 ? 'profit' : 'loss'),
            'season_count'              => $seasons->count(),
            'seasons'                   => $seasonSummaries,
        ];
    }

    // ─── Super Admin Aggregate ────────────────────────────────────────────────

    /**
     * Agregat hasil ekonomi seluruh petani (untuk Super Admin).
     *
     * @return array
     */
    public function getSuperAdminEconomicAggregate(): array
    {
        $farmers = User::where('role', 'user')->orderBy('name')->get();

        $farmerSummaries      = [];
        $platformTotalRevenue = 0.0;
        $platformTotalCost    = 0.0;
        $platformTotalProfit  = 0.0;

        foreach ($farmers as $farmer) {
            $summary = $this->getFarmerEconomicSummary($farmer->id);

            $farmerSummaries[] = [
                'farmer_id'                 => $farmer->id,
                'farmer_name'               => $farmer->name,
                'farm_name'                 => $farmer->farm_name,
                'total_weight_kg'           => $summary['total_weight_kg'],
                'revenue'                   => $summary['revenue'],
                'total_gross_harvest_value' => $summary['total_gross_harvest_value'],
                'total_production_cost'     => $summary['total_production_cost'],
                'total_profit_loss'         => $summary['total_profit_loss'],
                'profit_loss_status'        => $summary['profit_loss_status'],
            ];

            if ($summary['revenue'] !== null) {
                $platformTotalRevenue += $summary['revenue'];
            }
            $platformTotalCost += $summary['total_production_cost'];
            if ($summary['total_profit_loss'] !== null) {
                $platformTotalProfit += $summary['total_profit_loss'];
            }
        }

        return [
            'platform_total_revenue'             => round($platformTotalRevenue, 2),
            'platform_total_gross_harvest_value' => round($platformTotalRevenue, 2),
            'platform_total_production_cost'     => round($platformTotalCost, 2),
            'platform_total_profit_loss'         => round($platformTotalProfit, 2),
            'farmer_count'                       => $farmers->count(),
            'farmers'                            => $farmerSummaries,
        ];
    }

    // ─── Processed Product Economic Summary ──────────────────────────────────

    /**
     * Hitung ringkasan modal dan laba/rugi untuk satu produk olahan (Hilir).
     *
     * Aturan:
     * - Bahan baku dari panen sendiri bernilai tunai Rp 0 (karena sudah ditanggung biaya kebun)
     * - Modal pengolahan = Σ biaya bahan penolong (tepung, minyak, packaging, utility, labor)
     * - Laba Bersih Olahan = Penjualan Olahan - Modal Bahan Penolong
     *
     * @param  \App\Models\ProcessedProduct  $product
     * @return array
     */
    public function getProcessedProductEconomicSummary(\App\Models\ProcessedProduct $product): array
    {
        $product->loadMissing(['costs', 'sales', 'owner', 'rawMaterialHarvest']);

        $costs = $product->costs;
        $totalProcessingCost = (float) $costs->sum('amount');

        $paidSales = $product->sales->where('payment_status', 'paid');
        $unitsSold = (int) $paidSales->sum('weight_kg'); // weight_kg stores quantity for processed sales
        $realizedRevenue = (float) $paidSales->sum('total');
        $realizedProfitLoss = round($realizedRevenue - $totalProcessingCost, 2);

        $currentStock = (int) $product->stock;
        $totalPotentialUnits = $unitsSold + $currentStock;
        $unitPrice = (float) $product->price;
        $potentialRevenue = round($totalPotentialUnits * $unitPrice, 2);
        $potentialProfitLoss = round($potentialRevenue - $totalProcessingCost, 2);

        $costPerUnit = $totalPotentialUnits > 0
            ? round($totalProcessingCost / $totalPotentialUnits, 2)
            : 0.0;

        $costBreakdown = $costs->map(function ($c) {
            return [
                'id'             => $c->id,
                'category'       => $c->category,
                'item_name'      => $c->item_name,
                'quantity'       => $c->quantity !== null ? (float) $c->quantity : null,
                'unit'           => $c->unit,
                'price_per_unit' => $c->price_per_unit !== null ? (float) $c->price_per_unit : null,
                'amount'         => (float) $c->amount,
                'date'           => $c->date?->toDateString(),
                'notes'          => $c->notes,
            ];
        })->values();

        return [
            'product_id'             => $product->id,
            'product_name'           => $product->name,
            'owner_id'               => $product->owner_id,
            'owner_name'             => $product->owner?->farm_name ?? $product->owner?->name,
            'price_per_unit'         => $unitPrice,
            'unit'                   => $product->unit ?? 'pcs',
            'current_stock'          => $currentStock,
            'units_sold'             => $unitsSold,
            'raw_material_harvest_id'=> $product->harvest_id,
            'raw_material_weight_kg' => (float) ($product->raw_material_weight_kg ?? 0),
            'raw_material_cost'      => 0.0, // Bahan baku kebun bebas biaya tunai baru (mencegah double-counting)
            'total_processing_cost'  => (float) $totalProcessingCost,
            'cost_per_unit'          => (float) $costPerUnit,
            'realized_revenue'       => (float) $realizedRevenue,
            'realized_profit_loss'   => (float) $realizedProfitLoss,
            'realized_status'        => $realizedProfitLoss >= 0 ? 'profit' : 'loss',
            'potential_revenue'      => (float) $potentialRevenue,
            'potential_profit_loss'  => (float) $potentialProfitLoss,
            'potential_status'       => $potentialProfitLoss >= 0 ? 'profit' : 'loss',
            'costs'                  => $costBreakdown,
        ];
    }

    // ─── Integrated Agribusiness Profit & Loss (Hulu + Hilir) ────────────────

    /**
     * Hitung total laba/rugi terpadu agribisnis petani:
     * Laba Bersih Terpadu = Laba Panen (Hulu) + Laba Produk Olahan (Hilir).
     *
     * @param  int  $farmerId
     * @return array
     */
    public function getIntegratedEconomicSummary(int $farmerId): array
    {
        // 1. Sisi Hulu (Budidaya & Panen Mentah)
        $farmSummary = $this->getFarmerEconomicSummary($farmerId);

        // 2. Sisi Hilir (Produk Olahan)
        $products = \App\Models\ProcessedProduct::where('owner_id', $farmerId)->get();

        $processedSummaries          = [];
        $totalRawMaterialAllocatedKg = 0.0;
        $totalProcessingCost         = 0.0;
        $totalProcessedRevenue       = 0.0;
        $totalProcessedProfitLoss    = 0.0;

        foreach ($products as $prod) {
            $pSummary = $this->getProcessedProductEconomicSummary($prod);
            $processedSummaries[] = $pSummary;

            $totalRawMaterialAllocatedKg += $pSummary['raw_material_weight_kg'];
            $totalProcessingCost         += $pSummary['total_processing_cost'];
            $totalProcessedRevenue       += $pSummary['realized_revenue'];
            $totalProcessedProfitLoss    += $pSummary['realized_profit_loss'];
        }

        // 3. Sisi Terpadu (Grand Total Agribisnis Terpadu Petani)
        $farmRevenue    = $farmSummary['revenue'];
        $farmCost       = (float) $farmSummary['total_production_cost'];
        $farmProfitLoss = $farmSummary['total_profit_loss'];

        $integratedRevenue = ($farmRevenue !== null ? (float) $farmRevenue : 0.0) + (float) $totalProcessedRevenue;
        $integratedCost    = round($farmCost + $totalProcessingCost, 2);
        
        $integratedProfitLoss = null;
        if ($farmProfitLoss !== null) {
            $integratedProfitLoss = round($farmProfitLoss + $totalProcessedProfitLoss, 2);
        } else {
            $integratedProfitLoss = round($totalProcessedRevenue - $totalProcessingCost, 2);
        }

        return [
            'farmer_id'                   => $farmerId,
            // Hulu:
            'farm_harvest_weight_kg'      => (float) $farmSummary['total_weight_kg'],
            'raw_material_allocated_kg'   => (float) round($totalRawMaterialAllocatedKg, 2),
            'net_harvest_market_weight_kg'=> (float) max(0, round($farmSummary['total_weight_kg'] - $totalRawMaterialAllocatedKg, 2)),
            'farm_revenue'                => $farmRevenue,
            'farm_production_cost'        => (float) $farmCost,
            'farm_profit_loss'            => $farmProfitLoss,
            'farm_profit_loss_status'     => $farmSummary['profit_loss_status'],

            // Hilir:
            'processed_product_count'     => $products->count(),
            'processing_production_cost'  => (float) round($totalProcessingCost, 2),
            'processed_revenue'           => (float) round($totalProcessedRevenue, 2),
            'processed_profit_loss'       => (float) round($totalProcessedProfitLoss, 2),
            'processed_profit_loss_status'=> $totalProcessedProfitLoss >= 0 ? 'profit' : 'loss',
            'processed_products'          => $processedSummaries,

            // Terpadu (Integrated Grand Total):
            'total_integrated_revenue'    => (float) round($integratedRevenue, 2),
            'total_integrated_cost'       => (float) round($integratedCost, 2),
            'total_integrated_profit_loss'=> $integratedProfitLoss,
            'integrated_profit_loss_status'=> $integratedProfitLoss === null ? null : ($integratedProfitLoss >= 0 ? 'profit' : 'loss'),
        ];
    }

    // ─── Private Helpers ──────────────────────────────────────────────────────

    /**
     * Alokasikan biaya musim ke satu panen secara proporsional berdasarkan weight_kg.
     *
     * Formula:
     *   Harvest Allocated Cost = (harvest.weight_kg / total_season_harvest_weight_kg) × season_total_cost
     *
     * @return float|null
     */
    private function allocateCostToHarvest(Harvest $harvest): ?float
    {
        if (!$harvest->season_id) {
            return 0.0;
        }

        // Total berat seluruh panen dalam musim yang sama (oleh petani yang sama)
        $totalSeasonWeightKg = (float) Harvest::where('season_id', $harvest->season_id)
            ->where('user_id', $harvest->user_id)
            ->sum('weight_kg');

        if ($totalSeasonWeightKg <= 0) {
            return 0.0;
        }

        // Total biaya produksi musim ini
        $totalSeasonCost = (float) ProductionCost::where('season_id', $harvest->season_id)
            ->where('user_id', $harvest->user_id)
            ->sum('amount');

        if ($totalSeasonCost <= 0) {
            return 0.0;
        }

        $proportion = (float) $harvest->weight_kg / $totalSeasonWeightKg;
        return round($proportion * $totalSeasonCost, 2);
    }
}
