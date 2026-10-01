<?php

namespace App\Services;

use App\Models\FarmerCommodity;
use App\Models\MarketPrice;
use DomainException;
use Illuminate\Database\Eloquent\Collection;

class MarketPriceService
{
    /**
     * Mencari harga pasar yang berlaku efektif untuk komoditas tertentu pada tanggal tertentu.
     * Menggunakan aturan: effective_date <= date, diurutkan dari tanggal efektif paling mendekati.
     * Mendukung pencocokan berdasarkan jenis nama komoditas agar berlaku bagi semua petani.
     */
    public function findEffectivePrice(int $commodityId, string $date): ?MarketPrice
    {
        $exact = MarketPrice::effectiveForDate($commodityId, $date)->first();
        if ($exact) {
            return $exact;
        }

        $targetCommodity = FarmerCommodity::find($commodityId);
        if (!$targetCommodity) {
            return null;
        }

        $normName = strtolower(trim($targetCommodity->name));
        return MarketPrice::whereHas('commodity', function ($q) use ($normName) {
            $q->whereRaw('LOWER(TRIM(name)) = ?', [$normName]);
        })
        ->whereDate('effective_date', '<=', $date)
        ->orderBy('effective_date', 'desc')
        ->first();
    }

    /**
     * Membuat record harga pasar baru (Super Admin only).
     */
    public function createMarketPrice(array $data, int $userId): MarketPrice
    {
        $targetComm = FarmerCommodity::find($data['commodity_id']);
        $normName = $targetComm ? strtolower(trim($targetComm->name)) : null;

        $existing = MarketPrice::withTrashed()
            ->where(function ($q) use ($data, $normName) {
                $q->where('commodity_id', $data['commodity_id']);
                if ($normName) {
                    $q->orWhereHas('commodity', function ($sub) use ($normName) {
                        $sub->whereRaw('LOWER(TRIM(name)) = ?', [$normName]);
                    });
                }
            })
            ->whereDate('effective_date', $data['effective_date'])
            ->first();

        if ($existing) {
            if ($existing->trashed()) {
                $existing->restore();
            }
            $existing->update([
                'price'      => $data['price'],
                'unit'       => $data['unit'] ?? $existing->unit ?? 'kg',
                'source'     => $data['source'] ?? 'manual',
                'notes'      => $data['notes'] ?? null,
                'created_by' => $userId,
            ]);
            return $existing->fresh()->load('commodity');
        }

        return MarketPrice::create([
            'commodity_id'   => $data['commodity_id'],
            'price'          => $data['price'],
            'unit'           => $data['unit'] ?? 'kg',
            'effective_date' => $data['effective_date'],
            'source'         => $data['source'] ?? 'manual',
            'notes'          => $data['notes'] ?? null,
            'created_by'     => $userId,
        ]);
    }

    /**
     * Memperbarui master harga pasar dengan proteksi integritas referensi historis.
     * Record yang telah dirujuk oleh panen dilarang diubah nilai harga, tanggal, maupun komoditasnya.
     */
    public function updateMarketPrice(MarketPrice $marketPrice, array $data): MarketPrice
    {

        if (isset($data['effective_date']) || isset($data['commodity_id'])) {
            $targetCommId = $data['commodity_id'] ?? $marketPrice->commodity_id;
            $targetDate   = $data['effective_date'] ?? $marketPrice->effective_date?->toDateString();
            $duplicate = MarketPrice::withTrashed()
                ->where('commodity_id', $targetCommId)
                ->whereDate('effective_date', $targetDate)
                ->where('id', '!=', $marketPrice->id)
                ->exists();
            if ($duplicate) {
                throw new DomainException('Harga pasar untuk komoditas dan tanggal efektif tersebut sudah ada.');
            }
        }

        $marketPrice->update($data);
        return $marketPrice->load('commodity');
    }

    /**
     * Menghapus record harga pasar dengan guard proteksi referensi.
     */
    public function deleteMarketPrice(MarketPrice $marketPrice): void
    {
        if ($marketPrice->isReferenced()) {
            throw new DomainException('Harga pasar tidak dapat dihapus karena telah menjadi acuan pada data panen historis.');
        }

        $marketPrice->delete();
    }

    /**
     * Mengambil riwayat fluktuasi harga untuk komoditas tertentu.
     */
    public function getPriceHistory(int $commodityId, ?string $from = null, ?string $to = null): Collection
    {
        $query = MarketPrice::where('commodity_id', $commodityId)->orderBy('effective_date', 'desc');

        if ($from) $query->where('effective_date', '>=', $from);
        if ($to)   $query->where('effective_date', '<=', $to);

        return $query->get();
    }

    /**
     * Format respon harga pasar untuk output API.
     */
    public function formatMarketPrice(MarketPrice $price): array
    {
        return [
            'id'             => $price->id,
            'commodity_id'   => $price->commodity_id,
            'commodity_name' => $price->commodity?->name ?? 'N/A',
            'price'          => (float) $price->price,
            'unit'           => $price->unit,
            'effective_date' => $price->effective_date?->toDateString(),
            'source'         => $price->source,
            'notes'          => $price->notes ?? '',
            'is_referenced'  => $price->isReferenced(),
            'created_at'     => $price->created_at?->toIso8601String(),
        ];
    }
}
