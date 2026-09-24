<?php

namespace App\Http\Controllers;

use App\Services\AuthService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly AuthService $authService) {}

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
            ]);

            $user = $this->authService->createUser($validated);

            return $this->successResponse([
                'id'              => $user->id,
                'email'           => $user->email,
                'name'            => $user->name,
                'farm_name'       => $user->farm_name,
                'farmer_group_id' => $user->farmer_group_id,
                'status'          => 'active',
            ], 'Pendaftaran berhasil! Silakan masuk.', 201);
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
}
