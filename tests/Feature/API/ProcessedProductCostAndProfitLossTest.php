<?php

namespace Tests\Feature\API;

use App\Models\FarmerCommodity;
use App\Models\FarmerGroup;
use App\Models\Harvest;
use App\Models\MarketPrice;
use App\Models\ProcessedProduct;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\Season;
use App\Models\StockTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProcessedProductCostAndProfitLossTest extends TestCase
{
    use RefreshDatabase;

    private User $farmer1;
    private User $farmer2;
    private FarmerCommodity $commodity;
    private Season $season;
    private Harvest $harvest;
    private ProcessedProduct $processedProduct;

    protected function setUp(): void
    {
        parent::setUp();

        $group = FarmerGroup::create([
            'name'      => 'Poktan Jamur Makmur',
            'code'      => 'PKT-JM-01',
            'village'   => 'Tulungrejo',
            'district'  => 'Bumiaji',
            'regency'   => 'Kota Batu',
            'province'  => 'Jawa Timur',
            'is_active' => true,
        ]);

        $this->farmer1 = User::create([
            'name'            => 'Petani Jamur Tiram',
            'email'           => 'petani.jamur@test.com',
            'password'        => bcrypt('password123'),
            'role'            => 'user',
            'status'          => 'active',
            'farmer_group_id' => $group->id,
        ]);

        $this->farmer2 = User::create([
            'name'            => 'Petani Lain',
            'email'           => 'petani.lain@test.com',
            'password'        => bcrypt('password123'),
            'role'            => 'user',
            'status'          => 'active',
            'farmer_group_id' => $group->id,
        ]);

        $this->commodity = FarmerCommodity::create([
            'user_id' => $this->farmer1->id,
            'name'    => 'Jamur Tiram',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        // Market price 10.000/kg
        MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 10000,
            'source'         => 'manual',
            'effective_date' => '2026-01-01',
            'recorded_at'    => now(),
        ]);

        $this->season = Season::create([
            'user_id'      => $this->farmer1->id,
            'name'         => 'Musim Jamur 2026',
            'start_date'   => '2026-01-01',
            'end_date'     => '2026-12-31',
            'status'       => 'active',
            'target_kg'    => 100,
            'commodity_id' => $this->commodity->id,
        ]);

        // Modal kebun (farm cost) = Rp 200.000
        ProductionCost::create([
            'user_id'    => $this->farmer1->id,
            'season_id'  => $this->season->id,
            'cost_type'  => 'farm',
            'category'   => 'seed',
            'amount'     => 200000,
            'date'       => '2026-02-01',
            'notes'      => 'Bibit baglog jamur tiram',
        ]);

        // Panen 30 kg dengan snapshot harga Rp 10.000/kg
        $this->harvest = Harvest::create([
            'user_id'               => $this->farmer1->id,
            'season_id'             => $this->season->id,
            'commodity_id'          => $this->commodity->id,
            'date'                  => '2026-03-01',
            'weight_kg'             => 30,
            'quantity'              => 30,
            'unit'                  => 'kg',
            'market_price_snapshot' => 10000,
            'status'                => 'recorded',
            'notes'                 => 'Panen perdana 30kg',
        ]);

        // Initial warehouse stock for raw harvest
        StockTransaction::addTransaction('in', 30, 'Panen masuk gudang', 'harvest_' . $this->harvest->id, $this->farmer1->id);

        // Processed Product "Jamur Crispy"
        $this->processedProduct = ProcessedProduct::create([
            'owner_id'    => $this->farmer1->id,
            'name'        => 'Jamur Crispy Renyah',
            'price'       => 5000,
            'stock'       => 0,
            'status'      => 'active',
            'description' => 'Keripik jamur crispy kemasan 100gr',
        ]);
    }

    /** @test */
    public function test_farmer_can_convert_harvest_to_processed_product_with_zero_double_counting(): void
    {
        Sanctum::actingAs($this->farmer1);

        $payload = [
            'harvest_id'              => $this->harvest->id,
            'raw_material_weight_kg'  => 15.0,
            'additional_stock'        => 150,
            'cost_items'              => [
                [
                    'category'       => 'raw_material_addon',
                    'item_name'      => 'Tepung Terigu',
                    'quantity'       => 2,
                    'unit'           => 'kg',
                    'price_per_unit' => 10000,
                    'amount'         => 20000,
                    'date'           => '2026-03-05',
                    'notes'          => 'Tepung bumbu',
                ],
                [
                    'category'       => 'raw_material_addon',
                    'item_name'      => 'Minyak Goreng',
                    'quantity'       => 2,
                    'unit'           => 'liter',
                    'price_per_unit' => 12000,
                    'amount'         => 24000,
                    'date'           => '2026-03-05',
                    'notes'          => 'Minyak goreng kelapa',
                ],
            ],
        ];

        $response = $this->postJson("/api/processed-products/{$this->processedProduct->id}/convert-harvest", $payload);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Bahan baku panen berhasil dialihkan ke produk olahan.',
                'data' => [
                    'product' => [
                        'id'                     => $this->processedProduct->id,
                        'name'                   => 'Jamur Crispy Renyah',
                        'stock'                  => 150,
                        'raw_material_weight_kg' => 15,
                        'total_processing_cost'  => 44000,
                    ],
                ],
            ]);

        // Verifikasi database: Stock Transaction Out tercatat untuk bahan mentah panen
        $this->assertDatabaseHas('stock_transactions', [
            'user_id' => $this->farmer1->id,
            'type'    => 'out',
            'amount'  => 15.0,
        ]);

        // Verifikasi database: Stock Transaction In untuk produk olahan
        $this->assertDatabaseHas('stock_transactions', [
            'user_id'              => $this->farmer1->id,
            'processed_product_id' => $this->processedProduct->id,
            'type'                 => 'in',
            'amount'               => 150,
        ]);

        // Verifikasi database: Raw material record (amount = 0)
        $this->assertDatabaseHas('production_costs', [
            'user_id'                  => $this->farmer1->id,
            'cost_type'                => 'processing',
            'processed_product_id'     => $this->processedProduct->id,
            'raw_material_harvest_id'  => $this->harvest->id,
            'amount'                   => 0.00,
        ]);

        // Verifikasi database: Itemized modal olahan tambahan tercatat
        $this->assertDatabaseHas('production_costs', [
            'user_id'              => $this->farmer1->id,
            'cost_type'            => 'processing',
            'processed_product_id' => $this->processedProduct->id,
            'item_name'            => 'Tepung Terigu',
            'amount'               => 20000.00,
        ]);

        $this->assertDatabaseHas('production_costs', [
            'user_id'              => $this->farmer1->id,
            'cost_type'            => 'processing',
            'processed_product_id' => $this->processedProduct->id,
            'item_name'            => 'Minyak Goreng',
            'amount'               => 24000.00,
        ]);
    }

    /** @test */
    public function test_farmer_can_record_standalone_processing_cost_via_cost_api(): void
    {
        Sanctum::actingAs($this->farmer1);

        $payload = [
            'cost_type'            => 'processing',
            'processed_product_id' => $this->processedProduct->id,
            'category'             => 'packaging',
            'item_name'            => 'Standing Pouch Alumunium Foil',
            'quantity'             => 100,
            'unit'                 => 'pcs',
            'price_per_unit'       => 500,
            'amount'               => 50000,
            'date'                 => '2026-03-06',
            'notes'                => 'Kemasan kedap udara dengan zipper',
        ];

        $response = $this->postJson('/api/costs', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'cost_type'            => 'processing',
                    'processed_product_id' => $this->processedProduct->id,
                    'category'             => 'packaging',
                    'item_name'            => 'Standing Pouch Alumunium Foil',
                    'quantity'             => 100,
                    'unit'                 => 'pcs',
                    'price_per_unit'       => 500,
                    'amount'               => 50000,
                ],
            ]);

        $this->assertDatabaseHas('production_costs', [
            'user_id'              => $this->farmer1->id,
            'cost_type'            => 'processing',
            'processed_product_id' => $this->processedProduct->id,
            'category'             => 'packaging',
            'amount'               => 50000,
        ]);
    }

    /** @test */
    public function test_processed_product_economic_summary_computes_correct_profit_and_margins(): void
    {
        Sanctum::actingAs($this->farmer1);

        // Biaya Olahan Rp 44.000 (Tepung Rp 20.000 + Minyak Rp 24.000)
        ProductionCost::create([
            'user_id'              => $this->farmer1->id,
            'cost_type'            => 'processing',
            'processed_product_id' => $this->processedProduct->id,
            'category'             => 'raw_material_addon',
            'item_name'            => 'Tepung Terigu',
            'amount'               => 20000,
            'date'                 => '2026-03-05',
        ]);
        ProductionCost::create([
            'user_id'              => $this->farmer1->id,
            'cost_type'            => 'processing',
            'processed_product_id' => $this->processedProduct->id,
            'category'             => 'raw_material_addon',
            'item_name'            => 'Minyak Goreng',
            'amount'               => 24000,
            'date'                 => '2026-03-05',
        ]);

        $this->processedProduct->update([
            'stock'                  => 150,
            'raw_material_weight_kg' => 15.0,
        ]);

        // Penjualan produk olahan: 100 pcs @ 5.000 = Rp 500.000
        Sale::create([
            'user_id'              => $this->farmer1->id,
            'processed_product_id' => $this->processedProduct->id,
            'product_type'         => 'processed',
            'buyer_name'           => 'Toko Camilan Batu',
            'date'                 => '2026-03-10',
            'weight_kg'            => 100,
            'price_per_kg'         => 5000,
            'total'                => 500000,
            'payment_status'       => 'paid',
        ]);

        $response = $this->getJson("/api/processed-products/{$this->processedProduct->id}/economic-summary");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'product_id'             => $this->processedProduct->id,
                    'product_name'           => 'Jamur Crispy Renyah',
                    'raw_material_weight_kg' => 15.0,
                    'total_processing_cost'  => 44000.0,
                    'units_sold'             => 100,
                    'current_stock'          => 150,
                    'realized_revenue'       => 500000.0,
                    'realized_profit_loss'   => 456000.0, // 500.000 - 44.000
                    'realized_status'        => 'profit',
                ],
            ]);
    }

    /** @test */
    public function test_farmer_integrated_economic_summary_combines_hulu_and_hilir_cleanly(): void
    {
        Sanctum::actingAs($this->farmer1);

        // HULU (Hasil Tani Kebun):
        // Modal kebun = Rp 200.000 (sudah di setUp)
        // Panen = 30 kg @ 10.000/kg snapshot = Rp 300.000

        // HILIR (Produk Olahan):
        // 15 kg dialihkan menjadi produk olahan jamur crispy
        $this->processedProduct->update([
            'harvest_id'             => $this->harvest->id,
            'raw_material_weight_kg' => 15.0,
            'stock'                  => 150,
        ]);

        // Modal olahan: Rp 44.000 (Tepung + Minyak)
        ProductionCost::create([
            'user_id'              => $this->farmer1->id,
            'cost_type'            => 'processing',
            'processed_product_id' => $this->processedProduct->id,
            'category'             => 'raw_material_addon',
            'amount'               => 44000,
            'date'                 => '2026-03-05',
        ]);

        // Penjualan olahan: 150 pcs @ 5.000 = Rp 750.000
        Sale::create([
            'user_id'              => $this->farmer1->id,
            'processed_product_id' => $this->processedProduct->id,
            'product_type'         => 'processed',
            'buyer_name'           => 'Toko Oleh-Oleh Malang',
            'date'                 => '2026-03-12',
            'weight_kg'            => 150,
            'price_per_kg'         => 5000,
            'total'                => 750000,
            'payment_status'       => 'paid',
        ]);

        $response = $this->getJson('/api/farmer/integrated-economic-summary');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'farmer_id'                    => $this->farmer1->id,
                    'farm_harvest_weight_kg'       => 30.0,
                    'raw_material_allocated_kg'    => 15.0,
                    'net_harvest_market_weight_kg' => 15.0,
                    'farm_revenue'                 => 300000.0,
                    'farm_production_cost'         => 200000.0,
                    'farm_profit_loss'             => 100000.0,
                    'farm_profit_loss_status'      => 'profit',
                    'processing_production_cost'   => 44000.0,
                    'processed_revenue'            => 750000.0,
                    'processed_profit_loss'        => 706000.0,
                    'processed_profit_loss_status' => 'profit',
                    'total_integrated_revenue'     => 1050000.0, // 300.000 + 750.000
                    'total_integrated_cost'        => 244000.0,  // 200.000 + 44.000
                    'total_integrated_profit_loss' => 806000.0,  // 100.000 + 706.000
                    'integrated_profit_loss_status'=> 'profit',
                ],
            ]);
    }

    /** @test */
    public function test_multi_tenancy_farmer_cannot_convert_another_farmers_harvest(): void
    {
        Sanctum::actingAs($this->farmer2);

        $payload = [
            'harvest_id'             => $this->harvest->id, // milik farmer1
            'raw_material_weight_kg' => 10.0,
            'additional_stock'       => 50,
        ];

        // Farmer 2 mencoba convert ke produk farmer 1
        $response = $this->postJson("/api/processed-products/{$this->processedProduct->id}/convert-harvest", $payload);
        $response->assertStatus(403);

        // Buat produk milik farmer 2 tapi coba convert harvest milik farmer 1
        $farmer2Product = ProcessedProduct::create([
            'owner_id' => $this->farmer2->id,
            'name'     => 'Produk Petani 2',
            'price'    => 10000,
            'stock'    => 0,
            'status'   => 'active',
        ]);

        $response2 = $this->postJson("/api/processed-products/{$farmer2Product->id}/convert-harvest", $payload);
        $response2->assertStatus(403);
    }

    /** @test */
    public function test_multi_tenancy_farmer_cannot_add_processing_cost_to_another_farmers_product(): void
    {
        Sanctum::actingAs($this->farmer2);

        $payload = [
            'cost_type'            => 'processing',
            'processed_product_id' => $this->processedProduct->id, // milik farmer1
            'category'             => 'packaging',
            'amount'               => 25000,
            'date'                 => '2026-03-05',
        ];

        $response = $this->postJson('/api/costs', $payload);
        $response->assertStatus(403);
    }
}
