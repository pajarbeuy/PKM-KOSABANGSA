<?php

namespace App\Services;

use App\Models\Season;

class SeasonService
{
    /**
     * Create a new season for a user.
     */
    public function createSeason(array $data, int $userId): Season
    {
        return Season::create(array_merge($data, ['user_id' => $userId]));
    }

    /**
     * Update an existing season.
     */
    public function updateSeason(Season $season, array $data): Season
    {
        $season->update($data);
        return $season;
    }

    /**
     * Delete a season (soft delete).
     */
    public function deleteSeason(Season $season): void
    {
        $season->delete();
    }

    /**
     * Format a season for API response.
     */
    public function formatSeason(Season $season): array
    {
        return [
            'id'              => $season->id,
            'commodity_id'    => $season->commodity_id,
            'commodity_name'  => $season->commodity?->name ?? 'N/A',
            'commodity'       => $season->commodity ? [
                'id'   => $season->commodity->id,
                'name' => $season->commodity->name,
                'unit' => $season->commodity->unit,
            ] : null,
            'name'            => $season->name,
            'start_date'      => $season->start_date,
            'end_date'        => $season->end_date,
            'status'          => $season->status,
            'computed_status' => $season->computeStatus(),
            'target_kg'       => $season->target_kg,
        ];
    }
}
