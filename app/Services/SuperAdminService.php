<?php

namespace App\Services;

use App\Models\DashboardMenu;
use App\Models\LandingContent;
use App\Models\LoginLog;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;

class SuperAdminService
{
    // ─── User Management ────────────────────────────────────────────────────────

    /**
     * List all users ordered by newest first.
     */
    public function getAllUsers()
    {
        return User::with('farmerGroup')->latest()->get();
    }

    /**
     * Create a new user (from super admin panel).
     */
    public function createUser(array $data): User
    {
        $data['password'] = Hash::make($data['password']);
        return User::create($data);
    }

    /**
     * Update an existing user.
     */
    public function updateUser(User $user, array $data): User
    {
        if (isset($data['password']) && $data['password']) {
            $data['password'] = Hash::make($data['password']);
        } else {
            unset($data['password']);
        }

        $user->update($data);
        return $user->fresh(['farmerGroup']);
    }

    /**
     * Delete a user, preventing deletion of the last super admin.
     * Returns null on success, or an error message string on failure.
     */
    public function deleteUser(User $user): ?string
    {
        if ($user->role === 'super_admin' && User::where('role', 'super_admin')->count() === 1) {
            return 'Tidak bisa menghapus super admin terakhir.';
        }

        $user->delete();
        return null;
    }

    /**
     * Create an impersonation token for a target user (non-super-admin only).
     * Returns null if target is a super admin.
     */
    public function impersonate(User $user): ?string
    {
        if ($user->role === 'super_admin') {
            return null;
        }

        return $user->createToken('impersonate_token')->plainTextToken;
    }

    /**
     * Approve a pending user.
     */
    public function approveUser(User $user): User
    {
        $user->update([
            'approval' => 'approved',
            'status'   => 'active',
        ]);
        return $user->fresh(['farmerGroup']);
    }

    /**
     * Reject a user.
     */
    public function rejectUser(User $user): User
    {
        $user->update([
            'approval' => 'rejected',
            'status'   => 'inactive',
        ]);
        return $user->fresh(['farmerGroup']);
    }

    /**
     * Format user data for API response.
     */
    public function formatUser(User $user): array
    {
        $user->loadMissing('farmerGroup');

        return [
            'id'              => $user->id,
            'name'            => $user->name,
            'email'           => $user->email,
            'phone'           => $user->phone,
            'farm_name'       => $user->farm_name,
            'farmer_group_id' => $user->farmer_group_id,
            'farmer_group'    => $user->farmerGroup ? [
                'id'          => $user->farmerGroup->id,
                'name'        => $user->farmerGroup->name,
                'code'        => $user->farmerGroup->code,
            ] : null,
            'role'            => $user->role,
            'status'          => $user->status,
            'approval'        => $user->approval,
        ];
    }

    // ─── Landing Content ────────────────────────────────────────────────────────

    /**
     * Get all landing page content sections as a key→value map.
     */
    public function getLandingContent(): object|array
    {
        $contents = LandingContent::all()->pluck('content', 'section');
        return $contents->isEmpty() ? (object) [] : $contents;
    }

    /**
     * Update landing page sections using batch upsert.
     */
    public function updateLandingContent(array $sections, array $requestData): void
    {
        $upsertData = [];
        foreach ($sections as $section) {
            if (array_key_exists($section, $requestData)) {
                $upsertData[] = [
                    'section' => $section,
                    'content' => $requestData[$section],
                ];
            }
        }

        if (!empty($upsertData)) {
            LandingContent::upsert($upsertData, ['section'], ['content']);
        }
    }

    // ─── Dashboard Menus ────────────────────────────────────────────────────────

    /**
     * Get all dashboard menus ordered by sort_order.
     */
    public function getAllMenus()
    {
        return DashboardMenu::orderBy('sort_order')->get();
    }

    /**
     * Create a new dashboard menu.
     */
    public function createMenu(array $data): DashboardMenu
    {
        return DashboardMenu::create($data);
    }

    /**
     * Update a dashboard menu.
     */
    public function updateMenu(DashboardMenu $menu, array $data): DashboardMenu
    {
        $menu->update($data);
        return $menu;
    }

    /**
     * Delete a dashboard menu.
     */
    public function deleteMenu(DashboardMenu $menu): void
    {
        $menu->delete();
    }

