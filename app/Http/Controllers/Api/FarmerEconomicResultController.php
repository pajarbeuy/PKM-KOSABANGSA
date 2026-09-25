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

    // ─── Petani & Super Admin: Processed Product Economic Summary ─────────────

    /**
     * GET /api/processed-products/{processedProduct}/economic-summary
     * Ringkasan modal dan laba/rugi per produk olahan.
     */
    public function processedProductEconomicSummary(Request $request, \App\Models\ProcessedProduct $processedProduct)
    {
        if ($request->user()->role !== 'super_admin' && $processedProduct->owner_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak mengakses data produk olahan ini.');
        }

        $summary = $this->service->getProcessedProductEconomicSummary($processedProduct);

        return $this->successResponse($summary, 'Ringkasan ekonomi produk olahan.');
    }

    // ─── Petani & Super Admin: Integrated Economic Summary (Hulu + Hilir) ─────

    /**
     * GET /api/farmer/integrated-economic-summary
     * Total laba/rugi terpadu agribisnis petani: Laba Panen (Hulu) + Laba Olahan (Hilir).
     */
    public function integratedEconomicSummary(Request $request)
    {
        $farmerId = $request->user()->id;

        // Super Admin can view a specific farmer's integrated summary via query param
        if ($request->user()->role === 'super_admin' && $request->has('farmer_id')) {
            $farmerId = (int) $request->input('farmer_id');
        }

        $summary = $this->service->getIntegratedEconomicSummary($farmerId);

        return $this->successResponse($summary, 'Ringkasan ekonomi terpadu agribisnis petani.');
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
