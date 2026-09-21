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

/**
 * Phase 4 — Regression Test Expansion
 *
 * Covers: Positive, Negative, Boundary, Consistency tests for all core
 * business domains per BUSINESS_RULES.md and SIMHPSK_PKM_Next_Step_Execution_Plan.md §9.
 *
 * Constraint:
 *  - Tests are written against the CURRENT production implementation.
 *  - Assertions verified against controller source before writing.
 *  - No existing tests modified, no schema/API contract changes.
 */
class Phase4RegressionTest extends TestCase
{
    use RefreshDatabase;

    // =========================================================================
    // GROUP A — Season: Negative & Boundary (5 tests)
    // Validation rule ref: SeasonController — after:start_date, min:0,
    //                      in:active,completed,cancelled
    // =========================================================================

    /** @test */
    public function test_season_end_before_start_is_invalid(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Validation: end_date must be after:start_date
        $response = $this->postJson('/api/seasons', [
            'name'       => 'Musim Salah',
            'start_date' => '2026-06-01',
            'end_date'   => '2026-05-01', // before start → invalid
            'status'     => 'active',
            'target_kg'  => 1000,
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    /** @test */
    public function test_season_same_start_end_date_is_invalid(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Rule is after:start_date (strict), not after_or_equal — same day = invalid
        $response = $this->postJson('/api/seasons', [
            'name'       => 'Musim Satu Hari',
            'start_date' => '2026-06-01',
            'end_date'   => '2026-06-01',
            'status'     => 'active',
            'target_kg'  => 500,
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    /** @test */
    public function test_season_zero_target_kg_is_accepted(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // target_kg rule: min:0 → 0 is the boundary minimum and must be accepted
        $response = $this->postJson('/api/seasons', [
            'name'       => 'Musim Percobaan',
            'start_date' => '2026-09-01',
            'end_date'   => '2026-12-01',
            'status'     => 'active',
            'target_kg'  => 0,
        ]);

        $response->assertStatus(201)->assertJson(['success' => true]);
    }

    /** @test */
    public function test_season_negative_target_kg_is_invalid(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // target_kg < 0 violates min:0
        $response = $this->postJson('/api/seasons', [
            'name'       => 'Musim Negatif',
            'start_date' => '2026-09-01',
            'end_date'   => '2026-12-01',
            'status'     => 'active',
            'target_kg'  => -100,
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    /** @test */
    public function test_season_invalid_status_is_rejected(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Allowed values: active, completed, cancelled. 'pending' is not in enum.
        $response = $this->postJson('/api/seasons', [
            'name'       => 'Musim Status Aneh',
            'start_date' => '2026-09-01',
            'end_date'   => '2026-12-01',
            'status'     => 'pending',
            'target_kg'  => 1000,
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    // =========================================================================
    // GROUP B — Harvest: Negative & Boundary (5 tests)
    // Validation rule ref: HarvestController / HarvestService
    // =========================================================================

    /** @test */
    public function test_harvest_zero_weight_is_invalid(): void
    {
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // weight_kg = 0 must be rejected (min:0.01 per HarvestController)
        $response = $this->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'harvest_date' => now()->toDateString(),
            'weight_kg'    => 0,
        ]);

        // HarvestController uses $request->validate() without try-catch,
        // so Laravel formats the 422 without a 'success' field.
        $response->assertStatus(422);
        $this->assertArrayHasKey('errors', $response->json());
    }

    /** @test */
    public function test_harvest_minimum_weight_is_accepted(): void
    {
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // weight_kg = 0.01 — boundary minimum — must be accepted
        // Stock must increase by exactly 0.01
        $response = $this->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'harvest_date' => now()->toDateString(),
            'weight_kg'    => 0.01,
        ]);

        $response->assertStatus(201)->assertJson(['success' => true]);
        $this->assertEquals(0.01, StockTransaction::getCurrentBalance($user->id));
    }

    /** @test */
    public function test_harvest_negative_weight_is_invalid(): void
    {
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'harvest_date' => now()->toDateString(),
            'weight_kg'    => -10,
        ]);

        // HarvestController uses $request->validate() without try-catch.
        $response->assertStatus(422);
        $this->assertArrayHasKey('errors', $response->json());
    }

    /** @test */
    public function test_harvest_update_to_other_users_season_is_forbidden(): void
    {
        $userA   = User::factory()->create();
        $userB   = User::factory()->create();
        $seasonA = Season::factory()->create(['user_id' => $userA->id]);
        $seasonB = Season::factory()->create(['user_id' => $userB->id]);

        // Create harvest directly to avoid stock setup complexity
        $harvest = Harvest::create([
            'user_id'   => $userA->id,
            'season_id' => $seasonA->id,
            'date'      => now()->toDateString(),
            'weight_kg' => 50.0,
            'status'    => 'recorded',
        ]);
        StockTransaction::addTransaction('in', 50.0, 'Seed', 'harvest_' . $harvest->id, $userA->id);

        Sanctum::actingAs($userA);

        // Attempt to reassign harvest to User B's season → 403
        $response = $this->putJson('/api/harvests/' . $harvest->id, [
            'season_id' => $seasonB->id,
            'weight_kg' => 50.0,
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function test_harvest_delete_does_not_make_stock_negative(): void
    {
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // Create 100 kg harvest → stock = 100
        $harvestRes = $this->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'harvest_date' => now()->toDateString(),
            'weight_kg'    => 100.0,
        ]);
        $harvestRes->assertStatus(201);
        $harvestId = $harvestRes->json('data.id');

        // Drain all stock (simulate downstream sales consuming the stock)
        StockTransaction::addTransaction('out', 100.0, 'Manual drain for test', 'test', $user->id);
        $this->assertEquals(0.0, StockTransaction::getCurrentBalance($user->id));

        // Delete harvest → rollback must not produce negative balance
        $deleteRes = $this->deleteJson('/api/harvests/' . $harvestId);
        $deleteRes->assertStatus(200);

        $this->assertGreaterThanOrEqual(
            0.0,
            StockTransaction::getCurrentBalance($user->id),
            'Stock balance must never go below 0 after harvest deletion.'
        );
    }

    // =========================================================================
    // GROUP C — Stock: Exact-match Boundary (2 tests)
    // Per BUSINESS_RULES.md: stock guard uses >= (exact match is allowed)
    // =========================================================================

    /** @test */
    public function test_sale_exactly_equal_to_stock_is_accepted(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        Sanctum::actingAs($user);

        StockTransaction::addTransaction('in', 75.50, 'Seed', 'seed', $user->id);
        $this->assertEquals(75.50, StockTransaction::getCurrentBalance($user->id));

        // Sell exactly 75.50 kg — must succeed (balance >= weight_kg is satisfied)
        $response = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli Exact',
            'weight_kg'    => 75.50,
            'price_per_kg' => 10000,
            'date'         => now()->toDateString(),
        ]);

        $response->assertStatus(201)->assertJson(['success' => true]);
        $this->assertEquals(0.0, StockTransaction::getCurrentBalance($user->id));
    }

    /** @test */
    public function test_sale_one_cent_over_stock_is_rejected(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        Sanctum::actingAs($user);

        StockTransaction::addTransaction('in', 50.00, 'Seed', 'seed', $user->id);

        // Sell 50.01 — exceeds balance by 0.01 → must be 422
        $response = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli Over',
            'weight_kg'    => 50.01,
            'price_per_kg' => 10000,
            'date'         => now()->toDateString(),
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);

        // Stock must remain unchanged
        $this->assertEquals(50.00, StockTransaction::getCurrentBalance($user->id));
    }

    // =========================================================================
    // GROUP D — Sale: Negative & Integrity (7 tests)
    // Validation rule ref: SaleController / SaleService
    // =========================================================================

    /** @test */
    public function test_sale_zero_weight_is_invalid(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        StockTransaction::addTransaction('in', 100.0, 'Seed', 'seed', $user->id);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli Test',
            'weight_kg'    => 0,
            'price_per_kg' => 5000,
            'date'         => now()->toDateString(),
        ]);

        // SaleController uses $request->validate() without try-catch.
        $response->assertStatus(422);
        $this->assertArrayHasKey('errors', $response->json());
    }

    /** @test */
    public function test_sale_negative_weight_is_invalid(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        StockTransaction::addTransaction('in', 100.0, 'Seed', 'seed', $user->id);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli Test',
            'weight_kg'    => -10,
            'price_per_kg' => 5000,
            'date'         => now()->toDateString(),
        ]);

        $response->assertStatus(422);
        $this->assertArrayHasKey('errors', $response->json());
    }

