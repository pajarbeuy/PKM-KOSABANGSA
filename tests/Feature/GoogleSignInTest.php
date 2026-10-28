<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserOauthIdentity;
use App\Services\GoogleOAuthService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery\MockInterface;
use Tests\TestCase;

/**
 * Feature tests for POST /api/auth/google
 *
 * All tests mock GoogleOAuthService::verify() so no real Google token is needed.
 * This keeps the suite runnable in CI/CD without external credentials.
 */
class GoogleSignInTest extends TestCase
{
    use RefreshDatabase;

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Bind a mocked GoogleOAuthService that returns the given claims (or throws).
     */
    private function mockGoogle(array $claims): void
    {
        $this->mock(GoogleOAuthService::class, function (MockInterface $mock) use ($claims) {
            $mock->shouldReceive('verify')
                ->once()
                ->andReturn($claims);
        });
    }

    private function mockGoogleThrows(string $message): void
    {
        $this->mock(GoogleOAuthService::class, function (MockInterface $mock) use ($message) {
            $mock->shouldReceive('verify')
                ->once()
                ->andThrow(new \RuntimeException($message));
        });
    }

    private function validClaims(array $overrides = []): array
    {
        return array_merge([
            'sub'            => 'google-sub-123456',
            'email'          => 'petani@gmail.com',
            'email_verified' => true,
            'name'           => 'Budi Petani',
        ], $overrides);
    }

    // ── Test Cases ────────────────────────────────────────────────────────────

    /** TC-01: Valid token, unregistered email — returns needs_registration without creating user */
    public function test_unregistered_google_email_returns_needs_registration(): void
    {
        $this->mockGoogle($this->validClaims());

        $response = $this->postJson('/api/auth/google', ['id_token' => 'valid-token']);

        $response->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonPath('data.needs_registration', true)
            ->assertJsonPath('data.email', 'petani@gmail.com');

        // Akun belum dibuat otomatis
        $this->assertDatabaseMissing('users', ['email' => 'petani@gmail.com']);
    }

    /** TC-02: Already linked identity — user logged in, no duplicate identity row */
    public function test_existing_linked_user_can_sign_in_with_google(): void
    {
        $user = User::factory()->create(['email' => 'linked@gmail.com', 'role' => 'user']);
        UserOauthIdentity::create([
            'user_id'          => $user->id,
            'provider'         => 'google',
            'provider_user_id' => 'sub-already-linked',
        ]);

        $this->mockGoogle($this->validClaims([
            'sub'   => 'sub-already-linked',
            'email' => 'linked@gmail.com',
        ]));

        $response = $this->postJson('/api/auth/google', ['id_token' => 'valid-token']);

        $response->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonPath('data.is_new_account', false);

        // Exactly one identity row — no duplicate
        $this->assertSame(1, UserOauthIdentity::where('provider_user_id', 'sub-already-linked')->count());
    }

    /** TC-03: Email already in DB but not linked → auto-link, no new account */
    public function test_existing_email_user_gets_auto_linked(): void
    {
        User::factory()->create([
            'email'  => 'existing@gmail.com',
            'role'   => 'user',
            'status' => 'active',
        ]);

        $this->mockGoogle($this->validClaims([
            'email' => 'existing@gmail.com',
            'sub'   => 'new-sub-for-existing-email',
        ]));

        $response = $this->postJson('/api/auth/google', ['id_token' => 'valid-token']);

        $response->assertOk()
            ->assertJsonPath('data.is_new_account', false);

        $this->assertDatabaseHas('user_oauth_identities', [
            'provider'         => 'google',
            'provider_user_id' => 'new-sub-for-existing-email',
        ]);
        // Still only one user with that email
        $this->assertSame(1, User::where('email', 'existing@gmail.com')->count());
    }

    /** TC-04: Invalid / expired token from Google */
    public function test_invalid_google_token_returns_401(): void
    {
        $this->mockGoogleThrows('ID token tidak valid atau sudah kedaluwarsa.');

        $response = $this->postJson('/api/auth/google', ['id_token' => 'invalid-google-token-string']);

        $response->assertStatus(401)
            ->assertJson(['success' => false]);
    }

    /** TC-05: Missing id_token field → 422 Validation error */
    public function test_missing_id_token_returns_validation_error(): void
    {
        $response = $this->postJson('/api/auth/google', []);

        $response->assertStatus(422);
    }

