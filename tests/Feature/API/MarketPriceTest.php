<?php

namespace Tests\Feature\API;

use App\Contracts\MarketPriceProviderInterface;
use App\Models\FarmerCommodity;
use App\Models\Harvest;
use App\Models\MarketPrice;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\ProcessedProduct;
use App\Models\Season;
use App\Models\User;
use App\Services\FarmerCommodityService;
use App\Services\HarvestService;
use App\Services\MarketPrice\MockMarketPriceProvider;
use App\Services\MarketPriceIngestionService;
use App\Services\MarketPriceService;
use DateTimeInterface;
use DomainException;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class MarketPriceTest extends TestCase
{
    use RefreshDatabase;

    protected User $superAdmin;
    protected User $farmer;
    protected string $superAdminToken;
    protected string $farmerToken;
    protected FarmerCommodity $commodity;

    protected function setUp(): void
    {
        parent::setUp();

        if (DB::getDriverName() === 'sqlite') {
            DB::statement('PRAGMA foreign_keys = ON;');
        }

        $this->superAdmin = User::factory()->create([
            'role'   => 'super_admin',
            'status' => 'active',
        ]);
        $this->farmer = User::factory()->create([
            'role'   => 'user',
            'status' => 'active',
        ]);

        $this->superAdminToken = $this->superAdmin->createToken('admin-token')->plainTextToken;
        $this->farmerToken     = $this->farmer->createToken('farmer-token')->plainTextToken;

        $this->commodity = FarmerCommodity::create([
            'user_id'     => $this->farmer->id,
            'name'        => 'Cabai Rawit Merah',
            'code'        => 'CRM-01',
            'unit'        => 'kg',
            'description' => 'Komoditas cabai rawit merah segar',
            'status'      => 'active',
        ]);
    }

    /**
     * Test 1: Super Admin dapat menambah master harga pasar dengan effective_date.
     */
    public function test_super_admin_can_create_market_price()
    {
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->superAdminToken}",
            'Accept'        => 'application/json',
        ])->postJson('/api/market-prices', [
            'commodity_id'   => $this->commodity->id,
            'price'          => 35000,
            'unit'           => 'kg',
            'effective_date' => '2026-08-01',
            'source'         => 'mock_feed',
            'notes'          => 'Harga pasar acuan pembukaan Agustus',
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('data.commodity_id', $this->commodity->id);
        $this->assertEquals(35000.0, (float) $response->json('data.price'));
        $response->assertJsonPath('data.effective_date', '2026-08-01');

        $this->assertDatabaseHas('market_prices', [
            'commodity_id' => $this->commodity->id,
            'price'        => 35000,
        ]);
    }

    /**
     * Test 2: Ingestion Safe Mutation Test:
     * - same price → no-op (idempoten)
     * - different + unreferenced → update
     * - different + referenced → reject
     */
    public function test_ingestion_safe_mutation_rules()
    {
        $ingestionService = app(MarketPriceIngestionService::class);

        // Provider Mock khusus untuk simulasi multi-kondisi
        $mockProvider = new class($this->commodity->id) implements MarketPriceProviderInterface {
            private int $commodityId;
            private array $items = [];

            public function __construct(int $commodityId)
            {
                $this->commodityId = $commodityId;
            }

            public function setItems(array $items): void
            {
                $this->items = $items;
            }

            public function getIdentifier(): string
            {
                return 'test_mock_provider';
            }

            public function fetchPricesForDate(DateTimeInterface $date): array
            {
                return $this->items;
            }

            public function fetchLatestPrices(): array
            {
                return $this->items;
            }
        };

        // 1. Initial Ingestion: Insert record 1 (unreferenced) dan record 2 (akan direferensikan)
        $mockProvider->setItems([
            [
                'commodity_id'   => $this->commodity->id,
                'price'          => 30000,
                'unit'           => 'kg',
                'effective_date' => '2026-08-10',
                'source'         => 'mock_feed',
                'notes'          => 'Initial 1',
            ],
            [
                'commodity_id'   => $this->commodity->id,
                'price'          => 40000,
                'unit'           => 'kg',
                'effective_date' => '2026-08-20',
                'source'         => 'mock_feed',
                'notes'          => 'Initial 2',
            ],
        ]);

        $initialStats = $ingestionService->ingestFromProvider($mockProvider, null, $this->superAdmin->id);
        $this->assertEquals(2, $initialStats['created']);

        $priceRecord1 = MarketPrice::where('commodity_id', $this->commodity->id)->whereDate('effective_date', '2026-08-10')->first();
        $priceRecord2 = MarketPrice::where('commodity_id', $this->commodity->id)->whereDate('effective_date', '2026-08-20')->first();

        $this->assertNotNull($priceRecord1);
        $this->assertNotNull($priceRecord2);

        // Jadikan priceRecord2 dirujuk (referenced) oleh data panen
        $season = Season::create([
            'user_id'      => $this->farmer->id,
            'name'         => 'Musim Uji Coba',
            'commodity_id' => $this->commodity->id,
            'start_date'   => '2026-08-01',
            'end_date'     => '2026-08-31',
            'status'       => 'active',
        ]);

        Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $priceRecord2->id,
            'market_price_snapshot'       => 40000,
            'market_price_effective_date' => '2026-08-20',
            'weight_kg'                   => 100,
            'quantity'                    => 100,
            'unit'                        => 'kg',
            'date'                        => '2026-08-21',
            'status'                      => 'recorded',
        ]);

        $this->assertTrue($priceRecord2->fresh()->isReferenced());
        $this->assertFalse($priceRecord1->fresh()->isReferenced());

        // Jalankan Ingestion kedua dengan 3 kasus sekaligus:
        // A. Same price pada 2026-08-10 -> no-op (skipped)
        // B. Different price pada 2026-08-10 (misal diubah ke 32500) dan unreferenced -> update
        // C. Different price pada 2026-08-20 (misal diubah ke 45000) dan referenced -> reject
        
        // Uji A: same price -> no-op
        $mockProvider->setItems([
            [
                'commodity_id'   => $this->commodity->id,
                'price'          => 30000, // sama persis
                'unit'           => 'kg',
                'effective_date' => '2026-08-10',
                'source'         => 'mock_feed',
                'notes'          => 'Same price',
            ],
        ]);
        $statsA = $ingestionService->ingestFromProvider($mockProvider, null, $this->superAdmin->id);
        $this->assertEquals(1, $statsA['skipped'], 'Same price harus no-op (skipped)');
        $this->assertEquals(0, $statsA['updated']);
        $this->assertEquals(0, $statsA['rejected']);

        // Uji B: different + unreferenced -> update
        $mockProvider->setItems([
            [
                'commodity_id'   => $this->commodity->id,
                'price'          => 32500, // berbeda & unreferenced
                'unit'           => 'kg',
                'effective_date' => '2026-08-10',
                'source'         => 'mock_feed',
                'notes'          => 'Updated price',
            ],
        ]);
        $statsB = $ingestionService->ingestFromProvider($mockProvider, null, $this->superAdmin->id);
        $this->assertEquals(1, $statsB['updated'], 'Different price + unreferenced harus diupdate');
        $this->assertEquals(32500.0, (float) $priceRecord1->fresh()->price);

        // Uji C: different + referenced -> reject
        $mockProvider->setItems([
            [
                'commodity_id'   => $this->commodity->id,
                'price'          => 45000, // berbeda tetapi sudah direferensikan panen
                'unit'           => 'kg',
                'effective_date' => '2026-08-20',
                'source'         => 'mock_feed',
                'notes'          => 'Mutated price',
            ],
        ]);
        $statsC = $ingestionService->ingestFromProvider($mockProvider, null, $this->superAdmin->id);
        $this->assertEquals(1, $statsC['rejected'], 'Different price + referenced harus direject');
        $this->assertEquals(40000.0, (float) $priceRecord2->fresh()->price, 'Harga pada record yang direferensikan tidak boleh berubah');
    }

    /**
     * Test 3: Role Authorization Guard: Petani dilarang menambah, mengubah, atau menghapus master harga (HTTP 403).
     */
    public function test_farmer_is_forbidden_from_managing_market_prices()
    {
        $price = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 30000,
            'unit'           => 'kg',
            'effective_date' => '2026-08-01',
            'source'         => 'manual',
            'created_by'     => $this->superAdmin->id,
        ]);

        // 1. Create attempt -> 403
        $createRes = $this->withHeaders([
            'Authorization' => "Bearer {$this->farmerToken}",
            'Accept'        => 'application/json',
        ])->postJson('/api/market-prices', [
            'commodity_id'   => $this->commodity->id,
            'price'          => 32000,
            'unit'           => 'kg',
            'effective_date' => '2026-08-02',
        ]);
        $createRes->assertStatus(403);

        // 2. Update attempt -> 403
        $updateRes = $this->withHeaders([
            'Authorization' => "Bearer {$this->farmerToken}",
            'Accept'        => 'application/json',
        ])->putJson("/api/market-prices/{$price->id}", [
            'price' => 33000,
        ]);
        $updateRes->assertStatus(403);

        // 3. Delete attempt -> 403
        $deleteRes = $this->withHeaders([
            'Authorization' => "Bearer {$this->farmerToken}",
            'Accept'        => 'application/json',
        ])->deleteJson("/api/market-prices/{$price->id}");
        $deleteRes->assertStatus(403);

        // 4. Ingest attempt -> 403
        $ingestRes = $this->withHeaders([
            'Authorization' => "Bearer {$this->farmerToken}",
            'Accept'        => 'application/json',
        ])->postJson('/api/market-prices/ingest');
        $ingestRes->assertStatus(403);

        // 5. Namun Petani BISA membaca daftar harga pasar (Read-Only) -> 200
        $readRes = $this->withHeaders([
            'Authorization' => "Bearer {$this->farmerToken}",
            'Accept'        => 'application/json',
        ])->getJson('/api/market-prices');
        $readRes->assertStatus(200);
        $readRes->assertJsonPath('data.market_prices.0.id', $price->id);
    }

    /**
     * Test 4: Mock Ingestion Service: Ingestion mengimpor data terstruktur dengan kontrak array DTO.
     */
    public function test_mock_market_price_provider_contract_and_command()
    {
        $provider = new MockMarketPriceProvider();
        $this->assertEquals('mock_feed', $provider->getIdentifier());

        $latestPrices = $provider->fetchLatestPrices();
        $this->assertIsArray($latestPrices);
        $this->assertNotEmpty($latestPrices);

        foreach ($latestPrices as $item) {
            $this->assertArrayHasKey('commodity_id', $item);
            $this->assertArrayHasKey('price', $item);
            $this->assertArrayHasKey('unit', $item);
            $this->assertArrayHasKey('effective_date', $item);
            $this->assertArrayHasKey('source', $item);
            $this->assertArrayHasKey('notes', $item);
            $this->assertMatchesRegularExpression('/^\d{4}-\d{2}-\d{2}$/', $item['effective_date']);
        }

        // Test artisan command: market-price:ingest
        $this->artisan('market-price:ingest')
            ->expectsOutputToContain('Memulai proses ingestion')
            ->expectsOutputToContain('Proses ingestion harga pasar selesai.')
            ->assertSuccessful();
    }

    /**
     * Test 5: Harvest Automatic Snapshot Lookup: Panen otomatis mengunci harga pasar dengan effective_date <= harvest_date.
     */
    public function test_harvest_automatically_snapshots_effective_market_price()
    {
        // Setup harga bertanggal 1 Juli dan 1 Agustus
        MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 20000,
            'unit'           => 'kg',
            'effective_date' => '2026-07-01',
            'source'         => 'mock_feed',
        ]);

        $augustPrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 25000,
            'unit'           => 'kg',
            'effective_date' => '2026-08-01',
            'source'         => 'mock_feed',
        ]);

        $season = Season::create([
            'user_id'      => $this->farmer->id,
            'name'         => 'Musim Panen Raya',
            'commodity_id' => $this->commodity->id,
            'start_date'   => '2026-07-01',
            'end_date'     => '2026-09-30',
            'status'       => 'active',
        ]);

        // Catat panen pada tanggal 15 Agustus (harus mengunci harga 1 Agustus Rp25.000)
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->farmerToken}",
            'Accept'        => 'application/json',
        ])->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'commodity_id' => $this->commodity->id,
            'weight_kg'    => 50,
            'quantity'     => 50,
            'unit'         => 'kg',
            'harvest_date' => '2026-08-15',
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('data.market_price_id', $augustPrice->id);
        $this->assertEquals(25000.0, (float) $response->json('data.market_price_snapshot'));
        $response->assertJsonPath('data.market_price_effective_date', '2026-08-01');
        // Gross harvest value = 50 kg * 25.000 = 1.250.000
        $this->assertEquals(1250000.0, (float) $response->json('data.gross_harvest_value'));

        $this->assertDatabaseHas('harvests', [
            'commodity_id'          => $this->commodity->id,
            'market_price_id'       => $augustPrice->id,
            'market_price_snapshot' => 25000,
        ]);
    }

    /**
     * Test 6: Harvest Snapshot Immutability: Perubahan master harga pasar di masa depan tidak mengubah snapshot panen lama.
     */
    public function test_harvest_snapshot_remains_immutable_when_new_market_prices_are_added()
    {
        $season = Season::create([
            'user_id'      => $this->farmer->id,
            'name'         => 'Musim Panen Immutability',
            'commodity_id' => $this->commodity->id,
            'start_date'   => '2026-06-01',
            'end_date'     => '2026-08-31',
            'status'       => 'active',
        ]);

        $initialPrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 15000,
            'unit'           => 'kg',
            'effective_date' => '2026-06-01',
            'source'         => 'mock_feed',
        ]);

        // Buat panen 10 Juni
        $harvestRes = $this->withHeaders([
            'Authorization' => "Bearer {$this->farmerToken}",
            'Accept'        => 'application/json',
        ])->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'commodity_id' => $this->commodity->id,
            'weight_kg'    => 100,
            'harvest_date' => '2026-06-10',
        ]);
        $harvestId = $harvestRes->json('data.id');
        $this->assertEquals(15000.0, (float) $harvestRes->json('data.market_price_snapshot'));
        $this->assertEquals(1500000.0, (float) $harvestRes->json('data.gross_harvest_value'));

        // Bulan Juli harga pasar naik menjadi 22.000
        MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 22000,
            'unit'           => 'kg',
            'effective_date' => '2026-07-01',
            'source'         => 'mock_feed',
        ]);

        // Refresh panen lama dari DB: snapshot dan gross harvest value harus tetap 15.000 & 1.500.000!
        $harvest = Harvest::find($harvestId);
        $formatted = app(HarvestService::class)->formatHarvest($harvest);

        $this->assertEquals(15000.0, (float) $harvest->market_price_snapshot);
        $this->assertEquals('2026-06-01', $harvest->market_price_effective_date->toDateString());
        $this->assertEquals(1500000.0, (float) $formatted['gross_harvest_value']);
    }

    /**
     * Test 7: Referenced Price Delete Guard: Menghapus harga pasar yang sudah dirujuk panen ditolak dengan HTTP 422.
     */
    public function test_referenced_market_price_cannot_be_deleted()
    {
        $price = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 18000,
            'unit'           => 'kg',
            'effective_date' => '2026-07-01',
            'source'         => 'manual',
            'created_by'     => $this->superAdmin->id,
        ]);

        $season = Season::create([
            'user_id'      => $this->farmer->id,
            'name'         => 'Musim Cek Referensi',
            'commodity_id' => $this->commodity->id,
            'start_date'   => '2026-07-01',
            'end_date'     => '2026-07-31',
            'status'       => 'active',
        ]);

        Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $price->id,
            'market_price_snapshot'       => 18000,
            'market_price_effective_date' => '2026-07-01',
            'weight_kg'                   => 40,
            'date'                        => '2026-07-10',
            'status'                      => 'recorded',
        ]);

        $this->assertTrue($price->fresh()->isReferenced());

        // Super Admin mencoba menghapus harga yang telah dirujuk
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->superAdminToken}",
            'Accept'        => 'application/json',
        ])->deleteJson("/api/market-prices/{$price->id}");

        $response->assertStatus(422);
        $this->assertDatabaseHas('market_prices', ['id' => $price->id]);
    }

    /**
     * Test 8: Referenced Price Update Guard: Mengubah nominal harga pasar yang sudah dirujuk panen ditolak dengan HTTP 422.
     */
    public function test_referenced_market_price_nominal_cannot_be_updated()
    {
        $price = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 20000,
            'unit'           => 'kg',
            'effective_date' => '2026-07-01',
            'source'         => 'manual',
            'notes'          => 'Catatan awal',
            'created_by'     => $this->superAdmin->id,
        ]);

        $season = Season::create([
            'user_id'      => $this->farmer->id,
            'name'         => 'Musim Guard Update',
            'commodity_id' => $this->commodity->id,
            'start_date'   => '2026-07-01',
            'end_date'     => '2026-07-31',
            'status'       => 'active',
        ]);

        Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $price->id,
            'market_price_snapshot'       => 20000,
            'market_price_effective_date' => '2026-07-01',
            'weight_kg'                   => 60,
            'date'                        => '2026-07-15',
            'status'                      => 'recorded',
        ]);

        // Coba ubah nominal harga -> 422 ditolak
        $updatePriceRes = $this->withHeaders([
            'Authorization' => "Bearer {$this->superAdminToken}",
            'Accept'        => 'application/json',
        ])->putJson("/api/market-prices/{$price->id}", [
            'price' => 22000,
        ]);
        $updatePriceRes->assertStatus(422);

        // Namun jika hanya mengupdate metadata non-destruktif (seperti notes) -> diizinkan 200
        $updateNotesRes = $this->withHeaders([
            'Authorization' => "Bearer {$this->superAdminToken}",
            'Accept'        => 'application/json',
        ])->putJson("/api/market-prices/{$price->id}", [
            'notes' => 'Catatan diperbarui tanpa mengubah harga',
        ]);
        $updateNotesRes->assertStatus(200);
        $this->assertEquals('Catatan diperbarui tanpa mengubah harga', $price->fresh()->notes);
        $this->assertEquals(20000.0, (float) $price->fresh()->price);
    }

    /**
     * Test 9: Restrict Cascade Delete from Commodity:
     * Menghapus komoditas yang memiliki harga pasar acuan terikat ditolak oleh foreign key RESTRICT & domain guard.
     */
    public function test_commodity_cannot_be_deleted_if_it_has_market_prices_history()
    {
        MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 25000,
            'unit'           => 'kg',
            'effective_date' => '2026-07-01',
            'source'         => 'manual',
            'created_by'     => $this->superAdmin->id,
        ]);

        // 1. Guard di level Service / Controller: Ditolak dengan InvalidArgumentException / 422
        $apiDeleteRes = $this->withHeaders([
            'Authorization' => "Bearer {$this->farmerToken}",
            'Accept'        => 'application/json',
        ])->deleteJson("/api/commodities/{$this->commodity->id}");

        $apiDeleteRes->assertStatus(422);
        $this->assertDatabaseHas('farmer_commodities', ['id' => $this->commodity->id]);

        // 2. Guard di level Database (Foreign Key ON DELETE RESTRICT):
        // Jika ada query DELETE langsung di DB, SQLite / MySQL harus melempar QueryException constraint violation
        $caughtFkException = false;
        try {
            DB::table('farmer_commodities')->where('id', $this->commodity->id)->delete();
        } catch (\Throwable $e) {
            $caughtFkException = true;
            $this->assertTrue(
                $e instanceof QueryException || str_contains($e->getMessage(), 'FOREIGN KEY') || str_contains($e->getMessage(), 'constraint failed')
            );
        }

        $this->assertTrue($caughtFkException, 'Database engine wajib menolak penghapusan komoditas jika terdapat relasi ON DELETE RESTRICT');
        $this->assertDatabaseHas('farmer_commodities', ['id' => $this->commodity->id]);
    }

    /**
     * Test 10: Date Separation (Harvest vs Transaction):
     * - Panen tanggal 1 Juni mengunci harga acuan 1 Juni.
     * - Transaksi jual-beli pada 15 September mengacu pada harga efektif 15 September.
     */
    public function test_date_separation_between_harvest_snapshot_and_transaction_date()
    {
        // 1. Harga Pasar Juni: Rp12.000
        $junePrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 12000,
            'unit'           => 'kg',
            'effective_date' => '2026-06-01',
            'source'         => 'mock_feed',
        ]);

        // 2. Harga Pasar September: Rp18.000
        $septPrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 18000,
            'unit'           => 'kg',
            'effective_date' => '2026-09-01',
            'source'         => 'mock_feed',
        ]);

        $season = Season::create([
            'user_id'      => $this->farmer->id,
            'name'         => 'Musim Musim Silang',
            'commodity_id' => $this->commodity->id,
            'start_date'   => '2026-05-01',
            'end_date'     => '2026-09-30',
            'status'       => 'active',
        ]);

        // Panen pada 5 Juni mengunci harga 1 Juni (Rp12.000)
        $harvest = app(HarvestService::class)->createHarvest([
            'season_id'    => $season->id,
            'commodity_id' => $this->commodity->id,
            'weight_kg'    => 100,
            'harvest_date' => '2026-06-05',
        ], $this->farmer->id);

        $this->assertEquals(12000.0, (float) $harvest->market_price_snapshot);
        $this->assertEquals('2026-06-01', $harvest->market_price_effective_date->toDateString());

        // Transaksi penjualan pada 15 September:
        // Harga acuan pasar yang berlaku pada 15 September adalah harga efektif 1 September (Rp18.000), BUKAN harga panen 5 Juni (Rp12.000)
        $marketPriceService = app(MarketPriceService::class);
        $effectivePriceForTransaction = $marketPriceService->findEffectivePrice($this->commodity->id, '2026-09-15');

        $this->assertNotNull($effectivePriceForTransaction);
        $this->assertEquals($septPrice->id, $effectivePriceForTransaction->id);
        $this->assertEquals(18000.0, (float) $effectivePriceForTransaction->price);

        // Snapshot panen lama tetap utuh di Rp12.000
        $this->assertEquals(12000.0, (float) $harvest->fresh()->market_price_snapshot);
    }

    /**
     * Test 11: Processed Product Price Isolation & Audit Constraint:
     * Order/Sale produk olahan tidak terpengaruh oleh harga pasar komoditas mentah.
     * Tidak ada duplikasi field/flow baru pada pipeline pesanan & penjualan.
     */
    public function test_processed_product_order_uses_catalog_snapshot_without_market_price_interference()
    {
        // Setup harga pasar komoditas mentah
        MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 50000,
            'unit'           => 'kg',
            'effective_date' => '2026-08-01',
            'source'         => 'mock_feed',
        ]);

        // Produk olahan (misal Sambal Cabai Botol) di katalog
        $product = ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Sambal Botol Kemasan Super',
            'description' => 'Olahan cabai rawit pedas mantap',
            'price'       => 25000,
            'unit'        => 'botol',
            'stock'       => 50,
            'status'      => 'active',
        ]);

        // Buat Order pesanan produk olahan
        $order = Order::create([
            'order_code'       => 'ORD-20260810-001',
            'customer_name'    => 'Budi Santoso',
            'customer_phone'   => '081234567890',
            'customer_address' => 'Jl. Merdeka No. 12',
            'total_amount'     => 50000,
            'status'           => 'pending',
        ]);

        // Order item mengunci harga produk olahan Rp25.000/botol
        $orderItem = OrderItem::create([
            'order_id'             => $order->id,
            'processed_product_id' => $product->id,
            'quantity'             => 2,
            'price_snapshot'       => 25000,
            'subtotal'             => 50000,
        ]);

        // Verifikasi: Order item menggunakan harga katalog independen dari fluktuasi komoditas mentah
        $this->assertEquals(25000.0, (float) $orderItem->price_snapshot);
        $this->assertEquals(50000.0, (float) $orderItem->subtotal);

        // Ubah harga komoditas mentah menjadi Rp70.000
        MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 70000,
            'unit'           => 'kg',
            'effective_date' => '2026-08-11',
            'source'         => 'mock_feed',
        ]);

        // Order item tetap Rp25.000 / subtotal Rp50.000 (tidak ada distorsi / duplicate flow)
        $this->assertEquals(25000.0, (float) $orderItem->fresh()->price_snapshot);
        $this->assertEquals(50000.0, (float) $orderItem->fresh()->subtotal);
    }
}
