<?php

namespace Tests\Feature\API;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PasswordResetSecurityTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function test_prevents_email_enumeration(): void
    {
        $user = User::factory()->create([
            'email' => 'registered@example.com',
        ]);

        $expectedMessage = 'Jika email Anda terdaftar di sistem, instruksi reset password telah dikirimkan ke email Anda.';

        // 1. Request with registered email
        $responseRegistered = $this->postJson('/api/auth/forgot-password', [
            'email' => 'registered@example.com',
        ]);

        $responseRegistered->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => $expectedMessage,
            ]);

        // 2. Request with UNREGISTERED email
        $responseUnregistered = $this->postJson('/api/auth/forgot-password', [
            'email' => 'nonexistent_user_999@example.com',
        ]);

        // Both responses MUST be identical HTTP 200 with same generic message
        $responseUnregistered->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => $expectedMessage,
            ]);

        // Verify unregistered email response does not leak any data
        $this->assertNull($responseUnregistered->json('data'));
    }

    /** @test */
    public function test_token_not_exposed_in_production(): void
    {
        config(['app.debug' => false]);
        $user = User::factory()->create(['email' => 'testprod@example.com']);

        $response = $this->postJson('/api/auth/forgot-password', [
            'email' => 'testprod@example.com',
        ]);

        $response->assertStatus(200);
        $this->assertNull($response->json('data'), 'Reset token must NOT be exposed when debug is disabled/production');
    }

    /** @test */
    public function test_reset_password_with_valid_token(): void
    {
        $user = User::factory()->create([
            'email'    => 'resetuser@example.com',
            'password' => Hash::make('old_password_123'),
        ]);

        $token = Password::broker()->createToken($user);

        $response = $this->postJson('/api/auth/reset-password', [
            'email'                 => 'resetuser@example.com',
            'token'                 => $token,
            'password'              => 'new_secret_password_123',
            'password_confirmation' => 'new_secret_password_123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        // Verify password was changed in DB
        $user->refresh();
        $this->assertTrue(Hash::check('new_secret_password_123', $user->password));
        $this->assertFalse(Hash::check('old_password_123', $user->password));

        // Verify NO auto-login token was issued
        $this->assertNull($response->json('data'));
    }

    /** @test */
    public function test_reset_password_token_reuse_fails(): void
    {
        $user = User::factory()->create([
            'email' => 'reuseuser@example.com',
        ]);

        $token = Password::broker()->createToken($user);

        // First attempt succeeds
        $response1 = $this->postJson('/api/auth/reset-password', [
            'email'                 => 'reuseuser@example.com',
            'token'                 => $token,
            'password'              => 'first_reset_pass_123',
            'password_confirmation' => 'first_reset_pass_123',
        ]);
        $response1->assertStatus(200);

        // Second attempt with SAME token must FAIL
        $response2 = $this->postJson('/api/auth/reset-password', [
            'email'                 => 'reuseuser@example.com',
            'token'                 => $token,
            'password'              => 'second_reset_pass_123',
            'password_confirmation' => 'second_reset_pass_123',
        ]);

        $response2->assertStatus(400)
            ->assertJson([
                'success' => false,
            ]);
    }

    /** @test */
    public function test_reset_password_token_expired_fails(): void
    {
        $user = User::factory()->create([
            'email' => 'expireduser@example.com',
        ]);

        $token = Password::broker()->createToken($user);

        // Artificially expire the token by backdating created_at in password_reset_tokens table
        DB::table('password_reset_tokens')
            ->where('email', 'expireduser@example.com')
            ->update(['created_at' => now()->subHours(5)]);

        $response = $this->postJson('/api/auth/reset-password', [
            'email'                 => 'expireduser@example.com',
            'token'                 => $token,
            'password'              => 'new_expired_pass_123',
            'password_confirmation' => 'new_expired_pass_123',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
            ]);
    }

    /** @test */
    public function test_reset_password_email_mismatch_fails(): void
    {
        $userA = User::factory()->create(['email' => 'user_a@example.com']);
        $userB = User::factory()->create(['email' => 'user_b@example.com']);

        // Token created for User A
        $tokenUserA = Password::broker()->createToken($userA);

        // Try to use User A's token to reset User B's password
        $response = $this->postJson('/api/auth/reset-password', [
            'email'                 => 'user_b@example.com',
            'token'                 => $tokenUserA,
            'password'              => 'hacked_password_123',
            'password_confirmation' => 'hacked_password_123',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
            ]);
    }

    /** @test */
    public function test_super_admin_update_requires_password_confirmation(): void
    {
        $admin = User::factory()->create(['role' => 'super_admin']);
        $targetUser = User::factory()->create(['role' => 'user']);

        Sanctum::actingAs($admin);

        // 1. Mismatch confirmation fails with 422
        $mismatchResponse = $this->putJson("/api/super-admin/users/{$targetUser->id}", [
            'name'                  => $targetUser->name,
            'email'                 => $targetUser->email,
            'phone'                 => $targetUser->phone ?? '08123456789',
            'farm_name'             => $targetUser->farm_name ?? 'Lahan A',
            'role'                  => 'user',
            'status'                => 'active',
            'password'              => 'admin_set_new_pass_123',
            'password_confirmation' => 'wrong_confirmation',
        ]);

        $mismatchResponse->assertStatus(422);

        // 2. Matching confirmation succeeds
        $successResponse = $this->putJson("/api/super-admin/users/{$targetUser->id}", [
            'name'                  => $targetUser->name,
            'email'                 => $targetUser->email,
            'phone'                 => $targetUser->phone ?? '08123456789',
            'farm_name'             => $targetUser->farm_name ?? 'Lahan A',
            'role'                  => 'user',
            'status'                => 'active',
            'password'              => 'admin_set_new_pass_123',
            'password_confirmation' => 'admin_set_new_pass_123',
        ]);

        $successResponse->assertStatus(200);

        $targetUser->refresh();
        $this->assertTrue(Hash::check('admin_set_new_pass_123', $targetUser->password));
    }

    /** @test */
    public function test_unauthorized_regular_user_cannot_access_admin_user_update(): void
    {
        $regularUser = User::factory()->create(['role' => 'user']);
        $targetUser = User::factory()->create(['role' => 'user']);

        Sanctum::actingAs($regularUser);

        $response = $this->putJson("/api/super-admin/users/{$targetUser->id}", [
            'name' => 'Attempted Hack',
        ]);

        // Must be rejected with 403 Forbidden
        $response->assertStatus(403);
    }

    /** @test */
    public function test_reset_password_does_not_issue_auto_login_token(): void
    {
        $user = User::factory()->create();
        $token = Password::broker()->createToken($user);

        $response = $this->postJson('/api/auth/reset-password', [
            'email'                 => $user->email,
            'token'                 => $token,
            'password'              => 'secure_new_password_888',
            'password_confirmation' => 'secure_new_password_888',
        ]);

        $response->assertStatus(200);

        // Explicit security check: No authentication tokens or user objects leaked in payload
        $this->assertNull($response->json('data'));
        $this->assertArrayNotHasKey('access_token', $response->json());
        $this->assertArrayNotHasKey('token', $response->json());
    }
}
