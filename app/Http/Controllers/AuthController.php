<?php

namespace App\Http\Controllers;

use App\Services\AuthService;
use App\Services\GoogleOAuthService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly AuthService $authService,
        private readonly GoogleOAuthService $googleOAuthService,
    ) {}

    public function register(Request $request)
    {
        try {
            $validated = $request->validate([
                'farm_name'       => 'required|string|max:255',
                'name'            => 'required|string|max:255',
                'email'           => 'required|email|unique:users',
                'phone'           => 'required|string|max:20',
                'farmer_group_id' => 'required|integer|exists:farmer_groups,id',
                'password'        => 'required|string|min:8|confirmed',
                'google_sub'      => 'nullable|string',
            ]);

            $user = $this->authService->createUser($validated);

            if (!empty($validated['google_sub'])) {
                \App\Models\UserOauthIdentity::firstOrCreate(
                    [
                        'provider'         => 'google',
                        'provider_user_id' => $validated['google_sub'],
                    ],
                    [
                        'user_id' => $user->id,
                    ]
                );
            }

            try {
                $notifService = app(\App\Services\NotificationService::class);
                $notifService->notifySuperAdmins(
                    'user',
                    'Pendaftaran Petani Baru',
                    "Petani {$user->name} ({$user->farm_name}) telah mendaftar dan sedang menunggu persetujuan."
                );
            } catch (\Throwable $e) {}

            return $this->successResponse([
                'id'              => $user->id,
                'email'           => $user->email,
                'name'            => $user->name,
                'farm_name'       => $user->farm_name,
                'farmer_group_id' => $user->farmer_group_id,
                'status'          => $user->status,
                'approval'        => $user->approval,
            ], 'Pendaftaran berhasil! Akun Anda sedang menunggu persetujuan dari Super Admin.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function login(Request $request)
    {
        try {
            $validated = $request->validate([
                'email'    => 'required|email',
                'password' => 'required|string',
            ]);

            $user = $this->authService->attemptLogin($validated['email'], $validated['password']);

            if (!$user) {
                return $this->errorResponse('Email atau password salah.', 401);
            }

            if ($user->status === 'inactive') {
                return $this->errorResponse('Akun Anda tidak aktif.', 403);
            }

            $token = $this->authService->createToken($user);

            return $this->successResponse([
                'token'      => $token,
                'token_type' => 'Bearer',
                'user'       => $this->authService->formatUser($user),
            ], 'Login berhasil.');
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return $this->successResponse(null, 'Logout berhasil.');
    }

    public function me(Request $request)
    {
        $user = $request->user();
        return $this->successResponse(array_merge(
            $this->authService->formatUser($user),
            [
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ), 'Success.');
    }

    /**
     * POST /api/auth/google
     *
     * Accepts a Google ID Token from Flutter, verifies it at the backend,
     * then returns a Sanctum token for the matched/created local account.
     *
     * Request:  { "id_token": "<google_id_token>" }
     * Response: { success, message, data: { token, token_type, user, is_new_account } }
     */
    public function googleSignIn(Request $request)
    {
        try {
            $validated = $request->validate([
                'id_token' => 'required|string|min:10',
            ]);

            // 1. Verify the token with Google’s servers
            $googleClaims = $this->googleOAuthService->verify($validated['id_token']);

            // 2. Find / create local user and issue Sanctum token
            $result = $this->authService->loginWithGoogle($googleClaims);

            // Jika belum terdaftar -> minta pengguna lengkapi form register
            if (!empty($result['needs_registration'])) {
                return $this->successResponse([
                    'needs_registration' => true,
                    'email'              => $result['email'],
                    'name'               => $result['name'],
                    'google_sub'         => $result['google_sub'],
                ], 'Email Google belum terdaftar. Silakan lengkapi data pendaftaran Anda.');
            }

            $user  = $result['user'];
            $token = $result['token'];

            return $this->successResponse([
                'needs_registration' => false,
                'token'              => $token,
                'token_type'         => 'Bearer',
                'user'               => $this->authService->formatUser($user),
                'is_new_account'     => false,
            ], 'Login via Google berhasil.');

        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        } catch (\RuntimeException $e) {
            $msg = $e->getMessage();
            $code = (str_contains($msg, 'menunggu') || str_contains($msg, 'tidak aktif') || str_contains($msg, 'ditolak') || str_contains($msg, 'Super Admin')) ? 403 : 401;
            return $this->errorResponse($msg, $code);
        } catch (\Throwable $e) {
            report($e);
            return $this->errorResponse('Terjadi kesalahan saat memproses login Google. Coba lagi.', 500);
        }
    }
}
