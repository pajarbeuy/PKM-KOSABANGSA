<?php

namespace App\Services;

use App\Models\FarmerCommodity;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Validation\ValidationException;

class FarmerCommodityService
{
    /**
     * Get all commodities for a specific farmer.
     */
    public function getCommoditiesForFarmer(int $userId, bool $activeOnly = false): Collection
    {
        $query = FarmerCommodity::where('user_id', $userId)->orderBy('name');

        if ($activeOnly) {
            $query->active();
        }

        return $query->get();
    }

    /**
     * Get single commodity by ID with tenant guard.
     */
    public function getCommodityById(int $id, ?int $userId = null): ?FarmerCommodity
    {
        $query = FarmerCommodity::query();

        if ($userId !== null) {
            $query->where('user_id', $userId);
        }

        return $query->find($id);
    }

    /**
     * Create a new commodity for a farmer.
     */
    public function createCommodity(int $userId, array $data): FarmerCommodity
    {
        $name = trim($data['name']);

        // Invariant: Name must be unique PER FARMER, but can exist across different farmers
        $exists = FarmerCommodity::where('user_id', $userId)
            ->whereRaw('LOWER(name) = ?', [strtolower($name)])
            ->exists();

        if ($exists) {
            throw ValidationException::withMessages([
                'name' => ["Komoditas '{$name}' sudah terdaftar dalam daftar hasil tani Anda."],
            ]);
        }

        return FarmerCommodity::create([
            'user_id'     => $userId,
            'name'        => $name,
            'code'        => isset($data['code']) ? strtoupper(trim($data['code'])) : null,
            'unit'        => isset($data['unit']) ? strtolower(trim($data['unit'])) : 'kg',
            'description' => isset($data['description']) ? trim($data['description']) : null,
            'status'      => $data['status'] ?? 'active',
        ]);
    }

    /**
     * Update an existing commodity.
     */
    public function updateCommodity(FarmerCommodity $commodity, array $data): FarmerCommodity
    {
        if (isset($data['name'])) {
            $name = trim($data['name']);
            $exists = FarmerCommodity::where('user_id', $commodity->user_id)
                ->where('id', '!=', $commodity->id)
                ->whereRaw('LOWER(name) = ?', [strtolower($name)])
                ->exists();

            if ($exists) {
                throw ValidationException::withMessages([
                    'name' => ["Komoditas '{$name}' sudah digunakan pada data hasil tani lain."],
                ]);
            }
            $commodity->name = $name;
        }

        if (array_key_exists('code', $data)) {
            $commodity->code = $data['code'] ? strtoupper(trim($data['code'])) : null;
        }

        if (isset($data['unit'])) {
            $commodity->unit = strtolower(trim($data['unit']));
        }

        if (array_key_exists('description', $data)) {
            $commodity->description = $data['description'] ? trim($data['description']) : null;
        }

        if (isset($data['status'])) {
            $commodity->status = $data['status'];
        }

        $commodity->save();

        return $commodity->fresh();
    }

    /**
     * Delete a commodity.
     */
    public function deleteCommodity(FarmerCommodity $commodity): bool
    {
        // Business guard: check if harvests are attached
        $harvestCount = $commodity->harvests()->count();
        if ($harvestCount > 0) {
            throw new \InvalidArgumentException("Komoditas '{$commodity->name}' tidak dapat dihapus karena telah terhubung dengan {$harvestCount} data panen.");
        }

        return (bool) $commodity->delete();
    }

    /**
     * Super Admin: Get all commodities across all farmers with filters.
     */
    public function getAllCommoditiesForAdmin(array $filters = []): Collection
    {
        $query = FarmerCommodity::with(['user.farmerGroup'])
            ->orderBy('id', 'desc');

        if (!empty($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }

        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (!empty($filters['search'])) {
            $search = '%' . strtolower($filters['search']) . '%';
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(name) LIKE ?', [$search])
                  ->orWhereRaw('LOWER(code) LIKE ?', [$search])
                  ->orWhereHas('user', function ($uq) use ($search) {
                      $uq->whereRaw('LOWER(name) LIKE ?', [$search])
                         ->orWhereRaw('LOWER(farm_name) LIKE ?', [$search]);
                  });
            });
        }

        return $query->get();
    }

    /**
     * Format commodity for API response.
     */
    public function formatCommodity(FarmerCommodity $commodity, bool $includeFarmer = false): array
    {
        $data = [
            'id'          => $commodity->id,
            'user_id'     => $commodity->user_id,
            'name'        => $commodity->name,
            'code'        => $commodity->code,
            'unit'        => $commodity->unit,
            'description' => $commodity->description,
            'status'      => $commodity->status,
            'created_at'  => $commodity->created_at?->toIso8601String(),
            'updated_at'  => $commodity->updated_at?->toIso8601String(),
        ];

        if ($includeFarmer && $commodity->relationLoaded('user') && $commodity->user) {
            $data['farmer'] = [
                'id'           => $commodity->user->id,
                'name'         => $commodity->user->name,
                'email'        => $commodity->user->email,
                'farm_name'    => $commodity->user->farm_name,
                'farmer_group' => $commodity->user->farmerGroup ? [
                    'id'   => $commodity->user->farmerGroup->id,
                    'name' => $commodity->user->farmerGroup->name,
                    'code' => $commodity->user->farmerGroup->code,
                ] : null,
            ];
        }

        return $data;
    }
}
