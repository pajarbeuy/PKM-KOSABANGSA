<?php

namespace App\Http\Controllers;

use App\Models\ProcessedProduct;
use App\Models\User;
use App\Services\ProcessedProductService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class WebController extends Controller
{
    protected ProcessedProductService $processedProductService;

    public function __construct(ProcessedProductService $processedProductService)
    {
        $this->processedProductService = $processedProductService;
    }

    /**
     * Display the comprehensive platform landing page.
     * Focuses on education, value proposition, ecosystem, AI, and CTAs.
     */
    public function landing()
    {
        $featuredProducts = collect();
        $superAdminPhone = '6281234567890';

        try {
            if (Schema::hasTable('processed_products')) {
                // Get 4 featured active products for the landing page teaser section
                $featuredProducts = ProcessedProduct::with('owner:id,name,farm_name')
                    ->where('status', 'active')
                    ->latest()
                    ->take(4)
                    ->get();
            }

            if (Schema::hasTable('users')) {
                $superAdmin = User::where('role', 'super_admin')
                    ->whereNotNull('phone')
                    ->first();
                if ($superAdmin && !empty($superAdmin->phone)) {
                    $superAdminPhone = $superAdmin->phone;
                }
            }
        } catch (\Throwable $e) {
            // Graceful fallback if database is not reachable during early setups
        }

        return view('landing', compact('featuredProducts', 'superAdminPhone'));
    }

    /**
     * Display the dedicated product catalog page (/katalog).
     * Focuses on product discovery, filtering, details, and order checkout.
     */
    public function catalog(Request $request)
    {
        $products = collect();
        $superAdminPhone = '6281234567890';
        $search = $request->query('search', '');
        $statusFilter = $request->query('status', '');

        try {
            if (Schema::hasTable('processed_products')) {
                $filters = [];
                if (!empty($search)) {
                    $filters['search'] = $search;
                }
                if (!empty($statusFilter) && in_array($statusFilter, ['active', 'out_of_stock'])) {
                    $filters['status'] = $statusFilter;
                }

                $query = ProcessedProduct::with('owner:id,name,farm_name,phone')
                    ->forCatalog()
                    ->latest();

                if (!empty($filters['search'])) {
                    $query->where('name', 'like', '%' . $filters['search'] . '%');
                }

                if (!empty($filters['status'])) {
                    $query->where('status', $filters['status']);
                }

                $products = $query->paginate(12)->withQueryString();
            }

            if (Schema::hasTable('users')) {
                $superAdmin = User::where('role', 'super_admin')
                    ->whereNotNull('phone')
                    ->first();
                if ($superAdmin && !empty($superAdmin->phone)) {
                    $superAdminPhone = $superAdmin->phone;
                }
            }
        } catch (\Throwable $e) {
            // Graceful fallback
        }

        return view('catalog', compact('products', 'superAdminPhone', 'search', 'statusFilter'));
    }
}
