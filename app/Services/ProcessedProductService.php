<?php

namespace App\Services;

use App\Models\ProcessedProduct;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ProcessedProductService
{
    /**
     * Get list of processed products owned by a specific farmer.
     */
    public function listForOwner(int $ownerId, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = ProcessedProduct::where('owner_id', $ownerId)->latest();

        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (!empty($filters['search'])) {
            $query->where('name', 'like', '%' . $filters['search'] . '%');
        }

        return $query->paginate($perPage);
    }

    /**
     * Get all processed products across all farmers for Super Admin marketing view.
     */
    public function listForSuperAdmin(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = ProcessedProduct::with('owner:id,name,email,phone,farm_name')->latest();

        if (!empty($filters['owner_id'])) {
            $query->where('owner_id', $filters['owner_id']);
        }

        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (!empty($filters['search'])) {
            $query->where('name', 'like', '%' . $filters['search'] . '%');
        }

        return $query->paginate($perPage);
    }

    /**
     * Get active and out-of-stock products for public catalog.
     * Inactive products are strictly excluded.
     */
    public function getActiveCatalog(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = ProcessedProduct::with('owner:id,name,farm_name,phone')
            ->forCatalog()
            ->latest();

        if (!empty($filters['search'])) {
            $query->where('name', 'like', '%' . $filters['search'] . '%');
        }

        return $query->paginate($perPage);
    }

    /**
     * Create a new processed product for a farmer.
     */
    public function createForOwner(int $ownerId, array $data, ?UploadedFile $photo = null): ProcessedProduct
    {
        if ($photo) {
            $data['photo'] = $photo->store('processed_products', 'public');
        }

        $stock = isset($data['stock']) ? (int) $data['stock'] : 0;
        $status = $data['status'] ?? ($stock > 0 ? 'active' : 'out_of_stock');

        return ProcessedProduct::create([
            'owner_id'    => $ownerId,
            'name'        => $data['name'],
            'price'       => $data['price'],
            'stock'       => $stock,
            'description' => $data['description'] ?? null,
            'photo'       => $data['photo'] ?? null,
            'status'      => $status,
        ]);
    }

    /**
     * Update an existing processed product for a farmer.
     */
    public function updateForOwner(ProcessedProduct $product, array $data, ?UploadedFile $photo = null): ProcessedProduct
    {
        if ($photo) {
            if ($product->photo && Storage::disk('public')->exists($product->photo)) {
                Storage::disk('public')->delete($product->photo);
            }
            $data['photo'] = $photo->store('processed_products', 'public');
        }

        $product->update($data);

        return $product->fresh();
    }

    /**
     * Delete a processed product owned by a farmer.
     */
    public function deleteForOwner(ProcessedProduct $product): void
    {
        if ($product->photo && Storage::disk('public')->exists($product->photo)) {
            Storage::disk('public')->delete($product->photo);
        }

        $product->delete();
    }

    /**
     * Super Admin updates product status (e.g. toggle active/inactive).
     */
    public function updateStatusBySuperAdmin(ProcessedProduct $product, string $status): ProcessedProduct
    {
        if (!in_array($status, ['active', 'out_of_stock', 'inactive'])) {
            throw new \InvalidArgumentException("Status {$status} tidak valid.");
        }

        // If trying to set active but stock is 0, status must be out_of_stock
        if ($status === 'active' && $product->stock === 0) {
            $status = 'out_of_stock';
        }

        $product->status = $status;
        $product->save();

        return $product->fresh();
    }

    /**
     * Decrement stock atomically when a sale is recorded by Super Admin.
     */
    public function decrementStock(ProcessedProduct $product, int $quantity): ProcessedProduct
    {
        if ($quantity <= 0) {
            throw new \InvalidArgumentException('Jumlah penjualan harus lebih dari 0.');
        }

        return DB::transaction(function () use ($product, $quantity) {
            // Lock row for update
            $lockedProduct = ProcessedProduct::where('id', $product->id)->lockForUpdate()->firstOrFail();

            if ($lockedProduct->stock < $quantity) {
                throw new \DomainException("Stok tidak mencukupi. Stok saat ini: {$lockedProduct->stock}.");
            }

            $lockedProduct->stock -= $quantity;
            $lockedProduct->save();

            return $lockedProduct;
        });
    }

    /**
     * Format a processed product for API responses.
     */
    public function formatProduct(ProcessedProduct $product): array
    {
        return [
            'id'          => $product->id,
            'owner_id'    => $product->owner_id,
            'owner_name'  => $product->owner?->name ?? 'Petani',
            'farm_name'   => $product->owner?->farm_name,
            'name'        => $product->name,
            'price'       => (float) $product->price,
            'stock'       => (int) $product->stock,
            'description' => $product->description,
            'photo'       => $product->photo,
            'photo_url'   => $product->photo_url,
            'status'      => $product->status,
            'created_at'  => $product->created_at?->toIso8601String(),
            'updated_at'  => $product->updated_at?->toIso8601String(),
        ];
    }
}
