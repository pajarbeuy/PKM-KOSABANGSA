<?php

namespace App\Services;

use App\Models\Commission;
use App\Models\Sale;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

class CommissionService
{
    /**
     * Atomically calculate and record a 10% commission for a sale.
     * Enforces strict idempotency: if commission already exists for this sale, returns existing record.
     */
    public function calculateAndRecordCommission(Sale $sale, ?float $rate = null): Commission
    {
        $rate = $rate !== null ? (float) $rate : Commission::DEFAULT_RATE;

        // Idempotency Guard: prevent duplicate commission creation
        $existing = Commission::where('sale_id', $sale->id)->first();
        if ($existing) {
            return $existing;
        }

        return DB::transaction(function () use ($sale, $rate) {
            // Double check with lock inside transaction
            $lockedExisting = Commission::where('sale_id', $sale->id)->lockForUpdate()->first();
            if ($lockedExisting) {
                return $lockedExisting;
            }

            $baseAmount = (float) $sale->total;
            $commissionAmount = round($baseAmount * ($rate / 100), 2);
            $netFarmerAmount = round($baseAmount - $commissionAmount, 2);

            return Commission::create([
                'sale_id'           => $sale->id,
                'order_id'          => $sale->order_id,
                'user_id'           => $sale->user_id,
                'rate'              => $rate,
                'base_amount'       => $baseAmount,
                'commission_amount' => $commissionAmount,
                'net_farmer_amount' => $netFarmerAmount,
                'status'            => 'calculated',
                'notes'             => $sale->order_id
                    ? 'Komisi platform ' . $rate . '% dari pesanan ' . ($sale->order?->order_code ?? '#' . $sale->order_id)
                    : 'Komisi platform ' . $rate . '% dari transaksi penjualan #' . $sale->id,
            ]);
        });
    }

    /**
     * Get commission list and aggregate summary for Super Admin.
     */
    public function getCommissionsForSuperAdmin(array $filters = []): array
    {
        $query = Commission::with([
            'sale.processedProduct',
            'order',
            'farmer' => function ($q) {
                $q->select('id', 'name', 'email', 'phone', 'farmer_group_id')->with('farmerGroup');
            }
        ])->latest('id');

        $this->applyFilters($query, $filters);

        // Calculate summary aggregates before pagination
        $summaryQuery = Commission::query();
        $this->applyFilters($summaryQuery, $filters);

        $summary = [
            'total_transactions'      => (int) $summaryQuery->count(),
            'total_gross_amount'      => (float) ($summaryQuery->sum('base_amount') ?? 0.0),
            'total_commission_amount' => (float) ($summaryQuery->sum('commission_amount') ?? 0.0),
            'total_net_farmer_amount' => (float) ($summaryQuery->sum('net_farmer_amount') ?? 0.0),
            'commission_rate_default' => Commission::DEFAULT_RATE,
        ];

        $perPage = (int) ($filters['per_page'] ?? 15);
        $paginated = $query->paginate($perPage);

        return [
            'summary'     => $summary,
            'commissions' => $paginated,
        ];
    }

    /**
     * Get commission list and aggregate summary for a specific farmer.
     */
    public function getCommissionsForFarmer(int $farmerId, array $filters = []): array
    {
        $filters['user_id'] = $farmerId;

        $query = Commission::with([
            'sale.processedProduct',
            'order'
        ])
        ->where('user_id', $farmerId)
        ->latest('id');

        $this->applyFilters($query, $filters);

        $summaryQuery = Commission::where('user_id', $farmerId);
        $this->applyFilters($summaryQuery, $filters);

        $summary = [
            'total_sales_count'        => (int) $summaryQuery->count(),
            'total_gross_sales'        => (float) ($summaryQuery->sum('base_amount') ?? 0.0),
            'total_platform_commission'=> (float) ($summaryQuery->sum('commission_amount') ?? 0.0),
            'total_net_received'       => (float) ($summaryQuery->sum('net_farmer_amount') ?? 0.0),
            'commission_rate_default'  => Commission::DEFAULT_RATE,
        ];

        $perPage = (int) ($filters['per_page'] ?? 15);
        $paginated = $query->paginate($perPage);

        return [
            'summary'     => $summary,
            'commissions' => $paginated,
        ];
    }

    /**
     * Apply date range and user filters.
     */
    private function applyFilters(Builder $query, array $filters): void
    {
        if (!empty($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }

        if (!empty($filters['start_date'])) {
            $query->whereDate('created_at', '>=', $filters['start_date']);
        }

        if (!empty($filters['end_date'])) {
            $query->whereDate('created_at', '<=', $filters['end_date']);
        }

        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }
    }
}
