<?php

namespace App\Services;

use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\Season;
use App\Exports\ProfitLossExport;
use App\Exports\TargetVsActualExport;

class ReportService
{
    /**
     * Calculate profit/loss summary, optionally filtered by season.
     */
    public function getProfitLoss(int $userId, ?int $seasonId = null): array
    {
        $harvestQuery = Harvest::where('user_id', $userId);
        $saleQuery    = Sale::where('user_id', $userId);
        $costQuery    = ProductionCost::where('user_id', $userId);

        if ($seasonId) {
            $harvestQuery->where('season_id', $seasonId);
            $saleQuery->where('season_id', $seasonId);
            $costQuery->where('season_id', $seasonId);
        }

        $totalHarvest  = (int) $harvestQuery->sum('weight_kg');
        $totalRevenue  = (int) $saleQuery->sum('total');
        $totalCost     = (int) $costQuery->sum('amount');
        $profit        = $totalRevenue - $totalCost;

        return [
            'total_harvest_kg' => $totalHarvest,
            'total_revenue'    => $totalRevenue,
            'total_cost'       => $totalCost,
            'profit'           => $profit,
        ];
    }

    /**
     * Build target-vs-actual data for all user seasons.
     * Uses withSum to avoid N+1 queries.
     */
    public function getTargetVsActual(int $userId): array
    {
        $seasons = Season::where('user_id', $userId)
            ->withSum('harvests', 'weight_kg')
            ->get();

        $data = [];
        foreach ($seasons as $season) {
            $harvest    = (int) ($season->harvests_sum_weight_kg ?? 0);
            $target     = (int) $season->target_kg;
            $percentage = $target > 0 ? round(($harvest / $target) * 100, 2) : 0;

            $data[] = [
                'season_id'   => $season->id,
                'season_name' => $season->name,
                'target'      => $target,
                'actual'      => $harvest,
                'percentage'  => $percentage,
                'status'      => $percentage >= 100 ? 'success' : ($percentage >= 70 ? 'warning' : 'danger'),
            ];
        }

        return $data;
    }

    /**
     * Build target-vs-actual data for export (uses label instead of id).
     */
    public function getTargetVsActualForExport(int $userId, bool $forPdf = false): array
    {
        $seasons = Season::where('user_id', $userId)
            ->withSum('harvests', 'weight_kg')
            ->get();

        $data = [];
        foreach ($seasons as $season) {
            $harvest    = $season->harvests_sum_weight_kg ?? 0;
            $target     = $season->target_kg;
            $percentage = $target > 0 ? round(($harvest / $target) * 100, 2) : 0;

            if ($forPdf) {
                $status = $percentage >= 100 ? 'Tercapai' : ($percentage >= 70 ? 'Hampir' : 'Kurang');
            } else {
                $status = $percentage >= 100 ? 'success' : ($percentage >= 70 ? 'warning' : 'danger');
            }

            $data[] = [
                'season'     => $season->name,
                'target'     => $target,
                'actual'     => $harvest,
                'percentage' => $percentage,
                'status'     => $status,
            ];
        }

        return $data;
    }

    /**
     * Get profit/loss data for export (sales + costs with eager loaded season).
     */
    public function getProfitLossForExport(int $userId, ?int $seasonId = null): array
    {
        $saleQuery = Sale::where('user_id', $userId);
        $costQuery = ProductionCost::where('user_id', $userId);

        if ($seasonId) {
            $saleQuery->where('season_id', $seasonId);
            $costQuery->where('season_id', $seasonId);
        }

        $totalRevenue = $saleQuery->sum('total');
        $totalCost    = $costQuery->sum('amount');
        $sales        = $saleQuery->with('season')->get();
        $costs        = $costQuery->with('season')->get();

        return compact('totalRevenue', 'totalCost', 'sales', 'costs');
    }
}
