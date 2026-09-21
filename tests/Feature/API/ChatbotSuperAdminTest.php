<?php

namespace Tests\Feature\API;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ChatbotSuperAdminTest extends TestCase
{
    use RefreshDatabase;

    protected User $superAdmin;
    protected User $farmer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superAdmin = User::factory()->create([
            'role' => 'super_admin',
            'name' => 'Super Administrator',
        ]);

        $this->farmer = User::factory()->create([
            'role' => 'user',
            'name' => 'Petani Satu',
        ]);
    }

    /** @test */
    public function test_super_admin_can_chat_with_operational_tanibot(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/chat', [
            'message' => 'Bagaimana cara manajemen pemasaran produk olahan?',
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        $reply = $response->json('reply');
        $this->assertStringContainsString('Pemasaran', $reply);
        $this->assertStringNotContainsString('SIMHPSK', $reply);
    }

    /** @test */
    public function test_super_admin_can_chat_via_super_admin_prefix(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/super-admin/chat', [
            'message' => 'tentang platform ini',
        ]);

        $response->assertStatus(200);
        $reply = $response->json('reply');
        $this->assertStringContainsString('SumberTani berbasis AI', $reply);
    }

    /** @test */
    public function test_farmer_cannot_access_chatbot(): void
    {
        Sanctum::actingAs($this->farmer);

        $response = $this->postJson('/api/chat', [
            'message' => 'Halo bot',
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function test_unauthenticated_cannot_access_chatbot(): void
    {
        $response = $this->postJson('/api/chat', [
            'message' => 'Halo bot',
        ]);

        $response->assertStatus(401);
    }
}
