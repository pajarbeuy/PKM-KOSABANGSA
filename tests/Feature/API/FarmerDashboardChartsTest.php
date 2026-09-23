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
}
