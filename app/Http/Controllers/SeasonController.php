<?php

namespace App\Http\Controllers;

use App\Models\Season;
use App\Services\SeasonService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class SeasonController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly SeasonService $seasonService) {}

    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $seasons = Season::where('user_id', $request->user()->id)
            ->withSum('harvests', 'weight_kg')
            ->latest()
            ->paginate($perPage);

        return $this->successResponse($seasons->items(), 'Daftar musim tanam.');
    }

    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'name'       => 'required|string|max:255',
                'start_date' => 'required|date',
                'end_date'   => 'required|date|after:start_date',
                'status'     => 'required|in:active,completed,cancelled',
                'target_kg'  => 'required|numeric|min:0',
            ]);

            $season    = $this->seasonService->createSeason($validated, $request->user()->id);
            $formatted = array_merge($this->seasonService->formatSeason($season), ['created_at' => $season->created_at]);

            return $this->successResponse($formatted, 'Musim tanam berhasil ditambahkan.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function show(Request $request, Season $season)
    {
        if ($season->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak melihat data ini.');
        }

        $formatted = array_merge($this->seasonService->formatSeason($season), [
            'created_at' => $season->created_at,
            'updated_at' => $season->updated_at,
        ]);

        return $this->successResponse($formatted, 'Detail musim tanam.');
    }

    public function update(Request $request, Season $season)
    {
        try {
            if ($season->user_id !== $request->user()->id) {
                return $this->forbiddenResponse('Anda tidak berhak mengubah data ini.');
            }

            $validated = $request->validate([
                'name'       => 'required|string|max:255',
                'start_date' => 'required|date',
                'end_date'   => 'required|date|after:start_date',
                'status'     => 'required|in:active,completed,cancelled',
                'target_kg'  => 'required|numeric|min:0',
            ]);

            $updated   = $this->seasonService->updateSeason($season, $validated);
            $formatted = array_merge($this->seasonService->formatSeason($updated), ['updated_at' => $updated->updated_at]);

            return $this->successResponse($formatted, 'Musim tanam berhasil diperbarui.');
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function destroy(Request $request, Season $season)
    {
        if ($season->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $this->seasonService->deleteSeason($season);
        return $this->successResponse(null, 'Musim tanam berhasil dihapus.');
    }
}
