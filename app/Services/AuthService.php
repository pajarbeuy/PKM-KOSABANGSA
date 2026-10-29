<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserOauthIdentity;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthService
{
    /**
     * Create a new user account.
     */
    public function createUser(array $data, string $role = 'user'): User
    {
        return User::create([
            'farm_name'       => $data['farm_name'],
            'name'            => $data['name'],
            'email'           => $data['email'],
            'phone'           => $data['phone'],
            'farmer_group_id' => $data['farmer_group_id'] ?? null,
            'password'        => Hash::make($data['password']),
            'role'            => $role,
            'status'          => 'active',
            'approval'        => 'pending',
        ]);
    }

    /**
     * Attempt to find and authenticate a user by credentials.
     * Returns the user if valid, null otherwise.
     */
    public function attemptLogin(string $email, string $password): ?User
    {
        $user = User::with('farmerGroup')->where('email', $email)->first();

        if (!$user || !Hash::check($password, $user->password)) {
            return null;
        }

        return $user;
    }

    /**
     * Create a Sanctum API token for the user.
     */
    public function createToken(User $user, string $name = 'api-token'): string
    {
        return $user->createToken($name)->plainTextToken;
    }

    /**
     * Format a user for API response.
     */
    public function formatUser(User $user): array
    {
        $user->loadMissing('farmerGroup');

        return [
            'id'              => $user->id,
            'name'            => $user->name,
            'email'           => $user->email,
            'farm_name'       => $user->farm_name,
            'phone'           => $user->phone,
            'farmer_group_id' => $user->farmer_group_id,
            'farmer_group'    => $user->farmerGroup ? [
                'id'          => $user->farmerGroup->id,
                'name'        => $user->farmerGroup->name,
                'code'        => $user->farmerGroup->code,
            ] : null,
            'role'            => $user->role,
            'status'          => $user->status,
            'approval'        => $user->approval,
        ];
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Google OAuth
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Find or create a local user from verified Google ID Token claims,
     * then return the user and a fresh Sanctum token.
     *
     * Policy (agreed with product owner):
     *  - If Google sub already linked → load that user.
     *  - If email matches an existing local user → auto-link and load.
     *  - Otherwise → create a new active/approved Poktan account.
     *  - Super Admin accounts may NOT be accessed via Google Sign-In.
     *
     * @param  array  $googleClaims  Verified claims from GoogleOAuthService::verify()
     * @return array  ['user' => User, 'token' => string, 'is_new' => bool]
     *
     * @throws \RuntimeException   When the matched account is inactive or is super_admin.
     */
    public function loginWithGoogle(array $googleClaims): array
    {
        $sub   = $googleClaims['sub'];
        $email = $googleClaims['email'];
        $name  = $googleClaims['name'] ?? $email;

        return DB::transaction(function () use ($sub, $email, $name) {
            // 1. Look up existing OAuth identity
            $identity = UserOauthIdentity::with('user')
                ->where('provider', 'google')
                ->where('provider_user_id', $sub)
                ->first();

            $user = null;

            if ($identity) {
                $user = $identity->user;
            } else {
                // 2. No linked identity yet — try to find by email
                $user = User::where('email', $email)->first();

                if ($user) {
                    // Auto-link existing account to Google identity
                    UserOauthIdentity::create([
                        'user_id'          => $user->id,
                        'provider'         => 'google',
                        'provider_user_id' => $sub,
                    ]);
                }
            }

            // 3. Jika email belum terdaftar sama sekali -> TIDAK auto-create
            // Kembalikan flag needs_registration agar diarahkan ke form pendaftaran
            if (! $user) {
                return [
                    'needs_registration' => true,
                    'email'              => $email,
                    'name'               => $name,
                    'google_sub'         => $sub,
                ];
            }

            // 4. Safety & status checks
            if ($user->role === 'super_admin') {
                throw new \RuntimeException('Akun Super Admin tidak dapat masuk melalui Google Sign-In.');
            }

            if ($user->status === 'inactive') {
                throw new \RuntimeException('Akun Anda tidak aktif. Hubungi admin untuk informasi lebih lanjut.');
            }

            if ($user->approval === 'pending') {
                throw new \RuntimeException('Akun Anda sedang menunggu persetujuan dari Super Admin.');
            }

            if ($user->approval === 'rejected') {
                throw new \RuntimeException('Pendaftaran akun Anda ditolak oleh Super Admin.');
            }

            // 5. Issue Sanctum token
            $token = $this->createToken($user, 'google-oauth');

            $user->loadMissing('farmerGroup');

            return [
                'needs_registration' => false,
                'user'               => $user,
                'token'              => $token,
                'is_new'             => false,
            ];
        });
    }
}