    /** @test */
    public function test_sale_zero_price_is_invalid(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        StockTransaction::addTransaction('in', 100.0, 'Seed', 'seed', $user->id);
        Sanctum::actingAs($user);

        // price_per_kg = 0 must fail
        $response = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli Test',
            'weight_kg'    => 10,
            'price_per_kg' => 0,
            'date'         => now()->toDateString(),
        ]);

        $response->assertStatus(422);
        $this->assertArrayHasKey('errors', $response->json());
    }

    /** @test */
    public function test_sale_missing_buyer_name_is_invalid(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        StockTransaction::addTransaction('in', 100.0, 'Seed', 'seed', $user->id);
        Sanctum::actingAs($user);

        // buyer_name is required
        $response = $this->postJson('/api/sales', [
            'weight_kg'    => 10,
            'price_per_kg' => 5000,
            'date'         => now()->toDateString(),
        ]);

        $response->assertStatus(422);
        $this->assertArrayHasKey('errors', $response->json());
    }

    /** @test */
    public function test_sale_update_by_other_user_is_forbidden(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $sale = Sale::create([
            'user_id'        => $userA->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli A',
            'weight_kg'      => 50.0,
            'price_per_kg'   => 5000,
            'total'          => 250000,
            'payment_status' => 'paid',
        ]);

        Sanctum::actingAs($userB);
        $response = $this->putJson('/api/sales/' . $sale->id, [
            'buyer_name'   => 'Hacked',
            'weight_kg'    => 50.0,
            'price_per_kg' => 1,
            'date'         => now()->toDateString(),
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function test_sale_delete_by_other_user_is_forbidden(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $sale = Sale::create([
            'user_id'        => $userA->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli A',
            'weight_kg'      => 30.0,
            'price_per_kg'   => 5000,
            'total'          => 150000,
            'payment_status' => 'paid',
        ]);

        Sanctum::actingAs($userB);
        $response = $this->deleteJson('/api/sales/' . $sale->id);
        $response->assertStatus(403);
    }

    /** @test */
    public function test_sale_total_is_calculated_server_side(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        StockTransaction::addTransaction('in', 200.0, 'Seed', 'seed', $user->id);
        Sanctum::actingAs($user);

        // Do NOT send a 'total' field — backend calculates weight × price
        $response = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli Kalkulasi',
            'weight_kg'    => 10.0,
            'price_per_kg' => 15000,
            'date'         => now()->toDateString(),
        ]);

        $response->assertStatus(201);
        $saleId     = $response->json('data.id');
        $storedSale = Sale::find($saleId);

        $this->assertEquals(
            150000.0,
            (float) $storedSale->total,
            'Sale total must be calculated server-side as weight_kg × price_per_kg.'
        );
    }

    // =========================================================================
    // GROUP E — Cost: Negative, Boundary & Consistency (4 tests)
    // BUSINESS_RULES.md Invariant 2: Total Cost = SUM(category breakdown)
    // =========================================================================

    /** @test */
    public function test_cost_zero_amount_is_invalid(): void
    {
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // amount = 0 must fail (CostController: min:0.01 or similar)
        $response = $this->postJson('/api/costs', [
            'date'      => now()->toDateString(),
            'season_id' => $season->id,
            'category'  => 'seed',
            'amount'    => 0,
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    /** @test */
    public function test_cost_minimum_amount_is_accepted(): void
    {
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // amount = 0.01 — boundary minimum — must be accepted
        $response = $this->postJson('/api/costs', [
            'date'      => now()->toDateString(),
            'season_id' => $season->id,
            'category'  => 'pesticide',
            'amount'    => 0.01,
        ]);

        $response->assertStatus(201)->assertJson(['success' => true]);
    }

    /** @test */
    public function test_cost_breakdown_sum_equals_total(): void
    {
        // BUSINESS_RULES.md Invariant 2: total_cost = SUM(breakdown per category)
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        $costs = [
            ['category' => 'seed',       'amount' => 200000],
            ['category' => 'fertilizer', 'amount' => 150000],
            ['category' => 'pesticide',  'amount' =>  75000],
            ['category' => 'other',      'amount' => 100000],
        ];
        $expectedTotal = 525000;

        foreach ($costs as $cost) {
            $this->postJson('/api/costs', array_merge($cost, [
                'date'      => now()->toDateString(),
                'season_id' => $season->id,
            ]))->assertStatus(201);
        }

        $response = $this->getJson('/api/costs');
        $response->assertStatus(200);

        $total        = (float) $response->json('data.total_cost');
        $breakdown    = $response->json('data.cost_by_category');
        $breakdownSum = (float) collect($breakdown)->sum('total');

        $this->assertEquals($expectedTotal, $total,
            'Invariant 2: total_cost must equal sum of all cost records.'
        );
        $this->assertEquals($expectedTotal, $breakdownSum,
            'Invariant 2: sum of cost_by_category totals must equal total_cost.'
        );
    }

    /** @test */
    public function test_cost_update_category_shifts_breakdown(): void
    {
        // Consistency: after category update, old bucket → 0, new bucket increases
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // Create seed cost of 300,000
        $costRes = $this->postJson('/api/costs', [
            'date'      => now()->toDateString(),
            'season_id' => $season->id,
            'category'  => 'seed',
            'amount'    => 300000,
        ]);
        $costRes->assertStatus(201);
        $costId = $costRes->json('data.id');

        // Update category to fertilizer
        $this->putJson('/api/costs/' . $costId, [
            'date'     => now()->toDateString(),
            'category' => 'fertilizer',
            'amount'   => 300000,
        ])->assertStatus(200);

        // Verify DB
        $this->assertDatabaseHas('production_costs', [
            'id'       => $costId,
            'category' => 'fertilizer',
        ]);

        // Verify breakdown: fertilizer = 300,000, seed = 0
        $indexRes  = $this->getJson('/api/costs');
        $breakdown = collect($indexRes->json('data.cost_by_category'));

        $seedTotal       = (float) ($breakdown->firstWhere('category', 'seed')['total']       ?? 0);
        $fertilizerTotal = (float) ($breakdown->firstWhere('category', 'fertilizer')['total'] ?? 0);

        $this->assertEquals(0,      $seedTotal,       'seed total must be 0 after category change to fertilizer.');
        $this->assertEquals(300000, $fertilizerTotal, 'fertilizer total must reflect the moved 300,000 amount.');
    }

    // =========================================================================
    // GROUP F — Report: Consistency & Boundary (4 tests)
    // BUSINESS_RULES.md §7.1: Profit = Revenue − Cost
    // =========================================================================

    /** @test */
    public function test_report_profit_loss_formula_accuracy(): void
    {
        // Consistency: Profit/Loss = Revenue - Cost (mathematically proven)
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // Revenue: 500,000 + 300,000 = 800,000
        Sale::create(['user_id' => $user->id, 'season_id' => $season->id, 'date' => now()->toDateString(), 'buyer_name' => 'A', 'weight_kg' => 10, 'price_per_kg' => 50000, 'total' => 500000, 'payment_status' => 'paid']);
        Sale::create(['user_id' => $user->id, 'season_id' => $season->id, 'date' => now()->toDateString(), 'buyer_name' => 'B', 'weight_kg' =>  6, 'price_per_kg' => 50000, 'total' => 300000, 'payment_status' => 'paid']);

        // Cost: 200,000 + 150,000 = 350,000
        ProductionCost::create(['user_id' => $user->id, 'season_id' => $season->id, 'date' => now()->toDateString(), 'category' => 'seed',       'amount' => 200000]);
        ProductionCost::create(['user_id' => $user->id, 'season_id' => $season->id, 'date' => now()->toDateString(), 'category' => 'fertilizer', 'amount' => 150000]);

        // Expected: profit = 800,000 - 350,000 = 450,000
        $response = $this->getJson('/api/reports/profit-loss?season_id=' . $season->id);

        $response->assertStatus(200)->assertJson([
            'success' => true,
            'data'    => [
                'total_revenue' => 800000,
                'total_cost'    => 350000,
                'profit'        => 450000,
            ],
        ]);
    }

    /** @test */
    public function test_report_profit_loss_filtered_by_season(): void
    {
        // Positive: season_id filter isolates data to that season only
        $user    = User::factory()->create();
        $seasonA = Season::factory()->create(['user_id' => $user->id]);
        $seasonB = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // Season A: 1,000,000 revenue
        Sale::create(['user_id' => $user->id, 'season_id' => $seasonA->id, 'date' => now()->toDateString(), 'buyer_name' => 'SA', 'weight_kg' => 20, 'price_per_kg' => 50000, 'total' => 1000000, 'payment_status' => 'paid']);
        // Season B: 500,000 revenue — must NOT appear in Season A report
        Sale::create(['user_id' => $user->id, 'season_id' => $seasonB->id, 'date' => now()->toDateString(), 'buyer_name' => 'SB', 'weight_kg' => 10, 'price_per_kg' => 50000, 'total' =>  500000, 'payment_status' => 'paid']);

        $response = $this->getJson('/api/reports/profit-loss?season_id=' . $seasonA->id);
        $response->assertStatus(200);

        $this->assertEquals(1000000, $response->json('data.total_revenue'),
            'Profit-loss filtered by season_id must only include that season\'s revenue.'
        );
    }

    /** @test */
    public function test_report_target_vs_actual_zero_harvest(): void
    {
        // Boundary: no harvest records → actual=0, percentage=0.0
        $user   = User::factory()->create();
        Season::factory()->create(['user_id' => $user->id, 'target_kg' => 2000]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/reports/target-vs-actual');
        $response->assertStatus(200);

        $seasonData = collect($response->json('data'))->first();
        $this->assertNotNull($seasonData);
        $this->assertEquals(0,   $seasonData['actual'],             'Zero harvest → actual = 0.');
        $this->assertEquals(0.0, (float) $seasonData['percentage'], 'Zero harvest → percentage = 0%.');
    }

    /** @test */
    public function test_report_target_vs_actual_overharvest(): void
    {
        // Boundary: harvest > target → percentage > 100%
        $user   = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id, 'target_kg' => 100]);

        // 150 kg harvested vs 100 kg target = 150%
        Harvest::create([
            'user_id'   => $user->id,
            'season_id' => $season->id,
            'date'      => now()->toDateString(),
            'weight_kg' => 150,
            'status'    => 'recorded',
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/reports/target-vs-actual');
        $response->assertStatus(200);

        $seasonData = collect($response->json('data'))->firstWhere('season_id', $season->id);
        $this->assertNotNull($seasonData);
        $this->assertEquals(150,   $seasonData['actual']);
        $this->assertEquals(150.0, (float) $seasonData['percentage'],
            'Over-harvest: 150 / 100 = 150%.'
        );
    }

    // =========================================================================
    // GROUP G — Auth: Negative (2 tests)
    // Confirmed against AuthController: register requires farm_name, name,
    // email, phone, password, password_confirmation. Login wrong creds = 401.
    // =========================================================================

    /** @test */
    public function test_register_missing_required_fields_fails(): void
    {
        // Sending empty payload — all 5 required fields must fail validation
        $response = $this->postJson('/api/auth/register', []);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    /** @test */
    public function test_login_wrong_password_fails(): void
    {
        User::factory()->create([
            'email'    => 'petani_salah@example.com',
            'password' => Hash::make('password_benar'),
            'status'   => 'active',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email'    => 'petani_salah@example.com',
            'password' => 'password_salah',
        ]);

        // AuthController::login returns 401 when credentials are wrong
        $response->assertStatus(401)->assertJson(['success' => false]);
    }
}
