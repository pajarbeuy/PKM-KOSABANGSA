<?php

namespace App\Http\Controllers;

use App\Models\Harvest;
use App\Models\Season;
use App\Services\HarvestService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class HarvestController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly HarvestService $harvestService) {}

    public function index(Request $request)
    {
        $userId   = $request->user()->id;
        $perPage  = $request->input('per_page', 15);
        $seasonId = $request->input('season_id');

        $query = Harvest::where('user_id', $userId)->with('season')->latest('date');
        if ($seasonId) $query->where('season_id', $seasonId);

        $harvests     = $query->paginate($perPage);
        $activeSeason = Season::where('user_id', $userId)
            ->where('status', '!=', 'cancelled')
            ->whereDate('start_date', '<=', today())
            ->whereDate('end_date', '>=', today())
            ->latest('start_date')
            ->first();
        $totalHarvest = Harvest::where('user_id', $userId)->sum('weight_kg');

        return $this->successResponse([
            'harvests'         => $harvests->items(),
            'pagination'       => [
                'total'        => $harvests->total(),
                'per_page'     => $harvests->perPage(),
                'current_page' => $harvests->currentPage(),
                'last_page'    => $harvests->lastPage(),
            ],
            'active_season'    => $activeSeason,
            'total_harvest_kg' => $totalHarvest,
        ], 'Daftar pencatatan panen.');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'season_id'    => 'required|integer|exists:seasons,id',
            'harvest_date' => 'nullable|date',
            'date'         => 'nullable|date',
            'quantity'     => 'nullable|integer|min:0',
            'weight_kg'    => 'required|numeric|min:0.01',
            'notes'        => 'nullable|string|max:1000',
            'photo'        => 'nullable|image|mimes:jpg,jpeg,png|max:5120',
            'status'       => 'nullable|in:recorded,verified,cancelled',
        ], [
            'season_id.required' => 'Musim tanam harus dipilih.',
            'season_id.exists'   => 'Musim tanam tidak ditemukan.',
            'weight_kg.required' => 'Berat (kg) harus diisi.',
            'weight_kg.min'      => 'Berat minimal 0.01 kg.',
        ]);

        $season = $this->harvestService->verifySeasonOwnership($validated['season_id'], $request->user()->id);
        if (!$season) {
            return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik Anda.');
        }

        $harvest = $this->harvestService->createHarvest(
            $validated,
            $request->user()->id,
            $request->hasFile('photo') ? $request->file('photo') : null
        );

        $formatted               = $this->harvestService->formatHarvest($harvest, $season->name);
        $formatted['created_at'] = $harvest->created_at->toIso8601String();

        return $this->successResponse($formatted, 'Pencatatan panen berhasil ditambahkan.', 201);
    }

    public function show(Request $request, Harvest $harvest)
    {
        if ($harvest->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak melihat data ini.');
        }

        $formatted = $this->harvestService->formatHarvest($harvest);
        $formatted['created_at'] = $harvest->created_at?->toIso8601String();
        $formatted['updated_at'] = $harvest->updated_at?->toIso8601String();

        return $this->successResponse($formatted, 'Detail pencatatan panen.');
    }

    public function update(Request $request, Harvest $harvest)
    {
        if ($harvest->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak mengubah data ini.');
        }

        $validated = $request->validate([
            'season_id'    => 'sometimes|required|integer|exists:seasons,id',
            'harvest_date' => 'nullable|date',
            'date'         => 'nullable|date',
            'quantity'     => 'nullable|integer|min:0',
            'weight_kg'    => 'sometimes|required|numeric|min:0.01',
            'notes'        => 'nullable|string|max:1000',
            'photo'        => 'nullable|image|mimes:jpg,jpeg,png|max:5120',
            'status'       => 'nullable|in:recorded,verified,cancelled',
        ], [
            'season_id.required' => 'Musim tanam harus dipilih.',
            'season_id.exists'   => 'Musim tanam tidak ditemukan.',
            'weight_kg.required' => 'Berat (kg) harus diisi.',
            'weight_kg.min'      => 'Berat minimal 0.01 kg.',
        ]);

        if (isset($validated['season_id'])) {
            $season = $this->harvestService->verifySeasonOwnership($validated['season_id'], $request->user()->id);
            if (!$season) {
                return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik Anda.');
            }
        }

        $updated               = $this->harvestService->updateHarvest(
            $harvest,
            $validated,
            $request->user()->id,
            $request->hasFile('photo') ? $request->file('photo') : null
        );

        $formatted               = $this->harvestService->formatHarvest($updated);
        $formatted['updated_at'] = $updated->updated_at->toIso8601String();

        return $this->successResponse($formatted, 'Pencatatan panen berhasil diperbarui.');
    }

    public function destroy(Request $request, Harvest $harvest)
    {
        if ($harvest->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $this->harvestService->deleteHarvest($harvest, $request->user()->id);

        return $this->successResponse(null, 'Pencatatan panen berhasil dihapus.');
    }
}
