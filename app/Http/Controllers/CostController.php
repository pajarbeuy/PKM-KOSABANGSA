<?php

namespace App\Http\Controllers;

use App\Models\ProductionCost;
use App\Models\Season;
use App\Services\CostService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class CostController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly CostService $costService) {}

    public function index(Request $request)
    {
        $userId             = $request->user()->id;
        $perPage            = (int) $request->input('per_page', 15);
        $seasonId           = $request->input('season_id');
        $processedProductId = $request->input('processed_product_id');
        $costType           = $request->input('cost_type');

        $query = ProductionCost::where('user_id', $userId)
            ->with(['season', 'season.commodity', 'processedProduct', 'rawMaterialHarvest'])
            ->latest('date')
            ->latest('id');

        if ($costType && in_array($costType, ['farm', 'processing'])) {
            $query->where('cost_type', $costType);
        }
        if ($seasonId) {
            $query->where('season_id', $seasonId);
        }
        if ($processedProductId) {
            $query->where('processed_product_id', $processedProductId);
        }

        $costs = $query->paginate($perPage);

        $totalQuery = ProductionCost::where('user_id', $userId);
        if ($costType && in_array($costType, ['farm', 'processing'])) {
            $totalQuery->where('cost_type', $costType);
        }
        $totalCost      = (float) $totalQuery->sum('amount');
        $costByCategory = ProductionCost::getCostByCategory($userId, $costType);

        $formattedCosts = collect($costs->items())->map(fn ($c) => $this->costService->formatCost($c));

        return $this->successResponse([
            'costs'            => $formattedCosts,
            'pagination'       => [
                'total'        => $costs->total(),
                'per_page'     => $costs->perPage(),
                'current_page' => $costs->currentPage(),
                'last_page'    => $costs->lastPage(),
            ],
            'total_cost'       => $totalCost,
            'cost_by_category' => $costByCategory,
        ], 'Daftar biaya produksi.');
    }

    public function store(Request $request)
    {
        try {
            $costType = $request->input('cost_type', 'farm');

            $categoryRule = $costType === 'processing'
                ? 'required|string|in:raw_material_addon,packaging,utility,labor,other'
                : 'required|string|in:seed,fertilizer,pesticide,other';

            $rules = [
                'cost_type'               => 'nullable|in:farm,processing',
                'date'                    => 'required|date',
                'category'                => $categoryRule,
                'amount'                  => 'required|numeric|min:0.01',
                'notes'                   => 'nullable|string|max:255',
                'season_id'               => 'nullable|exists:seasons,id',
                'processed_product_id'    => 'nullable|exists:processed_products,id',
                'raw_material_harvest_id' => 'nullable|exists:harvests,id',
                'raw_material_weight_kg'  => 'nullable|numeric|min:0',
                'item_name'               => 'nullable|string|max:150',
                'quantity'                => 'nullable|numeric|min:0',
                'unit'                    => 'nullable|string|max:50',
                'price_per_unit'          => 'nullable|numeric|min:0',
            ];

            if ($costType === 'processing') {
                $rules['processed_product_id'] = 'required|exists:processed_products,id';
            }

            $validated = $request->validate($rules);
            $validated['cost_type'] = $costType;

            // Verify season ownership if provided
            if (!empty($validated['season_id'])) {
                $seasonExists = Season::where('id', $validated['season_id'])->where('user_id', $request->user()->id)->exists();
                if (!$seasonExists) {
                    return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik Anda.');
                }
            }

            // Verify processed product ownership if provided
            if (!empty($validated['processed_product_id'])) {
                $productExists = \App\Models\ProcessedProduct::where('id', $validated['processed_product_id'])
                    ->where('owner_id', $request->user()->id)
                    ->exists();
                if (!$productExists) {
                    return $this->forbiddenResponse('Produk olahan tidak ditemukan atau bukan milik Anda.');
                }
            }

            // Verify harvest ownership if provided
            if (!empty($validated['raw_material_harvest_id'])) {
                $harvestExists = \App\Models\Harvest::where('id', $validated['raw_material_harvest_id'])
                    ->where('user_id', $request->user()->id)
                    ->exists();
                if (!$harvestExists) {
                    return $this->forbiddenResponse('Panen acuan tidak ditemukan atau bukan milik Anda.');
                }
            }

            $cost      = $this->costService->createCost($validated, $request->user()->id);
            $formatted = array_merge($this->costService->formatCost($cost), ['created_at' => $cost->created_at]);

            return $this->successResponse($formatted, 'Biaya produksi berhasil ditambahkan.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function show(Request $request, ProductionCost $cost)
    {
        if ($cost->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak melihat data ini.');
        }

        $formatted = array_merge($this->costService->formatCost($cost), [
            'created_at' => $cost->created_at,
            'updated_at' => $cost->updated_at,
        ]);

        return $this->successResponse($formatted, 'Detail biaya produksi.');
    }

    public function update(Request $request, ProductionCost $cost)
    {
        try {
            if ($cost->user_id !== $request->user()->id) {
                return $this->forbiddenResponse('Anda tidak berhak mengubah data ini.');
            }

            $costType = $request->input('cost_type', $cost->cost_type ?? 'farm');

            $categoryRule = $costType === 'processing'
                ? 'required|string|in:raw_material_addon,packaging,utility,labor,other'
                : 'required|string|in:seed,fertilizer,pesticide,other';

            $rules = [
                'cost_type'               => 'nullable|in:farm,processing',
                'date'                    => 'required|date',
                'category'                => $categoryRule,
                'amount'                  => 'required|numeric|min:0.01',
                'notes'                   => 'nullable|string|max:255',
                'season_id'               => 'nullable|exists:seasons,id',
                'processed_product_id'    => 'nullable|exists:processed_products,id',
                'raw_material_harvest_id' => 'nullable|exists:harvests,id',
                'raw_material_weight_kg'  => 'nullable|numeric|min:0',
                'item_name'               => 'nullable|string|max:150',
                'quantity'                => 'nullable|numeric|min:0',
                'unit'                    => 'nullable|string|max:50',
                'price_per_unit'          => 'nullable|numeric|min:0',
            ];

            if ($costType === 'processing') {
                $rules['processed_product_id'] = 'required|exists:processed_products,id';
            }

            $validated = $request->validate($rules);
            $validated['cost_type'] = $costType;

            if (!empty($validated['season_id'])) {
                $seasonExists = Season::where('id', $validated['season_id'])->where('user_id', $request->user()->id)->exists();
                if (!$seasonExists) {
                    return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik Anda.');
                }
            }

            if (!empty($validated['processed_product_id'])) {
                $productExists = \App\Models\ProcessedProduct::where('id', $validated['processed_product_id'])
                    ->where('owner_id', $request->user()->id)
                    ->exists();
                if (!$productExists) {
                    return $this->forbiddenResponse('Produk olahan tidak ditemukan atau bukan milik Anda.');
                }
            }

            if (!empty($validated['raw_material_harvest_id'])) {
                $harvestExists = \App\Models\Harvest::where('id', $validated['raw_material_harvest_id'])
                    ->where('user_id', $request->user()->id)
                    ->exists();
                if (!$harvestExists) {
                    return $this->forbiddenResponse('Panen acuan tidak ditemukan atau bukan milik Anda.');
                }
            }

            $updated   = $this->costService->updateCost($cost, $validated);
            $formatted = array_merge($this->costService->formatCost($updated), ['updated_at' => $updated->updated_at]);

            return $this->successResponse($formatted, 'Biaya produksi berhasil diperbarui.');
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function destroy(Request $request, ProductionCost $cost)
    {
        if ($cost->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $this->costService->deleteCost($cost);
        return $this->successResponse(null, 'Biaya produksi berhasil dihapus.');
    }
}
