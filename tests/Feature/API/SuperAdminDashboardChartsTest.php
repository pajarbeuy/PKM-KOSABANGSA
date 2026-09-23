<?php

namespace Tests\Feature\API;

use App\Models\ProcessedProduct;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SuperAdminDashboardChartsTest extends TestCase
{
    use RefreshDatabase;

    protected User $superAdmin;
    protected User $farmer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superAdmin = User::factory()->create([
            'role' => 'super_admin',
            'name' => 'Super Administrator',
        ]);

        $this->farmer = User::factory()->create([
            'role' => 'user',
            'name' => 'Petani Satu',
        ]);
    }

    /** @test */
    public function test_dashboard_returns_monthly_product_sales_and_cumulative_revenue(): void
    {
        $product = ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Keripik Tempe Renyah',
            'price'       => 15000,
            'stock'       => 100,
            'description' => 'Keripik lezat',
            'status'      => 'active',
        ]);

        // Create sale in current year
        Sale::create([
            'user_id'              => $this->farmer->id,
            'created_by'           => $this->superAdmin->id,
            'product_type'         => 'processed',
            'processed_product_id' => $product->id,
            'date'                 => now()->toDateString(),
            'buyer_name'           => 'Pembeli A',
            'weight_kg'            => 10,
            'price_per_kg'         => 15000,
            'total'                => 150000,
            'payment_status'       => 'paid',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->getJson('/api/super-admin/dashboard?refresh=true');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'data' => [
                    'totalUsers',
                    'activeUsers',
                    'year',
                    'total_products_sold_year',
                    'total_farmer_revenue_year',
                    'monthly_product_sales',
                    'cumulative_farmer_revenue',
                    'cached_at',
                    'cache_ttl_seconds',
                ],
            ]);

        $data = $response->json('data');

        // Check 12 months structure
        $this->assertCount(12, $data['monthly_product_sales']);
        $this->assertCount(12, $data['cumulative_farmer_revenue']);

        $currentMonth = now()->month;
        $this->assertEquals(10, $data['monthly_product_sales'][$currentMonth - 1]['total_sold']);
        $this->assertEquals(150000, $data['cumulative_farmer_revenue'][$currentMonth - 1]['cumulative_revenue']);
        $this->assertEquals(3600, $data['cache_ttl_seconds']);
    }

    /** @test */
    public function test_dashboard_uses_cache_and_can_be_forced_refresh(): void
    {
        Sanctum::actingAs($this->superAdmin);

        Cache::forget('superadmin_dashboard_stats');
        $this->assertFalse(Cache::has('superadmin_dashboard_stats'));

        // First call caches the result
        $this->getJson('/api/super-admin/dashboard')->assertStatus(200);
        $this->assertTrue(Cache::has('superadmin_dashboard_stats'));

        // Call with refresh=true invalidates and rebuilds cache
        $this->getJson('/api/super-admin/dashboard?refresh=true')->assertStatus(200);
        $this->assertTrue(Cache::has('superadmin_dashboard_stats'));
    }
}
