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
            'unit'        => $data['unit'] ?? 'pcs',
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
     * Convert raw harvest weight into processed product raw material,
     * decrement warehouse harvest stock, increment processed stock, and record processing costs.
     */
    public function convertHarvestToProcessedProduct(
        ProcessedProduct $product,
        \App\Models\Harvest $harvest,
        float $rawWeightKg,
        int $additionalStock = 0,
        array $costItems = []
    ): array {
        if ($rawWeightKg <= 0) {
            throw new \InvalidArgumentException('Bobot bahan baku panen harus lebih dari 0.');
        }

        if ($harvest->user_id !== $product->owner_id) {
            throw new \DomainException('Data panen tidak sesuai dengan pemilik produk olahan.');
        }

        return DB::transaction(function () use ($product, $harvest, $rawWeightKg, $additionalStock, $costItems) {
            // Check sufficiency of raw harvest stock in warehouse
            $currentRawBalance = \App\Models\StockTransaction::getCurrentBalance($product->owner_id);
            if ($currentRawBalance < $rawWeightKg) {
                throw new \DomainException("Stok panen mentah di gudang tidak mencukupi ({$currentRawBalance} kg tersedia, dibutuhkan {$rawWeightKg} kg).");
            }

            // 1. Decrement raw harvest warehouse stock (Rp 0 raw material cash cost because it was already funded by farm cost)
            \App\Models\StockTransaction::addTransaction(
                'out',
                $rawWeightKg,
                "Bahan Baku Olahan: {$product->name} (dari Panen #{$harvest->id})",
                'harvest_convert_' . $harvest->id,
                $product->owner_id
            );

            // 2. Update processed product model
            $product->harvest_id = $harvest->id;
            $product->raw_material_weight_kg = (float) ($product->raw_material_weight_kg ?? 0) + $rawWeightKg;

            if ($additionalStock > 0) {
                $product->stock += $additionalStock;
                \App\Models\StockTransaction::recordProcessedProductTransaction(
                    $product,
                    'in',
                    $additionalStock,
                    "Hasil Produksi Olahan ({$rawWeightKg} kg bahan baku)",
                    'produce_stock_' . $harvest->id,
                    $product->owner_id
                );
            }

            $product->save();

            // 3. Record processing costs (modal bahan penolong: tepung, minyak, bumbu, packaging)
            $createdCosts = [];

            // Record raw material harvest entry (Rp 0 to prevent double-counting)
            $rawEntry = \App\Models\ProductionCost::create([
                'user_id'                 => $product->owner_id,
                'cost_type'               => 'processing',
                'date'                    => now()->toDateString(),
                'season_id'               => null,
                'processed_product_id'    => $product->id,
                'raw_material_harvest_id' => $harvest->id,
                'raw_material_weight_kg'  => $rawWeightKg,
                'category'                => 'raw_material_addon',
                'item_name'               => 'Bahan Baku Panen: ' . ($harvest->commodity?->name ?? ('Panen #' . $harvest->id)),
                'quantity'                => $rawWeightKg,
                'unit'                    => $harvest->unit ?? 'kg',
                'price_per_unit'          => 0.00,
                'amount'                  => 0.00,
                'notes'                   => "Pengalihan {$rawWeightKg} kg dari panen #{$harvest->id} ke produk olahan (bebas double-counting)",
            ]);
            $createdCosts[] = $rawEntry;

            foreach ($costItems as $item) {
                $qty = isset($item['quantity']) ? (float) $item['quantity'] : null;
                $pricePerUnit = isset($item['price_per_unit']) ? (float) $item['price_per_unit'] : null;
                $amount = isset($item['amount'])
                    ? (float) $item['amount']
                    : ($qty && $pricePerUnit ? round($qty * $pricePerUnit, 2) : 0.0);

                if ($amount <= 0) {
                    continue;
                }

                $cost = \App\Models\ProductionCost::create([
                    'user_id'                 => $product->owner_id,
                    'cost_type'               => 'processing',
                    'date'                    => $item['date'] ?? now()->toDateString(),
                    'season_id'               => null,
                    'processed_product_id'    => $product->id,
                    'raw_material_harvest_id' => $harvest->id,
                    'raw_material_weight_kg'  => $rawWeightKg,
                    'category'                => $item['category'] ?? 'raw_material_addon',
                    'item_name'               => $item['item_name'] ?? null,
                    'quantity'                => $qty,
                    'unit'                    => $item['unit'] ?? null,
                    'price_per_unit'          => $pricePerUnit,
                    'amount'                  => $amount,
                    'notes'                   => $item['notes'] ?? null,
                ]);

                $createdCosts[] = $cost;
            }

            return [
                'product'                => $this->formatProduct($product->fresh()),
                'converted_weight_kg'    => $rawWeightKg,
                'additional_stock'       => $additionalStock,
                'raw_harvest_remaining'  => \App\Models\StockTransaction::getCurrentBalance($product->owner_id),
                'processing_costs_added' => count($createdCosts),
                'total_processing_cost'  => (float) $product->fresh()->total_processing_cost,
            ];
        });
    }

    /**
     * Format a processed product for API responses.
     */
    public function formatProduct(ProcessedProduct $product): array
    {
        return [
            'id'                     => $product->id,
            'owner_id'               => $product->owner_id,
            'owner_name'             => $product->owner?->name ?? 'Petani',
            'farm_name'              => $product->owner?->farm_name,
            'harvest_id'             => $product->harvest_id,
            'name'                   => $product->name,
            'price'                  => (float) $product->price,
            'stock'                  => (int) $product->stock,
            'unit'                   => $product->unit ?? 'pcs',
            'raw_material_weight_kg' => (float) ($product->raw_material_weight_kg ?? 0),
            'total_processing_cost'  => (float) $product->total_processing_cost,
            'total_sales_revenue'    => (float) $product->total_sales_revenue,
            'profit_loss'            => (float) $product->profit_loss,
            'description'            => $product->description,
            'photo'                  => $product->photo,
            'photo_url'              => $product->photo_url,
            'status'                 => $product->status,
            'created_at'             => $product->created_at?->toIso8601String(),
            'updated_at'             => $product->updated_at?->toIso8601String(),
        ];
    }
}
