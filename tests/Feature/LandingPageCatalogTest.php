<?php

namespace Tests\Feature;

use App\Models\ProcessedProduct;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LandingPageCatalogTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function test_catalog_page_renders_active_and_out_of_stock_products(): void
    {
        $superAdmin = User::factory()->create([
            'role'  => 'super_admin',
            'phone' => '081234567890',
        ]);

        $farmer = User::factory()->create([
            'role'      => 'user',
            'farm_name' => 'Kebun Sejahtera',
        ]);

        // Active product
        ProcessedProduct::factory()->create([
            'owner_id' => $farmer->id,
            'name'     => 'Keripik Tempe Renyah',
            'price'    => 20000,
            'stock'    => 15,
            'status'   => 'active',
        ]);

        // Out of stock product (must be displayed in catalog with Stok Habis badge)
        ProcessedProduct::factory()->create([
            'owner_id' => $farmer->id,
            'name'     => 'Stik Kentang Balado',
            'price'    => 25000,
            'stock'    => 0,
            'status'   => 'out_of_stock',
        ]);

        // Inactive product (must be hidden)
        ProcessedProduct::factory()->create([
            'owner_id' => $farmer->id,
            'name'     => 'Tepung Kentang Rahasia',
            'price'    => 50000,
            'stock'    => 10,
            'status'   => 'inactive',
        ]);

        // Test dedicated catalog page
        $catalogResponse = $this->get('/katalog');
        $catalogResponse->assertStatus(200);
        $catalogResponse->assertSee('Keripik Tempe Renyah');
        $catalogResponse->assertSee('Tersedia (15)');
        $catalogResponse->assertSee('Stik Kentang Balado');
        $catalogResponse->assertSee('Stok Habis');
        $catalogResponse->assertDontSee('Tepung Kentang Rahasia');

        // Check landing page has CTA to /katalog
        $landingResponse = $this->get('/');
        $landingResponse->assertStatus(200);
        $landingResponse->assertSee(route('catalog'));
    }
}
