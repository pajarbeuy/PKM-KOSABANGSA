<?php

namespace App\Services;

use App\Models\FarmerGroup;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class FarmerGroupService
{
    /**
     * Get all active farmer groups for public/farmer dropdown selection.
     */
    public function getActiveGroups(): Collection
    {
        return FarmerGroup::active()->orderBy('id')->get();
    }

    /**
     * Get all farmer groups for Super Admin management, including member counts.
     */
    public function getAllForSuperAdmin(): Collection
    {
        return FarmerGroup::withCount('members')->orderBy('id')->get();
    }

    /**
     * Find farmer group by ID with loaded members.
     */
    public function getGroupWithMembers(int $id): ?FarmerGroup
    {
        return FarmerGroup::with(['members' => function ($query) {
            $query->orderBy('name');
        }])->find($id);
    }

    /**
     * Create a new farmer group (Super Admin only).
     */
    public function createGroup(array $data): FarmerGroup
    {
        return FarmerGroup::create([
            'name'        => trim($data['name']),
            'code'        => strtoupper(trim($data['code'])),
            'status'      => $data['status'] ?? 'active',
            'leader_name' => isset($data['leader_name']) ? trim($data['leader_name']) : null,
            'village'     => isset($data['village']) ? trim($data['village']) : null,
            'description' => isset($data['description']) ? trim($data['description']) : null,
        ]);
    }

    /**
     * Update an existing farmer group (Super Admin only).
     */
    public function updateGroup(FarmerGroup $group, array $data): FarmerGroup
    {
        $group->update(array_filter([
            'name'        => isset($data['name']) ? trim($data['name']) : $group->name,
            'code'        => isset($data['code']) ? strtoupper(trim($data['code'])) : $group->code,
            'status'      => $data['status'] ?? $group->status,
            'leader_name' => array_key_exists('leader_name', $data) ? trim($data['leader_name'] ?? '') : $group->leader_name,
            'village'     => array_key_exists('village', $data) ? trim($data['village'] ?? '') : $group->village,
            'description' => array_key_exists('description', $data) ? trim($data['description'] ?? '') : $group->description,
        ]));

        return $group->fresh();
    }

    /**
     * Assign or move a farmer to a specific Poktan (Super Admin only).
     */
    public function assignFarmerToGroup(User $farmer, int $farmerGroupId): User
    {
        $group = FarmerGroup::findOrFail($farmerGroupId);

        $farmer->farmer_group_id = $group->id;
        $farmer->save();

        return $farmer->fresh(['farmerGroup']);
    }

    /**
     * Format farmer group data for API response.
     */
    public function formatGroup(FarmerGroup $group, bool $includeMembers = false): array
    {
        $data = [
            'id'            => $group->id,
            'name'          => $group->name,
            'code'          => $group->code,
            'status'        => $group->status,
            'leader_name'   => $group->leader_name,
            'village'       => $group->village,
            'description'   => $group->description,
            'members_count' => $group->members_count ?? $group->members()->count(),
            'created_at'    => $group->created_at?->toIso8601String(),
        ];

        if ($includeMembers && $group->relationLoaded('members')) {
            $data['members'] = $group->members->map(function (User $member) {
                return [
                    'id'        => $member->id,
                    'name'      => $member->name,
                    'email'     => $member->email,
                    'phone'     => $member->phone,
                    'farm_name' => $member->farm_name,
                    'status'    => $member->status,
                ];
            })->toArray();
        }

        return $data;
    }
}
