<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Season;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_requires_authentication(): void
    {
        $response = $this->get('/dashboard');
        $response->assertRedirect('/login');
    }

    public function test_authenticated_user_can_access_dashboard(): void
    {
        $user = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($user)
            ->get('/dashboard');

        $response->assertStatus(200);
        $response->assertJson([
            'success' => false,
            'message' => 'Blade views have been disabled. Please access the Dashboard via the Flutter client.',
        ]);
    }

    public function test_dashboard_displays_statistics(): void
    {
        $user = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($user)
            ->get('/dashboard');

        $response->assertJsonStructure([
            'success',
            'message',
        ]);
    }
}
