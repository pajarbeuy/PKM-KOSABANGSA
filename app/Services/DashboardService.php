<?php

namespace App\Services;

use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\Season;
use App\Models\Setting;
use App\Models\StockTransaction;

class DashboardService
{
    /**
     * Get all dashboard summary data for a user.
     */
    public function getSummary(int $userId): array
    {
        $activeSeason    = Season::where('user_id', $userId)
            ->where('status', '!=', 'cancelled')
            ->whereDate('start_date', '<=', today())
            ->whereDate('end_date', '>=', today())
            ->latest('start_date')
            ->first();
        $stockBalance    = (float) StockTransaction::getCurrentBalance($userId);
        $totalRevenue    = (float) Sale::where('user_id', $userId)->sum('total');
        $totalCost       = (float) ProductionCost::where('user_id', $userId)->sum('amount');
        $estimatedProfit = $totalRevenue - $totalCost;
        $totalHarvest    = (float) Harvest::where('user_id', $userId)->sum('weight_kg');

        $rawSalesRev       = (float) Sale::where('user_id', $userId)
            ->where(fn($q) => $q->where('product_type', 'harvest')->orWhereNull('product_type'))
            ->sum('total');
        $rawSalesKg        = (float) Sale::where('user_id', $userId)
            ->where(fn($q) => $q->where('product_type', 'harvest')->orWhereNull('product_type'))
            ->sum('weight_kg');
        $processedSalesRev = (float) Sale::where('user_id', $userId)
            ->where('product_type', 'processed')
            ->sum('total');
        $processedSalesPcs = (float) Sale::where('user_id', $userId)
            ->where('product_type', 'processed')
            ->sum('weight_kg');

        return [
            'totalStok'               => $stockBalance,
            'totalPenjualan'          => $totalRevenue,
            'totalBiaya'              => $totalCost,
            'totalPanen'              => $totalHarvest,
            'estimatedProfit'         => $estimatedProfit,
            'totalRawSalesKg'         => $rawSalesKg,
            'totalRawSalesRp'         => $rawSalesRev,
            'totalProcessedSalesPcs'  => $processedSalesPcs,
            'totalProcessedSalesRp'   => $processedSalesRev,
            'targetPanen'             => (float) ($activeSeason?->target_kg ?? 0),
            'minStock'                => (int) Setting::get('min_stock', 100),
            'maxStock'                => (int) Setting::get('max_stock', 5000),
            'notifyLowStock'          => (bool) Setting::get('notify_low_stock', 1),
            'notifyNewSale'           => (bool) Setting::get('notify_new_sale', 1),
            'notifyCost'              => (bool) Setting::get('notify_cost', 1),
        ];
    }

    /**
     * Get 5 most recent harvests for a user.
     */
    public function getRecentHarvests(int $userId): array
    {
        return Harvest::where('user_id', $userId)
            ->with('season')
            ->latest('date')
            ->take(5)
            ->get()
            ->map(fn ($h) => [
                'id'          => $h->id,
                'season_name' => $h->season?->name ?? 'N/A',
                'quantity'    => (int) $h->weight_kg,
                'status'      => $h->status,
            ])
            ->toArray();
    }

    /**
     * Get 5 most recent stock transactions for a user.
     */
    public function getRecentTransactions(int $userId): array
    {
        return StockTransaction::where('user_id', $userId)
            ->latest('date')
            ->take(5)
            ->get()
            ->map(fn ($t) => [
                'id'         => $t->id,
                'type'       => $t->type,
                'quantity'   => (int) $t->amount,
                'created_at' => $t->created_at->toIso8601String(),
            ])
            ->toArray();
    }

    /**
     * Get monthly harvest and sales stats for the last 6 months,
     * anchored to the latest recorded data date (or now, whichever is later).
     */
    public function getMonthlyStats(int $userId): array
    {
        $latestHarvest = Harvest::where('user_id', $userId)->max('date');
        $latestSale    = Sale::where('user_id', $userId)->max('date');

        $referenceDate = now();
        if ($latestHarvest) {
            $hDate = \Carbon\Carbon::parse($latestHarvest);
            if ($hDate->isAfter($referenceDate)) {
                $referenceDate = $hDate;
            }
        }
        if ($latestSale) {
            $sDate = \Carbon\Carbon::parse($latestSale);
            if ($sDate->isAfter($referenceDate)) {
                $referenceDate = $sDate;
            }
        }

        $monthsIndo = [
            1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'Mei', 6 => 'Jun',
            7 => 'Jul', 8 => 'Agt', 9 => 'Sep', 10 => 'Okt', 11 => 'Nov', 12 => 'Des',
        ];

        $monthlyStats = [];
        for ($i = 5; $i >= 0; $i--) {
            $date     = $referenceDate->copy()->subMonths($i);
            $monthNum = $date->month;
            $year     = $date->year;

            $harvestSum = (float) Harvest::where('user_id', $userId)
                ->whereYear('date', $year)
                ->whereMonth('date', $monthNum)
                ->sum('weight_kg');

            // Raw harvest sales (in kg)
            $harvestSalesSum = (float) Sale::where('user_id', $userId)
                ->whereYear('date', $year)
                ->whereMonth('date', $monthNum)
                ->where(function ($q) {
                    $q->where('product_type', 'harvest')
                      ->orWhereNull('product_type');
                })
                ->sum('weight_kg');

            // Raw harvest revenue (in Rp)
            $harvestRevenueSum = (float) Sale::where('user_id', $userId)
                ->whereYear('date', $year)
                ->whereMonth('date', $monthNum)
                ->where(function ($q) {
                    $q->where('product_type', 'harvest')
                      ->orWhereNull('product_type');
                })
                ->sum('total');

            // Processed product sales (in pcs / unit)
            $processedSalesSum = (float) Sale::where('user_id', $userId)
                ->whereYear('date', $year)
                ->whereMonth('date', $monthNum)
                ->where('product_type', 'processed')
                ->sum('weight_kg');

            // Processed product revenue (in Rp)
            $processedRevenueSum = (float) Sale::where('user_id', $userId)
                ->whereYear('date', $year)
                ->whereMonth('date', $monthNum)
                ->where('product_type', 'processed')
                ->sum('total');

            $monthlyStats[] = [
                'label'               => $monthsIndo[$monthNum] ?? $date->format('M'),
                'harvest'             => $harvestSum,
                'sales'               => $harvestSalesSum, // Bahan mentah kg
                'harvest_kg'          => $harvestSum,
                'harvest_sales_kg'    => $harvestSalesSum,
                'harvest_sales_rp'    => $harvestRevenueSum,
                'processed_sales_pcs' => $processedSalesSum,
                'processed_sales_rp'  => $processedRevenueSum,
                'sales_harvest'       => $harvestSalesSum,
                'sales_processed'     => $processedSalesSum,
                'sales_unit'          => 'kg',
            ];
        }

        return $monthlyStats;
    }
}