    /** TC-06: Super Admin account blocked via Google Sign-In */
    public function test_super_admin_cannot_sign_in_via_google(): void
    {
        User::factory()->create([
            'email'  => 'superadmin@gmail.com',
            'role'   => 'super_admin',
            'status' => 'active',
        ]);

        $this->mockGoogle($this->validClaims(['email' => 'superadmin@gmail.com']));

        $response = $this->postJson('/api/auth/google', ['id_token' => 'valid-token']);

        $response->assertStatus(403)
            ->assertJsonFragment(['success' => false]);

        // Ensure no identity row created for super_admin
        $this->assertDatabaseMissing('user_oauth_identities', ['provider_user_id' => 'google-sub-123456']);
    }

    /** TC-07: Inactive user blocked */
    public function test_inactive_user_cannot_sign_in_via_google(): void
    {
        User::factory()->create([
            'email'  => 'inactive@gmail.com',
            'role'   => 'user',
            'status' => 'inactive',
        ]);
        // Pre-link the identity
        $user = User::where('email', 'inactive@gmail.com')->first();
        UserOauthIdentity::create([
            'user_id'          => $user->id,
            'provider'         => 'google',
            'provider_user_id' => 'sub-inactive',
        ]);

        $this->mockGoogle($this->validClaims([
            'sub'   => 'sub-inactive',
            'email' => 'inactive@gmail.com',
        ]));

        $response = $this->postJson('/api/auth/google', ['id_token' => 'valid-token']);

        $response->assertStatus(403)->assertJson(['success' => false]);
    }

    /** TC-08: Returned Sanctum token is usable on protected endpoints */
    public function test_returned_sanctum_token_grants_api_access(): void
    {
        User::factory()->create(['email' => 'petani@gmail.com', 'role' => 'user', 'status' => 'active', 'approval' => 'approved']);
        $this->mockGoogle($this->validClaims());

        $signInResponse = $this->postJson('/api/auth/google', ['id_token' => 'valid-token']);
        $token          = $signInResponse->json('data.token');

        $this->assertNotEmpty($token);

        // Use token to access a protected endpoint
        $meResponse = $this->withHeaders(['Authorization' => "Bearer $token"])
            ->getJson('/api/auth/me');

        $meResponse->assertOk()->assertJsonPath('data.email', 'petani@gmail.com');
    }

    /** TC-09: Login lama (email + password) masih berfungsi setelah Google linked */
    public function test_password_login_still_works_after_google_link(): void
    {
        $user = User::factory()->create([
            'email'    => 'both@gmail.com',
            'password' => bcrypt('secret123'),
            'role'     => 'user',
            'status'   => 'active',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email'    => 'both@gmail.com',
            'password' => 'secret123',
        ]);

        $response->assertOk()->assertJsonPath('data.token_type', 'Bearer');
    }

    /** TC-10: One Google sub cannot be linked to two local accounts */
    public function test_one_google_sub_cannot_link_to_two_accounts(): void
    {
        $user1 = User::factory()->create(['email' => 'user1@test.com']);
        UserOauthIdentity::create([
            'user_id'          => $user1->id,
            'provider'         => 'google',
            'provider_user_id' => 'shared-sub',
        ]);

        $this->expectException(\Illuminate\Database\QueryException::class);

        // Attempt to insert a second row with the same provider+sub
        UserOauthIdentity::create([
            'user_id'          => User::factory()->create()->id,
            'provider'         => 'google',
            'provider_user_id' => 'shared-sub',
        ]);
    }

    /** TC-11: Logout revokes the Google-issued Sanctum token */
    public function test_logout_revokes_google_issued_sanctum_token(): void
    {
        User::factory()->create(['email' => 'petani@gmail.com', 'role' => 'user', 'status' => 'active', 'approval' => 'approved']);
        $this->mockGoogle($this->validClaims());

        $token = $this->postJson('/api/auth/google', ['id_token' => 'valid-token'])
            ->json('data.token');

        // Logout
        $this->withHeaders(['Authorization' => "Bearer $token"])
            ->postJson('/api/auth/logout')
            ->assertOk();

        // Flush guard cache so next request evaluates the token from DB
        $this->app['auth']->forgetGuards();

        // Token should no longer work
        $this->withHeaders(['Authorization' => "Bearer $token"])
            ->getJson('/api/auth/me')
            ->assertStatus(401);
    }
}
