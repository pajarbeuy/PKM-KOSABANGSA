<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Harvest;
use App\Models\Season;
use App\Services\FarmerEconomicResultService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

/**
 * FarmerEconomicResultController — Phase 6
 *
 * Endpoints:
 *   GET  /api/harvests/{harvest}/economic-result      → hasil ekonomi per panen (Petani)
 *   GET  /api/seasons/{season}/economic-summary       → ringkasan ekonomi per musim (Petani)
 *   GET  /api/farmer/economic-summary                 → ringkasan keseluruhan petani (Petani)
 *   GET  /api/super-admin/economic-aggregate          → agregat semua petani (Super Admin)
 */
class FarmerEconomicResultController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly FarmerEconomicResultService $service
    ) {}

    // ─── Petani: Per-Harvest ──────────────────────────────────────────────────

    /**
     * GET /api/harvests/{harvest}/economic-result
     * Hasil ekonomi satu catatan panen.
     */
    public function harvestEconomicResult(Request $request, Harvest $harvest)
    {
        if ($harvest->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak mengakses data ini.');
        }

        $result = $this->service->getHarvestEconomicResult($harvest);

        return $this->successResponse($result, 'Hasil ekonomi panen.');
    }

    // ─── Petani: Per-Season ───────────────────────────────────────────────────

    /**
     * GET /api/seasons/{season}/economic-summary
     * Ringkasan ekonomi per musim tanam.
     */
    public function seasonEconomicSummary(Request $request, Season $season)
    {
        if ($season->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak mengakses data ini.');
        }

        $summary = $this->service->getSeasonEconomicSummary($season, $request->user()->id);

        return $this->successResponse($summary, 'Ringkasan ekonomi musim tanam.');
    }

    // ─── Petani: Seluruh Musim ────────────────────────────────────────────────

    /**
     * GET /api/farmer/economic-summary
     * Ringkasan ekonomi keseluruhan petani (semua musim).
     */
    public function farmerEconomicSummary(Request $request)
    {
        $summary = $this->service->getFarmerEconomicSummary($request->user()->id);

        return $this->successResponse($summary, 'Ringkasan ekonomi keseluruhan petani.');
    }

    // ─── Super Admin: Aggregate ───────────────────────────────────────────────

    /**
     * GET /api/super-admin/economic-aggregate
     * Agregat hasil ekonomi seluruh petani.
     */
    public function superAdminEconomicAggregate(Request $request)
    {
        $aggregate = $this->service->getSuperAdminEconomicAggregate();

        return $this->successResponse($aggregate, 'Agregat hasil ekonomi seluruh petani.');
    }
}
