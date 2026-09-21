<?php

namespace Tests\Feature\API;

use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SuperAdminProfitLossAggregateTest extends TestCase
{
    use RefreshDatabase;

    protected User $superAdmin;
    protected User $farmer1;
    protected User $farmer2;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superAdmin = User::factory()->create([
            'role' => 'super_admin',
            'name' => 'Super Administrator',
        ]);

        $this->farmer1 = User::factory()->create([
            'role'      => 'user',
            'name'      => 'Petani Satu',
            'farm_name' => 'Kebun Satu',
        ]);

        $this->farmer2 = User::factory()->create([
            'role'      => 'user',
            'name'      => 'Petani Dua',
            'farm_name' => 'Kebun Dua',
        ]);
    }

    /** @test */
    public function test_super_admin_can_get_farmer_profit_loss_aggregate_with_exact_formula(): void
    {
        // Farmer 1: Revenue = 1,000,000, Cost = 300,000 -> P/L = +700,000
        Sale::create([
            'user_id'        => $this->farmer1->id,
            'date'           => '2026-09-10',
            'buyer_name'     => 'Pembeli F1',
            'weight_kg'      => 100,
            'price_per_kg'   => 10000,
            'total'          => 1000000,
            'payment_status' => 'paid',
        ]);

        ProductionCost::create([
            'user_id'     => $this->farmer1->id,
            'category'    => 'pupuk',
            'amount'      => 300000,
            'date'        => '2026-09-01',
            'description' => 'Pupuk organik',
        ]);

        // Farmer 2: Revenue = 500,000, Cost = 600,000 -> P/L = -100,000
        Sale::create([
            'user_id'        => $this->farmer2->id,
            'date'           => '2026-09-12',
            'buyer_name'     => 'Pembeli F2',
            'weight_kg'      => 50,
            'price_per_kg'   => 10000,
            'total'          => 500000,
            'payment_status' => 'paid',
        ]);

        ProductionCost::create([
            'user_id'     => $this->farmer2->id,
            'category'    => 'benih',
            'amount'      => 600000,
            'date'        => '2026-09-02',
            'description' => 'Benih unggul',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->getJson('/api/super-admin/reports/farmer-profit-loss-aggregate');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'total_farmer_revenue'     => 1500000,
                    'total_farmer_cost'        => 900000,
                    'total_farmer_profit_loss' => 600000,
                    'farmer_count'             => 2,
                ],
            ]);

        $farmers = $response->json('data.farmers');
        $this->assertCount(2, $farmers);
    }

    /** @test */
    public function test_farmer_cannot_access_aggregate_profit_loss(): void
    {
        Sanctum::actingAs($this->farmer1);

        $response = $this->getJson('/api/super-admin/reports/farmer-profit-loss-aggregate');

        $response->assertStatus(403);
    }

    /** @test */
    public function test_unauthenticated_cannot_access_aggregate_profit_loss(): void
    {
        $response = $this->getJson('/api/super-admin/reports/farmer-profit-loss-aggregate');

        $response->assertStatus(401);
    }
}
