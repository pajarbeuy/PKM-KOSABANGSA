<?php

namespace App\Services;

use App\Models\FarmerGroup;
use App\Models\PasswordResetRequest;
use App\Models\PasswordResetRequestToken;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class PasswordResetRequestService
{
    /**
     * Submit a new password recovery request from user.
     */
    public function createRequest(array $data, ?string $ipAddress = null, ?string $userAgent = null): array
    {
        $name = trim($data['name'] ?? '');
        $farmerGroupName = isset($data['farmer_group']) ? trim($data['farmer_group']) : null;
        if (empty($farmerGroupName) && isset($data['farmer_group_name'])) {
            $farmerGroupName = trim($data['farmer_group_name']);
        }

        // Anti-spam check: prevent identical pending requests submitted within 5 minutes
        $recentPending = PasswordResetRequest::where('name', $name)
            ->where('status', 'pending')
            ->where('created_at', '>=', now()->subMinutes(5))
            ->first();

        if ($recentPending) {
            return [
                'success' => true,
                'message' => 'Permintaan reset password untuk nama ini sedang dalam antrean verifikasi Super Admin. Silakan hubungi admin.',
                'request_id' => $recentPending->id,
                'status' => 'pending',
            ];
        }

        // Identify matched farmer group if provided
        $farmerGroupId = null;
        if ($farmerGroupName) {
            $group = FarmerGroup::where('name', 'like', "%{$farmerGroupName}%")->first();
            if ($group) {
                $farmerGroupId = $group->id;
            }
        }

        // Look for candidate user in database
        $userQuery = User::whereRaw('LOWER(name) = ?', [strtolower($name)]);
        if ($farmerGroupId) {
            $userWithGroup = (clone $userQuery)->where('farmer_group_id', $farmerGroupId)->first();
            $matchedUser = $userWithGroup ?: $userQuery->first();
        } else {
            $matchedUser = $userQuery->first();
        }

        $request = PasswordResetRequest::create([
            'user_id' => $matchedUser?->id,
            'name' => $name,
            'farmer_group_name' => $farmerGroupName,
            'farmer_group_id' => $farmerGroupId ?: $matchedUser?->farmer_group_id,
            'status' => 'pending',
            'ip_address' => $ipAddress,
            'user_agent' => $userAgent ? Str::limit($userAgent, 500) : null,
        ]);

        return [
            'success' => true,
            'message' => 'Permintaan pemulihan akun berhasil diajukan. Silakan hubungi Super Admin untuk verifikasi identitas.',
            'request_id' => $request->id,
            'status' => 'pending',
        ];
    }

    /**
     * List password reset requests for Super Admin.
     */
    public function listRequests(array $filters = [], int $perPage = 15)
    {
        $query = PasswordResetRequest::with(['user.farmerGroup', 'admin', 'farmerGroup', 'activeToken'])
            ->latest('id');

        if (!empty($filters['status']) && $filters['status'] !== 'all') {
            $query->where('status', $filters['status']);
        }

        if (!empty($filters['search'])) {
            $search = trim($filters['search']);
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('farmer_group_name', 'like', "%{$search}%")
                  ->orWhereHas('user', function ($uq) use ($search) {
                      $uq->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%");
                  });
            });
        }

        return $query->paginate($perPage);
    }

    /**
     * Get detail of a single password reset request.
     */
    public function getRequestDetail(int $id): PasswordResetRequest
    {
        return PasswordResetRequest::with(['user.farmerGroup', 'admin', 'farmerGroup', 'tokens'])
            ->findOrFail($id);
    }

    /**
     * Approve a password reset request.
     */
    public function approveRequest(int $requestId, int $adminId, ?int $userId = null): PasswordResetRequest
    {
        return DB::transaction(function () use ($requestId, $adminId, $userId) {
            $request = PasswordResetRequest::lockForUpdate()->findOrFail($requestId);

            if ($request->status === 'completed') {
                throw ValidationException::withMessages([
                    'status' => ['Permintaan ini sudah selesai diproses dan tidak dapat disetujui ulang.'],
                ]);
            }

            if ($request->status === 'rejected') {
                throw ValidationException::withMessages([
                    'status' => ['Permintaan ini telah ditolak. Ubah status atau buat permintaan baru jika diperlukan.'],
                ]);
            }

            // Link specified user or ensure user exists
            if ($userId) {
                $user = User::findOrFail($userId);
                $request->user_id = $user->id;
            } elseif (!$request->user_id) {
                // Try finding matching user by name
                $matchedUser = User::whereRaw('LOWER(name) = ?', [strtolower($request->name)])->first();
                if ($matchedUser) {
                    $request->user_id = $matchedUser->id;
                } else {
                    throw ValidationException::withMessages([
                        'user_id' => ['Akun pengguna belum terhubung. Pilih akun pengguna yang valid untuk menyetujui permintaan ini.'],
                    ]);
                }
            }

            $request->status = 'approved';
            $request->admin_id = $adminId;
            $request->approved_at = now();
            $request->rejected_at = null;
            $request->rejection_reason = null;
            $request->save();

            return $request->load(['user.farmerGroup', 'admin', 'farmerGroup']);
        });
    }

    /**
     * Reject a password reset request.
     */
    public function rejectRequest(int $requestId, int $adminId, ?string $reason = null): PasswordResetRequest
    {
        return DB::transaction(function () use ($requestId, $adminId, $reason) {
            $request = PasswordResetRequest::lockForUpdate()->findOrFail($requestId);

            if ($request->status === 'completed') {
                throw ValidationException::withMessages([
                    'status' => ['Permintaan ini sudah selesai diproses dan tidak dapat ditolak.'],
                ]);
            }

            // Revoke any active tokens associated with this request
            PasswordResetRequestToken::where('request_id', $request->id)
                ->where('status', 'active')
                ->update([
                    'status' => 'revoked',
                    'revoked_at' => now(),
                    'revoked_by_admin_id' => $adminId,
                ]);

            $request->status = 'rejected';
            $request->admin_id = $adminId;
            $request->rejected_at = now();
            $request->rejection_reason = $reason ? trim($reason) : 'Ditolak oleh Super Admin.';
            $request->save();

            return $request->load(['user.farmerGroup', 'admin', 'farmerGroup']);
        });
    }

    /**
     * Generate 5-minute cryptographic token for an approved request.
     */
    public function generateToken(int $requestId, int $adminId): array
    {
        return DB::transaction(function () use ($requestId, $adminId) {
            $request = PasswordResetRequest::lockForUpdate()->findOrFail($requestId);

            if ($request->status !== 'approved') {
                throw ValidationException::withMessages([
                    'status' => ['Token hanya dapat dibuat untuk permintaan yang berstatus disetujui (approved).'],
                ]);
            }

            if (!$request->user_id) {
                throw ValidationException::withMessages([
                    'user_id' => ['Permintaan harus terhubung dengan akun pengguna yang telah diverifikasi.'],
                ]);
            }

            // Revoke all prior active tokens for this user and request
            PasswordResetRequestToken::where('user_id', $request->user_id)
                ->where('status', 'active')
                ->update([
                    'status' => 'revoked',
                    'revoked_at' => now(),
                    'revoked_by_admin_id' => $adminId,
                ]);

            // Generate cryptographically secure token (16 alphanumeric characters)
            $plainToken = Str::random(16);
            $tokenHash = hash('sha256', $plainToken);
            $expiresAt = now()->addMinutes(5);

            $tokenRecord = PasswordResetRequestToken::create([
                'request_id' => $request->id,
                'user_id' => $request->user_id,
                'token_hash' => $tokenHash,
                'status' => 'active',
                'expires_at' => $expiresAt,
            ]);

            // Return plain token once to Super Admin
            return [
                'token' => $plainToken,
                'expires_at' => $expiresAt->toIso8601String(),
                'validity_seconds' => 300,
                'request_id' => $request->id,
                'user_name' => $request->user?->name ?? $request->name,
                'message' => 'Token reset password berhasil dibuat. Salin dan berikan kepada pengguna. Token berlaku selama 5 menit.',
            ];
        });
    }

    /**
     * Confirm password reset using the token.
     */
    public function confirmReset(string $token, string $newPassword): array
    {
        $cleanToken = trim($token);
        if (empty($cleanToken)) {
            throw ValidationException::withMessages([
                'token' => ['Token reset password wajib diisi.'],
            ]);
        }

        $tokenHash = hash('sha256', $cleanToken);

        return DB::transaction(function () use ($tokenHash, $newPassword) {
            // Concurrency lock on token record
            $tokenRecord = PasswordResetRequestToken::where('token_hash', $tokenHash)
                ->lockForUpdate()
                ->first();

            if (!$tokenRecord) {
                throw ValidationException::withMessages([
                    'token' => ['Token reset password tidak valid atau tidak ditemukan.'],
                ]);
            }

            if ($tokenRecord->status === 'revoked' || $tokenRecord->revoked_at !== null) {
                throw ValidationException::withMessages([
                    'token' => ['Token reset password telah dicabut. Silakan hubungi Super Admin untuk meminta token baru.'],
                ]);
            }

            if ($tokenRecord->status === 'used' || $tokenRecord->used_at !== null) {
                throw ValidationException::withMessages([
                    'token' => ['Token reset password sudah pernah digunakan. Token hanya berlaku untuk satu kali pemakaian.'],
                ]);
            }

            if ($tokenRecord->isExpired() || $tokenRecord->status === 'expired') {
                $tokenRecord->status = 'expired';
                $tokenRecord->save();

                throw ValidationException::withMessages([
                    'token' => ['Token reset password sudah kedaluwarsa (masa berlaku 5 menit telah habis). Silakan hubungi Super Admin untuk meminta token baru.'],
                ]);
            }

            // Concurrency lock on request record
            $requestRecord = PasswordResetRequest::where('id', $tokenRecord->request_id)
                ->lockForUpdate()
                ->first();

            if (!$requestRecord || $requestRecord->status !== 'approved') {
                throw ValidationException::withMessages([
                    'token' => ['Permintaan reset password belum disetujui atau sudah tidak aktif.'],
                ]);
            }

            // Concurrency lock on user record
            $user = User::where('id', $tokenRecord->user_id)
                ->lockForUpdate()
                ->first();

            if (!$user) {
                throw ValidationException::withMessages([
                    'token' => ['Akun pengguna yang terkait dengan token ini tidak ditemukan.'],
                ]);
            }

            // Update user password securely
            $user->password = Hash::make($newPassword);
            $user->save();

            // Mark token as used
            $tokenRecord->status = 'used';
            $tokenRecord->used_at = now();
            $tokenRecord->save();

            // Mark request as completed
            $requestRecord->status = 'completed';
            $requestRecord->completed_at = now();
            $requestRecord->save();

            // Revoke all existing personal access tokens for security
            $user->tokens()->delete();

            // Trigger Laravel PasswordReset event
            event(new PasswordReset($user));

            return [
                'success' => true,
                'message' => 'Password akun Anda berhasil diperbarui. Silakan login menggunakan password baru.',
            ];
        });
    }
}
