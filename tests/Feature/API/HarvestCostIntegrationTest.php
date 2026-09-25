<?php

namespace Tests\Feature\API;

use App\Models\FarmerCommodity;
use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Season;
use App\Models\StockTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HarvestCostIntegrationTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected User $otherUser;
    protected string $token;
    protected string $otherToken;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'farmer']);
        $this->otherUser = User::factory()->create(['role' => 'farmer']);

        $this->token = $this->user->createToken('farmer-token')->plainTextToken;
        $this->otherToken = $this->otherUser->createToken('other-token')->plainTextToken;
    }

    /** @test */
    public function test_it_can_create_a_season_associated_with_commodity()
    {
        $commodity = FarmerCommodity::create([
            'user_id' => $this->user->id,
            'name'    => 'Cabai Rawit Merah',
            'type'    => 'hortikultura',
            'unit'    => 'kg',
        ]);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept'        => 'application/json',
        ])->postJson('/api/seasons', [
            'name'         => 'Musim Hujan Cabai 2026',
            'commodity_id' => $commodity->id,
            'start_date'   => '2026-10-01',
            'end_date'     => '2026-12-31',
            'status'       => 'active',
            'target_kg'    => 500,
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('data.commodity_id', $commodity->id);
        $response->assertJsonPath('data.commodity_name', 'Cabai Rawit Merah');
        $this->assertDatabaseHas('seasons', [
            'name'         => 'Musim Hujan Cabai 2026',
            'commodity_id' => $commodity->id,
        ]);
    }

    /** @test */
    public function test_it_forbids_associating_season_with_another_users_commodity()
    {
        $otherCommodity = FarmerCommodity::create([
            'user_id' => $this->otherUser->id,
            'name'    => 'Jagung Manis',
            'type'    => 'pangan',
            'unit'    => 'kg',
        ]);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept'        => 'application/json',
        ])->postJson('/api/seasons', [
            'name'         => 'Musim Ilegal',
            'commodity_id' => $otherCommodity->id,
            'start_date'   => '2026-10-01',
            'end_date'     => '2026-12-31',
            'status'       => 'active',
            'target_kg'    => 200,
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function test_it_can_record_harvest_with_commodity_and_unit()
    {
        $commodity = FarmerCommodity::create([
            'user_id' => $this->user->id,
            'name'    => 'Padi Ciherang',
            'type'    => 'pangan',
            'unit'    => 'ton',
        ]);

        $season = Season::factory()->create([
            'user_id'      => $this->user->id,
            'commodity_id' => $commodity->id,
        ]);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept'        => 'application/json',
        ])->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'commodity_id' => $commodity->id,
            'harvest_date' => '2026-10-15',
            'quantity'     => 5,
            'unit'         => 'ton',
            'weight_kg'    => 5000.00,
            'notes'        => 'Panen raya tahap 1',
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('data.commodity_id', $commodity->id);
        $response->assertJsonPath('data.commodity_name', 'Padi Ciherang');
        $response->assertJsonPath('data.unit', 'ton');
        $this->assertEquals(5000.0, (float) $response->json('data.weight_kg'));

        $this->assertDatabaseHas('harvests', [
            'season_id'    => $season->id,
            'commodity_id' => $commodity->id,
            'unit'         => 'ton',
            'weight_kg'    => 5000.00,
        ]);

        // Verify stock transaction
        $this->assertDatabaseHas('stock_transactions', [
            'user_id' => $this->user->id,
            'type'    => 'in',
            'amount'  => 5000.00,
        ]);
    }

    /** @test */
    public function test_it_inherits_commodity_id_from_season_if_not_specified()
    {
        $commodity = FarmerCommodity::create([
            'user_id' => $this->user->id,
            'name'    => 'Tomat Ceri',
            'type'    => 'hortikultura',
            'unit'    => 'kg',
        ]);

        $season = Season::factory()->create([
            'user_id'      => $this->user->id,
            'commodity_id' => $commodity->id,
        ]);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept'        => 'application/json',
        ])->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'harvest_date' => '2026-10-20',
            'weight_kg'    => 25.50,
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('data.commodity_id', $commodity->id);
        $response->assertJsonPath('data.commodity_name', 'Tomat Ceri');
        $response->assertJsonPath('data.unit', 'kg');
    }

    /** @test */
    public function test_it_forbids_recording_harvest_with_another_users_commodity()
    {
        $season = Season::factory()->create([
            'user_id' => $this->user->id,
        ]);

        $otherCommodity = FarmerCommodity::create([
            'user_id' => $this->otherUser->id,
            'name'    => 'Bawang Merah',
            'type'    => 'hortikultura',
            'unit'    => 'kg',
        ]);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept'        => 'application/json',
        ])->postJson('/api/harvests', [
            'season_id'    => $season->id,
            'commodity_id' => $otherCommodity->id,
            'harvest_date' => '2026-10-20',
            'weight_kg'    => 10.00,
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function test_it_can_update_harvest_commodity_and_unit()
    {
        $commodity1 = FarmerCommodity::create([
            'user_id' => $this->user->id,
            'name'    => 'Bayam Hijau',
            'type'    => 'hortikultura',
            'unit'    => 'ikat',
        ]);

        $commodity2 = FarmerCommodity::create([
            'user_id' => $this->user->id,
            'name'    => 'Bayam Merah',
            'type'    => 'hortikultura',
            'unit'    => 'ikat',
        ]);

        $season = Season::factory()->create(['user_id' => $this->user->id]);

        $harvest = Harvest::create([
            'user_id'      => $this->user->id,
            'season_id'    => $season->id,
            'commodity_id' => $commodity1->id,
            'quantity'     => 100,
            'unit'         => 'ikat',
            'date'         => '2026-10-10',
            'weight_kg'    => 20.00,
            'status'       => 'recorded',
        ]);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept'        => 'application/json',
        ])->putJson("/api/harvests/{$harvest->id}", [
            'commodity_id' => $commodity2->id,
            'quantity'     => 120,
            'unit'         => 'ikat',
            'weight_kg'    => 24.00,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('data.commodity_id', $commodity2->id);
        $response->assertJsonPath('data.commodity_name', 'Bayam Merah');
        $this->assertEquals(24.0, (float) $response->json('data.weight_kg'));
    }

    /** @test */
    public function test_historical_harvest_data_without_commodity_remains_backward_compatible()
    {
        $season = Season::factory()->create(['user_id' => $this->user->id]);

        $harvest = Harvest::create([
            'user_id'      => $this->user->id,
            'season_id'    => $season->id,
            'commodity_id' => null,
            'quantity'     => 50,
            'unit'         => null,
            'date'         => '2025-01-10',
            'weight_kg'    => 100.00,
            'status'       => 'recorded',
        ]);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept'        => 'application/json',
        ])->getJson("/api/harvests/{$harvest->id}");

        $response->assertStatus(200);
        $response->assertJsonPath('data.commodity_id', null);
        $response->assertJsonPath('data.commodity_name', null);
        $this->assertEquals(100.0, $response->json('data.weight_kg'));
    }

    /** @test */
    public function test_production_cost_is_attributed_to_commodity_via_season()
    {
        $commodity = FarmerCommodity::create([
            'user_id' => $this->user->id,
            'name'    => 'Kopi Arabika',
            'type'    => 'perkebunan',
            'unit'    => 'kg',
        ]);

        $season = Season::factory()->create([
            'user_id'      => $this->user->id,
            'commodity_id' => $commodity->id,
            'name'         => 'Musim Kopi 2026',
        ]);

        $cost = ProductionCost::create([
            'user_id'   => $this->user->id,
            'season_id' => $season->id,
            'category'  => 'fertilizer',
            'amount'    => 450000,
            'date'      => '2026-10-05',
            'notes'     => 'Pupuk Organik NPK',
        ]);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept'        => 'application/json',
        ])->getJson("/api/costs/{$cost->id}");

        $response->assertStatus(200);
        $response->assertJsonPath('data.season_id', $season->id);
        $response->assertJsonPath('data.commodity_id', $commodity->id);
        $response->assertJsonPath('data.commodity_name', 'Kopi Arabika');
        $response->assertJsonPath('data.category', 'fertilizer');
        $this->assertEquals(450000.0, (float) $response->json('data.amount'));
    }
}
