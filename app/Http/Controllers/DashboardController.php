<?php

namespace App\Http\Controllers;

use App\Services\DashboardService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly DashboardService $dashboardService) {}

    public function index(Request $request)
    {
        $userId  = $request->user()->id;
        $summary = $this->dashboardService->getSummary($userId);

        $data = array_merge($summary, [
            'harvests'     => $this->dashboardService->getRecentHarvests($userId),
            'transactions' => $this->dashboardService->getRecentTransactions($userId),
            'profitLoss'   => [
                'revenue' => $summary['totalPenjualan'],
                'cost'    => $summary['totalBiaya'],
                'profit'  => $summary['estimatedProfit'],
            ],
            'monthlyStats' => $this->dashboardService->getMonthlyStats($userId),
        ]);

        unset($data['estimatedProfit']);

        return $this->successResponse($data, 'Data dashboard berhasil diambil.');
    }
}
