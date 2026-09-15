<?php

namespace Tests\Feature\API;

use App\Models\User;
use App\Models\Season;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SeasonApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'admin']);
        $this->token = $this->user->createToken('test-token')->plainTextToken;
    }

    /** @test */
    public function user_can_list_seasons_via_api()
    {
        Season::factory(3)->create(['user_id' => $this->user->id]);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept' => 'application/json',
        ])->get('/api/seasons');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'data',
            'message',
        ]);
    }

    /** @test */
    public function user_can_create_season_via_api()
    {
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept' => 'application/json',
        ])->post('/api/seasons', [
            'name' => 'Musim Tanam API',
            'start_date' => '2024-01-01',
            'end_date' => '2024-03-31',
            'status' => 'active',
            'target_kg' => 1000,
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'success',
            'data',
            'message',
        ]);

        $this->assertDatabaseHas('seasons', [
            'name' => 'Musim Tanam API',
            'user_id' => $this->user->id,
        ]);
    }

    /** @test */
    public function unauthorized_user_cannot_access_api()
    {
        $response = $this->withHeaders([
            'Accept' => 'application/json',
        ])->get('/api/seasons');

        $response->assertStatus(401);
    }

    /** @test */
    public function invalid_token_is_rejected()
    {
        $response = $this->withHeaders([
            'Authorization' => 'Bearer invalid-token',
            'Accept' => 'application/json',
        ])->get('/api/seasons');

        $response->assertStatus(401);
    }
}
