<?php

namespace App\Contracts;

interface MarketPriceProviderInterface
{
    /**
     * Unique identifier for the provider (e.g. 'mock_feed', 'manual', 'bapanas').
     */
    public function getIdentifier(): string;

    /**
     * Mengambil feed harga pasar acuan untuk tanggal tertentu.
     *
     * @return array<int, array{
     *     commodity_id: int,
     *     price: float|numeric-string,
     *     unit: string,
     *     effective_date: string,
     *     source: string,
     *     notes: ?string
     * }>
     */
    public function fetchPricesForDate(\DateTimeInterface $date): array;

    /**
     * Mengambil feed harga pasar acuan terkini.
     *
     * @return array<int, array{
     *     commodity_id: int,
     *     price: float|numeric-string,
     *     unit: string,
     *     effective_date: string,
     *     source: string,
     *     notes: ?string
     * }>
     */
    public function fetchLatestPrices(): array;
}
