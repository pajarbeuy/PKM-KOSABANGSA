<?php

namespace Tests\Feature\API;

use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Season;
use App\Models\User;
use App\Services\DashboardService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BugFixRegressionTest extends TestCase
{
    use RefreshDatabase;

    // =========================================================================
    // BUG-001 REGRESSION TESTS: Cost Categories
    // =========================================================================

    /** @test */
    public function test_cost_creation_accepts_all_official_categories(): void
    {
        $user = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        $officialCategories = ['seed', 'fertilizer', 'pesticide', 'other'];

        foreach ($officialCategories as $cat) {
            $response = $this->postJson('/api/costs', [
                'season_id' => $season->id,
                'category'  => $cat,
                'amount'    => 100000,
                'date'      => now()->toDateString(),
                'notes'     => "Biaya {$cat}",
            ]);

            $response->assertStatus(201)
                ->assertJson([
                    'success' => true,
                    'data'    => [
                        'category' => $cat,
                        'amount'   => 100000,
                    ],
                ]);

            $this->assertDatabaseHas('production_costs', [
                'user_id'   => $user->id,
                'season_id' => $season->id,
                'category'  => $cat,
            ]);
        }
    }

    /** @test */
    public function test_cost_creation_rejects_legacy_chart_categories(): void
    {
        $user = User::factory()->create();
        $season = Season::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // 'equipment' was only a chart artifact, never valid in backend/DB
        $resEquip = $this->postJson('/api/costs', [
            'season_id' => $season->id,
            'category'  => 'equipment',
            'amount'    => 100000,
            'date'      => now()->toDateString(),
        ]);
        $resEquip->assertStatus(422);

        // 'transport' was also only a chart artifact
        $resTrans = $this->postJson('/api/costs', [
            'season_id' => $season->id,
            'category'  => 'transport',
            'amount'    => 100000,
            'date'      => now()->toDateString(),
        ]);
        $resTrans->assertStatus(422);
    }

    // =========================================================================
    // BUG-002 REGRESSION TESTS: Season Status Derivation & Cancelled Semantics
    // =========================================================================

    /** @test */
    public function test_season_compute_status_unit_logic(): void
    {
        $today = Carbon::today();

        // 1. Cancelled season: always returns 'cancelled' regardless of dates
        $cancelledPast = new Season([
            'start_date' => $today->copy()->subDays(30),
            'end_date'   => $today->copy()->subDays(10),
            'status'     => 'cancelled',
        ]);
        $this->assertEquals('cancelled', $cancelledPast->computeStatus());

        $cancelledCurrent = new Season([
            'start_date' => $today->copy()->subDays(10),
            'end_date'   => $today->copy()->addDays(10),
            'status'     => 'cancelled',
        ]);
        $this->assertEquals('cancelled', $cancelledCurrent->computeStatus());

        $cancelledFuture = new Season([
            'start_date' => $today->copy()->addDays(10),
            'end_date'   => $today->copy()->addDays(30),
            'status'     => 'cancelled',
        ]);
        $this->assertEquals('cancelled', $cancelledFuture->computeStatus());

        // 2. Future season: today < start_date
        $futureSeason = new Season([
            'start_date' => $today->copy()->addDays(5),
            'end_date'   => $today->copy()->addDays(35),
            'status'     => 'active',
        ]);
        $this->assertEquals('belum_dimulai', $futureSeason->computeStatus());

        // 3. Current season: start_date <= today <= end_date
        $currentSeason = new Season([
            'start_date' => $today->copy()->subDays(10),
            'end_date'   => $today->copy()->addDays(20),
            'status'     => 'active',
        ]);
        $this->assertEquals('active', $currentSeason->computeStatus());

        // 4. Boundary test: start_date == today
        $boundaryStart = new Season([
            'start_date' => $today->copy(),
            'end_date'   => $today->copy()->addDays(30),
            'status'     => 'active',
        ]);
        $this->assertEquals('active', $boundaryStart->computeStatus());

        // 5. Boundary test: end_date == today (last day is still active)
        $boundaryEnd = new Season([
            'start_date' => $today->copy()->subDays(30),
            'end_date'   => $today->copy(),
            'status'     => 'active',
        ]);
        $this->assertEquals('active', $boundaryEnd->computeStatus());

        // 6. Past season: today > end_date (even if DB status says 'active')
        $pastSeason = new Season([
            'start_date' => $today->copy()->subDays(60),
            'end_date'   => $today->copy()->subDays(5),
            'status'     => 'active', // stale DB status
        ]);
        $this->assertEquals('completed', $pastSeason->computeStatus());
    }

    /** @test */
    public function test_season_api_includes_computed_status(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $today = Carbon::today();

        // Past season
        $pastSeason = Season::factory()->create([
            'user_id'    => $user->id,
            'start_date' => $today->copy()->subDays(60)->toDateString(),
            'end_date'   => $today->copy()->subDays(10)->toDateString(),
            'status'     => 'active', // Stale
        ]);

        $showRes = $this->getJson("/api/seasons/{$pastSeason->id}");
        $showRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'id'              => $pastSeason->id,
                    'status'          => 'active',      // raw DB status preserved
                    'computed_status' => 'completed',   // correctly derived
                ],
            ]);

        $listRes = $this->getJson('/api/seasons');
        $listRes->assertStatus(200);
        $items = $listRes->json('data');
        $firstItem = collect($items)->firstWhere('id', $pastSeason->id);
        $this->assertNotNull($firstItem);
        $this->assertEquals('completed', $firstItem['computed_status']);
    }

    /** @test */
    public function test_dashboard_active_season_ignores_stale_and_cancelled_seasons(): void
    {
        $user = User::factory()->create();
        $today = Carbon::today();

        // Season 1: Stale past season (DB status = active, but ended 30 days ago)
        Season::factory()->create([
            'user_id'    => $user->id,
            'name'       => 'Stale Season',
            'start_date' => $today->copy()->subDays(90)->toDateString(),
            'end_date'   => $today->copy()->subDays(30)->toDateString(),
            'status'     => 'active',
            'target_kg'  => 1000,
        ]);

        // Season 2: Cancelled season covering today
        Season::factory()->create([
            'user_id'    => $user->id,
            'name'       => 'Cancelled Season',
            'start_date' => $today->copy()->subDays(10)->toDateString(),
            'end_date'   => $today->copy()->addDays(20)->toDateString(),
            'status'     => 'cancelled',
            'target_kg'  => 2000,
        ]);

        // Season 3: Legitimate active season covering today
        $validActive = Season::factory()->create([
            'user_id'    => $user->id,
            'name'       => 'Valid Active Season',
            'start_date' => $today->copy()->subDays(5)->toDateString(),
            'end_date'   => $today->copy()->addDays(25)->toDateString(),
            'status'     => 'active',
            'target_kg'  => 3500,
        ]);

        $dashboardService = app(DashboardService::class);
        $summary = $dashboardService->getSummary($user->id);

        // Target Panen must come from Season 3 (3500 kg), not Season 1 (1000) or Season 2 (2000)
        $this->assertEquals(3500.0, $summary['targetPanen']);
    }

    /** @test */
    public function test_harvest_index_active_season_ignores_stale_and_cancelled_seasons(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        $today = Carbon::today();

        // Stale past season with lower ID
        Season::factory()->create([
            'user_id'    => $user->id,
            'start_date' => $today->copy()->subDays(60)->toDateString(),
            'end_date'   => $today->copy()->subDays(10)->toDateString(),
            'status'     => 'active',
        ]);

        // Legitimate current season
        $validSeason = Season::factory()->create([
            'user_id'    => $user->id,
            'start_date' => $today->copy()->subDays(5)->toDateString(),
            'end_date'   => $today->copy()->addDays(25)->toDateString(),
            'status'     => 'active',
        ]);

        $res = $this->getJson('/api/harvests');
        $res->assertStatus(200);

        $activeSeason = $res->json('data.active_season');
        $this->assertNotNull($activeSeason);
        $this->assertEquals($validSeason->id, $activeSeason['id']);
    }

    // =========================================================================
    // BUG-003 REGRESSION TESTS: SaleService::updateSale() $oldWeight undefined
    // =========================================================================

    /** @test */
    public function test_update_sale_weight_decrease_returns_stock_to_warehouse(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        Sanctum::actingAs($user);

        // Seed stock: add 100 kg in
        \App\Models\StockTransaction::addTransaction('in', 100.0, 'Seed stock', 'seed', $user->id);
        $balanceBefore = \App\Models\StockTransaction::getCurrentBalance($user->id);
        $this->assertEquals(100.0, $balanceBefore);

        // Create a sale for 50 kg → stock becomes 50
        $saleResp = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli A',
            'weight_kg'    => 50.0,
            'price_per_kg' => 5000,
            'date'         => now()->toDateString(),
        ]);
        $saleResp->assertStatus(201);
        $saleId = $saleResp->json('data.id');
        $this->assertEquals(50.0, \App\Models\StockTransaction::getCurrentBalance($user->id));

        // Update the sale weight from 50 → 30 (weight decreased by 20)
        // Expected: 20 kg returned to stock → balance = 70
        $updateResp = $this->putJson("/api/sales/{$saleId}", [
            'buyer_name'   => 'Pembeli A',
            'weight_kg'    => 30.0,
            'price_per_kg' => 5000,
            'date'         => now()->toDateString(),
        ]);
        $updateResp->assertStatus(200);

        $balanceAfter = \App\Models\StockTransaction::getCurrentBalance($user->id);
        $this->assertEquals(70.0, $balanceAfter,
            'BUG-003: Updating sale weight downward must return the difference to stock.'
        );
    }

    /** @test */
    public function test_update_sale_weight_increase_deducts_additional_stock(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        Sanctum::actingAs($user);

        // Seed stock: add 200 kg
        \App\Models\StockTransaction::addTransaction('in', 200.0, 'Seed stock', 'seed', $user->id);

        // Create a sale for 50 kg → stock becomes 150
        $saleResp = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli B',
            'weight_kg'    => 50.0,
            'price_per_kg' => 5000,
            'date'         => now()->toDateString(),
        ]);
        $saleResp->assertStatus(201);
        $saleId = $saleResp->json('data.id');
        $this->assertEquals(150.0, \App\Models\StockTransaction::getCurrentBalance($user->id));

        // Update the sale weight from 50 → 80 (weight increased by 30)
        // Expected: 30 kg additionally deducted → balance = 120
        $updateResp = $this->putJson("/api/sales/{$saleId}", [
            'buyer_name'   => 'Pembeli B',
            'weight_kg'    => 80.0,
            'price_per_kg' => 5000,
            'date'         => now()->toDateString(),
        ]);
        $updateResp->assertStatus(200);

        $balanceAfter = \App\Models\StockTransaction::getCurrentBalance($user->id);
        $this->assertEquals(120.0, $balanceAfter,
            'BUG-003: Updating sale weight upward must deduct the additional amount from stock.'
        );
    }

    /** @test */
    public function test_update_sale_non_weight_fields_leaves_stock_unchanged(): void
    {
        $user = User::factory()->create(['role' => 'super_admin']);
        Sanctum::actingAs($user);

        \App\Models\StockTransaction::addTransaction('in', 100.0, 'Seed', 'seed', $user->id);

        $saleResp = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli C',
            'weight_kg'    => 40.0,
            'price_per_kg' => 5000,
            'date'         => now()->toDateString(),
        ]);
        $saleResp->assertStatus(201);
        $saleId       = $saleResp->json('data.id');
        $balanceAfterCreate = \App\Models\StockTransaction::getCurrentBalance($user->id); // 60

        // Update only the buyer name and price — no weight change
        $updateResp = $this->putJson("/api/sales/{$saleId}", [
            'buyer_name'   => 'Pembeli C Updated',
            'weight_kg'    => 40.0,
            'price_per_kg' => 6000,
            'date'         => now()->toDateString(),
        ]);
        $updateResp->assertStatus(200);

        $balanceAfterUpdate = \App\Models\StockTransaction::getCurrentBalance($user->id);
        $this->assertEquals($balanceAfterCreate, $balanceAfterUpdate,
            'BUG-003: Updating non-weight fields must not affect stock balance.'
        );
    }
}
