<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MarketPrice;
use App\Services\MarketPrice\MockMarketPriceProvider;
use App\Services\MarketPriceIngestionService;
use App\Services\MarketPriceService;
use App\Traits\ApiResponseTrait;
use Carbon\Carbon;
use DomainException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class MarketPriceController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly MarketPriceService $marketPriceService,
        private readonly MarketPriceIngestionService $ingestionService
    ) {}

    /**
     * Menampilkan daftar harga pasar acuan (dapat diakses Petani & Super Admin).
     */
    public function index(Request $request)
    {
        $perPage     = (int) $request->input('per_page', 15);
        $commodityId = $request->input('commodity_id');
        $fromDate    = $request->input('from_date');
        $toDate      = $request->input('to_date');

        $query = MarketPrice::with(['commodity', 'creator'])->orderBy('effective_date', 'desc');

        if ($commodityId) {
            $query->where('commodity_id', $commodityId);
        }
        if ($fromDate) {
            $query->where('effective_date', '>=', $fromDate);
        }
        if ($toDate) {
            $query->where('effective_date', '<=', $toDate);
        }

        $paginated = $query->paginate($perPage);

        $items = collect($paginated->items())->map(function ($price) {
            return $this->marketPriceService->formatMarketPrice($price);
        });

        return $this->successResponse([
            'market_prices' => $items,
            'pagination'    => [
                'total'        => $paginated->total(),
                'per_page'     => $paginated->perPage(),
                'current_page' => $paginated->currentPage(),
                'last_page'    => $paginated->lastPage(),
            ],
        ], 'Daftar harga pasar acuan berhasil diambil.');
    }

    /**
     * Mengambil harga pasar efektif terkini untuk suatu komoditas.
     */
    public function latest(Request $request, int $commodityId)
    {
        $targetDate = $request->input('date', now()->toDateString());
        $price = $this->marketPriceService->findEffectivePrice($commodityId, $targetDate);

        if (!$price) {
            return $this->successResponse(null, 'Belum ada harga pasar yang berlaku untuk komoditas ini.');
        }

        return $this->successResponse(
            $this->marketPriceService->formatMarketPrice($price),
            'Harga pasar efektif terkini ditemukan.'
        );
    }

    /**
     * Menambah master harga pasar baru (Super Admin only).
     */
    public function store(Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return $this->errorResponse('Akses ditolak. Hanya Super Admin yang diizinkan mengelola master harga pasar.', 403);
        }

        $validator = Validator::make($request->all(), [
            'commodity_id'   => 'required|exists:farmer_commodities,id',
            'price'          => 'required|numeric|min:0',
            'unit'           => 'nullable|string|max:20',
            'effective_date' => 'required|date',
            'source'         => 'nullable|string|max:100',
            'notes'          => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator->errors());
        }

        try {
            $price = $this->marketPriceService->createMarketPrice($validator->validated(), $request->user()->id);
            return $this->successResponse(
                $this->marketPriceService->formatMarketPrice($price),
                'Harga pasar acuan berhasil ditambahkan.',
                201
            );
        } catch (\Illuminate\Database\QueryException $e) {
            if (str_contains($e->getMessage(), 'Duplicate entry') || $e->errorInfo[1] == 1062) {
                return $this->errorResponse('Harga pasar untuk komoditas dan tanggal efektif tersebut sudah ada.', 422);
            }
            throw $e;
        } catch (DomainException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        }
    }

    /**
     * Memperbarui record harga pasar (Super Admin only).
     */
    public function update(Request $request, int $id)
    {
        if ($request->user()->role !== 'super_admin') {
            return $this->errorResponse('Akses ditolak. Hanya Super Admin yang diizinkan mengelola master harga pasar.', 403);
        }

        $marketPrice = MarketPrice::find($id);
        if (!$marketPrice) {
            return $this->errorResponse('Data harga pasar tidak ditemukan.', 404);
        }

        $validator = Validator::make($request->all(), [
            'commodity_id'   => 'sometimes|exists:farmer_commodities,id',
            'price'          => 'sometimes|numeric|min:0',
            'unit'           => 'nullable|string|max:20',
            'effective_date' => 'sometimes|date',
            'source'         => 'nullable|string|max:100',
            'notes'          => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator->errors());
        }

        try {
            $updated = $this->marketPriceService->updateMarketPrice($marketPrice, $validator->validated());
            return $this->successResponse(
                $this->marketPriceService->formatMarketPrice($updated),
                'Harga pasar acuan berhasil diperbarui.'
            );
        } catch (\Illuminate\Database\QueryException $e) {
            if (str_contains($e->getMessage(), 'Duplicate entry') || $e->errorInfo[1] == 1062) {
                return $this->errorResponse('Harga pasar untuk komoditas dan tanggal efektif tersebut sudah ada.', 422);
            }
            throw $e;
        } catch (DomainException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        }
    }

    /**
     * Menghapus record harga pasar (Super Admin only).
     */
    public function destroy(Request $request, int $id)
    {
        if ($request->user()->role !== 'super_admin') {
            return $this->errorResponse('Akses ditolak. Hanya Super Admin yang diizinkan mengelola master harga pasar.', 403);
        }

        $marketPrice = MarketPrice::find($id);
        if (!$marketPrice) {
            return $this->errorResponse('Data harga pasar tidak ditemukan.', 404);
        }

        try {
            $this->marketPriceService->deleteMarketPrice($marketPrice);
            return $this->successResponse(null, 'Harga pasar acuan berhasil dihapus.');
        } catch (DomainException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        }
    }

    /**
     * Trigger sinkronisasi/ingestion harga pasar dari mock/real provider (Super Admin only).
     */
    public function ingest(Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return $this->errorResponse('Akses ditolak. Hanya Super Admin yang diizinkan melakukan sinkronisasi harga pasar.', 403);
        }

        $dateParam = $request->input('date');
        $date = $dateParam ? Carbon::parse($dateParam) : null;

        $provider = new \App\Services\MarketPrice\MockMarketPriceProvider();
        $stats = $this->ingestionService->ingestFromProvider($provider, $date, $request->user()->id);

        return $this->successResponse($stats, 'Sinkronisasi harga pasar berhasil dijalankan.');
    }
}
