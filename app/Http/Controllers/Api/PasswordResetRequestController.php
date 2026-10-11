<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PasswordResetRequestService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class PasswordResetRequestController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        protected PasswordResetRequestService $service
    ) {}

    /**
     * Submit password recovery request (Public).
     * POST /api/password-reset-requests
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'name'         => 'required|string|max:255',
                'farmer_group' => 'nullable|string|max:255',
            ], [
                'name.required' => 'Nama pengguna wajib diisi sesuai akun Anda.',
                'name.max'      => 'Nama pengguna tidak boleh lebih dari 255 karakter.',
            ]);

            $result = $this->service->createRequest(
                $validated,
                $request->ip(),
                $request->userAgent()
            );

            return $this->successResponse($result, $result['message'], 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        } catch (\Throwable $e) {
            \Log::error('Error pada PasswordResetRequestController@store: ' . $e->getMessage());
            return $this->errorResponse('Terjadi kesalahan saat memproses permintaan reset password.', 500);
        }
    }

    /**
     * List password reset requests for Super Admin.
     * GET /api/super-admin/password-reset-requests
     * GET /api/admin/password-reset-requests
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $filters = $request->only(['status', 'search']);
            $perPage = (int) $request->input('per_page', 15);

            $paginator = $this->service->listRequests($filters, $perPage);

            return response()->json([
                'success' => true,
                'message' => 'Daftar permintaan reset password.',
                'data'    => $paginator->items(),
                'pagination' => [
                    'current_page' => $paginator->currentPage(),
                    'last_page'    => $paginator->lastPage(),
                    'per_page'     => $paginator->perPage(),
                    'total'        => $paginator->total(),
                ],
            ]);
        } catch (\Throwable $e) {
            \Log::error('Error pada PasswordResetRequestController@index: ' . $e->getMessage());
            return $this->errorResponse('Terjadi kesalahan saat mengambil daftar permintaan reset password.', 500);
        }
    }

    /**
     * Get detail of a single password reset request (Super Admin).
     * GET /api/super-admin/password-reset-requests/{id}
     */
    public function show($id): JsonResponse
    {
        try {
            $item = $this->service->getRequestDetail((int) $id);
            return $this->successResponse($item, 'Detail permintaan reset password.');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFoundResponse('Permintaan reset password tidak ditemukan.');
        } catch (\Throwable $e) {
            \Log::error('Error pada PasswordResetRequestController@show: ' . $e->getMessage());
            return $this->errorResponse('Terjadi kesalahan saat mengambil detail permintaan.', 500);
        }
    }

    /**
     * Approve a password reset request (Super Admin).
     * POST /api/super-admin/password-reset-requests/{id}/approve
     */
    public function approve(Request $request, $id): JsonResponse
    {
        try {
            $request->validate([
                'user_id' => 'nullable|integer|exists:users,id',
            ]);

            $adminId = auth()->id();
            $approved = $this->service->approveRequest((int) $id, $adminId, $request->input('user_id'));

            return $this->successResponse($approved, 'Permintaan reset password berhasil disetujui.');
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFoundResponse('Permintaan atau akun pengguna tidak ditemukan.');
        } catch (\Throwable $e) {
            \Log::error('Error pada PasswordResetRequestController@approve: ' . $e->getMessage());
            return $this->errorResponse('Terjadi kesalahan saat menyetujui permintaan reset password.', 500);
        }
    }

    /**
     * Reject a password reset request (Super Admin).
     * POST /api/super-admin/password-reset-requests/{id}/reject
     */
    public function reject(Request $request, $id): JsonResponse
    {
        try {
            $request->validate([
                'reason' => 'nullable|string|max:1000',
            ]);

            $adminId = auth()->id();
            $rejected = $this->service->rejectRequest((int) $id, $adminId, $request->input('reason'));

            return $this->successResponse($rejected, 'Permintaan reset password berhasil ditolak.');
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFoundResponse('Permintaan reset password tidak ditemukan.');
        } catch (\Throwable $e) {
            \Log::error('Error pada PasswordResetRequestController@reject: ' . $e->getMessage());
            return $this->errorResponse('Terjadi kesalahan saat menolak permintaan reset password.', 500);
        }
    }

    /**
     * Generate 5-minute cryptographic token (Super Admin).
     * POST /api/super-admin/password-reset-requests/{id}/generate-token
     */
    public function generateToken($id): JsonResponse
    {
        try {
            $adminId = auth()->id();
            $result = $this->service->generateToken((int) $id, $adminId);

            return $this->successResponse($result, $result['message']);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFoundResponse('Permintaan reset password tidak ditemukan.');
        } catch (\Throwable $e) {
            \Log::error('Error pada PasswordResetRequestController@generateToken: ' . $e->getMessage());
            return $this->errorResponse('Terjadi kesalahan saat menghasilkan token reset password.', 500);
        }
    }

    /**
     * Confirm reset password with token (Public).
     * POST /api/password-reset/confirm
     */
    public function confirm(Request $request): JsonResponse
    {
        try {
            $request->validate([
                'token'                 => 'required|string',
                'password'              => 'required|string|min:8|confirmed',
                'password_confirmation' => 'required|string',
            ], [
                'token.required'        => 'Token reset password wajib diisi.',
                'password.required'     => 'Password baru wajib diisi.',
                'password.min'          => 'Password baru minimal 8 karakter.',
                'password.confirmed'    => 'Konfirmasi password tidak cocok dengan password baru.',
            ]);

            $result = $this->service->confirmReset($request->token, $request->password);

            return $this->successResponse(null, $result['message']);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        } catch (\Throwable $e) {
            \Log::error('Error pada PasswordResetRequestController@confirm: ' . $e->getMessage());
            return $this->errorResponse('Terjadi kesalahan saat mereset password.', 500);
        }
    }
}
