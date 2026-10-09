<?php

namespace Tests\Feature\API;

use App\Models\FarmerGroup;
use App\Models\PasswordResetRequest;
use App\Models\PasswordResetRequestToken;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PasswordResetManualVerificationTest extends TestCase
{
    use RefreshDatabase;

    protected User $superAdmin;
    protected User $farmer;
    protected FarmerGroup $farmerGroup;

    protected function setUp(): void
    {
        parent::setUp();

        $this->farmerGroup = FarmerGroup::create([
            'name' => 'Kelompok Tani Harapan Jaya',
            'code' => 'POKTAN-01',
            'village' => 'Desa Sukamaju',
            'status' => 'active',
        ]);

        $this->superAdmin = User::factory()->create([
            'name' => 'Super Administrator',
            'email' => 'admin@sumbertani.id',
            'role' => 'super_admin',
            'password' => Hash::make('AdminSecret123'),
        ]);

        $this->farmer = User::factory()->create([
            'name' => 'Budi Santoso',
            'email' => 'budi@petani.id',
            'role' => 'user',
            'farmer_group_id' => $this->farmerGroup->id,
            'password' => Hash::make('OldPassword123'),
        ]);
    }

    /** 1. Pengguna dapat mengirim permintaan reset dengan input valid */
    public function test_user_can_submit_reset_request_with_valid_input(): void
    {
        $response = $this->postJson('/api/password-reset-requests', [
            'name' => 'Budi Santoso',
            'farmer_group' => 'Kelompok Tani Harapan Jaya',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'pending',
                ],
            ]);

        $this->assertDatabaseHas('password_reset_requests', [
            'name' => 'Budi Santoso',
            'farmer_group_name' => 'Kelompok Tani Harapan Jaya',
            'status' => 'pending',
            'user_id' => $this->farmer->id,
        ]);
    }

    /** 2. Input tidak valid ditolak */
    public function test_invalid_input_is_rejected(): void
    {
        $response = $this->postJson('/api/password-reset-requests', [
            'name' => '',
        ]);

        $response->assertStatus(422)
            ->assertJsonStructure(['errors' => ['name']]);
    }

    /** 3. Permintaan muncul pada panel Super Admin */
    public function test_request_appears_on_super_admin_panel(): void
    {
        PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'farmer_group_name' => 'Kelompok Tani Harapan Jaya',
            'user_id' => $this->farmer->id,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->getJson('/api/super-admin/password-reset-requests');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonFragment(['name' => 'Budi Santoso']);
    }

    /** 4. Petani atau role lain tidak dapat mengakses endpoint administrasi */
    public function test_farmer_cannot_access_admin_endpoints(): void
    {
        Sanctum::actingAs($this->farmer);

        $response = $this->getJson('/api/super-admin/password-reset-requests');
        $response->assertStatus(403);

        $responsePost = $this->postJson('/api/super-admin/password-reset-requests/1/approve');
        $responsePost->assertStatus(403);
    }

    /** 5. Pengguna yang belum terautentikasi tidak dapat mengakses endpoint administrasi */
    public function test_unauthenticated_user_cannot_access_admin_endpoints(): void
    {
        $response = $this->getJson('/api/super-admin/password-reset-requests');
        $response->assertStatus(401);

        $aliasResponse = $this->getJson('/api/admin/password-reset-requests');
        $aliasResponse->assertStatus(401);
    }

    /** 6. Permintaan dapat disetujui oleh Super Admin */
    public function test_request_can_be_approved_by_super_admin(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'farmer_group_name' => 'Kelompok Tani Harapan Jaya',
            'user_id' => $this->farmer->id,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/approve");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'approved',
                    'admin_id' => $this->superAdmin->id,
                ],
            ]);

        $this->assertDatabaseHas('password_reset_requests', [
            'id' => $req->id,
            'status' => 'approved',
            'admin_id' => $this->superAdmin->id,
        ]);
    }

    /** 7. Permintaan dapat ditolak oleh Super Admin */
    public function test_request_can_be_rejected_by_super_admin(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'farmer_group_name' => 'Kelompok Tani Harapan Jaya',
            'user_id' => $this->farmer->id,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/reject", [
            'reason' => 'Identitas tidak sesuai dengan data KTP pengurus Poktan.',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'rejected',
                    'admin_id' => $this->superAdmin->id,
                ],
            ]);

        $this->assertDatabaseHas('password_reset_requests', [
            'id' => $req->id,
            'status' => 'rejected',
            'rejection_reason' => 'Identitas tidak sesuai dengan data KTP pengurus Poktan.',
        ]);
    }

    /** 8. Token hanya dapat dibuat untuk permintaan yang memenuhi syarat (approved) */
    public function test_token_can_only_be_generated_for_approved_requests(): void
    {
        $reqPending = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'farmer_group_name' => 'Kelompok Tani Harapan Jaya',
            'user_id' => $this->farmer->id,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->superAdmin);

        // Attempt on pending request -> 422
        $response = $this->postJson("/api/super-admin/password-reset-requests/{$reqPending->id}/generate-token");
        $response->assertStatus(422);

        // Approve it first
        $reqPending->update(['status' => 'approved']);

        // Now generate token succeeds
        $responseGen = $this->postJson("/api/super-admin/password-reset-requests/{$reqPending->id}/generate-token");
        $responseGen->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['token', 'expires_at', 'validity_seconds']]);

        $this->assertEquals(300, $responseGen->json('data.validity_seconds'));
    }

    /** 9. Token valid dapat digunakan untuk mengubah password */
    public function test_valid_token_can_be_used_to_reset_password(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'user_id' => $this->farmer->id,
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->superAdmin);
        $genRes = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/generate-token");
        $token = $genRes->json('data.token');

        // Confirm reset with valid token as public user
        $response = $this->postJson('/api/password-reset/confirm', [
            'token' => $token,
            'password' => 'NewSecurePassword123',
            'password_confirmation' => 'NewSecurePassword123',
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        // Check password updated
        $this->farmer->refresh();
        $this->assertTrue(Hash::check('NewSecurePassword123', $this->farmer->password));

        // Check request status updated to completed
        $req->refresh();
        $this->assertEquals('completed', $req->status);
    }

    /** 10. Token salah ditolak */
    public function test_invalid_token_is_rejected(): void
    {
        $response = $this->postJson('/api/password-reset/confirm', [
            'token' => 'INVALID_TOKEN_RANDOM_XYZ',
            'password' => 'NewSecurePassword123',
            'password_confirmation' => 'NewSecurePassword123',
        ]);

        $response->assertStatus(422)
            ->assertJsonStructure(['errors' => ['token']]);
    }

    /** 11. Token kedaluwarsa setelah 5 menit ditolak */
    public function test_expired_token_after_5_minutes_is_rejected(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'user_id' => $this->farmer->id,
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->superAdmin);
        $genRes = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/generate-token");
        $token = $genRes->json('data.token');

        // Advance system time past 5 minutes (e.g. 5 minutes 1 second)
        Carbon::setTestNow(now()->addSeconds(301));

        $response = $this->postJson('/api/password-reset/confirm', [
            'token' => $token,
            'password' => 'NewSecurePassword123',
            'password_confirmation' => 'NewSecurePassword123',
        ]);

        $response->assertStatus(422)
            ->assertJsonFragment(['token' => ['Token reset password sudah kedaluwarsa (masa berlaku 5 menit telah habis). Silakan hubungi Super Admin untuk meminta token baru.']]);

        Carbon::setTestNow(); // Reset time
    }

    /** 12. Token yang sudah digunakan tidak dapat digunakan ulang */
    public function test_used_token_cannot_be_reused(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'user_id' => $this->farmer->id,
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->superAdmin);
        $genRes = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/generate-token");
        $token = $genRes->json('data.token');

        // First use -> Success
        $first = $this->postJson('/api/password-reset/confirm', [
            'token' => $token,
            'password' => 'NewSecurePassword123',
            'password_confirmation' => 'NewSecurePassword123',
        ]);
        $first->assertStatus(200);

        // Second use -> Rejected
        $second = $this->postJson('/api/password-reset/confirm', [
            'token' => $token,
            'password' => 'AnotherPassword123',
            'password_confirmation' => 'AnotherPassword123',
        ]);
        $second->assertStatus(422);
    }

    /** 13. Token yang dicabut tidak dapat digunakan */
    public function test_revoked_token_cannot_be_used(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'user_id' => $this->farmer->id,
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->superAdmin);
        // Generate 1st token
        $genRes1 = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/generate-token");
        $token1 = $genRes1->json('data.token');

        // Generate 2nd token (which automatically revokes 1st token)
        $genRes2 = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/generate-token");
        $token2 = $genRes2->json('data.token');

        // Try using revoked token1 -> Rejected
        $response1 = $this->postJson('/api/password-reset/confirm', [
            'token' => $token1,
            'password' => 'NewSecurePassword123',
            'password_confirmation' => 'NewSecurePassword123',
        ]);
        $response1->assertStatus(422);

        // Active token2 -> Works
        $response2 = $this->postJson('/api/password-reset/confirm', [
            'token' => $token2,
            'password' => 'NewSecurePassword123',
            'password_confirmation' => 'NewSecurePassword123',
        ]);
        $response2->assertStatus(200);
    }

    /** 14. Token untuk akun A tidak dapat digunakan untuk mengubah password akun B */
    public function test_token_for_user_a_only_changes_user_a(): void
    {
        $farmerB = User::factory()->create([
            'name' => 'Siti Aminah',
            'email' => 'siti@petani.id',
            'password' => Hash::make('FarmerBOriginal123'),
        ]);

        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'user_id' => $this->farmer->id,
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->superAdmin);
        $genRes = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/generate-token");
        $token = $genRes->json('data.token');

        // Perform reset with token
        $response = $this->postJson('/api/password-reset/confirm', [
            'token' => $token,
            'password' => 'NewPasswordForA123',
            'password_confirmation' => 'NewPasswordForA123',
        ]);
        $response->assertStatus(200);

        // Check farmer A password changed
        $this->farmer->refresh();
        $this->assertTrue(Hash::check('NewPasswordForA123', $this->farmer->password));

        // Farmer B password must remain unchanged
        $farmerB->refresh();
        $this->assertTrue(Hash::check('FarmerBOriginal123', $farmerB->password));
    }

    /** 15. Password baru dan konfirmasi yang tidak cocok ditolak */
    public function test_mismatched_password_confirmation_is_rejected(): void
    {
        $response = $this->postJson('/api/password-reset/confirm', [
            'token' => 'dummy-token',
            'password' => 'NewSecurePassword123',
            'password_confirmation' => 'DifferentPassword456',
        ]);

        $response->assertStatus(422)
            ->assertJsonStructure(['errors' => ['password']]);
    }

    /** 16. Password lama tidak lagi menjadi password yang berlaku setelah reset berhasil */
    public function test_old_password_no_longer_valid_after_reset(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'user_id' => $this->farmer->id,
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->superAdmin);
        $genRes = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/generate-token");
        $token = $genRes->json('data.token');

        $this->postJson('/api/password-reset/confirm', [
            'token' => $token,
            'password' => 'NewFreshPassword123',
            'password_confirmation' => 'NewFreshPassword123',
        ])->assertStatus(200);

        // Old password check fails
        $this->farmer->refresh();
        $this->assertFalse(Hash::check('OldPassword123', $this->farmer->password));
        $this->assertTrue(Hash::check('NewFreshPassword123', $this->farmer->password));
    }

    /** 17. Hash password tersimpan dengan benar */
    public function test_password_is_hashed_and_not_stored_as_plaintext(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'user_id' => $this->farmer->id,
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->superAdmin);
        $genRes = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/generate-token");
        $token = $genRes->json('data.token');

        $this->postJson('/api/password-reset/confirm', [
            'token' => $token,
            'password' => 'MySecretHashedPass123',
            'password_confirmation' => 'MySecretHashedPass123',
        ])->assertStatus(200);

        $this->farmer->refresh();
        $this->assertNotEquals('MySecretHashedPass123', $this->farmer->password);
        $this->assertStringStartsWith('$', $this->farmer->password);
    }

    /** 18. Raw token is never stored in database; only hash is stored */
    public function test_raw_token_never_stored_in_database(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'user_id' => $this->farmer->id,
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->superAdmin);
        $genRes = $this->postJson("/api/super-admin/password-reset-requests/{$req->id}/generate-token");
        $rawToken = $genRes->json('data.token');

        // Check database tokens table does NOT contain plain text
        $this->assertDatabaseMissing('password_reset_request_tokens', [
            'token_hash' => $rawToken,
        ]);

        // Check hash exists
        $this->assertDatabaseHas('password_reset_request_tokens', [
            'token_hash' => hash('sha256', $rawToken),
        ]);
    }

    /** 19. Public request response does not leak sensitive user info */
    public function test_public_request_response_does_not_leak_sensitive_info(): void
    {
        $response = $this->postJson('/api/password-reset-requests', [
            'name' => 'Budi Santoso',
            'farmer_group' => 'Kelompok Tani Harapan Jaya',
        ]);

        $response->assertStatus(201);
        $content = $response->getContent();

        $this->assertStringNotContainsString('budi@petani.id', $content);
        $this->assertStringNotContainsString('password', strtolower($response->json('data.email') ?? ''));
        $this->assertArrayNotHasKey('email', $response->json('data'));
    }

    /** 20. Re-submitting identical request within 5 minutes is gracefully handled without duplicates */
    public function test_anti_spam_prevents_duplicate_pending_requests(): void
    {
        $first = $this->postJson('/api/password-reset-requests', [
            'name' => 'Budi Santoso',
        ]);
        $first->assertStatus(201);

        $second = $this->postJson('/api/password-reset-requests', [
            'name' => 'Budi Santoso',
        ]);
        $second->assertStatus(201);

        // Only 1 pending request record should exist for Budi Santoso
        $this->assertEquals(1, PasswordResetRequest::where('name', 'Budi Santoso')->count());
    }

    /** 21. Super Admin detail endpoint retrieves full verification information */
    public function test_super_admin_can_view_request_detail(): void
    {
        $req = PasswordResetRequest::create([
            'name' => 'Budi Santoso',
            'farmer_group_name' => 'Kelompok Tani Harapan Jaya',
            'user_id' => $this->farmer->id,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->getJson("/api/super-admin/password-reset-requests/{$req->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $req->id,
                    'name' => 'Budi Santoso',
                    'user' => [
                        'id' => $this->farmer->id,
                        'name' => 'Budi Santoso',
                    ],
                ],
            ]);
    }
}
