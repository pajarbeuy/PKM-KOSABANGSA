<?php

namespace App\Services;

use App\Contracts\MarketPriceProviderInterface;
use App\Models\MarketPrice;
use DateTimeInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class MarketPriceIngestionService
{
    /**
     * Mengorkestrasi proses ingestion harga pasar dari provider terpilih secara aman.
     *
     * @return array{
     *     provider: string,
     *     total: int,
     *     created: int,
     *     updated: int,
     *     skipped: int,
     *     rejected: int,
     *     details: array
     * }
     */
    public function ingestFromProvider(
        MarketPriceProviderInterface $provider,
        ?DateTimeInterface $date = null,
        ?int $userId = null
    ): array {
        $feed = $date
            ? $provider->fetchPricesForDate($date)
            : $provider->fetchLatestPrices();

        $stats = [
            'provider' => $provider->getIdentifier(),
            'total'    => count($feed),
            'created'  => 0,
            'updated'  => 0,
            'skipped'  => 0,
            'rejected' => 0,
            'details'  => [],
        ];

        DB::transaction(function () use ($feed, $userId, &$stats) {
            foreach ($feed as $item) {
                $commodityId   = (int) $item['commodity_id'];
                $effectiveDate = (string) $item['effective_date'];
                $incomingPrice = (float) $item['price'];

                $existing = MarketPrice::where('commodity_id', $commodityId)
                    ->whereDate('effective_date', $effectiveDate)
                    ->first();

                if (!$existing) {
                    MarketPrice::create([
                        'commodity_id'   => $commodityId,
                        'price'          => $incomingPrice,
                        'unit'           => $item['unit'] ?? 'kg',
                        'effective_date' => $effectiveDate,
                        'source'         => $item['source'] ?? 'mock_feed',
                        'notes'          => $item['notes'] ?? null,
                        'created_by'     => $userId,
                    ]);
                    $stats['created']++;
                    $stats['details'][] = [
                        'commodity_id'   => $commodityId,
                        'effective_date' => $effectiveDate,
                        'status'         => 'created',
                        'price'          => $incomingPrice,
                    ];
                } else {
                    $existingPrice = (float) $existing->price;

                    // 1. Kondisi Same Price -> Idempoten No-Op
                    if (abs($existingPrice - $incomingPrice) < 0.001) {
                        $stats['skipped']++;
                        $stats['details'][] = [
                            'commodity_id'   => $commodityId,
                            'effective_date' => $effectiveDate,
                            'status'         => 'skipped_same_price',
                            'price'          => $existingPrice,
                        ];
                    }
                    // 2. Kondisi Different Price + Referenced -> REJECT MUTATION
                    elseif ($existing->isReferenced()) {
                        Log::warning(
                            "MarketPriceIngestionService: Menolak mutasi harga komoditas {$commodityId} pada tanggal {$effectiveDate}. " .
                            "Record ID {$existing->id} telah terkunci sebagai acuan panen historis."
                        );
                        $stats['rejected']++;
                        $stats['details'][] = [
                            'commodity_id'   => $commodityId,
                            'effective_date' => $effectiveDate,
                            'status'         => 'rejected_referenced',
                            'current_price'  => $existingPrice,
                            'attempted_price'=> $incomingPrice,
                        ];
                    }
                    // 3. Kondisi Different Price + Unreferenced -> UPDATE ALLOWED
                    else {
                        $existing->update([
                            'price'  => $incomingPrice,
                            'unit'   => $item['unit'] ?? $existing->unit,
                            'source' => $item['source'] ?? $existing->source,
                            'notes'  => $item['notes'] ?? $existing->notes,
                        ]);
                        $stats['updated']++;
                        $stats['details'][] = [
                            'commodity_id'   => $commodityId,
                            'effective_date' => $effectiveDate,
                            'status'         => 'updated',
                            'old_price'      => $existingPrice,
                            'new_price'      => $incomingPrice,
                        ];
                    }
                }
            }
        });

        return $stats;
    }
}
