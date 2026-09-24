<?php

namespace Tests\Feature\API;

use App\Models\Harvest;
use App\Models\ProcessedProduct;
use App\Models\Sale;
use App\Models\Season;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FarmerDashboardChartsTest extends TestCase
{
    use RefreshDatabase;

    public function test_farmer_dashboard_returns_raw_material_and_processed_product_stats(): void
    {
        $farmer = User::factory()->create([
            'role'   => 'user',
            'status' => 'active',
        ]);

        $season = Season::factory()->create([
            'user_id'    => $farmer->id,
            'start_date' => now()->subMonths(2)->format('Y-m-d'),
            'end_date'   => now()->addMonths(2)->format('Y-m-d'),
            'status'     => 'active',
        ]);

        // 1. Raw Harvest (1000 kg)
        Harvest::create([
            'user_id'   => $farmer->id,
            'season_id' => $season->id,
            'weight_kg' => 1000,
            'date'      => now()->format('Y-m-d'),
            'status'    => 'approved',
        ]);

        // 2. Raw Material Sale (400 kg @ Rp 10.000 = Rp 4.000.000)
        Sale::create([
            'user_id'        => $farmer->id,
            'season_id'      => $season->id,
            'product_type'   => 'harvest',
            'date'           => now()->format('Y-m-d'),
            'buyer_name'     => 'Pengepul Pak Budi',
            'weight_kg'      => 400,
            'price_per_kg'   => 10000,
            'total'          => 4000000,
            'payment_status' => 'paid',
        ]);

        // 3. Processed Product
        $product = ProcessedProduct::create([
            'owner_id' => $farmer->id,
            'name'     => 'Keripik Kentang Original',
            'price'    => 25000,
            'stock'    => 50,
            'status'   => 'active',
        ]);

        // 4. Processed Product Sale (20 pcs @ Rp 25.000 = Rp 500.000)
        Sale::create([
            'user_id'              => $farmer->id,
            'season_id'            => $season->id,
            'product_type'         => 'processed',
            'processed_product_id' => $product->id,
            'date'                 => now()->format('Y-m-d'),
            'buyer_name'           => 'Toko Oleh-Oleh Asri',
            'weight_kg'            => 20, // pcs
            'price_per_kg'         => 25000,
            'total'                => 500000,
            'payment_status'       => 'paid',
        ]);

        $response = $this->actingAs($farmer)->getJson('/api/dashboard');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'totalStok',
                    'totalPanen',
                    'totalPenjualan',
                    'totalRawSalesKg',
                    'totalRawSalesRp',
                    'totalProcessedSalesPcs',
                    'totalProcessedSalesRp',
                    'monthlyStats' => [
                        '*' => [
                            'label',
                            'harvest_kg',
                            'harvest_sales_kg',
                            'harvest_sales_rp',
                            'processed_sales_pcs',
                            'processed_sales_rp',
                        ],
                    ],
                ],
            ]);

        $data = $response->json('data');
        $this->assertEquals(1000, $data['totalPanen']);
        $this->assertEquals(4500000, $data['totalPenjualan']); // 4jt + 500rb
        $this->assertEquals(400, $data['totalRawSalesKg']);
        $this->assertEquals(4000000, $data['totalRawSalesRp']);
        $this->assertEquals(20, $data['totalProcessedSalesPcs']);
        $this->assertEquals(500000, $data['totalProcessedSalesRp']);

        // Check latest month stats
        $latestMonth = end($data['monthlyStats']);
        $this->assertEquals(1000, $latestMonth['harvest_kg']);
        $this->assertEquals(400, $latestMonth['harvest_sales_kg']);
        $this->assertEquals(4000000, $latestMonth['harvest_sales_rp']);
        $this->assertEquals(20, $latestMonth['processed_sales_pcs']);
        $this->assertEquals(500000, $latestMonth['processed_sales_rp']);
    }

    public function test_farmer_dashboard_handles_month_subtraction_overflow_without_skipping_months(): void
    {
        $farmer = User::factory()->create([
            'role'   => 'user',
            'status' => 'active',
        ]);

        $season = Season::factory()->create([
            'user_id'    => $farmer->id,
            'start_date' => '2026-05-01',
            'end_date'   => '2026-11-30',
            'status'     => 'active',
        ]);

        // Harvest on 31 October 2026 (day 31)
        Harvest::create([
            'user_id'   => $farmer->id,
            'season_id' => $season->id,
            'weight_kg' => 500,
            'date'      => '2026-10-31',
            'status'    => 'approved',
        ]);

        // Processed Product
        $product = ProcessedProduct::create([
            'owner_id' => $farmer->id,
            'name'     => 'Keripik Pisang Sale',
            'price'    => 15000,
            'stock'    => 100,
            'unit'     => 'pcs',
            'status'   => 'active',
        ]);

        // Sale in September 2026 (30 days month)
        Sale::create([
            'user_id'              => $farmer->id,
            'season_id'            => $season->id,
            'product_type'         => 'processed',
            'processed_product_id' => $product->id,
            'date'                 => '2026-09-23',
            'buyer_name'           => 'Pembeli September',
            'weight_kg'            => 10,
            'price_per_kg'         => 15000,
            'total'                => 150000,
            'payment_status'       => 'paid',
        ]);

        $response = $this->actingAs($farmer)->getJson('/api/dashboard');
        $response->assertStatus(200);

        $monthlyStats = $response->json('data.monthlyStats');
        $labels = array_column($monthlyStats, 'label');

        // Verify September is present and has the processed sales
        $septemberIndex = array_search('Sep', $labels);
        $this->assertNotFalse($septemberIndex, 'Bulan Sep harus ada di monthlyStats');
        $this->assertEquals(10, $monthlyStats[$septemberIndex]['processed_sales_pcs']);
        $this->assertEquals(150000, $monthlyStats[$septemberIndex]['processed_sales_rp']);
    }

    public function test_processed_product_supports_custom_unit(): void
    {
        $farmer = User::factory()->create([
            'role'   => 'user',
            'status' => 'active',
        ]);

        // Create with kg unit
        $response = $this->actingAs($farmer)->postJson('/api/processed-products', [
            'name'        => 'Tepung Singkong Murni',
            'price'       => 20000,
            'stock'       => 50,
            'unit'        => 'kg',
            'description' => 'Tepung singkong organik dalam kemasan 1 kg',
            'status'      => 'active',
        ]);

        $response->assertStatus(201);
        $this->assertEquals('kg', $response->json('data.unit'));

        $productId = $response->json('data.id');

        // Update to pcs unit
        $updateResponse = $this->actingAs($farmer)->putJson("/api/processed-products/{$productId}", [
            'name'  => 'Tepung Singkong Kemasan',
            'price' => 22000,
            'stock' => 45,
            'unit'  => 'pcs',
        ]);

        $updateResponse->assertStatus(200);
        $this->assertEquals('pcs', $updateResponse->json('data.unit'));
    }
}
