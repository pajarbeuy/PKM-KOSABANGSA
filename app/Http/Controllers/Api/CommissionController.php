<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\CommissionService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommissionController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly CommissionService $commissionService
    ) {}

    /**
     * Get commission list and financial summary based on user role.
     * Super Admin gets global platform perspective; Farmer gets their own sales deduction perspective.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $request->validate([
            'start_date' => 'nullable|date',
            'end_date'   => 'nullable|date|after_or_equal:start_date',
            'user_id'    => 'nullable|integer|exists:users,id',
            'per_page'   => 'nullable|integer|min:1|max:100',
            'status'     => 'nullable|string|in:calculated,settled',
        ]);

        $filters = $request->only(['start_date', 'end_date', 'user_id', 'per_page', 'status']);

        if ($user->role === 'super_admin') {
            $result = $this->commissionService->getCommissionsForSuperAdmin($filters);
            return $this->successResponse($result, 'Data komisi platform berhasil dimuat');
        }

        if (in_array($user->role, ['farmer', 'user'])) {
            $result = $this->commissionService->getCommissionsForFarmer($user->id, $filters);
            return $this->successResponse($result, 'Data komisi penjualan berhasil dimuat');
        }

        return $this->forbiddenResponse('Anda tidak memiliki akses ke data komisi');
    }

    /**
     * Get standalone KPI summary metrics for commissions.
     */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();

        $filters = $request->only(['start_date', 'end_date', 'user_id', 'status']);

        if ($user->role === 'super_admin') {
            $result = $this->commissionService->getCommissionsForSuperAdmin($filters);
            return $this->successResponse($result['summary'], 'Ringkasan komisi platform berhasil dimuat');
        }

        if (in_array($user->role, ['farmer', 'user'])) {
            $result = $this->commissionService->getCommissionsForFarmer($user->id, $filters);
            return $this->successResponse($result['summary'], 'Ringkasan komisi penjualan berhasil dimuat');
        }

        return $this->forbiddenResponse('Anda tidak memiliki akses ke ringkasan komisi');
    }
}
