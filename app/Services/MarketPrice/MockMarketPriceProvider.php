<?php

namespace App\Services\MarketPrice;

use App\Contracts\MarketPriceProviderInterface;
use App\Models\FarmerCommodity;
use DateTimeInterface;

/**
 * MockMarketPriceProvider
 *
 * PENTING:
 * Provider ini hanya digunakan untuk keperluan development, automated testing,
 * dan demonstrasi offline sampai sumber API eksternal nyata (seperti Bapanas/PIHPS)
 * telah terverifikasi kredensial dan endpoint-nya.
 * Sistem TIDAK mengklaim integrasi Bapanas asli sebelum endpoint riil diverifikasi.
 */
class MockMarketPriceProvider implements MarketPriceProviderInterface
{
    protected array $customPrices = [];

    public function getIdentifier(): string
    {
        return 'mock_feed';
    }

    /**
     * Memungkinkan penentuan harga kustom untuk skenario pengujian unit/feature test.
     */
    public function setMockPrices(array $prices): self
    {
        $this->customPrices = $prices;
        return $this;
    }

    public function fetchPricesForDate(DateTimeInterface $date): array
    {
        if (!empty($this->customPrices)) {
            return $this->customPrices;
        }

        $dateStr = $date->format('Y-m-d');
        $commodities = FarmerCommodity::where('status', 'active')->get();
        $feed = [];

        foreach ($commodities as $commodity) {
            $basePrice = $this->determineDefaultPrice($commodity->name);
            $feed[] = [
                'commodity_id'   => $commodity->id,
                'price'          => $basePrice,
                'unit'           => 'kg',
                'effective_date' => $dateStr,
                'source'         => $this->getIdentifier(),
                'notes'          => 'Data simulasi acuan pasar untuk development & testing',
            ];
        }

        return $feed;
    }

    public function fetchLatestPrices(): array
    {
        return $this->fetchPricesForDate(new \DateTimeImmutable());
    }

    protected function determineDefaultPrice(string $commodityName): float
    {
        $name = strtolower($commodityName);
        if (str_contains($name, 'cabai') || str_contains($name, 'cabe')) {
            return 45000.00;
        }
        if (str_contains($name, 'padi') || str_contains($name, 'beras')) {
            return 14500.00;
        }
        if (str_contains($name, 'bawang')) {
            return 32000.00;
        }
        if (str_contains($name, 'jagung')) {
            return 8500.00;
        }
        if (str_contains($name, 'tomat')) {
            return 12000.00;
        }
        if (str_contains($name, 'jamur')) {
            return 28000.00;
        }
        if (str_contains($name, 'kopi')) {
            return 65000.00;
        }
        return 20000.00;
    }
}
