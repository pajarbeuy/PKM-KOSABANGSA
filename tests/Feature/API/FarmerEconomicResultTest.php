<?php

namespace Tests\Feature\API;

use App\Models\FarmerCommodity;
use App\Models\FarmerGroup;
use App\Models\Harvest;
use App\Models\MarketPrice;
use App\Models\ProductionCost;
use App\Models\Season;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * FarmerEconomicResultTest — Phase 6
 *
 * Formula yang diuji:
 *   Gross Harvest Value  = weight_kg × market_price_snapshot
 *   Allocated Cost       = (harvest.weight_kg / season_total_weight_kg) × season_total_cost
 *   Profit / Loss        = Gross Harvest Value − Allocated Cost
 */
class FarmerEconomicResultTest extends TestCase
{
    use RefreshDatabase;

    private User $farmer;
    private string $token;
    private FarmerGroup $group;
    private FarmerCommodity $commodity;
    private Season $season;

    protected function setUp(): void
    {
        parent::setUp();

        $this->group = FarmerGroup::create([
            'name'      => 'Poktan Test',
            'code'      => 'PKT-TEST',
            'village'   => 'Sumber Brantas',
            'district'  => 'Bumiaji',
            'regency'   => 'Kota Batu',
            'province'  => 'Jawa Timur',
            'is_active' => true,
        ]);

        $this->farmer = User::create([
            'name'            => 'Petani Uji',
            'email'           => 'petani@test.com',
            'password'        => bcrypt('password123'),
            'role'            => 'user',
            'status'          => 'active',
            'farmer_group_id' => $this->group->id,
        ]);

        $this->token = $this->farmer->createToken('test')->plainTextToken;

        $this->commodity = FarmerCommodity::create([
            'user_id' => $this->farmer->id,
            'name'    => 'Jamur Tiram',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        $this->season = Season::create([
            'user_id'      => $this->farmer->id,
            'name'         => 'Musim Panen 2026',
            'start_date'   => '2026-01-01',
            'end_date'     => '2026-12-31',
            'status'       => 'active',
            'target_kg'    => 1000,
            'commodity_id' => $this->commodity->id,
        ]);
    }

    // ─── Helper ───────────────────────────────────────────────────────────────

    /**
     * assertJsonPath tidak bisa membedakan 200 vs 200.0 di PHP JSON.
     * Helper ini melakukan cast numerik sebelum perbandingan.
     */
    private function assertNumericJsonPath(
        \Illuminate\Testing\TestResponse $response,
        string $path,
        float|int|null $expected
    ): void {
        $data  = $response->json($path);
        if ($expected === null) {
            $this->assertNull($data, "Failed asserting that [{$path}] is null.");
            return;
        }
        $this->assertEquals(
            (float) $expected,
            (float) $data,
            "Failed asserting that [{$path}] equals {$expected}. Got: {$data}"
        );
    }

    // ─── Test 1: Harvest Economic Result — with market price snapshot ─────────

    public function test_harvest_economic_result_with_price_snapshot(): void
    {
        // Harga acuan: Rp15.000/kg efektif 1 Jan 2026
        $marketPrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 15000,
            'unit'           => 'kg',
            'effective_date' => '2026-01-01',
            'source'         => 'manual',
            'created_by'     => $this->farmer->id,
        ]);

        // Catat panen 200 kg pada 15 Jan 2026 → snapshot Rp15.000
        $harvest = Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $this->season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $marketPrice->id,
            'market_price_snapshot'       => 15000,
            'market_price_effective_date' => '2026-01-01',
            'date'                        => '2026-01-15',
            'weight_kg'                   => 200,
            'quantity'                    => 2,
            'unit'                        => 'kuintal',
            'status'                      => 'recorded',
        ]);

        // Biaya musim: Rp2.000.000
        ProductionCost::create([
            'user_id'   => $this->farmer->id,
            'season_id' => $this->season->id,
            'date'      => '2026-01-10',
            'category'  => 'seed',
            'amount'    => 2000000,
        ]);

        $response = $this->withToken($this->token)
            ->getJson("/api/harvests/{$harvest->id}/economic-result");

        $response->assertOk()
            ->assertJsonPath('data.harvest_id', $harvest->id)
            ->assertJsonPath('data.unit', 'kuintal');

        // Numeric comparisons (float-safe)
        $this->assertNumericJsonPath($response, 'data.weight_kg', 200);
        $this->assertNumericJsonPath($response, 'data.market_price_snapshot', 15000);
        // Gross = 200 × 15000 = 3.000.000
        $this->assertNumericJsonPath($response, 'data.gross_harvest_value', 3000000);
        // Allocated = (200/200) × 2.000.000 = 2.000.000 (satu-satunya panen di musim ini)
        $this->assertNumericJsonPath($response, 'data.allocated_production_cost', 2000000);
        // Profit = 3.000.000 - 2.000.000 = 1.000.000
        $this->assertNumericJsonPath($response, 'data.profit_loss', 1000000);
        $this->assertEquals('profit', $response->json('data.profit_loss_status'));
    }

    // ─── Test 2: Proportional cost allocation across multiple harvests ─────────

    public function test_proportional_cost_allocation_across_multiple_harvests(): void
    {
        $marketPrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 10000,
            'unit'           => 'kg',
            'effective_date' => '2026-01-01',
            'source'         => 'manual',
            'created_by'     => $this->farmer->id,
        ]);

        // Panen A: 200 kg
        $harvestA = Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $this->season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $marketPrice->id,
            'market_price_snapshot'       => 10000,
            'market_price_effective_date' => '2026-01-01',
            'date'                        => '2026-01-15',
            'weight_kg'                   => 200,
            'quantity'                    => 200,
            'unit'                        => 'kg',
            'status'                      => 'recorded',
        ]);

        // Panen B: 800 kg
        $harvestB = Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $this->season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $marketPrice->id,
            'market_price_snapshot'       => 10000,
            'market_price_effective_date' => '2026-01-01',
            'date'                        => '2026-02-15',
            'weight_kg'                   => 800,
            'quantity'                    => 800,
            'unit'                        => 'kg',
            'status'                      => 'recorded',
        ]);

        // Total biaya musim: Rp1.000.000
        ProductionCost::create([
            'user_id'   => $this->farmer->id,
            'season_id' => $this->season->id,
            'date'      => '2026-01-10',
            'category'  => 'fertilizer',
            'amount'    => 1000000,
        ]);

        // Total panen musim = 1.000 kg

        // Panen A: 200/1000 × 1.000.000 = 200.000 biaya
        $responseA = $this->withToken($this->token)
            ->getJson("/api/harvests/{$harvestA->id}/economic-result");

        $responseA->assertOk();
        // Gross A = 200 × 10000 = 2.000.000
        $this->assertNumericJsonPath($responseA, 'data.gross_harvest_value', 2000000);
        $this->assertNumericJsonPath($responseA, 'data.allocated_production_cost', 200000);
        // Profit = 2.000.000 - 200.000 = 1.800.000
        $this->assertNumericJsonPath($responseA, 'data.profit_loss', 1800000);
        $this->assertEquals('profit', $responseA->json('data.profit_loss_status'));

        // Panen B: 800/1000 × 1.000.000 = 800.000 biaya
        $responseB = $this->withToken($this->token)
            ->getJson("/api/harvests/{$harvestB->id}/economic-result");

        $responseB->assertOk();
        // Gross B = 800 × 10000 = 8.000.000
        $this->assertNumericJsonPath($responseB, 'data.gross_harvest_value', 8000000);
        $this->assertNumericJsonPath($responseB, 'data.allocated_production_cost', 800000);
        // Profit = 8.000.000 - 800.000 = 7.200.000
        $this->assertNumericJsonPath($responseB, 'data.profit_loss', 7200000);
        $this->assertEquals('profit', $responseB->json('data.profit_loss_status'));
    }

    // ─── Test 3: Loss scenario ────────────────────────────────────────────────

    public function test_loss_scenario_when_cost_exceeds_revenue(): void
    {
        $marketPrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 5000,
            'unit'           => 'kg',
            'effective_date' => '2026-01-01',
            'source'         => 'manual',
            'created_by'     => $this->farmer->id,
        ]);

        $harvest = Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $this->season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $marketPrice->id,
            'market_price_snapshot'       => 5000,
            'market_price_effective_date' => '2026-01-01',
            'date'                        => '2026-01-15',
            'weight_kg'                   => 100,
            'quantity'                    => 100,
            'unit'                        => 'kg',
            'status'                      => 'recorded',
        ]);

        // Biaya: Rp2.000.000 (lebih besar dari revenue 500.000)
        ProductionCost::create([
            'user_id'   => $this->farmer->id,
            'season_id' => $this->season->id,
            'date'      => '2026-01-05',
            'category'  => 'seed',
            'amount'    => 2000000,
        ]);

        $response = $this->withToken($this->token)
            ->getJson("/api/harvests/{$harvest->id}/economic-result");

        $response->assertOk();
        // Gross = 100 × 5000 = 500.000
        $this->assertNumericJsonPath($response, 'data.gross_harvest_value', 500000);
        $this->assertNumericJsonPath($response, 'data.allocated_production_cost', 2000000);
        // Loss = 500.000 - 2.000.000 = -1.500.000
        $this->assertNumericJsonPath($response, 'data.profit_loss', -1500000);
        $this->assertEquals('loss', $response->json('data.profit_loss_status'));
    }

    // ─── Test 4: No market price → gross_harvest_value null ──────────────────

    public function test_harvest_without_price_snapshot_returns_null_values(): void
    {
        $harvest = Harvest::create([
            'user_id'   => $this->farmer->id,
            'season_id' => $this->season->id,
            'date'      => '2026-01-15',
            'weight_kg' => 150,
            'quantity'  => 150,
            'unit'      => 'kg',
            'status'    => 'recorded',
        ]);

        $response = $this->withToken($this->token)
            ->getJson("/api/harvests/{$harvest->id}/economic-result");

        $response->assertOk()
            ->assertJsonPath('data.market_price_snapshot', null)
            ->assertJsonPath('data.gross_harvest_value', null)
            ->assertJsonPath('data.profit_loss', null)
            ->assertJsonPath('data.profit_loss_status', null);
    }

    // ─── Test 5: Tenant isolation — cannot access other farmer's harvest ───────

    public function test_farmer_cannot_access_other_farmers_harvest_result(): void
    {
        $other = User::create([
            'name'            => 'Petani Lain',
            'email'           => 'other@test.com',
            'password'        => bcrypt('password123'),
            'role'            => 'user',
            'status'          => 'active',
            'farmer_group_id' => $this->group->id,
        ]);

        $otherSeason = Season::create([
            'user_id'    => $other->id,
            'name'       => 'Musim Lain',
            'start_date' => '2026-01-01',
            'end_date'   => '2026-12-31',
            'status'     => 'active',
            'target_kg'  => 500,
        ]);

        $otherHarvest = Harvest::create([
            'user_id'   => $other->id,
            'season_id' => $otherSeason->id,
            'date'      => '2026-01-15',
            'weight_kg' => 100,
            'unit'      => 'kg',
            'status'    => 'recorded',
        ]);

        $response = $this->withToken($this->token)
            ->getJson("/api/harvests/{$otherHarvest->id}/economic-result");

        $response->assertForbidden();
    }

    // ─── Test 6: Season economic summary ─────────────────────────────────────

    public function test_season_economic_summary_aggregates_harvests(): void
    {
        $marketPrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 12000,
            'unit'           => 'kg',
            'effective_date' => '2026-01-01',
            'source'         => 'manual',
            'created_by'     => $this->farmer->id,
        ]);

        // 2 panen dalam musim yang sama: 300 + 200 = 500 kg total
        Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $this->season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $marketPrice->id,
            'market_price_snapshot'       => 12000,
            'market_price_effective_date' => '2026-01-01',
            'date'                        => '2026-01-15',
            'weight_kg'                   => 300,
            'quantity'                    => 300,
            'unit'                        => 'kg',
            'status'                      => 'recorded',
        ]);

        Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $this->season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $marketPrice->id,
            'market_price_snapshot'       => 12000,
            'market_price_effective_date' => '2026-01-01',
            'date'                        => '2026-02-15',
            'weight_kg'                   => 200,
            'quantity'                    => 200,
            'unit'                        => 'kg',
            'status'                      => 'recorded',
        ]);

        ProductionCost::create([
            'user_id'   => $this->farmer->id,
            'season_id' => $this->season->id,
            'date'      => '2026-01-05',
            'category'  => 'fertilizer',
            'amount'    => 1500000,
        ]);

        $response = $this->withToken($this->token)
            ->getJson("/api/seasons/{$this->season->id}/economic-summary");

        $response->assertOk()
            ->assertJsonPath('data.season_id', $this->season->id)
            ->assertJsonPath('data.harvest_count', 2)
            ->assertJsonPath('data.has_complete_price_data', true)
            ->assertJsonCount(2, 'data.harvests');

        $this->assertNumericJsonPath($response, 'data.total_weight_kg', 500);
        // Total Gross = 500 × 12000 = 6.000.000
        $this->assertNumericJsonPath($response, 'data.total_gross_harvest_value', 6000000);
        $this->assertNumericJsonPath($response, 'data.total_production_cost', 1500000);
        // Profit = 6.000.000 - 1.500.000 = 4.500.000
        $this->assertNumericJsonPath($response, 'data.total_profit_loss', 4500000);
        $this->assertEquals('profit', $response->json('data.profit_loss_status'));
    }

    public function test_season_with_mixed_harvest_snapshots_aggregates_valid_revenues(): void
    {
        $mixedSeason = Season::create([
            'user_id'      => $this->farmer->id,
            'name'         => 'Musim Mixed 2026',
            'start_date'   => '2026-03-01',
            'end_date'     => '2026-09-30',
            'status'       => 'active',
            'target_kg'    => 500,
            'commodity_id' => $this->commodity->id,
        ]);

        $marketPrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 10000,
            'unit'           => 'kg',
            'effective_date' => '2026-03-01',
            'source'         => 'manual',
            'created_by'     => $this->farmer->id,
        ]);

        // Harvest 1: with snapshot -> weight 100kg * 10.000 = 1.000.000
        Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $mixedSeason->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $marketPrice->id,
            'market_price_snapshot'       => 10000,
            'market_price_effective_date' => '2026-03-01',
            'date'                        => '2026-03-15',
            'weight_kg'                   => 100,
            'quantity'                    => 1,
            'unit'                        => 'kuintal',
            'status'                      => 'recorded',
        ]);

        // Harvest 2: without snapshot -> weight 200kg, snapshot null
        Harvest::create([
            'user_id'      => $this->farmer->id,
            'season_id'    => $mixedSeason->id,
            'commodity_id' => $this->commodity->id,
            'date'         => '2026-04-15',
            'weight_kg'    => 200,
            'quantity'     => 200,
            'unit'         => 'kg',
            'status'       => 'recorded',
        ]);

        // Biaya musim: Rp600.000
        ProductionCost::create([
            'user_id'   => $this->farmer->id,
            'season_id' => $mixedSeason->id,
            'date'      => '2026-03-05',
            'category'  => 'fertilizer',
            'amount'    => 600000,
        ]);

        $response = $this->withToken($this->token)
            ->getJson("/api/seasons/{$mixedSeason->id}/economic-summary");

        $response->assertOk()
            ->assertJsonPath('data.season_id', $mixedSeason->id)
            ->assertJsonPath('data.harvest_count', 2)
            ->assertJsonPath('data.has_complete_price_data', false);

        // Season Revenue = Σ harvest revenue yang valid = 1.000.000
        $this->assertNumericJsonPath($response, 'data.season_revenue', 1000000);
        $this->assertNumericJsonPath($response, 'data.season_production_cost', 600000);
        // Season Profit/Loss = 1.000.000 - 600.000 = 400.000
        $this->assertNumericJsonPath($response, 'data.season_profit_loss', 400000);
        $this->assertEquals('profit', $response->json('data.profit_loss_status'));
    }

    // ─── Test 7: Season isolation ─────────────────────────────────────────────

    public function test_farmer_cannot_access_other_farmers_season_summary(): void
    {
        $other = User::create([
            'name'            => 'Petani Lain 2',
            'email'           => 'other2@test.com',
            'password'        => bcrypt('password123'),
            'role'            => 'user',
            'status'          => 'active',
            'farmer_group_id' => $this->group->id,
        ]);

        $otherSeason = Season::create([
            'user_id'    => $other->id,
            'name'       => 'Musim Lain 2',
            'start_date' => '2026-01-01',
            'end_date'   => '2026-12-31',
            'status'     => 'active',
            'target_kg'  => 500,
        ]);

        $response = $this->withToken($this->token)
            ->getJson("/api/seasons/{$otherSeason->id}/economic-summary");

        $response->assertForbidden();
    }

    // ─── Test 8: Farmer overall economic summary ──────────────────────────────

    public function test_farmer_overall_economic_summary_returns_all_seasons(): void
    {
        $marketPrice = MarketPrice::create([
            'commodity_id'   => $this->commodity->id,
            'price'          => 20000,
            'unit'           => 'kg',
            'effective_date' => '2026-01-01',
            'source'         => 'manual',
            'created_by'     => $this->farmer->id,
        ]);

        Harvest::create([
            'user_id'                     => $this->farmer->id,
            'season_id'                   => $this->season->id,
            'commodity_id'                => $this->commodity->id,
            'market_price_id'             => $marketPrice->id,
            'market_price_snapshot'       => 20000,
            'market_price_effective_date' => '2026-01-01',
            'date'                        => '2026-01-15',
            'weight_kg'                   => 50,
            'unit'                        => 'kg',
            'status'                      => 'recorded',
        ]);

        ProductionCost::create([
            'user_id'   => $this->farmer->id,
            'season_id' => $this->season->id,
            'date'      => '2026-01-05',
            'category'  => 'other',
            'amount'    => 500000,
        ]);

        $response = $this->withToken($this->token)
            ->getJson('/api/farmer/economic-summary');

        $response->assertOk()
            ->assertJsonStructure(['data' => [
                'total_weight_kg',
                'total_gross_harvest_value',
                'total_production_cost',
                'total_profit_loss',
                'profit_loss_status',
                'season_count',
                'seasons',
            ]])
            ->assertJsonPath('data.season_count', 1);

        // Gross = 50 × 20000 = 1.000.000
        $this->assertNumericJsonPath($response, 'data.total_gross_harvest_value', 1000000);
        $this->assertNumericJsonPath($response, 'data.total_production_cost', 500000);
        $this->assertNumericJsonPath($response, 'data.total_profit_loss', 500000);
    }

    // ─── Test 9: Super Admin economic aggregate endpoint ─────────────────────

    public function test_super_admin_can_view_economic_aggregate(): void
    {
        $admin = User::create([
            'name'     => 'Super Admin',
            'email'    => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role'     => 'super_admin',
            'status'   => 'active',
        ]);

        $adminToken = $admin->createToken('test')->plainTextToken;

        $response = $this->withToken($adminToken)
            ->getJson('/api/super-admin/economic-aggregate');

        $response->assertOk()
            ->assertJsonStructure(['data' => [
                'platform_total_gross_harvest_value',
                'platform_total_production_cost',
                'platform_total_profit_loss',
                'farmer_count',
                'farmers',
            ]]);
    }

    // ─── Test 10: Farmer cannot access Super Admin aggregate ──────────────────

    public function test_farmer_cannot_access_super_admin_aggregate(): void
    {
        $response = $this->withToken($this->token)
            ->getJson('/api/super-admin/economic-aggregate');

        $response->assertForbidden();
    }
}
