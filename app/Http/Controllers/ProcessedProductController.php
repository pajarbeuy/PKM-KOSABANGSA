<?php

namespace App\Http\Controllers;

use App\Models\ProcessedProduct;
use App\Services\ProcessedProductService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProcessedProductController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly ProcessedProductService $processedProductService
    ) {}

    /**
     * List processed products owned by authenticated farmer.
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 15);
        $paginator = $this->processedProductService->listForOwner(
            $request->user()->id,
            $request->all(),
            $perPage
        );

        $items = collect($paginator->items())->map(fn ($p) => $this->processedProductService->formatProduct($p));

        return $this->successResponse([
            'products'   => $items,
            'pagination' => [
                'total'        => $paginator->total(),
                'per_page'     => $paginator->perPage(),
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
            ],
        ], 'Daftar produk olahan.');
    }

    /**
     * Create a new processed product (Farmer).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'        => 'required|string|max:255',
            'price'       => 'required|numeric|min:0',
            'stock'       => 'nullable|integer|min:0',
            'unit'        => 'nullable|string|in:pcs,kg',
            'description' => 'nullable|string|max:2000',
            'photo'       => 'nullable|image|max:4096',
            'status'      => 'nullable|in:active,out_of_stock,inactive',
        ], [
            'name.required'  => 'Nama produk olahan harus diisi.',
            'price.required' => 'Harga produk olahan harus diisi.',
            'price.min'      => 'Harga tidak boleh bernilai negatif.',
            'stock.min'      => 'Stok tidak boleh bernilai negatif.',
        ]);

        $product = $this->processedProductService->createForOwner(
            $request->user()->id,
            $validated,
            $request->file('photo')
        );

        return $this->successResponse(
            $this->processedProductService->formatProduct($product),
            'Produk olahan berhasil ditambahkan.',
            201
        );
    }

    /**
     * Show processed product details.
     */
    public function show(Request $request, ProcessedProduct $processedProduct): JsonResponse
    {
        // Petani can only see their own product; Super admin can see any product
        if ($request->user()->role !== 'super_admin' && $processedProduct->owner_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak melihat data produk olahan ini.');
        }

        return $this->successResponse(
            $this->processedProductService->formatProduct($processedProduct),
            'Detail produk olahan.'
        );
    }

    /**
     * Update processed product (Farmer).
     */
    public function update(Request $request, ProcessedProduct $processedProduct): JsonResponse
    {
        if ($processedProduct->owner_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak mengubah data produk olahan ini.');
        }

        $validated = $request->validate([
            'name'        => 'sometimes|required|string|max:255',
            'price'       => 'sometimes|required|numeric|min:0',
            'stock'       => 'sometimes|required|integer|min:0',
            'unit'        => 'nullable|string|in:pcs,kg',
            'description' => 'nullable|string|max:2000',
            'photo'       => 'nullable|image|max:4096',
            'status'      => 'sometimes|required|in:active,out_of_stock,inactive',
        ], [
            'name.required'  => 'Nama produk olahan harus diisi.',
            'price.required' => 'Harga produk olahan harus diisi.',
            'price.min'      => 'Harga tidak boleh bernilai negatif.',
            'stock.min'      => 'Stok tidak boleh bernilai negatif.',
        ]);

        $product = $this->processedProductService->updateForOwner(
            $processedProduct,
            $validated,
            $request->file('photo')
        );

        return $this->successResponse(
            $this->processedProductService->formatProduct($product),
            'Produk olahan berhasil diperbarui.'
        );
    }

    /**
     * Delete processed product (Farmer).
     */
    public function destroy(Request $request, ProcessedProduct $processedProduct): JsonResponse
    {
        if ($processedProduct->owner_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data produk olahan ini.');
        }

        $this->processedProductService->deleteForOwner($processedProduct);

        return $this->successResponse(null, 'Produk olahan berhasil dihapus.');
    }

    /**
     * Super Admin: View all processed products across all farmers (Marketing Management).
     */
    public function superAdminIndex(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 15);
        $paginator = $this->processedProductService->listForSuperAdmin($request->all(), $perPage);

        $items = collect($paginator->items())->map(fn ($p) => $this->processedProductService->formatProduct($p));

        return $this->successResponse([
            'products'   => $items,
            'pagination' => [
                'total'        => $paginator->total(),
                'per_page'     => $paginator->perPage(),
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
            ],
        ], 'Daftar seluruh produk olahan untuk manajemen pemasaran.');
    }

    /**
     * Super Admin: Update product status (active/out_of_stock/inactive).
     */
    public function superAdminUpdateStatus(Request $request, ProcessedProduct $processedProduct): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'required|in:active,out_of_stock,inactive',
        ]);

        $product = $this->processedProductService->updateStatusBySuperAdmin($processedProduct, $validated['status']);

        return $this->successResponse(
            $this->processedProductService->formatProduct($product),
            'Status produk olahan berhasil diperbarui.'
        );
    }

    /**
     * Public catalog: active and out_of_stock products (inactive hidden).
     */
    public function publicCatalog(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 12);
        $paginator = $this->processedProductService->getActiveCatalog($request->all(), $perPage);

        $items = collect($paginator->items())->map(fn ($p) => $this->processedProductService->formatProduct($p));

        return $this->successResponse([
            'products'   => $items,
            'pagination' => [
                'total'        => $paginator->total(),
                'per_page'     => $paginator->perPage(),
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
            ],
        ], 'Katalog publik produk olahan.');
    }
}
