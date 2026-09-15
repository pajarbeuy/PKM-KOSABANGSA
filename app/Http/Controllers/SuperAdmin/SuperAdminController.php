<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\DashboardMenu;
use App\Models\User;
use App\Services\SuperAdminService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class SuperAdminController extends Controller
{
    use ApiResponseTrait;

    private const LANDING_SECTIONS = [
        'hero_title', 'hero_description', 'hero_cta_1', 'hero_cta_2',
        'feature_1_title', 'feature_1_desc', 'feature_2_title', 'feature_2_desc',
        'feature_3_title', 'feature_3_desc', 'feature_4_title', 'feature_4_desc',
        'feature_5_title', 'feature_5_desc', 'feature_6_title', 'feature_6_desc',
    ];

    public function __construct(private readonly SuperAdminService $superAdminService) {}

    // ─── Dashboard ────────────────────────────────────────────────────────────────

    public function dashboard()
    {
        return $this->successResponse(
            $this->superAdminService->getDashboardStats(),
            'Data dashboard super admin berhasil diambil.'
        );
    }

    // ─── User Management ─────────────────────────────────────────────────────────

    public function indexUsers()
    {
        return $this->successResponse($this->superAdminService->getAllUsers(), 'Daftar user berhasil diambil.');
    }

    public function storeUser(Request $request)
    {
        $validated = $request->validate([
            'name'      => 'required|string|max:255',
            'email'     => 'required|email|unique:users,email',
            'password'  => 'required|string|min:6',
            'phone'     => 'required|string|max:20',
            'farm_name' => 'required|string|max:255',
            'role'      => 'required|in:user,super_admin',
            'status'    => 'required|in:active,inactive',
        ]);

        $user = $this->superAdminService->createUser($validated);
        return $this->successResponse($user, 'User berhasil ditambahkan.', 201);
    }

    public function updateUser(Request $request, User $user)
    {
        $validated = $request->validate([
            'name'      => 'sometimes|required|string|max:255',
            'email'     => 'sometimes|required|email|unique:users,email,' . $user->id,
            'phone'     => 'sometimes|required|string|max:20',
            'farm_name' => 'sometimes|required|string|max:255',
            'role'      => 'sometimes|required|in:user,super_admin',
            'status'    => 'sometimes|required|in:active,inactive',
            'password'  => 'sometimes|string|min:6',
        ]);

        $updated = $this->superAdminService->updateUser($user, $validated);
        return $this->successResponse($updated, 'User berhasil diperbarui.');
    }

    public function destroyUser(User $user)
    {
        $error = $this->superAdminService->deleteUser($user);
        if ($error) {
            return $this->errorResponse($error, 422);
        }
        return $this->successResponse(null, 'User berhasil dihapus.');
    }

    public function impersonate(Request $request, User $user)
    {
        $token = $this->superAdminService->impersonate($user);
        if (!$token) {
            return $this->errorResponse('Tidak bisa impersonate super admin lain.', 422);
        }

        return $this->successResponse([
            'token' => $token,
            'user'  => $this->superAdminService->formatUser($user),
        ], 'Berhasil masuk sebagai ' . $user->name);
    }

    // ─── Landing Content ──────────────────────────────────────────────────────────

    public function getLanding()
    {
        return $this->successResponse(
            $this->superAdminService->getLandingContent(),
            'Konten landing page berhasil diambil.'
        );
    }

    public function updateLanding(Request $request)
    {
        $this->superAdminService->updateLandingContent(self::LANDING_SECTIONS, $request->all());
        $contents = $this->superAdminService->getLandingContent();
        return $this->successResponse($contents, 'Landing page berhasil diperbarui.');
    }

    // ─── Dashboard Menus ─────────────────────────────────────────────────────────

    public function indexMenus()
    {
        return $this->successResponse($this->superAdminService->getAllMenus(), 'Daftar menu dashboard berhasil diambil.');
    }

    public function storeMenu(Request $request)
    {
        $validated = $request->validate([
            'title'       => 'required|string|max:255',
            'icon'        => 'required|string|max:100',
            'color'       => 'required|regex:/^#[A-Fa-f0-9]{6}$/',
            'description' => 'required|string|max:500',
            'url'         => 'nullable|string|max:500',
            'sort_order'  => 'required|integer',
        ]);

        $menu = $this->superAdminService->createMenu($validated);
        return $this->successResponse($menu, 'Menu dashboard berhasil ditambahkan.', 201);
    }

    public function updateMenu(Request $request, DashboardMenu $menu)
    {
        $validated = $request->validate([
            'title'       => 'required|string|max:255',
            'icon'        => 'required|string|max:100',
            'color'       => 'required|regex:/^#[A-Fa-f0-9]{6}$/',
            'description' => 'required|string|max:500',
            'url'         => 'nullable|string|max:500',
            'sort_order'  => 'required|integer',
            'is_active'   => 'boolean',
        ]);

        $updated = $this->superAdminService->updateMenu($menu, $validated);
        return $this->successResponse($updated, 'Menu dashboard berhasil diperbarui.');
    }

    public function destroyMenu(DashboardMenu $menu)
    {
        $this->superAdminService->deleteMenu($menu);
        return $this->successResponse(null, 'Menu dashboard berhasil dihapus.');
    }
}