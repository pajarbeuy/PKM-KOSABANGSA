<?php

namespace App\Http\Controllers;

use App\Models\ProductionCost;
use App\Models\Season;
use App\Services\CostService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class CostController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly CostService $costService) {}

    public function index(Request $request)
    {
        $userId   = $request->user()->id;
        $perPage  = $request->input('per_page', 15);
        $seasonId = $request->input('season_id');

        $query = ProductionCost::where('user_id', $userId)->with('season')->latest('date');
        if ($seasonId) $query->where('season_id', $seasonId);

        $costs          = $query->paginate($perPage);
        $totalCost      = ProductionCost::where('user_id', $userId)->sum('amount');
        $costByCategory = ProductionCost::getCostByCategory($userId);

        return $this->successResponse([
            'costs'            => $costs->items(),
            'pagination'       => [
                'total'        => $costs->total(),
                'per_page'     => $costs->perPage(),
                'current_page' => $costs->currentPage(),
                'last_page'    => $costs->lastPage(),
            ],
            'total_cost'       => $totalCost,
            'cost_by_category' => $costByCategory,
        ], 'Daftar biaya produksi.');
    }

    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'date'      => 'required|date',
                'season_id' => 'nullable|exists:seasons,id',
                'category'  => 'required|in:seed,fertilizer,pesticide,other',
                'amount'    => 'required|numeric|min:0.01',
                'notes'     => 'nullable|string|max:255',
            ]);

            if (!empty($validated['season_id'])) {
                $seasonExists = Season::where('id', $validated['season_id'])->where('user_id', $request->user()->id)->exists();
                if (!$seasonExists) {
                    return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik Anda.');
                }
            }

            $cost      = $this->costService->createCost($validated, $request->user()->id);
            $formatted = array_merge($this->costService->formatCost($cost), ['created_at' => $cost->created_at]);

            return $this->successResponse($formatted, 'Biaya produksi berhasil ditambahkan.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function show(Request $request, ProductionCost $cost)
    {
        if ($cost->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak melihat data ini.');
        }

        $formatted = array_merge($this->costService->formatCost($cost), [
            'created_at' => $cost->created_at,
            'updated_at' => $cost->updated_at,
        ]);

        return $this->successResponse($formatted, 'Detail biaya produksi.');
    }

    public function update(Request $request, ProductionCost $cost)
    {
        try {
            if ($cost->user_id !== $request->user()->id) {
                return $this->forbiddenResponse('Anda tidak berhak mengubah data ini.');
            }

            $validated = $request->validate([
                'date'      => 'required|date',
                'season_id' => 'nullable|exists:seasons,id',
                'category'  => 'required|in:seed,fertilizer,pesticide,other',
                'amount'    => 'required|numeric|min:0.01',
                'notes'     => 'nullable|string|max:255',
            ]);

            if (!empty($validated['season_id'])) {
                $seasonExists = Season::where('id', $validated['season_id'])->where('user_id', $request->user()->id)->exists();
                if (!$seasonExists) {
                    return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik Anda.');
                }
            }

            $updated   = $this->costService->updateCost($cost, $validated);
            $formatted = array_merge($this->costService->formatCost($updated), ['updated_at' => $updated->updated_at]);

            return $this->successResponse($formatted, 'Biaya produksi berhasil diperbarui.');
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function destroy(Request $request, ProductionCost $cost)
    {
        if ($cost->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $this->costService->deleteCost($cost);
        return $this->successResponse(null, 'Biaya produksi berhasil dihapus.');
    }
}
