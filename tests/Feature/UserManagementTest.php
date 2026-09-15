<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->create(['role' => 'super_admin']);
    }

    /** @test */
    public function super_admin_can_view_users_list()
    {
        $response = $this->actingAs($this->admin)
            ->get('/users');

        $response->assertStatus(200);
        $response->assertViewIs('users.index');
    }

    /** @test */
    public function super_admin_can_create_user()
    {
        $response = $this->actingAs($this->admin)
            ->post('/users', [
                'farm_name' => 'Test Farm',
                'name' => 'Test User',
                'email' => 'test@example.com',
                'phone' => '081234567890',
                'role' => 'user',
                'status' => 'active',
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'test@example.com',
            'role' => 'user',
        ]);

        $response->assertRedirect();
    }

    /** @test */
    public function super_admin_can_update_user()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($this->admin)
            ->put("/users/{$user->id}", [
                'farm_name' => 'Updated Farm',
                'name' => 'Updated Name',
                'email' => 'updated@example.com',
                'phone' => '081234567899',
                'role' => 'admin',
                'status' => 'active',
            ]);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Name',
            'role' => 'admin',
        ]);

        $response->assertRedirect();
    }

    /** @test */
    public function super_admin_can_delete_user()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($this->admin)
            ->delete("/users/{$user->id}");

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
        $response->assertRedirect();
    }

    /** @test */
    public function super_admin_can_approve_pending_user()
    {
        $pendingUser = User::factory()->create([
            'status' => 'active',
            'approval' => 'pending',
        ]);

        $response = $this->actingAs($this->admin)
            ->post("/users/{$pendingUser->id}/approve");

        $this->assertDatabaseHas('users', [
            'id' => $pendingUser->id,
            'approval' => 'approved',
        ]);

        $response->assertRedirect();
    }

    /** @test */
    public function super_admin_can_reject_pending_user()
    {
        $pendingUser = User::factory()->create([
            'status' => 'active',
            'approval' => 'pending',
        ]);

        $response = $this->actingAs($this->admin)
            ->post("/users/{$pendingUser->id}/reject");

        $this->assertDatabaseHas('users', [
            'id' => $pendingUser->id,
            'approval' => 'rejected',
        ]);

        $response->assertRedirect();
    }

    /** @test */
    public function non_super_admin_cannot_manage_users()
    {
        $regularUser = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($regularUser)
            ->get('/users');

        $response->assertStatus(403);
    }

    /** @test */
    public function super_admin_can_view_user_details()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($this->admin)
            ->get("/users/{$user->id}");

        $response->assertStatus(200);
        $response->assertViewHas('user', $user);
    }

    /** @test */
    public function user_email_must_be_unique()
    {
        User::factory()->create(['email' => 'duplicate@example.com']);

        $response = $this->actingAs($this->admin)
            ->post('/users', [
                'farm_name' => 'Test Farm',
                'name' => 'Test User',
                'email' => 'duplicate@example.com',
                'phone' => '081234567890',
                'role' => 'user',
                'status' => 'active',
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ]);

        $response->assertSessionHasErrors('email');
    }

    /** @test */
    public function user_role_must_be_valid()
    {
        $response = $this->actingAs($this->admin)
            ->post('/users', [
                'farm_name' => 'Test Farm',
                'name' => 'Test User',
                'email' => 'test@example.com',
                'phone' => '081234567890',
                'role' => 'invalid_role',
                'status' => 'active',
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ]);

        $response->assertSessionHasErrors('role');
    }

    /** @test */
    public function user_status_must_be_valid()
    {
        $response = $this->actingAs($this->admin)
            ->post('/users', [
                'farm_name' => 'Test Farm',
                'name' => 'Test User',
                'email' => 'test@example.com',
                'phone' => '081234567890',
                'role' => 'user',
                'status' => 'invalid_status',
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ]);

        $response->assertSessionHasErrors('status');
    }

    /** @test */
    public function user_can_view_own_profile()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->get('/profile');

        $response->assertStatus(200);
    }
}