    // ─── Dashboard Stats ─────────────────────────────────────────────────────────

    /**
     * Get super admin dashboard summary with 1-hour caching.
     * Caches query results for 3600 seconds to prevent running heavy aggregates every minute.
     */
    public function getDashboardStats(bool $forceRefresh = false): array
    {
        $cacheKey = 'superadmin_dashboard_stats';

        if ($forceRefresh) {
            Cache::forget($cacheKey);
        }

        return Cache::remember($cacheKey, 3600, function () {
            $year = now()->year;

            $monthsIndo = [
                1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'Mei', 6 => 'Jun',
                7 => 'Jul', 8 => 'Agt', 9 => 'Sep', 10 => 'Okt', 11 => 'Nov', 12 => 'Des',
            ];

            // 1. Monthly Processed Product Sales (Bar Chart)
            $monthlyProductSales = [];
            $totalProductSoldYear = 0;

            for ($m = 1; $m <= 12; $m++) {
                $sold = (float) Sale::where('product_type', 'processed')
                    ->whereYear('date', $year)
                    ->whereMonth('date', $m)
                    ->sum('weight_kg');

                $totalProductSoldYear += (int) $sold;

                $monthlyProductSales[] = [
                    'month'      => $m,
                    'label'      => $monthsIndo[$m],
                    'total_sold' => (int) $sold,
                ];
            }

            // 2. Monthly Cumulative Farmer Revenue (Line Chart)
            $cumulativeFarmerRevenue = [];
            $runningRevenue = 0.0;

            for ($m = 1; $m <= 12; $m++) {
                $monthlyRevenue = (float) Sale::whereYear('date', $year)
                    ->whereMonth('date', $m)
                    ->sum('total');

                $runningRevenue += $monthlyRevenue;

                $cumulativeFarmerRevenue[] = [
                    'month'              => $m,
                    'label'              => $monthsIndo[$m],
                    'monthly_revenue'    => (int) $monthlyRevenue,
                    'cumulative_revenue' => (int) $runningRevenue,
                ];
            }

            return [
                'totalUsers'                 => User::count(),
                'activeUsers'                => User::where('status', 'active')->count(),
                'year'                       => $year,
                'total_products_sold_year'   => $totalProductSoldYear,
                'total_farmer_revenue_year'  => (int) $runningRevenue,
                'monthly_product_sales'      => $monthlyProductSales,
                'cumulative_farmer_revenue'  => $cumulativeFarmerRevenue,
                'cached_at'                  => now()->toIso8601String(),
                'cache_ttl_seconds'          => 3600,
            ];
        });
    }

    // ─── Aggregate Profit/Loss ───────────────────────────────────────────────────

    /**
     * Calculate aggregate profit/loss across all farmers.
     * Formula strictly matches ReportService: Profit = Total Revenue - Total Cost.
     */
    public function getFarmerProfitLossAggregate(?string $startDate = null, ?string $endDate = null): array
    {
        $farmers = User::where('role', 'user')->orderBy('name')->get();
        $totalRevenue = 0;
        $totalCost = 0;
        $farmerSummaries = [];

        foreach ($farmers as $farmer) {
            $saleQuery = Sale::where('user_id', $farmer->id);
            $costQuery = ProductionCost::where('user_id', $farmer->id);

            if ($startDate) {
                $saleQuery->where('date', '>=', $startDate);
                $costQuery->where('date', '>=', $startDate);
            }
            if ($endDate) {
                $saleQuery->where('date', '<=', $endDate);
                $costQuery->where('date', '<=', $endDate);
            }

            $rev = (int) $saleQuery->sum('total');
            $cost = (int) $costQuery->sum('amount');
            $pl = $rev - $cost;

            $totalRevenue += $rev;
            $totalCost += $cost;

            $farmerSummaries[] = [
                'farmer_id'   => $farmer->id,
                'farmer_name' => $farmer->name,
                'farm_name'   => $farmer->farm_name,
                'phone'       => $farmer->phone,
                'revenue'     => $rev,
                'cost'        => $cost,
                'profit_loss' => $pl,
            ];
        }

        return [
            'total_farmer_revenue'     => $totalRevenue,
            'total_farmer_cost'        => $totalCost,
            'total_farmer_profit_loss' => $totalRevenue - $totalCost,
            'farmer_count'             => count($farmers),
            'farmers'                  => $farmerSummaries,
        ];
    }

