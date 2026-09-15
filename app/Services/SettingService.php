<?php

namespace App\Services;

use App\Models\Setting;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class SettingService
{
    /**
     * Get all settings for the given user.
     */
    public function getSettings(User $user): array
    {
        return [
            'user' => [
                'id'        => $user->id,
                'name'      => $user->name,
                'email'     => $user->email,
                'phone'     => $user->phone,
                'farm_name' => $user->farm_name,
                'role'      => $user->role,
                'status'    => $user->status,
            ],
            'min_stock'        => (int) Setting::get('min_stock', 100),
            'max_stock'        => (int) Setting::get('max_stock', 5000),
            'notify_low_stock' => (bool) Setting::get('notify_low_stock', 1),
            'notify_new_sale'  => (bool) Setting::get('notify_new_sale', 1),
            'notify_cost'      => (bool) Setting::get('notify_cost', 1),
        ];
    }

    /**
     * Update user profile fields.
     */
    public function updateProfile(User $user, array $data): User
    {
        $user->update($data);
        return $user;
    }

    /**
     * Update user password if current password matches.
     * Returns true on success, false if current password is wrong.
     */
    public function updatePassword(User $user, string $currentPassword, string $newPassword): bool
    {
        if (!Hash::check($currentPassword, $user->password)) {
            return false;
        }

        $user->update(['password' => Hash::make($newPassword)]);
        return true;
    }

    /**
     * Update warehouse (gudang) settings.
     */
    public function updateGudang(float $minStock, float $maxStock): void
    {
        Setting::set('min_stock', $minStock);
        Setting::set('max_stock', $maxStock);
    }

    /**
     * Update notification preferences.
     */
    public function updateNotifications(array $preferences): void
    {
        foreach ($preferences as $key => $value) {
            Setting::set($key, $value ? 1 : 0);
        }
    }

    /**
     * Permanently delete a user account and revoke all tokens.
     */
    public function deleteAccount(User $user): void
    {
        $user->tokens()->delete();
        $user->delete();
    }

    /**
     * Format a user profile for API response.
     */
    public function formatProfile(User $user): array
    {
        return [
            'id'        => $user->id,
            'name'      => $user->name,
            'email'     => $user->email,
            'phone'     => $user->phone,
            'farm_name' => $user->farm_name,
            'role'      => $user->role,
            'status'    => $user->status,
        ];
    }
}
