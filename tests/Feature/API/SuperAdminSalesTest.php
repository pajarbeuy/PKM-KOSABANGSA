<?php

namespace Tests\Feature\API;

use App\Models\ProcessedProduct;
use App\Models\Sale;
use App\Models\Season;
use App\Models\StockTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SuperAdminSalesTest extends TestCase
{
    use RefreshDatabase;

    protected User $superAdmin;
    protected User $farmer1;
    protected User $farmer2;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superAdmin = User::factory()->create([
            'role' => 'super_admin',
            'name' => 'Super Administrator',
        ]);

        $this->farmer1 = User::factory()->create([
            'role' => 'user',
            'name' => 'Petani Satu',
        ]);

        $this->farmer2 = User::factory()->create([
            'role' => 'user',
            'name' => 'Petani Dua',
        ]);
    }

    /** @test */
    public function test_farmer_cannot_create_sale(): void
    {
        Sanctum::actingAs($this->farmer1);

        $response = $this->postJson('/api/sales', [
            'buyer_name'   => 'Pembeli X',
            'weight_kg'    => 10,
            'price_per_kg' => 5000,
            'date'         => now()->toDateString(),
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function test_farmer_cannot_update_sale(): void
    {
        $sale = Sale::create([
            'user_id'        => $this->farmer1->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli A',
            'weight_kg'      => 10,
            'price_per_kg'   => 5000,
            'total'          => 50000,
            'payment_status' => 'paid',
        ]);

        Sanctum::actingAs($this->farmer1);

        $response = $this->putJson("/api/sales/{$sale->id}", [
            'buyer_name' => 'Pembeli Updated',
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function test_farmer_cannot_delete_sale(): void
    {
        $sale = Sale::create([
            'user_id'        => $this->farmer1->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli A',
            'weight_kg'      => 10,
            'price_per_kg'   => 5000,
            'total'          => 50000,
            'payment_status' => 'paid',
        ]);

        Sanctum::actingAs($this->farmer1);

        $response = $this->deleteJson("/api/sales/{$sale->id}");

        $response->assertStatus(403);
    }

    /** @test */
    public function test_super_admin_can_record_harvest_sale_for_farmer(): void
    {
        StockTransaction::addTransaction('in', 100, 'Panen', null, $this->farmer1->id);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/sales', [
            'user_id'      => $this->farmer1->id,
            'product_type' => 'harvest',
            'buyer_name'   => 'Pasar Induk',
            'weight_kg'    => 40,
            'price_per_kg' => 8000,
            'date'         => now()->toDateString(),
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'total'        => 320000,
                    'user_id'      => $this->farmer1->id,
                    'created_by'   => $this->superAdmin->id,
                    'product_type' => 'harvest',
                ],
            ]);

        $this->assertEquals(60.0, StockTransaction::getCurrentBalance($this->farmer1->id));
    }

    /** @test */
    public function test_super_admin_can_record_processed_product_sale(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'name'     => 'Keripik Tempe',
            'price'    => 15000,
            'stock'    => 20,
            'status'   => 'active',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/sales', [
            'product_type'         => 'processed',
            'processed_product_id' => $product->id,
            'buyer_name'           => 'Pelanggan Super Admin',
            'quantity'             => 5,
            'price_per_unit'       => 15000,
            'date'                 => now()->toDateString(),
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'total'                => 75000,
                    'user_id'              => $this->farmer1->id,
                    'product_type'         => 'processed',
                    'processed_product_id' => $product->id,
                ],
            ]);

        // Stock decrements to 15
        $this->assertEquals(15, $product->fresh()->stock);
        $this->assertEquals('active', $product->fresh()->status);
    }

    /** @test */
    public function test_processed_product_sale_reaching_zero_stock_becomes_out_of_stock(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'stock'    => 5,
            'status'   => 'active',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/sales', [
            'product_type'         => 'processed',
            'processed_product_id' => $product->id,
            'buyer_name'           => 'Pelanggan Borongan',
            'quantity'             => 5,
            'price_per_unit'       => 20000,
            'date'                 => now()->toDateString(),
        ]);

        $response->assertStatus(201);
        $this->assertEquals(0, $product->fresh()->stock);
        $this->assertEquals('out_of_stock', $product->fresh()->status);
    }

    /** @test */
    public function test_processed_product_sale_rejects_when_insufficient_stock(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'stock'    => 3,
            'status'   => 'active',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/sales', [
            'product_type'         => 'processed',
            'processed_product_id' => $product->id,
            'buyer_name'           => 'Pelanggan Beli Banyak',
            'quantity'             => 10,
            'price_per_unit'       => 20000,
            'date'                 => now()->toDateString(),
        ]);

        $response->assertStatus(422)
            ->assertJson(['success' => false]);

        $this->assertEquals(3, $product->fresh()->stock);
    }

    /** @test */
    public function test_farmer_views_only_own_sales_in_read_only(): void
    {
        Sale::create([
            'user_id'        => $this->farmer1->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli Petani 1',
            'weight_kg'      => 10,
            'price_per_kg'   => 5000,
            'total'          => 50000,
            'payment_status' => 'paid',
        ]);

        Sale::create([
            'user_id'        => $this->farmer2->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli Petani 2',
            'weight_kg'      => 20,
            'price_per_kg'   => 5000,
            'total'          => 100000,
            'payment_status' => 'paid',
        ]);

        Sanctum::actingAs($this->farmer1);

        $response = $this->getJson('/api/sales');

        $response->assertStatus(200);
        $items = $response->json('data.sales');
        $this->assertCount(1, $items);
        $this->assertEquals('Pembeli Petani 1', $items[0]['buyer_name']);
    }

    /** @test */
    public function test_super_admin_can_view_all_sales_across_farmers(): void
    {
        Sale::create([
            'user_id'        => $this->farmer1->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli Petani 1',
            'weight_kg'      => 10,
            'price_per_kg'   => 5000,
            'total'          => 50000,
            'payment_status' => 'paid',
        ]);

        Sale::create([
            'user_id'        => $this->farmer2->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli Petani 2',
            'weight_kg'      => 20,
            'price_per_kg'   => 5000,
            'total'          => 100000,
            'payment_status' => 'paid',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->getJson('/api/sales');

        $response->assertStatus(200);
        $items = $response->json('data.sales');
        $this->assertCount(2, $items);
    }

    /** @test */
    public function test_deleting_processed_product_sale_restores_stock(): void
    {
        $product = ProcessedProduct::factory()->create([
            'owner_id' => $this->farmer1->id,
            'stock'    => 10,
            'status'   => 'active',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $saleResponse = $this->postJson('/api/sales', [
            'product_type'         => 'processed',
            'processed_product_id' => $product->id,
            'buyer_name'           => 'Pembeli Akan Dibatalkan',
            'quantity'             => 4,
            'price_per_unit'       => 15000,
            'date'                 => now()->toDateString(),
        ]);

        $saleId = $saleResponse->json('data.id');
        $this->assertEquals(6, $product->fresh()->stock);

        $deleteResponse = $this->deleteJson("/api/sales/{$saleId}");
        $deleteResponse->assertStatus(200);

        // Restored back to 10
        $this->assertEquals(10, $product->fresh()->stock);
    }
}
