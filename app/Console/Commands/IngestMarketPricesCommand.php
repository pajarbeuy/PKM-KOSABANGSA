<?php

namespace App\Console\Commands;

use App\Contracts\MarketPriceProviderInterface;
use App\Services\MarketPrice\MockMarketPriceProvider;
use App\Services\MarketPriceIngestionService;
use DateTimeImmutable;
use Illuminate\Console\Command;

class IngestMarketPricesCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'market-price:ingest
                            {--date= : Tanggal acuan harga pasar format YYYY-MM-DD (opsional, default hari ini)}
                            {--provider=mock : Provider feed acuan pasar (default: mock)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Ingest harga acuan pasar komoditas secara terjadwal atau manual';

    /**
     * Execute the console command.
     */
    public function handle(MarketPriceIngestionService $ingestionService): int
    {
        $this->info('Memulai proses ingestion harga pasar...');

        $providerName = $this->option('provider');
        $dateStr      = $this->option('date');

        // Resolve provider
        $provider = $this->resolveProvider($providerName);
        if (!$provider) {
            $this->error("Provider [{$providerName}] tidak ditemukan atau belum terdaftar.");
            return self::FAILURE;
        }

        $date = null;
        if ($dateStr) {
            try {
                $date = new DateTimeImmutable($dateStr);
            } catch (\Exception $e) {
                $this->error("Format tanggal [{$dateStr}] tidak valid. Gunakan YYYY-MM-DD.");
                return self::INVALID;
            }
        }

        $result = $ingestionService->ingestFromProvider($provider, $date);

        $this->table(
            ['Provider', 'Total', 'Created', 'Updated', 'Skipped (Same)', 'Rejected (Locked)'],
            [[
                $result['provider'],
                $result['total'],
                $result['created'],
                $result['updated'],
                $result['skipped'],
                $result['rejected'],
            ]]
        );

        $this->info('Proses ingestion harga pasar selesai.');
        return self::SUCCESS;
    }

    protected function resolveProvider(string $name): ?MarketPriceProviderInterface
    {
        return match (strtolower($name)) {
            'mock', 'mock_feed', 'simulated' => app(MockMarketPriceProvider::class),
            default => null,
        };
    }
}
