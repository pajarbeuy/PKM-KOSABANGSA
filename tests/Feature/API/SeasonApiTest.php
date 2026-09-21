<?php

namespace Tests\Feature\API;

use App\Models\User;
use App\Models\Season;
use App\Models\Harvest;
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
    public function test_user_can_list_seasons_via_api()
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
    public function test_user_can_create_season_via_api()
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
    public function test_unauthorized_user_cannot_access_api()
    {
        $response = $this->withHeaders([
            'Accept' => 'application/json',
        ])->get('/api/seasons');

        $response->assertStatus(401);
    }

    /** @test */
    public function test_invalid_token_is_rejected()
    {
        $response = $this->withHeaders([
            'Authorization' => 'Bearer invalid-token',
            'Accept' => 'application/json',
        ])->get('/api/seasons');

        $response->assertStatus(401);
    }

    /** @test */
    public function test_season_and_target_aggregate_multiple_harvests_correctly()
    {
        $season = Season::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Musim Hujan Multiple',
            'target_kg' => 200,
            'status' => 'active',
            'start_date' => now()->subMonth(),
            'end_date' => now()->addMonth(),
        ]);

        // Harvest A = 2.000 kg
        Harvest::create([
            'user_id' => $this->user->id,
            'season_id' => $season->id,
            'date' => now()->toDateString(),
            'weight_kg' => 2000,
            'quantity' => 1,
            'status' => 'recorded',
        ]);

        // Harvest B = 500 kg
        Harvest::create([
            'user_id' => $this->user->id,
            'season_id' => $season->id,
            'date' => now()->toDateString(),
            'weight_kg' => 500,
            'quantity' => 1,
            'status' => 'recorded',
        ]);

        // 1. Check Season API
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept' => 'application/json',
        ])->get('/api/seasons');

        $response->assertStatus(200);
        $data = $response->json('data');
        $seasonData = collect($data)->firstWhere('id', $season->id);
        $this->assertNotNull($seasonData);
        $this->assertEquals(2500, (float) $seasonData['harvests_sum_weight_kg']);

        // 2. Check Report Target vs Actual API
        $reportResponse = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'Accept' => 'application/json',
        ])->get('/api/reports/target-vs-actual');

        $reportResponse->assertStatus(200);
        $reportData = collect($reportResponse->json('data'))->firstWhere('season_id', $season->id);
        $this->assertNotNull($reportData);
        $this->assertEquals(2500, (float) $reportData['actual']);
        $this->assertEquals(200, (float) $reportData['target']);
        $this->assertEquals(1250, (float) $reportData['percentage']);
    }
}
