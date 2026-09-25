<?php

namespace Tests\Feature\Web;

use App\Models\ProcessedProduct;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CatalogSeparationTest extends TestCase
{
    use RefreshDatabase;

    protected User $superAdmin;
    protected User $farmer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superAdmin = User::factory()->create([
            'role'  => 'super_admin',
            'phone' => '081234567890',
        ]);

        $this->farmer = User::factory()->create([
            'role'      => 'user',
            'farm_name' => 'Kelompok Tani Maju',
            'phone'     => '089876543210',
        ]);
    }

    public function test_landing_page_renders_platform_landing_view_with_ecosystem_and_catalog_cta(): void
    {
        // Seed an active processed product
        ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Keripik Kentang Original',
            'price'       => 25000,
            'stock'       => 50,
            'unit'        => 'kemasan',
            'description' => 'Keripik olahan bermutu tinggi dari hasil panen kentang mitra.',
            'status'      => 'active',
        ]);

        $response = $this->get('/');

        $response->assertStatus(200);
        $response->assertViewIs('landing');
        $response->assertSee('SumberTani');
        $response->assertSee('Hilirisasi');
        $response->assertSee('Cara Kerja');
        $response->assertSee('Tentang SumberTani');
        $response->assertSee(route('catalog'));
        $response->assertSee('Jelajahi Katalog Produk');
    }

    public function test_katalog_route_renders_dedicated_catalog_view_with_active_products(): void
    {
        $product = ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Tepung Pati Kentang Murni',
            'price'       => 45000,
            'stock'       => 30,
            'unit'        => 'pouch',
            'description' => 'Pati kentang berkualitas tinggi serbaguna.',
            'status'      => 'active',
        ]);

        $response = $this->get('/katalog');

        $response->assertStatus(200);
        $response->assertViewIs('catalog');
        $response->assertSee('Katalog Produk Olahan Tani');
        $response->assertSee('Tepung Pati Kentang Murni');
        $response->assertSee('45.000');
        $response->assertSee('Kelompok Tani Maju');
        $response->assertSee('Formulir Pesanan Produk Olahan');
        $response->assertSee('Lacak Status Pesanan Publik');
    }

    public function test_catalog_alias_redirects_to_katalog(): void
    {
        $response = $this->get('/catalog');

        $response->assertRedirect(route('catalog'));
    }

    public function test_inactive_products_are_hidden_from_public_catalog(): void
    {
        ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Produk Nonaktif Rahasia',
            'price'       => 10000,
            'stock'       => 5,
            'unit'        => 'pack',
            'status'      => 'inactive',
        ]);

        $response = $this->get('/katalog');

        $response->assertStatus(200);
        $response->assertDontSee('Produk Nonaktif Rahasia');
    }

    public function test_catalog_search_filters_matching_products(): void
    {
        ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Keripik Balado Spesial',
            'price'       => 20000,
            'stock'       => 25,
            'unit'        => 'pack',
            'status'      => 'active',
        ]);

        ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Stik Kentang Keju',
            'price'       => 15000,
            'stock'       => 15,
            'unit'        => 'pack',
            'status'      => 'active',
        ]);

        $response = $this->get('/katalog?search=Balado');

        $response->assertStatus(200);
        $response->assertSee('Keripik Balado Spesial');
        $response->assertDontSee('Stik Kentang Keju');
    }

    public function test_existing_order_pipeline_remains_fully_functional(): void
    {
        $product = ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Keripik Kentang Original',
            'price'       => 25000,
            'stock'       => 50,
            'unit'        => 'kemasan',
            'status'      => 'active',
        ]);

        // 1. Customer places order via public API
        $orderPayload = [
            'customer_name'    => 'Pembeli Publik',
            'customer_phone'   => '081299998888',
            'customer_address' => 'Jl. Kebon Jeruk No. 10',
            'notes'            => 'Tolong kirim siang hari',
            'items'            => [
                [
                    'processed_product_id' => $product->id,
                    'quantity'             => 2,
                ],
            ],
        ];

        $postResponse = $this->postJson('/api/catalog/orders', $orderPayload);
        $postResponse->assertStatus(201);
        $postResponse->assertJsonPath('success', true);

        $orderCode = $postResponse->json('data.order_code');
        $this->assertNotEmpty($orderCode);

        // 2. Customer can track the order via public tracking API (with privacy masking)
        $trackResponse = $this->getJson('/api/catalog/orders/' . $orderCode);
        $trackResponse->assertStatus(200);
        $trackResponse->assertJsonPath('data.order_code', $orderCode);
        $this->assertStringStartsWith('Pembeli', $trackResponse->json('data.customer_name'));
        $trackResponse->assertJsonPath('data.total_amount', 50000);
    }
}
