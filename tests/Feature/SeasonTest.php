<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Season;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SeasonTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'admin']);
    }

    public function test_user_can_view_seasons_list()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/seasons');

        $response->assertStatus(200)
            ->assertJson([ 'success' => true, 'message' => 'Daftar musim tanam.' ]);
    }

    public function test_user_can_create_season()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/seasons', [
                'name' => 'Musim Tanam 1',
                'start_date' => '2024-01-01',
                'end_date' => '2024-03-31',
                'status' => 'active',
                'target_kg' => 1000,
            ]);

        $this->assertDatabaseHas('seasons', [
            'name' => 'Musim Tanam 1',
            'user_id' => $this->user->id,
            'target_kg' => 1000,
        ]);

        $response->assertStatus(201)
            ->assertJson([ 'success' => true, 'message' => 'Musim tanam berhasil ditambahkan.' ]);
    }

    public function test_user_can_update_season()
    {
        $season = Season::factory()->create(['user_id' => $this->user->id]);

        $response = $this->actingAs($this->user)
            ->putJson("/seasons/{$season->id}", [
                'name' => 'Musim Tanam Updated',
                'start_date' => '2024-01-15',
                'end_date' => '2024-04-15',
                'status' => 'completed',
                'target_kg' => 2000,
            ]);

        $this->assertDatabaseHas('seasons', [
            'id' => $season->id,
            'name' => 'Musim Tanam Updated',
            'status' => 'completed',
            'target_kg' => 2000,
        ]);

        $response->assertStatus(200)
            ->assertJson([ 'success' => true, 'message' => 'Musim tanam berhasil diperbarui.' ]);
    }

    public function test_user_can_delete_season()
    {
        $season = Season::factory()->create(['user_id' => $this->user->id]);

        $response = $this->actingAs($this->user)
            ->deleteJson("/seasons/{$season->id}");

        $this->assertSoftDeleted($season);
        $response->assertStatus(200)
            ->assertJson([ 'success' => true, 'message' => 'Musim tanam berhasil dihapus.' ]);
    }

    public function test_season_requires_valid_end_date_after_start_date()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/seasons', [
                'name' => 'Invalid Season',
                'start_date' => '2024-03-31',
                'end_date' => '2024-01-01',
                'status' => 'active',
                'target_kg' => 1000,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('end_date');
    }

    public function test_unauthenticated_user_cannot_view_seasons()
    {
        $response = $this->getJson('/seasons');
        $response->assertStatus(401);
    }

    public function test_user_can_only_see_own_seasons()
    {
        $otherUser = User::factory()->create();
        $otherSeason = Season::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($this->user)
            ->getJson('/seasons');

        $response->assertStatus(200);
        $seasons = collect($response->json('data'))->pluck('id')->toArray();
        $this->assertNotContains($otherSeason->id, $seasons);
    }
}
