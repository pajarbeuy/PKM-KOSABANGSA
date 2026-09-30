<?php

namespace App\Http\Controllers;

use App\Models\ProcessedProduct;
use App\Models\Sale;
use App\Models\Season;
use App\Services\SaleService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SaleController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly SaleService $saleService) {}

    public function index(Request $request): JsonResponse
    {
        $currentUser = $request->user();
        $perPage     = (int) $request->input('per_page', 15);
        $seasonId    = $request->input('season_id');
        $productType = $request->input('product_type');
        $farmerId    = $request->input('user_id');

        $query = Sale::with([
            'user:id,name,farm_name,phone',
            'processedProduct:id,name,price,stock',
            'commodity:id,name,unit',
            'season.commodity:id,name',
        ])->latest('date');

        if ($currentUser->role === 'super_admin') {
            if ($farmerId) {
                $query->where('user_id', $farmerId);
            }
        } else {
            // Petani can view their own sales (raw materials / harvest)
            $query->where('user_id', $currentUser->id);
            if (!$productType) {
                $query->where('product_type', 'harvest');
            }
        }

        if ($seasonId) {
            $query->where('season_id', $seasonId);
        }

        if ($productType) {
            $query->where('product_type', $productType);
        }

        $sales = $query->paginate($perPage);

        $aggregateTargetUserId = ($currentUser->role === 'super_admin' && !$farmerId) ? null : ($farmerId ?: $currentUser->id);

        $totalSales = $aggregateTargetUserId
            ? Sale::where('user_id', $aggregateTargetUserId)->sum('total')
            : Sale::sum('total');

        $averagePrice = $aggregateTargetUserId
            ? Sale::where('user_id', $aggregateTargetUserId)->avg('price_per_kg')
            : Sale::avg('price_per_kg');

        $items = collect($sales->items())->map(fn ($s) => $this->saleService->formatSale($s, 'show'));

        return $this->successResponse([
            'sales'         => $items,
            'pagination'    => [
                'total'        => $sales->total(),
                'per_page'     => $sales->perPage(),
                'current_page' => $sales->currentPage(),
                'last_page'    => $sales->lastPage(),
            ],
            'total_sales'   => (int) $totalSales,
            'average_price' => (int) $averagePrice,
        ], 'Daftar penjualan.');
    }

    public function store(Request $request): JsonResponse
    {
        $currentUser = $request->user();
        $productType = $request->input('product_type') ?? ($request->filled('processed_product_id') ? 'processed' : 'harvest');

        if ($productType === 'harvest') {
            // Pencatatan penjualan bahan baku dicatat oleh petani, bukan super admin
            if ($currentUser->role !== 'user') {
                return $this->forbiddenResponse('Pencatatan penjualan bahan baku dicatat oleh petani bersangkutan, bukan Super Admin.');
            }
            $farmerUserId = $currentUser->id;
        } else {
            // Pencatatan produk olahan dikelola oleh Super Admin
            if ($currentUser->role !== 'super_admin') {
                return $this->forbiddenResponse('Pencatatan penjualan produk olahan dikelola oleh Super Admin.');
            }
            $farmerUserId = $request->input('user_id');
        }

        $validated = $request->validate([
            'user_id'              => 'nullable|integer|exists:users,id',
            'product_type'         => 'nullable|in:harvest,processed',
            'commodity_id'         => 'nullable|integer|exists:farmer_commodities,id',
            'processed_product_id' => 'required_if:product_type,processed|nullable|integer|exists:processed_products,id',
            'season_id'            => 'nullable|integer|exists:seasons,id',
            'quantity'             => 'required_without:weight_kg|numeric|min:0.01',
            'weight_kg'            => 'required_without:quantity|numeric|min:0.01',
            'price_per_unit'       => 'required_without:price_per_kg|numeric|min:0.01',
            'price_per_kg'         => 'required_without:price_per_unit|numeric|min:0.01',
            'sale_date'            => 'nullable|date',
            'date'                 => 'nullable|date',
            'buyer_name'           => 'required|string|max:255',
            'buyer_phone'          => 'nullable|string|max:20',
            'buyer_address'        => 'nullable|string|max:1000',
            'notes'                => 'nullable|string|max:1000',
            'status'               => 'nullable|string',
            'payment_status'       => 'nullable|in:paid,unpaid',
        ], [
            'buyer_name.required'              => 'Nama pembeli harus diisi.',
            'buyer_name.max'                   => 'Nama pembeli maksimal 255 karakter.',
            'processed_product_id.required_if' => 'Produk olahan wajib dipilih untuk penjualan produk olahan.',
        ]);

        $normalized = $this->saleService->normalizeData($validated);

        if ($normalized['product_type'] === 'processed') {
            $product = ProcessedProduct::findOrFail($normalized['processed_product_id']);
            $farmerUserId = $product->owner_id;
        } else {
            $farmerUserId = $currentUser->id;

            if (!empty($normalized['commodity_id'])) {
                $commExists = \App\Models\FarmerCommodity::where('id', $normalized['commodity_id'])
                    ->where(function ($q) use ($farmerUserId) {
                        $q->where('user_id', $farmerUserId)->orWhereNull('user_id');
                    })->exists();
                if (!$commExists) {
                    return $this->forbiddenResponse('Komoditas bahan baku tidak ditemukan atau tidak aktif.');
                }
            }

            if (!empty($normalized['season_id'])) {
                $seasonExists = Season::where('id', $normalized['season_id'])->where('user_id', $farmerUserId)->exists();
                if (!$seasonExists) {
                    return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik petani bersangkutan.');
                }
            }
        }

        if (!$this->saleService->hasSufficientStock($normalized, $farmerUserId)) {
            $stock = $this->saleService->getCurrentStock($normalized, $farmerUserId);
            $unit = $normalized['product_type'] === 'processed' ? 'unit' : 'kg';
            return $this->errorResponse("Stok tidak mencukupi. Sisa stok: {$stock} {$unit}.", 422);
        }

        $sale = $this->saleService->createSale($normalized, $farmerUserId, $currentUser->id);

        return $this->successResponse(
            $this->saleService->formatSale($sale, 'created'),
            'Penjualan berhasil dicatat.',
            201
        );
    }

    public function show(Request $request, Sale $sale): JsonResponse
    {
        if ($request->user()->role !== 'super_admin' && $sale->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak melihat data ini.');
        }

        return $this->successResponse($this->saleService->formatSale($sale, 'show'), 'Detail penjualan.');
    }

    public function update(Request $request, Sale $sale): JsonResponse
    {
        $currentUser = $request->user();

        if ($sale->product_type === 'harvest') {
            if ($currentUser->role !== 'user' || $sale->user_id !== $currentUser->id) {
                return $this->forbiddenResponse('Hanya petani pemilik yang berhak mengubah transaksi penjualan bahan baku.');
            }
        } else {
            if ($currentUser->role !== 'super_admin') {
                return $this->forbiddenResponse('Hanya Super Admin yang berhak mengubah transaksi penjualan produk olahan.');
            }
        }

        $validated = $request->validate([
            'commodity_id'  => 'nullable|integer|exists:farmer_commodities,id',
            'season_id'     => 'sometimes|required|integer|exists:seasons,id',
            'quantity'      => 'sometimes|required_without:weight_kg|numeric|min:0.01',
            'weight_kg'     => 'sometimes|required_without:quantity|numeric|min:0.01',
            'price_per_unit'=> 'sometimes|required_without:price_per_kg|numeric|min:0.01',
            'price_per_kg'  => 'sometimes|required_without:price_per_unit|numeric|min:0.01',
            'sale_date'     => 'nullable|date',
            'date'          => 'nullable|date',
            'buyer_name'    => 'sometimes|required|string|max:255',
            'buyer_phone'   => 'nullable|string|max:20',
            'buyer_address' => 'nullable|string|max:1000',
            'notes'         => 'nullable|string|max:1000',
            'status'        => 'nullable|string',
            'payment_status'=> 'nullable|in:paid,unpaid',
        ], [
            'buyer_name.required' => 'Nama pembeli harus diisi.',
            'buyer_name.max'      => 'Nama pembeli maksimal 255 karakter.',
        ]);

        if (!empty($validated['season_id'])) {
            $seasonExists = Season::where('id', $validated['season_id'])->where('user_id', $sale->user_id)->exists();
            if (!$seasonExists) {
                return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik petani.');
            }
        }

        $newWeight = $validated['weight_kg'] ?? $validated['quantity'] ?? null;
        if ($newWeight !== null && $newWeight > $sale->weight_kg) {
            $difference = $newWeight - $sale->weight_kg;
            $stock = $this->saleService->getCurrentStock([
                'product_type'         => $sale->product_type,
                'processed_product_id' => $sale->processed_product_id,
            ], $sale->user_id);

            if ($difference > $stock) {
                $unit = $sale->product_type === 'processed' ? 'unit' : 'kg';
                return $this->errorResponse("Stok tidak mencukupi untuk penambahan ini. Sisa stok: {$stock} {$unit}.", 422);
            }
        }

        $updated = $this->saleService->updateSale($sale, $validated, $sale->user_id);

        return $this->successResponse($this->saleService->formatSale($updated, 'updated'), 'Penjualan berhasil diperbarui.');
    }

    public function destroy(Request $request, Sale $sale): JsonResponse
    {
        $currentUser = $request->user();

        if ($sale->product_type === 'harvest') {
            if ($currentUser->role !== 'user' || $sale->user_id !== $currentUser->id) {
                return $this->forbiddenResponse('Hanya petani pemilik yang berhak menghapus transaksi penjualan bahan baku.');
            }
        } else {
            if ($currentUser->role !== 'super_admin') {
                return $this->forbiddenResponse('Hanya Super Admin yang berhak menghapus transaksi penjualan produk olahan.');
            }
        }

        $this->saleService->deleteSale($sale);

        return $this->successResponse(null, 'Penjualan berhasil dihapus.');
    }
}
