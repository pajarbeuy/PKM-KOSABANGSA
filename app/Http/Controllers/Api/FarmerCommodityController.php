<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FarmerCommodity;
use App\Services\FarmerCommodityService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class FarmerCommodityController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly FarmerCommodityService $commodityService
    ) {}

    /**
     * Get all commodities belonging to the authenticated farmer, or all commodities if Super Admin.
     */
    public function index(Request $request): JsonResponse
    {
        $activeOnly = $request->boolean('active_only', false);

        if ($request->user()->role === 'super_admin') {
            $commodities = $this->commodityService->getAllCommoditiesForAdmin([
                'status' => $activeOnly ? 'active' : null,
            ]);
            $formatted = $commodities->map(fn($c) => $this->commodityService->formatCommodity($c, true));
        } else {
            $commodities = $this->commodityService->getCommoditiesForFarmer($request->user()->id, $activeOnly);
            $formatted = $commodities->map(fn($c) => $this->commodityService->formatCommodity($c));
        }

        return $this->successResponse($formatted, 'Daftar komoditas hasil tani.');
    }

    /**
     * Get single commodity detail for the authenticated farmer.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $commodity = $this->commodityService->getCommodityById($id, $request->user()->id);

        if (!$commodity) {
            return $this->errorResponse('Komoditas hasil tani tidak ditemukan.', 404);
        }

        return $this->successResponse(
            $this->commodityService->formatCommodity($commodity),
            'Detail komoditas hasil tani.'
        );
    }

    /**
     * Create a new commodity for the authenticated farmer.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'        => 'required|string|max:255',
            'code'        => 'nullable|string|max:50',
            'unit'        => 'nullable|string|in:kg,kuintal,ton,ikat,pcs',
            'description' => 'nullable|string',
            'status'      => 'nullable|string|in:active,inactive',
        ]);

        try {
            $commodity = $this->commodityService->createCommodity($request->user()->id, $validated);

            return $this->successResponse(
                $this->commodityService->formatCommodity($commodity),
                'Komoditas hasil tani berhasil ditambahkan.',
                201
            );
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Throwable $e) {
            return $this->errorResponse('Gagal menambahkan komoditas: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Update an existing commodity belonging to the authenticated farmer.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $commodity = $this->commodityService->getCommodityById($id, $request->user()->id);

        if (!$commodity) {
            return $this->errorResponse('Komoditas hasil tani tidak ditemukan.', 404);
        }

        $validated = $request->validate([
            'name'        => 'sometimes|required|string|max:255',
            'code'        => 'nullable|string|max:50',
            'unit'        => 'nullable|string|in:kg,kuintal,ton,ikat,pcs',
            'description' => 'nullable|string',
            'status'      => 'nullable|string|in:active,inactive',
        ]);

        try {
            $updated = $this->commodityService->updateCommodity($commodity, $validated);

            return $this->successResponse(
                $this->commodityService->formatCommodity($updated),
                'Komoditas hasil tani berhasil diperbarui.'
            );
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Throwable $e) {
            return $this->errorResponse('Gagal memperbarui komoditas: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Delete a commodity belonging to the authenticated farmer.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $commodity = $this->commodityService->getCommodityById($id, $request->user()->id);

        if (!$commodity) {
            return $this->errorResponse('Komoditas hasil tani tidak ditemukan.', 404);
        }

        try {
            $this->commodityService->deleteCommodity($commodity);

            return $this->successResponse(null, 'Komoditas hasil tani berhasil dihapus.');
        } catch (\InvalidArgumentException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        } catch (\Throwable $e) {
            return $this->errorResponse('Gagal menghapus komoditas: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Super Admin: List all commodities across farmers.
     */
    public function adminIndex(Request $request): JsonResponse
    {
        $filters = [
            'user_id' => $request->query('user_id'),
            'status'  => $request->query('status'),
            'search'  => $request->query('search'),
        ];

        $commodities = $this->commodityService->getAllCommoditiesForAdmin($filters);
        $formatted = $commodities->map(fn($c) => $this->commodityService->formatCommodity($c, true));

        return $this->successResponse($formatted, 'Daftar komoditas seluruh petani.');
    }

    /**
     * Super Admin: Update a farmer's commodity for administrative/monitoring purposes.
     */
    public function adminUpdate(Request $request, int $id): JsonResponse
    {
        $commodity = $this->commodityService->getCommodityById($id);

        if (!$commodity) {
            return $this->errorResponse('Komoditas hasil tani tidak ditemukan.', 404);
        }

        $validated = $request->validate([
            'name'        => 'sometimes|required|string|max:255',
            'code'        => 'nullable|string|max:50',
            'unit'        => 'nullable|string|in:kg,kuintal,ton,ikat,pcs',
            'description' => 'nullable|string',
            'status'      => 'nullable|string|in:active,inactive',
        ]);

        try {
            $updated = $this->commodityService->updateCommodity($commodity, $validated);

            return $this->successResponse(
                $this->commodityService->formatCommodity($updated, true),
                'Komoditas petani berhasil disesuaikan oleh Super Admin.'
            );
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Throwable $e) {
            return $this->errorResponse('Gagal memperbarui komoditas: ' . $e->getMessage(), 500);
        }
    }
}
