<?php

namespace App\Services;

use App\Models\Harvest;
use App\Models\Season;
use App\Models\StockTransaction;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class HarvestService
{
    public function __construct(
        private readonly MarketPriceService $marketPriceService
    ) {}

    /**
     * Verify that a season belongs to the given user.
     */
    public function verifySeasonOwnership(int $seasonId, int $userId): ?Season
    {
        return Season::where('id', $seasonId)
            ->where('user_id', $userId)
            ->first();
    }

    /**
     * Create a harvest record and add incoming stock transaction.
     */
    public function createHarvest(array $data, int $userId, ?UploadedFile $photo = null): Harvest
    {
        $commodityId = $data['commodity_id'] ?? null;
        if (!$commodityId && !empty($data['season_id'])) {
            $season = Season::find($data['season_id']);
            if ($season && $season->commodity_id) {
                $commodityId = $season->commodity_id;
            }
        }

        $harvestDate = $data['harvest_date'] ?? $data['date'] ?? now()->toDateString();

        $dbData = [
            'user_id'      => $userId,
            'season_id'    => $data['season_id'],
            'commodity_id' => $commodityId,
            'quantity'     => $data['quantity'] ?? 0,
            'unit'         => $data['unit'] ?? 'kg',
            'date'         => $harvestDate,
            'weight_kg'    => $data['weight_kg'],
            'notes'        => $data['notes'] ?? null,
            'status'       => isset($data['status']) && in_array($data['status'], ['recorded', 'verified', 'cancelled'])
                ? $data['status']
                : 'recorded',
        ];

        // Otomatisasi Snapshot Harga Pasar Acuan (Phase 5)
        if ($commodityId) {
            $effectivePrice = $this->marketPriceService->findEffectivePrice((int) $commodityId, $harvestDate);
            if ($effectivePrice) {
                $dbData['market_price_id']             = $effectivePrice->id;
                $dbData['market_price_snapshot']       = (float) $effectivePrice->price;
                $dbData['market_price_effective_date'] = $effectivePrice->effective_date ? $effectivePrice->effective_date->toDateString() : null;
            }
        }

        if ($photo) {
            $photoPath       = $photo->store('harvest_photos', 'public');
            $dbData['photo'] = 'storage/' . $photoPath;
        }

        return DB::transaction(function () use ($dbData, $userId) {
            $harvest = Harvest::create($dbData);

            StockTransaction::addTransaction(
                'in',
                $dbData['weight_kg'],
                'Panen masuk',
                'harvest_' . $harvest->id,
                $userId
            );

            return $harvest->load(['season', 'commodity', 'marketPrice']);
        });
    }

    /**
     * Update a harvest record and adjust stock if weight changed.
     */
     public function updateHarvest(Harvest $harvest, array $data, int $userId, ?UploadedFile $photo = null): Harvest
     {
         $dbData = [];

         if (isset($data['season_id']))    $dbData['season_id']    = $data['season_id'];
         if (array_key_exists('commodity_id', $data)) $dbData['commodity_id'] = $data['commodity_id'];
         if (isset($data['weight_kg']))    $dbData['weight_kg']    = $data['weight_kg'];
         if (isset($data['quantity']))     $dbData['quantity']     = $data['quantity'];
         if (isset($data['unit']))         $dbData['unit']         = $data['unit'];
         if (isset($data['notes']))        $dbData['notes']        = $data['notes'];

         $newDate = $data['harvest_date'] ?? $data['date'] ?? null;
         if ($newDate) $dbData['date'] = $newDate;

         if (isset($data['status'])) {
             $dbData['status'] = in_array($data['status'], ['recorded', 'verified', 'cancelled'])
                 ? $data['status']
                 : $harvest->status;
         }

         $commodityChanged = array_key_exists('commodity_id', $data) && $data['commodity_id'] != $harvest->commodity_id;
         $dateChanged = $newDate !== null && $newDate != ($harvest->date ? $harvest->date->toDateString() : null);

         // Jika komoditas atau tanggal berubah, atau sebelumnya belum ada snapshot, sinkronkan ulang snapshot
         if ($commodityChanged || $dateChanged || empty($harvest->market_price_snapshot)) {
             $targetCommodityId = array_key_exists('commodity_id', $data) ? $data['commodity_id'] : $harvest->commodity_id;
             $targetDate = $newDate ?? ($harvest->date ? $harvest->date->toDateString() : now()->toDateString());

             if ($targetCommodityId) {
                 $effectivePrice = $this->marketPriceService->findEffectivePrice((int) $targetCommodityId, $targetDate);
                 if ($effectivePrice) {
                     $dbData['market_price_id']             = $effectivePrice->id;
                     $dbData['market_price_snapshot']       = (float) $effectivePrice->price;
                     $dbData['market_price_effective_date'] = $effectivePrice->effective_date ? $effectivePrice->effective_date->toDateString() : null;
                 } else {
                     $dbData['market_price_id']             = null;
                     $dbData['market_price_snapshot']       = null;
                     $dbData['market_price_effective_date'] = null;
                 }
             }
         }

         if ($photo) {
             // Delete old photo if exists
             if (!empty($harvest->photo) && str_starts_with($harvest->photo, 'storage/')) {
                 Storage::disk('public')->delete(str_replace('storage/', '', $harvest->photo));
             }
             $photoPath       = $photo->store('harvest_photos', 'public');
             $dbData['photo'] = 'storage/' . $photoPath;
         }

         $oldWeight = $harvest->weight_kg;

         return DB::transaction(function () use ($harvest, $dbData, $userId, $oldWeight) {
             $harvest->update($dbData);

             // Adjust stock if weight changed
             if (isset($dbData['weight_kg']) && $oldWeight != $dbData['weight_kg']) {
                 $difference = $dbData['weight_kg'] - $oldWeight;
                 StockTransaction::addTransaction(
                     $difference > 0 ? 'in' : 'out',
                     abs($difference),
                     'Panen diupdate',
                     'harvest_' . $harvest->id,
                     $userId
                 );
             }

             return $harvest->load(['season', 'commodity', 'marketPrice']);
         });
     }

    /**
     * Delete a harvest and rollback stock (out transaction equal to harvest weight).
     */
    public function deleteHarvest(Harvest $harvest, int $userId): void
    {
        DB::transaction(function () use ($harvest, $userId) {
            $currentBalance = StockTransaction::getCurrentBalance($userId);

            if ($harvest->weight_kg > 0 && $currentBalance > 0) {
                $rollback = min($harvest->weight_kg, $currentBalance);
                StockTransaction::addTransaction(
                    'out',
                    $rollback,
                    'Panen dihapus (rollback)',
                    'harvest_delete_' . $harvest->id,
                    $userId
                );
            }

            $harvest->delete();
        });
    }

    /**
     * Format a harvest model for API response.
     */
    public function formatHarvest(Harvest $harvest, ?string $seasonName = null): array
    {
        $snapshot = $harvest->market_price_snapshot !== null ? (float) $harvest->market_price_snapshot : null;
        $grossHarvestValue = $snapshot !== null ? round((float) $harvest->weight_kg * $snapshot, 2) : null;

        return [
            'id'                          => $harvest->id,
            'season_id'                   => $harvest->season_id,
            'season_name'                 => $seasonName ?? $harvest->season?->name ?? 'N/A',
            'commodity_id'                => $harvest->commodity_id,
            'commodity_name'              => $harvest->commodity?->name ?? null,
            'market_price_id'             => $harvest->market_price_id,
            'market_price_snapshot'       => $snapshot,
            'market_price_effective_date' => $harvest->market_price_effective_date ? $harvest->market_price_effective_date->toDateString() : null,
            'gross_harvest_value'         => $grossHarvestValue,
            'harvest_date'                => $harvest->date ? $harvest->date->toDateString() : null,
            'date'                        => $harvest->date ? $harvest->date->toDateString() : null,
            'weight_kg'                   => (float) $harvest->weight_kg,
            'quantity'                    => (float) ($harvest->quantity ?? 0),
            'unit'                        => $harvest->unit ?? 'kg',
            'status'                      => $harvest->status,
            'notes'                       => $harvest->notes ?? '',
            'photo'                       => $harvest->photo ?? '',
            'photo_url'                   => $harvest->photo_url,
        ];
    }
}
