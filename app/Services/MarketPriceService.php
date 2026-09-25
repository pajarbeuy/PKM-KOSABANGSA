<?php

namespace App\Services;

use App\Models\MarketPrice;
use DomainException;
use Illuminate\Database\Eloquent\Collection;

class MarketPriceService
{
    /**
     * Mencari harga pasar yang berlaku efektif untuk komoditas tertentu pada tanggal tertentu.
     * Menggunakan aturan: effective_date <= date, diurutkan dari tanggal efektif paling mendekati.
     */
    public function findEffectivePrice(int $commodityId, string $date): ?MarketPrice
    {
        return MarketPrice::effectiveForDate($commodityId, $date)->first();
    }

    /**
     * Membuat record harga pasar baru (Super Admin only).
     */
    public function createMarketPrice(array $data, int $userId): MarketPrice
    {
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
        if ($marketPrice->isReferenced()) {
            $isPriceChanged = isset($data['price']) && (float) $data['price'] !== (float) $marketPrice->price;
            $isDateChanged  = isset($data['effective_date']) && $data['effective_date'] !== $marketPrice->effective_date?->toDateString();
            $isCommChanged  = isset($data['commodity_id']) && (int) $data['commodity_id'] !== (int) $marketPrice->commodity_id;

            if ($isPriceChanged || $isDateChanged || $isCommChanged) {
                throw new DomainException('Harga pasar tidak dapat diubah karena telah menjadi acuan pada data panen historis.');
            }

            // Jika hanya notes atau source yang diupdate
            if (isset($data['notes'])) $marketPrice->notes = $data['notes'];
            if (isset($data['source'])) $marketPrice->source = $data['source'];
            $marketPrice->save();

            return $marketPrice->load('commodity');
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
