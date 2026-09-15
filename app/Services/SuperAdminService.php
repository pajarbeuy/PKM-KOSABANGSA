<?php

namespace App\Services;

use App\Models\DashboardMenu;
use App\Models\LandingContent;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class SuperAdminService
{
    // ─── User Management ────────────────────────────────────────────────────────

    /**
     * List all users ordered by newest first.
     */
    public function getAllUsers()
    {
        return User::latest()->get();
    }

    /**
     * Create a new user (from super admin panel).
     */
    public function createUser(array $data): User
    {
        $data['password'] = Hash::make($data['password']);
        return User::create($data);
    }

    /**
     * Update an existing user.
     */
    public function updateUser(User $user, array $data): User
    {
        if (isset($data['password']) && $data['password']) {
            $data['password'] = Hash::make($data['password']);
        } else {
            unset($data['password']);
        }

        $user->update($data);
        return $user;
    }

    /**
     * Delete a user, preventing deletion of the last super admin.
     * Returns null on success, or an error message string on failure.
     */
    public function deleteUser(User $user): ?string
    {
        if ($user->role === 'super_admin' && User::where('role', 'super_admin')->count() === 1) {
            return 'Tidak bisa menghapus super admin terakhir.';
        }

        $user->delete();
        return null;
    }

    /**
     * Create an impersonation token for a target user (non-super-admin only).
     * Returns null if target is a super admin.
     */
    public function impersonate(User $user): ?string
    {
        if ($user->role === 'super_admin') {
            return null;
        }

        return $user->createToken('impersonate_token')->plainTextToken;
    }

    /**
     * Format user data for API response.
     */
    public function formatUser(User $user): array
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

    // ─── Landing Content ────────────────────────────────────────────────────────

    /**
     * Get all landing page content sections as a key→value map.
     */
    public function getLandingContent(): object|array
    {
        $contents = LandingContent::all()->pluck('content', 'section');
        return $contents->isEmpty() ? (object) [] : $contents;
    }

    /**
     * Update landing page sections using batch upsert.
     */
    public function updateLandingContent(array $sections, array $requestData): void
    {
        $upsertData = [];
        foreach ($sections as $section) {
            if (array_key_exists($section, $requestData)) {
                $upsertData[] = [
                    'section' => $section,
                    'content' => $requestData[$section],
                ];
            }
        }

        if (!empty($upsertData)) {
            LandingContent::upsert($upsertData, ['section'], ['content']);
        }
    }

    // ─── Dashboard Menus ────────────────────────────────────────────────────────

    /**
     * Get all dashboard menus ordered by sort_order.
     */
    public function getAllMenus()
    {
        return DashboardMenu::orderBy('sort_order')->get();
    }

    /**
     * Create a new dashboard menu.
     */
    public function createMenu(array $data): DashboardMenu
    {
        return DashboardMenu::create($data);
    }

    /**
     * Update a dashboard menu.
     */
    public function updateMenu(DashboardMenu $menu, array $data): DashboardMenu
    {
        $menu->update($data);
        return $menu;
    }

    /**
     * Delete a dashboard menu.
     */
    public function deleteMenu(DashboardMenu $menu): void
    {
        $menu->delete();
    }

    // ─── Dashboard Stats ─────────────────────────────────────────────────────────

    /**
     * Get super admin dashboard summary.
     */
    public function getDashboardStats(): array
    {
        return [
            'totalUsers'  => User::count(),
            'activeUsers' => User::where('status', 'active')->count(),
        ];
    }
}
