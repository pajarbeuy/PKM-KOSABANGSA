<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Services\SaleService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class SaleController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly SaleService $saleService) {}

    public function index(Request $request)
    {
        $userId   = $request->user()->id;
        $perPage  = $request->input('per_page', 15);
        $seasonId = $request->input('season_id');

        $query = Sale::where('user_id', $userId)->latest('date');
        if ($seasonId) $query->where('season_id', $seasonId);

        $sales        = $query->paginate($perPage);
        $totalSales   = Sale::where('user_id', $userId)->sum('total');
        $averagePrice = Sale::where('user_id', $userId)->avg('price_per_kg');

        return $this->successResponse([
            'sales'         => $sales->items(),
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

    public function store(Request $request)
    {
        $validated = $request->validate([
            'season_id'     => 'nullable|integer|exists:seasons,id',
            'quantity'      => 'required_without:weight_kg|numeric|min:0.01',
            'weight_kg'     => 'required_without:quantity|numeric|min:0.01',
            'price_per_unit'=> 'required_without:price_per_kg|numeric|min:0.01',
            'price_per_kg'  => 'required_without:price_per_unit|numeric|min:0.01',
            'sale_date'     => 'nullable|date',
            'date'          => 'nullable|date',
            'buyer_name'    => 'required|string|max:255',
            'buyer_phone'   => 'nullable|string|max:20',
            'buyer_address' => 'nullable|string|max:1000',
            'notes'         => 'nullable|string|max:1000',
            'status'        => 'nullable|string',
            'payment_status'=> 'nullable|in:paid,unpaid',
        ], [
            'buyer_name.required' => 'Nama pembeli harus diisi.',
            'buyer_name.max'      => 'Nama pembeli maksimal 255 karakter.',
        ]);

        $normalized = $this->saleService->normalizeData($validated);
        $userId     = $request->user()->id;

        if (!$this->saleService->hasSufficientStock($normalized['weight_kg'], $userId)) {
            $stock = $this->saleService->getCurrentStock($userId);
            return $this->errorResponse("Stok gudang tidak mencukupi. Sisa stok: {$stock} kg.", 422);
        }

        $sale = $this->saleService->createSale($normalized, $userId);

        return $this->successResponse(
            $this->saleService->formatSale($sale, 'created'),
            'Penjualan berhasil dicatat.',
            201
        );
    }

    public function update(Request $request, Sale $sale)
    {
        if ($sale->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak mengubah data ini.');
        }

        $validated = $request->validate([
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

        $newWeight = $validated['weight_kg'] ?? $validated['quantity'] ?? null;
        if ($newWeight !== null && $newWeight > $sale->weight_kg) {
            $difference = $newWeight - $sale->weight_kg;
            $stock      = $this->saleService->getCurrentStock($request->user()->id);
            if ($difference > $stock) {
                return $this->errorResponse("Stok gudang tidak mencukupi untuk penambahan ini. Sisa stok: {$stock} kg.", 422);
            }
        }

        $updated = $this->saleService->updateSale($sale, $validated, $request->user()->id);

        return $this->successResponse($this->saleService->formatSale($updated, 'updated'), 'Penjualan berhasil diperbarui.');
    }

    public function destroy(Request $request, Sale $sale)
    {
        if ($sale->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $this->saleService->deleteSale($sale, $request->user()->id);

        return $this->successResponse(null, 'Penjualan berhasil dihapus.');
    }
}
