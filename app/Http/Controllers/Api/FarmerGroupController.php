<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FarmerGroup;
use App\Models\User;
use App\Services\FarmerGroupService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FarmerGroupController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly FarmerGroupService $farmerGroupService
    ) {}

    /**
     * Public / Authenticated: Get active farmer groups for dropdown selection.
     */
    public function index(): JsonResponse
    {
        $groups = $this->farmerGroupService->getActiveGroups();
        $formatted = $groups->map(fn($g) => $this->farmerGroupService->formatGroup($g));

        return $this->successResponse($formatted, 'Daftar Kelompok Tani aktif.');
    }

    /**
     * Super Admin: Get all farmer groups with member counts.
     */
    public function adminIndex(): JsonResponse
    {
        $groups = $this->farmerGroupService->getAllForSuperAdmin();
        $formatted = $groups->map(fn($g) => $this->farmerGroupService->formatGroup($g));

        return $this->successResponse($formatted, 'Daftar seluruh Kelompok Tani.');
    }

    /**
     * Super Admin: Get details of a single farmer group including member list.
     */
    public function show(int $id): JsonResponse
    {
        $group = $this->farmerGroupService->getGroupWithMembers($id);

        if (!$group) {
            return $this->errorResponse('Kelompok Tani tidak ditemukan.', 404);
        }

        return $this->successResponse(
            $this->farmerGroupService->formatGroup($group, true),
            'Detail Kelompok Tani.'
        );
    }

    /**
     * Super Admin: Create a new farmer group.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'        => 'required|string|max:255',
            'code'        => 'required|string|max:50|unique:farmer_groups,code',
            'status'      => 'nullable|string|in:active,inactive',
            'leader_name' => 'nullable|string|max:255',
            'village'     => 'nullable|string|max:255',
            'description' => 'nullable|string',
        ]);

        $group = $this->farmerGroupService->createGroup($validated);

        return $this->successResponse(
            $this->farmerGroupService->formatGroup($group),
            'Kelompok Tani berhasil ditambahkan.',
            201
        );
    }

    /**
     * Super Admin: Update an existing farmer group.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $group = FarmerGroup::find($id);

        if (!$group) {
            return $this->errorResponse('Kelompok Tani tidak ditemukan.', 404);
        }

        $validated = $request->validate([
            'name'        => 'sometimes|required|string|max:255',
            'code'        => ['sometimes', 'required', 'string', 'max:50', Rule::unique('farmer_groups', 'code')->ignore($group->id)],
            'status'      => 'nullable|string|in:active,inactive',
            'leader_name' => 'nullable|string|max:255',
            'village'     => 'nullable|string|max:255',
            'description' => 'nullable|string',
        ]);

        $updated = $this->farmerGroupService->updateGroup($group, $validated);

        return $this->successResponse(
            $this->farmerGroupService->formatGroup($updated),
            'Kelompok Tani berhasil diperbarui.'
        );
    }

    /**
     * Super Admin: Delete a farmer group.
     */
    public function destroy(int $id): JsonResponse
    {
        $group = FarmerGroup::find($id);

        if (!$group) {
            return $this->errorResponse('Kelompok Tani tidak ditemukan.', 404);
        }

        try {
            $this->farmerGroupService->deleteGroup($group);
            return $this->successResponse(null, 'Kelompok Tani berhasil dihapus.');
        } catch (\InvalidArgumentException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        } catch (\Throwable $e) {
            return $this->errorResponse('Gagal menghapus Kelompok Tani: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Super Admin: Assign or move a farmer to a Poktan.
     */
    public function assignMember(Request $request, int $userId): JsonResponse
    {
        $validated = $request->validate([
            'farmer_group_id' => 'required|integer|exists:farmer_groups,id',
        ]);

        $user = User::find($userId);
        if (!$user) {
            return $this->errorResponse('Petani tidak ditemukan.', 404);
        }

        $updatedUser = $this->farmerGroupService->assignFarmerToGroup($user, $validated['farmer_group_id']);

        return $this->successResponse([
            'user_id'         => $updatedUser->id,
            'name'            => $updatedUser->name,
            'farmer_group_id' => $updatedUser->farmer_group_id,
            'farmer_group'    => $updatedUser->farmerGroup ? [
                'id'   => $updatedUser->farmerGroup->id,
                'name' => $updatedUser->farmerGroup->name,
                'code' => $updatedUser->farmerGroup->code,
            ] : null,
        ], 'Keanggotaan Kelompok Tani berhasil diperbarui.');
    }
}
