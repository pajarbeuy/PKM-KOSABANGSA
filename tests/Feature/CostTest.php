<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Season;
use App\Models\ProductionCost;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CostTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'admin']);
        $this->season = Season::factory()->create(['user_id' => $this->user->id]);
    }

    /** @test */
    public function user_can_view_costs_list()
    {
        $response = $this->actingAs($this->user)
            ->get('/costs');

        $response->assertStatus(200);
        $response->assertViewIs('costs.index');
    }

    /** @test */
    public function user_can_record_production_cost()
    {
        $response = $this->actingAs($this->user)
            ->post('/costs', [
                'season_id' => $this->season->id,
                'category' => 'bibit',
                'amount' => 500000,
                'date' => '2024-01-15',
                'description' => 'Bibit kentang berkualitas',
            ]);

        $this->assertDatabaseHas('production_costs', [
            'season_id' => $this->season->id,
            'user_id' => $this->user->id,
            'category' => 'bibit',
            'amount' => 500000,
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');
    }

    /** @test */
    public function user_can_view_cost_details()
    {
        $cost = ProductionCost::factory()->create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
        ]);

        $response = $this->actingAs($this->user)
            ->get("/costs/{$cost->id}");

        $response->assertStatus(200);
        $response->assertViewHas('cost', $cost);
    }

    /** @test */
    public function user_can_update_production_cost()
    {
        $cost = ProductionCost::factory()->create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'amount' => 500000,
        ]);

        $response = $this->actingAs($this->user)
            ->put("/costs/{$cost->id}", [
                'season_id' => $this->season->id,
                'category' => 'pupuk',
                'amount' => 700000,
                'date' => '2024-02-01',
                'description' => 'Updated cost',
            ]);

        $this->assertDatabaseHas('production_costs', [
            'id' => $cost->id,
            'amount' => 700000,
            'category' => 'pupuk',
        ]);

        $response->assertRedirect();
    }

    /** @test */
    public function user_can_delete_production_cost()
    {
        $cost = ProductionCost::factory()->create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
        ]);

        $response = $this->actingAs($this->user)
            ->delete("/costs/{$cost->id}");

        $this->assertDatabaseMissing('production_costs', ['id' => $cost->id]);
        $response->assertRedirect();
    }

    /** @test */
    public function cost_requires_valid_amount()
    {
        $response = $this->actingAs($this->user)
            ->post('/costs', [
                'season_id' => $this->season->id,
                'category' => 'bibit',
                'amount' => -500000,
                'date' => '2024-01-15',
                'description' => 'Test',
            ]);

        $response->assertSessionHasErrors('amount');
    }

    /** @test */
    public function cost_requires_valid_category()
    {
        $response = $this->actingAs($this->user)
            ->post('/costs', [
                'season_id' => $this->season->id,
                'category' => 'invalid_category',
                'amount' => 500000,
                'date' => '2024-01-15',
                'description' => 'Test',
            ]);

        $response->assertSessionHasErrors('category');
    }

    /** @test */
    public function unauthenticated_user_cannot_view_costs()
    {
        $response = $this->get('/costs');
        $response->assertRedirect('/login');
    }

    /** @test */
    public function user_can_only_see_own_costs()
    {
        $otherUser = User::factory()->create();
        $otherSeason = Season::factory()->create(['user_id' => $otherUser->id]);
        ProductionCost::factory(3)->create(['user_id' => $otherUser->id, 'season_id' => $otherSeason->id]);

        $response = $this->actingAs($this->user)
            ->get('/costs');

        $costs = $response->viewData('costs');
        $this->assertCount(0, $costs);
    }

    /** @test */
    public function cost_is_associated_with_season()
    {
        $cost = ProductionCost::factory()->create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
        ]);

        $this->assertEquals($this->season->id, $cost->season_id);
        $this->assertTrue($cost->season->is($this->season));
    }

    /** @test */
    public function total_cost_for_season_is_calculated_correctly()
    {
        ProductionCost::create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'category' => 'bibit',
            'amount' => 500000,
            'date' => '2024-01-15',
            'description' => 'Bibit',
        ]);

        ProductionCost::create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'category' => 'pupuk',
            'amount' => 300000,
            'date' => '2024-02-01',
            'description' => 'Pupuk',
        ]);

        $totalCost = ProductionCost::where('season_id', $this->season->id)->sum('amount');
        $this->assertEquals(800000, $totalCost);
    }
}
