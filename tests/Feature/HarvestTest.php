<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Season;
use App\Models\Harvest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HarvestTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'admin']);
        $this->season = Season::factory()->create(['user_id' => $this->user->id]);
    }

    /** @test */
    public function user_can_view_harvests_list()
    {
        $response = $this->actingAs($this->user)
            ->get('/harvests');

        $response->assertStatus(200);
        $response->assertViewIs('harvests.index');
    }

    /** @test */
    public function user_can_record_harvest()
    {
        $response = $this->actingAs($this->user)
            ->post('/harvests', [
                'season_id' => $this->season->id,
                'date' => '2024-03-15',
                'weight_kg' => 500,
                'notes' => 'Panen bagus',
                'location' => 'Ladang Utama',
            ]);

        $this->assertDatabaseHas('harvests', [
            'season_id' => $this->season->id,
            'user_id' => $this->user->id,
            'weight_kg' => 500,
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');
    }

    /** @test */
    public function user_can_view_harvest_details()
    {
        $harvest = Harvest::factory()->create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
        ]);

        $response = $this->actingAs($this->user)
            ->get("/harvests/{$harvest->id}");

        $response->assertStatus(200);
        $response->assertViewHas('harvest', $harvest);
    }

    /** @test */
    public function user_can_update_harvest_record()
    {
        $harvest = Harvest::factory()->create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'weight_kg' => 500,
        ]);

        $response = $this->actingAs($this->user)
            ->put("/harvests/{$harvest->id}", [
                'season_id' => $this->season->id,
                'date' => '2024-03-20',
                'weight_kg' => 600,
                'notes' => 'Updated notes',
                'location' => 'Ladang Utama',
            ]);

        $this->assertDatabaseHas('harvests', [
            'id' => $harvest->id,
            'weight_kg' => 600,
        ]);

        $response->assertRedirect();
    }

    /** @test */
    public function user_can_delete_harvest()
    {
        $harvest = Harvest::factory()->create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
        ]);

        $response = $this->actingAs($this->user)
            ->delete("/harvests/{$harvest->id}");

        $this->assertDatabaseMissing('harvests', ['id' => $harvest->id]);
        $response->assertRedirect();
    }

    /** @test */
    public function harvest_requires_valid_weight()
    {
        $response = $this->actingAs($this->user)
            ->post('/harvests', [
                'season_id' => $this->season->id,
                'date' => '2024-03-15',
                'weight_kg' => -100,
                'notes' => 'Invalid weight',
                'location' => 'Ladang',
            ]);

        $response->assertSessionHasErrors('weight_kg');
    }

    /** @test */
    public function harvest_requires_valid_date()
    {
        $response = $this->actingAs($this->user)
            ->post('/harvests', [
                'season_id' => $this->season->id,
                'date' => 'invalid-date',
                'weight_kg' => 500,
                'notes' => 'Test',
                'location' => 'Ladang',
            ]);

        $response->assertSessionHasErrors('date');
    }

    /** @test */
    public function unauthenticated_user_cannot_record_harvest()
    {
        $response = $this->get('/harvests');
        $response->assertRedirect('/login');
    }

    /** @test */
    public function user_can_only_see_own_harvests()
    {
        $otherUser = User::factory()->create();
        $otherHarvest = Harvest::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($this->user)
            ->get('/harvests');

        $harvests = $response->viewData('harvests')->pluck('id')->toArray();
        $this->assertNotContains($otherHarvest->id, $harvests);
    }

    /** @test */
    public function harvest_is_associated_with_season()
    {
        $harvest = Harvest::factory()->create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
        ]);

        $this->assertEquals($this->season->id, $harvest->season_id);
        $this->assertTrue($harvest->season->is($this->season));
    }
}
