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
