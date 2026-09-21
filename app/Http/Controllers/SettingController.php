<?php

namespace App\Http\Controllers;

use App\Services\SettingService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly SettingService $settingService) {}

    public function index(Request $request)
    {
        return $this->successResponse(
            $this->settingService->getSettings($request->user()),
            'Pengaturan berhasil diambil.'
        );
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name'      => 'required|string|max:255',
            'email'     => 'required|email|unique:users,email,' . $user->id,
            'phone'     => 'required|string|max:20',
            'farm_name' => 'nullable|string|max:255',
        ]);

        $updated = $this->settingService->updateProfile($user, $validated);

        return $this->successResponse($this->settingService->formatProfile($updated), 'Profil berhasil diperbarui.');
    }

    public function updatePassword(Request $request)
    {
        $validated = $request->validate([
            'current_password' => 'required|string',
            'password'         => 'required|string|min:8|confirmed',
        ], [
            'password.min'       => 'Password baru minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi password baru tidak cocok.',
        ]);

        $success = $this->settingService->updatePassword(
            $request->user(),
            $validated['current_password'],
            $validated['password']
        );

        if (!$success) {
            return $this->errorResponse('Password saat ini tidak sesuai.', 422);
        }

        return $this->successResponse(null, 'Password berhasil diperbarui.');
    }

    public function updateGudang(Request $request)
    {
        $validated = $request->validate([
            'min_stock' => 'required|numeric|min:1',
            'max_stock' => 'required|numeric|min:1',
        ]);

        $this->settingService->updateGudang($validated['min_stock'], $validated['max_stock']);

        return $this->successResponse([
            'min_stock' => (int) $validated['min_stock'],
            'max_stock' => (int) $validated['max_stock'],
        ], 'Pengaturan gudang berhasil diperbarui.');
    }

    public function updateNotifications(Request $request)
    {
        $validated = $request->validate([
            'notify_low_stock' => 'required|boolean',
            'notify_new_sale'  => 'required|boolean',
            'notify_cost'      => 'required|boolean',
        ]);

        $this->settingService->updateNotifications($validated);

        return $this->successResponse($validated, 'Pengaturan notifikasi berhasil diperbarui.');
    }

    public function deleteAccount(Request $request)
    {
        $this->settingService->deleteAccount($request->user());
        return $this->successResponse(null, 'Akun berhasil dihapus.');
    }
}