    // ─── Poktan Login Logs ───────────────────────────────────────────────────────

    /**
     * Get Poktan (role=user) login logs, daily counts, and location summary for a date range.
     */
    public function getPoktanLoginLogs(
        string $period = '30d',
        ?string $startDate = null,
        ?string $endDate = null,
        int $limit = 50
    ): array {
        if ($startDate && $endDate) {
            $start = Carbon::parse($startDate)->startOfDay();
            $end   = Carbon::parse($endDate)->endOfDay();
            $resolvedPeriod = 'custom';
        } else {
            $days = match ($period) {
                '7d'  => 7,
                '90d' => 90,
                default => 30,
            };
            $resolvedPeriod = match ($period) {
                '7d'  => '7d',
                '90d' => '90d',
                default => '30d',
            };
            $end   = now()->endOfDay();
            $start = now()->subDays($days - 1)->startOfDay();
        }

        if ($start->gt($end)) {
            [$start, $end] = [$end->copy()->startOfDay(), $start->copy()->endOfDay()];
        }

        $limit = max(1, min($limit, 100));

        $baseQuery = LoginLog::query()
            ->whereHas('user', fn ($q) => $q->where('role', 'user'))
            ->whereBetween('logged_in_at', [$start, $end]);

        $totalLogins = (clone $baseQuery)->count();
        $uniqueUsers = (clone $baseQuery)->distinct('user_id')->count('user_id');

        $rawDaily = (clone $baseQuery)
            ->selectRaw('DATE(logged_in_at) as login_date, COUNT(*) as total')
            ->groupBy('login_date')
            ->pluck('total', 'login_date')
            ->toArray();

        $monthsShort = [
            1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'Mei', 6 => 'Jun',
            7 => 'Jul', 8 => 'Agt', 9 => 'Sep', 10 => 'Okt', 11 => 'Nov', 12 => 'Des',
        ];

        $dailyCounts = [];
        $cursor = $start->copy()->startOfDay();
        $endDay = $end->copy()->startOfDay();

        while ($cursor->lte($endDay)) {
            $dateKey = $cursor->toDateString();
            $dailyCounts[] = [
                'date'  => $dateKey,
                'label' => $cursor->day . ' ' . $monthsShort[$cursor->month],
                'count' => (int) ($rawDaily[$dateKey] ?? 0),
            ];
            $cursor->addDay();
        }

        $locationSummary = (clone $baseQuery)
            ->selectRaw("COALESCE(NULLIF(location, ''), 'Tidak Diketahui') as location_name, COUNT(*) as total")
            ->groupBy('location_name')
            ->orderByDesc('total')
            ->limit(8)
            ->get()
            ->map(fn ($row) => [
                'location' => $row->location_name,
                'count'    => (int) $row->total,
            ])
            ->values()
            ->toArray();

        $logs = (clone $baseQuery)
            ->with(['user:id,name,email,farm_name,farmer_group_id', 'farmerGroup:id,name,village'])
            ->orderByDesc('logged_in_at')
            ->limit($limit)
            ->get()
            ->map(fn (LoginLog $log) => [
                'id'                     => $log->id,
                'user_id'                => $log->user_id,
                'user_name'              => $log->user?->name ?? 'User Dihapus',
                'user_email'             => $log->user?->email ?? '-',
                'farm_name'              => $log->user?->farm_name ?? '-',
                'farmer_group_name'      => $log->farmerGroup?->name ?? '-',
                'farmer_group_village'   => $log->farmerGroup?->village,
                'login_method'           => $log->login_method,
                'ip_address'             => $log->ip_address,
                'location'               => $log->location ?: 'Tidak Diketahui',
                'logged_in_at'           => $log->logged_in_at?->toIso8601String(),
                'logged_in_at_formatted' => $log->logged_in_at?->format('d M Y, H:i'),
            ])
            ->values()
            ->toArray();

        return [
            'period'           => $resolvedPeriod,
            'start_date'       => $start->toDateString(),
            'end_date'         => $end->toDateString(),
            'total_logins'     => $totalLogins,
            'unique_users'     => $uniqueUsers,
            'daily_counts'     => $dailyCounts,
            'location_summary' => $locationSummary,
            'logs'             => $logs,
        ];
    }
}
