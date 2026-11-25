<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LoginApprovalTest extends TestCase
{
    use RefreshDatabase;

    public function test_approved_user_can_login_via_credentials(): void
    {
        $user = User::factory()->create([
            'email'    => 'approved@test.com',
            'password' => bcrypt('password123'),
            'role'     => 'user',
            'status'   => 'active',
            'approval' => 'approved',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email'    => 'approved@test.com',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'approved@test.com')
            ->assertJsonPath('data.token_type', 'Bearer');
    }

    public function test_pending_user_cannot_login_via_credentials(): void
    {
        $user = User::factory()->create([
            'email'    => 'pending@test.com',
            'password' => bcrypt('password123'),
            'role'     => 'user',
            'status'   => 'active',
            'approval' => 'pending',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email'    => 'pending@test.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(403)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Akun Anda sedang menunggu persetujuan Admin.');
    }

    public function test_rejected_user_cannot_login_via_credentials(): void
    {
        $user = User::factory()->create([
            'email'    => 'rejected@test.com',
            'password' => bcrypt('password123'),
            'role'     => 'user',
            'status'   => 'active',
            'approval' => 'rejected',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email'    => 'rejected@test.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(403)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Pendaftaran akun Anda ditolak. Hubungi Admin untuk informasi lebih lanjut.');
    }

    public function test_inactive_user_cannot_login_via_credentials(): void
    {
        $user = User::factory()->create([
            'email'    => 'inactive@test.com',
            'password' => bcrypt('password123'),
            'role'     => 'user',
            'status'   => 'inactive',
            'approval' => 'approved',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email'    => 'inactive@test.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(403)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Akun Anda tidak aktif.');
    }

    public function test_super_admin_can_login_via_credentials(): void
    {
        $admin = User::factory()->create([
            'email'    => 'superadmin@test.com',
            'password' => bcrypt('admin123'),
            'role'     => 'super_admin',
            'status'   => 'active',
            'approval' => 'approved',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email'    => 'superadmin@test.com',
            'password' => 'admin123',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.role', 'super_admin');
    }

    public function test_super_admin_approves_pending_user_then_user_can_login(): void
    {
        $admin = User::factory()->create([
            'role'     => 'super_admin',
            'status'   => 'active',
            'approval' => 'approved',
        ]);

        $pendingUser = User::factory()->create([
            'email'    => 'farmer@test.com',
            'password' => bcrypt('secret123'),
            'role'     => 'user',
            'status'   => 'active',
            'approval' => 'pending',
        ]);

        // Attempt login before approval -> rejected
        $this->postJson('/api/auth/login', [
            'email'    => 'farmer@test.com',
            'password' => 'secret123',
        ])->assertStatus(403);

        // Super Admin approves the user
        $this->actingAs($admin)
            ->postJson("/api/super-admin/users/{$pendingUser->id}/approve")
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('users', [
            'id'       => $pendingUser->id,
            'approval' => 'approved',
        ]);

        // Now user can log in
        $this->postJson('/api/auth/login', [
            'email'    => 'farmer@test.com',
            'password' => 'secret123',
        ])->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'farmer@test.com');
    }

    public function test_super_admin_rejects_user(): void
    {
        $admin = User::factory()->create([
            'role'     => 'super_admin',
            'status'   => 'active',
            'approval' => 'approved',
        ]);

        $pendingUser = User::factory()->create([
            'email'    => 'rejectme@test.com',
            'password' => bcrypt('secret123'),
            'role'     => 'user',
            'status'   => 'active',
            'approval' => 'pending',
        ]);

        // Super Admin rejects the user
        $this->actingAs($admin)
            ->postJson("/api/super-admin/users/{$pendingUser->id}/reject", [
                'reason' => 'Dokumen tidak valid',
            ])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('users', [
            'id'       => $pendingUser->id,
            'approval' => 'rejected',
        ]);

        // User cannot login
        $this->postJson('/api/auth/login', [
            'email'    => 'rejectme@test.com',
            'password' => 'secret123',
        ])->assertStatus(403)
            ->assertJsonPath('message', 'Pendaftaran akun Anda ditolak. Hubungi Admin untuk informasi lebih lanjut.');
    }
}
