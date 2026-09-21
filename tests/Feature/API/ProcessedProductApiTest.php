<?php

namespace Tests\Feature\API;

use App\Models\ProcessedProduct;
use App\Models\User;
use App\Services\ProcessedProductService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProcessedProductApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $farmer1;
    protected User $farmer2;
    protected User $superAdmin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->farmer1 = User::factory()->create([
            'role' => 'user',
            'name' => 'Petani Satu',
        ]);

        $this->farmer2 = User::factory()->create([
            'role' => 'user',
            'name' => 'Petani Dua',
        ]);

        $this->superAdmin = User::factory()->create([
            'role' => 'super_admin',
            'name' => 'Super Administrator',
        ]);
    }

    /** @test */
    public function test_farmer_can_create_processed_product_with_http_201(): void
    {
        Sanctum::actingAs($this->farmer1);

        $payload = [
            'name'        => 'Keripik Kentang Renyah',
            'price'       => 25000,
            'stock'       => 50,
            'description' => 'Keripik renyah dari kentang pilihan',
        ];

        $response = $this->postJson('/api/processed-products', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'name'     => 'Keripik Kentang Renyah',
                    'price'    => 25000,
                    'stock'    => 50,
                    'status'   => 'active',
                    'owner_id' => $this->farmer1->id,
                ],
            ]);

        $this->assertDatabaseHas('processed_products', [
            'name'     => 'Keripik Kentang Renyah',
            'owner_id' => $this->farmer1->id,
            'stock'    => 50,
            'status'   => 'active',
        ]);
    }

    /** @test */
    public function test_farmer_creating_product_with_zero_stock_defaults_to_out_of_stock(): void
    {
        Sanctum::actingAs($this->farmer1);

        $response = $this->postJson('/api/processed-products', [
            'name'  => 'Sambal Kentang Pedas',
            'price' => 30000,
            'stock' => 0,
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'stock'  => 0,
                    'status' => 'out_of_stock',
                ],
            ]);
    }

    /** @test */
    public function test_farmer_can_only_view_own_processed_products(): void
    {
        ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'name'     => 'Produk Milik Petani 1',
        ]);

        ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer2->id,
            'name'     => 'Produk Milik Petani 2',
        ]);

        Sanctum::actingAs($this->farmer1);

        $response = $this->getJson('/api/processed-products');

        $response->assertStatus(200);
        $products = $response->json('data.products');
        $this->assertCount(1, $products);
        $this->assertEquals('Produk Milik Petani 1', $products[0]['name']);
    }

    /** @test */
    public function test_farmer_cannot_view_or_modify_other_farmer_product(): void
    {
        $otherProduct = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer2->id,
            'name'     => 'Produk Petani 2',
        ]);

        Sanctum::actingAs($this->farmer1);

        // Cannot view
        $viewResponse = $this->getJson("/api/processed-products/{$otherProduct->id}");
        $viewResponse->assertStatus(403);

        // Cannot update
        $updateResponse = $this->putJson("/api/processed-products/{$otherProduct->id}", [
            'name'  => 'Hacked Name',
            'price' => 1000,
            'stock' => 10,
        ]);
        $updateResponse->assertStatus(403);

        // Cannot delete
        $deleteResponse = $this->deleteJson("/api/processed-products/{$otherProduct->id}");
        $deleteResponse->assertStatus(403);
    }

    /** @test */
    public function test_farmer_can_update_own_product(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'name'     => 'Nama Awal',
            'price'    => 20000,
            'stock'    => 10,
            'status'   => 'active',
        ]);

        Sanctum::actingAs($this->farmer1);

        $response = $this->putJson("/api/processed-products/{$product->id}", [
            'name'  => 'Nama Baru',
            'price' => 25000,
            'stock' => 15,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'name'  => 'Nama Baru',
                    'price' => 25000,
                    'stock' => 15,
                ],
            ]);

        $this->assertDatabaseHas('processed_products', [
            'id'    => $product->id,
            'name'  => 'Nama Baru',
            'price' => 25000,
            'stock' => 15,
        ]);
    }

    /** @test */
    public function test_farmer_can_delete_own_product(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
        ]);

        Sanctum::actingAs($this->farmer1);

        $response = $this->deleteJson("/api/processed-products/{$product->id}");

        $response->assertStatus(200);
        $this->assertSoftDeleted('processed_products', ['id' => $product->id]);
    }

    /** @test */
    public function test_super_admin_can_view_all_farmers_processed_products(): void
    {
        ProcessedProduct::factory()->create(['owner_id' => $this->farmer1->id]);
        ProcessedProduct::factory()->create(['owner_id' => $this->farmer2->id]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->getJson('/api/super-admin/processed-products');

        $response->assertStatus(200);
        $this->assertCount(2, $response->json('data.products'));
    }

    /** @test */
    public function test_super_admin_can_update_product_status(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'stock'    => 20,
            'status'   => 'active',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->patchJson("/api/super-admin/processed-products/{$product->id}/status", [
            'status' => 'inactive',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'status' => 'inactive',
                ],
            ]);

        $this->assertDatabaseHas('processed_products', [
            'id'     => $product->id,
            'status' => 'inactive',
        ]);
    }

    /** @test */
    public function test_public_catalog_displays_active_and_out_of_stock_products_but_hides_inactive(): void
    {
        // Active product
        $p1 = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'name'     => 'Katalog Active',
            'stock'    => 10,
            'status'   => 'active',
        ]);

        // Out of stock product (must be displayed in catalog with out_of_stock status)
        $p2 = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer2->id,
            'name'     => 'Katalog Out of Stock',
            'stock'    => 0,
            'status'   => 'out_of_stock',
        ]);

        // Inactive product (must be hidden)
        $p3 = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'name'     => 'Katalog Inactive',
            'stock'    => 15,
            'status'   => 'inactive',
        ]);

        // Unauthenticated call to public catalog
        $response = $this->getJson('/api/catalog/processed-products');

        $response->assertStatus(200);
        $products = $response->json('data.products');

        $names = collect($products)->pluck('name')->all();
        $this->assertContains('Katalog Active', $names);
        $this->assertContains('Katalog Out of Stock', $names);
        $this->assertNotContains('Katalog Inactive', $names);
    }

    /** @test */
    public function test_stock_zero_auto_transitions_to_out_of_stock(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'stock'    => 5,
            'status'   => 'active',
        ]);

        $product->stock = 0;
        $product->save();

        $this->assertEquals('out_of_stock', $product->fresh()->status);
    }

    /** @test */
    public function test_restock_auto_transitions_from_out_of_stock_to_active(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'stock'    => 0,
            'status'   => 'out_of_stock',
        ]);

        $product->stock = 25;
        $product->save();

        $this->assertEquals('active', $product->fresh()->status);
    }

    /** @test */
    public function test_manual_inactive_status_is_preserved_even_when_restocked(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'stock'    => 0,
            'status'   => 'inactive',
        ]);

        $product->stock = 30;
        $product->save();

        // Must remain inactive
        $this->assertEquals('inactive', $product->fresh()->status);
    }

    /** @test */
    public function test_decrement_stock_atomic_guards_against_insufficient_stock(): void
    {
        $service = app(ProcessedProductService::class);

        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'stock'    => 3,
            'status'   => 'active',
        ]);

        // Trying to buy 5 should throw DomainException
        $this->expectException(\DomainException::class);
        $service->decrementStock($product, 5);

        // Product stock must still be 3
        $this->assertEquals(3, $product->fresh()->stock);
    }

    /** @test */
    public function test_decrement_stock_to_zero_transitions_to_out_of_stock(): void
    {
        $service = app(ProcessedProductService::class);

        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'stock'    => 4,
            'status'   => 'active',
        ]);

        $updated = $service->decrementStock($product, 4);

        $this->assertEquals(0, $updated->stock);
        $this->assertEquals('out_of_stock', $updated->status);
    }
}
