<?php

namespace Tests\Feature\API;

use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\Season;
use App\Models\StockTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ComprehensiveApiTest extends TestCase
{
    use RefreshDatabase;

    // =========================================================================
    // 1. AUTHENTICATION API TESTS
    // =========================================================================

    /** @test */
    public function test_user_can_register(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'farm_name'             => 'Kebun Kentang Subur',
            'name'                  => 'Budi Santoso',
            'email'                 => 'budi@example.com',
            'phone'                 => '081234567890',
            'password'              => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'email'     => 'budi@example.com',
                    'name'      => 'Budi Santoso',
                    'farm_name' => 'Kebun Kentang Subur',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email'     => 'budi@example.com',
            'role'      => 'user',
            'status'    => 'active',
        ]);
    }

    /** @test */
    public function test_user_login_success_and_token_generation(): void
    {
        $user = User::factory()->create([
            'email'    => 'petani@example.com',
            'password' => Hash::make('rahasia123'),
            'status'   => 'active',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email'    => 'petani@example.com',
            'password' => 'rahasia123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'token_type' => 'Bearer',
                    'user'       => [
                        'id'    => $user->id,
                        'email' => 'petani@example.com',
                    ],
                ],
            ]);

        $this->assertNotEmpty($response->json('data.token'));
    }

    /** @test */
    public function test_inactive_user_cannot_login(): void
    {
        User::factory()->create([
            'email'    => 'inactive@example.com',
            'password' => Hash::make('rahasia123'),
            'status'   => 'inactive',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email'    => 'inactive@example.com',
            'password' => 'rahasia123',
        ]);

        $response->assertStatus(403)
            ->assertJson(['success' => false]);
    }

    /** @test */
    public function test_user_me_and_logout(): void
    {
        $user = User::factory()->create(['status' => 'active']);
        Sanctum::actingAs($user);

        // Get Profile
        $meRes = $this->getJson('/api/auth/me');
        $meRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'id'    => $user->id,
                    'email' => $user->email,
                ],
            ]);

        // Logout
        $logoutRes = $this->postJson('/api/auth/logout');
        $logoutRes->assertStatus(200)
            ->assertJson(['success' => true]);
    }

    // =========================================================================
    // 2. SEASON API & MULTI-TENANCY TESTS
    // =========================================================================

    /** @test */
    public function test_season_crud_lifecycle(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // 1. Create Season
        $createRes = $this->postJson('/api/seasons', [
            'name'       => 'Musim Kentang G1',
            'start_date' => '2026-01-01',
            'end_date'   => '2026-04-30',
            'status'     => 'active',
            'target_kg'  => 5000,
        ]);

        $createRes->assertStatus(201);
        $seasonId = $createRes->json('data.id');

        // 2. Show Season
        $showRes = $this->getJson("/api/seasons/{$seasonId}");
        $showRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => ['id' => $seasonId, 'name' => 'Musim Kentang G1'],
            ]);

        // 3. Update Season
        $updateRes = $this->putJson("/api/seasons/{$seasonId}", [
            'name'       => 'Musim Kentang G1 (Revisi)',
            'start_date' => '2026-01-01',
            'end_date'   => '2026-05-15',
            'status'     => 'completed',
            'target_kg'  => 5500,
        ]);
        $updateRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => ['name' => 'Musim Kentang G1 (Revisi)', 'status' => 'completed'],
            ]);

        // 4. Delete Season
        $deleteRes = $this->deleteJson("/api/seasons/{$seasonId}");
        $deleteRes->assertStatus(200);

        $this->assertSoftDeleted('seasons', ['id' => $seasonId]);
    }

    /** @test */
    public function test_season_multi_tenancy_isolation(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $seasonA = Season::factory()->create(['user_id' => $userA->id]);

        Sanctum::actingAs($userB);

        // User B cannot show User A's season
        $this->getJson("/api/seasons/{$seasonA->id}")->assertStatus(403);

        // User B cannot update User A's season
        $this->putJson("/api/seasons/{$seasonA->id}", [
            'name'       => 'Hacked',
            'start_date' => '2026-01-01',
            'end_date'   => '2026-02-01',
            'status'     => 'active',
            'target_kg'  => 100,
        ])->assertStatus(403);

        // User B cannot delete User A's season
        $this->deleteJson("/api/seasons/{$seasonA->id}")->assertStatus(403);
    }

    // =========================================================================
    // 3. HARVEST API & STOCK INTEGRATION TESTS
    // =========================================================================

    /** @test */
    public function test_harvest_creates_and_manages_inventory_stock(): void
    {
        $user = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        // 1. Record Harvest of 150.5 kg
        $harvestRes = $this->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'harvest_date' => '2026-03-10',
            'weight_kg'    => 150.5,
            'quantity'     => 150,
            'notes'        => 'Panen perdana varietas granola',
        ]);

        $harvestRes->assertStatus(201);
        $harvestId = $harvestRes->json('data.id');

        // Stock balance must automatically become 150.5 kg
        $this->assertEquals(150.5, StockTransaction::getCurrentBalance($user->id));

        // 2. Show Harvest
        $showRes = $this->getJson("/api/harvests/{$harvestId}");
        $showRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => ['id' => $harvestId, 'weight_kg' => 150.5],
            ]);

        // 3. Update Harvest weight to 200.0 kg (+49.5 kg difference)
        $updateRes = $this->putJson("/api/harvests/{$harvestId}", [
            'season_id'    => $season->id,
            'harvest_date' => '2026-03-10',
            'weight_kg'    => 200.0,
        ]);
        $updateRes->assertStatus(200);

        // Stock balance must now be 200.0 kg
        $this->assertEquals(200.0, StockTransaction::getCurrentBalance($user->id));

        // 4. Delete Harvest - stock must be rolled back to 0
        $deleteRes = $this->deleteJson("/api/harvests/{$harvestId}");
        $deleteRes->assertStatus(200);

        $this->assertEquals(0.0, StockTransaction::getCurrentBalance($user->id));
    }

    /** @test */
    public function test_cannot_attach_harvest_to_other_users_season(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();
        $seasonB = Season::factory()->create(['user_id' => $userB->id]);

        Sanctum::actingAs($userA);

        $response = $this->postJson('/api/harvests', [
            'season_id'    => $seasonB->id,
            'harvest_date' => '2026-03-10',
            'weight_kg'    => 50.0,
        ]);

        $response->assertStatus(403);
    }

    // =========================================================================
    // 4. SALE API & INVENTORY DEDUCTION TESTS
    // =========================================================================

    /** @test */
    public function test_sale_rejects_when_insufficient_stock_and_succeeds_when_available(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        $season = Season::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        // Current stock is 0. Attempting to sell 50 kg must fail with 422
        $failRes = $this->postJson('/api/sales', [
            'season_id'      => $season->id,
            'weight_kg'      => 50.0,
            'price_per_kg'   => 15000,
            'buyer_name'     => 'Pasar Induk',
            'payment_status' => 'paid',
        ]);
        $failRes->assertStatus(422)
            ->assertJson(['success' => false]);

        // Add 100 kg to stock via Harvest
        $this->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'harvest_date' => '2026-03-15',
            'weight_kg'    => 100.0,
        ])->assertStatus(201);

        $this->assertEquals(100.0, StockTransaction::getCurrentBalance($user->id));

        // Now sell 60 kg
        $saleRes = $this->postJson('/api/sales', [
            'season_id'      => $season->id,
            'weight_kg'      => 60.0,
            'price_per_kg'   => 15000,
            'buyer_name'     => 'Pasar Induk',
            'payment_status' => 'paid',
        ]);
        $saleRes->assertStatus(201);
        $saleId = $saleRes->json('data.id');

        // Remaining stock must be exactly 40.0 kg
        $this->assertEquals(40.0, StockTransaction::getCurrentBalance($user->id));

        // Delete the sale -> 60 kg must be returned to stock
        $this->deleteJson("/api/sales/{$saleId}")->assertStatus(200);
        $this->assertEquals(100.0, StockTransaction::getCurrentBalance($user->id));
    }

    /** @test */
    public function test_sale_season_ownership_isolation(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();
        $seasonB = Season::factory()->create(['user_id' => $userB->id]);

        Sanctum::actingAs($userA);

        // Add stock to User A
        StockTransaction::addTransaction('in', 100.0, 'Initial Stock', null, $userA->id);

        // User A tries to create a sale attached to User B's season
        $response = $this->postJson('/api/sales', [
            'season_id'    => $seasonB->id,
            'weight_kg'    => 20.0,
            'price_per_kg' => 12000,
            'buyer_name'   => 'Pembeli A',
        ]);

        $response->assertStatus(403);
    }

    // =========================================================================
    // 5. PRODUCTION COST API TESTS
    // =========================================================================

    /** @test */
    public function test_cost_crud_and_season_isolation(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();
        $seasonA = Season::factory()->create(['user_id' => $userA->id]);
        $seasonB = Season::factory()->create(['user_id' => $userB->id]);

        Sanctum::actingAs($userA);

        // 1. Reject attaching to other user's season
        $badRes = $this->postJson('/api/costs', [
            'date'      => '2026-03-01',
            'season_id' => $seasonB->id,
            'category'  => 'fertilizer',
            'amount'    => 250000,
        ]);
        $badRes->assertStatus(403);

        // 2. Create Cost successfully
        $costRes = $this->postJson('/api/costs', [
            'date'      => '2026-03-01',
            'season_id' => $seasonA->id,
            'category'  => 'fertilizer',
            'amount'    => 250000,
            'notes'     => 'Pupuk NPK 50kg',
        ]);
        $costRes->assertStatus(201);
        $costId = $costRes->json('data.id');

        // 3. Show Cost
        $showRes = $this->getJson("/api/costs/{$costId}");
        $showRes->assertStatus(200)
            ->assertJson(['data' => ['id' => $costId, 'amount' => 250000]]);

        // 4. Delete Cost
        $this->deleteJson("/api/costs/{$costId}")->assertStatus(200);
        $this->assertSoftDeleted('production_costs', ['id' => $costId]);
    }

    // =========================================================================
    // 6. DASHBOARD & FINANCIAL REPORT API TESTS
    // =========================================================================

    /** @test */
    public function test_dashboard_and_profit_loss_calculations(): void
    {
        $user = User::factory()->create();
        $season = Season::factory()->create([
            'user_id'   => $user->id,
            'status'    => 'active',
            'target_kg' => 2000,
        ]);

        Sanctum::actingAs($user);

        // Harvest: 1000 kg
        Harvest::create([
            'user_id'   => $user->id,
            'season_id' => $season->id,
            'date'      => now()->toDateString(),
            'weight_kg' => 1000,
            'status'    => 'verified',
        ]);
        StockTransaction::addTransaction('in', 1000, 'Panen', null, $user->id);

        // Sale: 600 kg @ Rp 15.000 = Rp 9.000.000
        Sale::create([
            'user_id'        => $user->id,
            'season_id'      => $season->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Grosir Sayur',
            'weight_kg'      => 600,
            'price_per_kg'   => 15000,
            'total'          => 9000000,
            'payment_status' => 'paid',
        ]);
        StockTransaction::addTransaction('out', 600, 'Jual', null, $user->id);

        // Production Cost: Rp 3.000.000
        ProductionCost::create([
            'user_id'   => $user->id,
            'season_id' => $season->id,
            'date'      => now()->toDateString(),
            'category'  => 'fertilizer',
            'amount'    => 3000000,
        ]);

        // Check Dashboard
        $dashRes = $this->getJson('/api/dashboard');
        $dashRes->assertStatus(200);

        $dashData = $dashRes->json('data');
        $this->assertEquals(400.0, $dashData['totalStok']); // 1000 - 600
        $this->assertEquals(9000000, $dashData['totalPenjualan']);
        $this->assertEquals(3000000, $dashData['totalBiaya']);
        $this->assertEquals(6000000, $dashData['profitLoss']['profit']); // 9jt - 3jt

        // Check Profit & Loss Report
        $reportRes = $this->getJson('/api/reports/profit-loss?season_id=' . $season->id);
        $reportRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'total_harvest_kg' => 1000,
                    'total_revenue'    => 9000000,
                    'total_cost'       => 3000000,
                    'profit'           => 6000000,
                ],
            ]);
    }
}
