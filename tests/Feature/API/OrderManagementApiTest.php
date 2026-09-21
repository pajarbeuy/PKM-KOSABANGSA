<?php

namespace Tests\Feature\API;

use App\Models\Order;
use App\Models\ProcessedProduct;
use App\Models\Sale;
use App\Models\StockTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OrderManagementApiTest extends TestCase
{
    use RefreshDatabase;

    private User $superAdmin;
    private User $farmer;
    private ProcessedProduct $product;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superAdmin = User::factory()->create([
            'role'  => 'super_admin',
            'phone' => '081234567890',
        ]);

        $this->farmer = User::factory()->create([
            'role'      => 'user',
            'farm_name' => 'Kebun Tani Makmur',
            'phone'     => '089876543210',
        ]);

        $this->product = ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Jamur Crispy Original',
            'price'       => 15000,
            'stock'       => 10,
            'description' => 'Keripik jamur tiram renyah',
            'status'      => 'active',
        ]);
    }

    /** @test */
    public function test_guest_can_place_order_from_catalog_and_stock_is_not_decremented(): void
    {
        $payload = [
            'customer_name'        => 'Budi Santoso',
            'customer_phone'       => '081299887766',
            'customer_address'     => 'Jl. Merdeka No. 45, Bandung',
            'notes'                => 'Tolong kirim siang hari',
            'processed_product_id' => $this->product->id,
            'quantity'             => 3,
        ];

        $response = $this->postJson('/api/catalog/orders', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Pesanan berhasil dibuat. Silakan konfirmasi pesanan Anda via WhatsApp.',
            ])
            ->assertJsonStructure([
                'data' => [
                    'order' => [
                        'order_code',
                        'status',
                        'customer_name',
                        'customer_phone',
                        'customer_address',
                        'total_amount',
                        'items',
                    ],
                    'order_code',
                ],
            ]);

        // Verify Order in DB
        $this->assertDatabaseHas('orders', [
            'customer_name'  => 'Budi Santoso',
            'customer_phone' => '081299887766',
            'status'         => 'pending',
            'total_amount'   => 45000, // 3 * 15000
        ]);

        $this->assertDatabaseHas('order_items', [
            'processed_product_id' => $this->product->id,
            'quantity'             => 3,
            'price_snapshot'       => 15000,
            'subtotal'             => 45000,
        ]);

        // CRITICAL INVARIANT: Stock MUST NOT be decremented on order placement!
        $this->assertEquals(10, $this->product->fresh()->stock);

        // CRITICAL INVARIANT: No Sale should be created yet!
        $this->assertEquals(0, Sale::count());
    }

    /** @test */
    public function test_cannot_order_inactive_or_out_of_stock_product(): void
    {
        $inactiveProduct = ProcessedProduct::create([
            'owner_id' => $this->farmer->id,
            'name'     => 'Sambal Bawang Premium',
            'price'    => 20000,
            'stock'    => 5,
            'status'   => 'inactive',
        ]);

        $outOfStockProduct = ProcessedProduct::create([
            'owner_id' => $this->farmer->id,
            'name'     => 'Keripik Singkong Balado',
            'price'    => 10000,
            'stock'    => 0,
            'status'   => 'out_of_stock',
        ]);

        // Inactive product
        $res1 = $this->postJson('/api/catalog/orders', [
            'customer_name'        => 'Pembeli A',
            'customer_phone'       => '0811223344',
            'processed_product_id' => $inactiveProduct->id,
            'quantity'             => 1,
        ]);
        $res1->assertStatus(422)->assertJson(['success' => false]);

        // Out of stock product
        $res2 = $this->postJson('/api/catalog/orders', [
            'customer_name'        => 'Pembeli B',
            'customer_phone'       => '0811223344',
            'processed_product_id' => $outOfStockProduct->id,
            'quantity'             => 1,
        ]);
        $res2->assertStatus(422)->assertJson(['success' => false]);
    }

    /** @test */
    public function test_cannot_order_quantity_exceeding_stock(): void
    {
        $response = $this->postJson('/api/catalog/orders', [
            'customer_name'        => 'Pembeli Serakah',
            'customer_phone'       => '0811223344',
            'processed_product_id' => $this->product->id,
            'quantity'             => 15, // available stock is 10
        ]);

        $response->assertStatus(422)
            ->assertJson(['success' => false]);

        $this->assertEquals(10, $this->product->fresh()->stock);
    }

    /** @test */
    public function test_price_snapshot_preserved_after_product_price_changes(): void
    {
        // Place order when price is 15,000
        $this->postJson('/api/catalog/orders', [
            'customer_name'        => 'Ahmad',
            'customer_phone'       => '0812345678',
            'processed_product_id' => $this->product->id,
            'quantity'             => 2,
        ]);

        $order = Order::latest()->first();
        $this->assertEquals(30000, (float) $order->total_amount);

        // Product price increases to 25,000
        $this->product->update(['price' => 25000]);

        // Historical order MUST retain 15,000 price snapshot
        $item = $order->fresh()->items->first();
        $this->assertEquals(15000, (float) $item->price_snapshot);
        $this->assertEquals(30000, (float) $item->subtotal);
        $this->assertEquals(30000, (float) $order->fresh()->total_amount);
    }

    /** @test */
    public function test_super_admin_can_update_order_status_to_confirmed_or_processing(): void
    {
        $order = Order::create([
            'order_code'       => Order::generateOrderCode(),
            'customer_name'    => 'Dewi',
            'customer_phone'   => '0855667788',
            'status'           => 'pending',
            'total_amount'     => 15000,
        ]);

        Sanctum::actingAs($this->superAdmin);

        // Update to confirmed
        $resConfirmed = $this->patchJson("/api/super-admin/orders/{$order->id}/status", [
            'status' => 'confirmed',
        ]);
        $resConfirmed->assertStatus(200);
        $this->assertEquals('confirmed', $order->fresh()->status);
        // Stock must STILL not change
        $this->assertEquals(10, $this->product->fresh()->stock);

        // Update to processing
        $resProcessing = $this->patchJson("/api/super-admin/orders/{$order->id}/status", [
            'status' => 'processing',
        ]);
        $resProcessing->assertStatus(200);
        $this->assertEquals('processing', $order->fresh()->status);
        // Stock must STILL not change
        $this->assertEquals(10, $this->product->fresh()->stock);
    }

    /** @test */
    public function test_super_admin_cannot_set_completed_via_update_status_patch(): void
    {
        $order = Order::create([
            'order_code'       => Order::generateOrderCode(),
            'customer_name'    => 'Rina',
            'customer_phone'   => '0855667799',
            'status'           => 'confirmed',
            'total_amount'     => 15000,
        ]);

        Sanctum::actingAs($this->superAdmin);

        // Attempting to patch 'completed' must be rejected (only complete endpoint allowed)
        $response = $this->patchJson("/api/super-admin/orders/{$order->id}/status", [
            'status' => 'completed',
        ]);

        $response->assertStatus(422);
        $this->assertNotEquals('completed', $order->fresh()->status);
    }

    /** @test */
    public function test_super_admin_can_complete_order_and_creates_sale_decrements_stock_records_stock_transaction(): void
    {
        // Create an order with 10 units (all available stock)
        $order = Order::create([
            'order_code'       => Order::generateOrderCode(),
            'customer_name'    => 'Citra',
            'customer_phone'   => '0877889900',
            'customer_address' => 'Jl. Kebon Jeruk No. 12',
            'status'           => 'processing',
            'total_amount'     => 150000,
        ]);

        $order->items()->create([
            'processed_product_id' => $this->product->id,
            'quantity'             => 10,
            'price_snapshot'       => 15000,
            'subtotal'             => 150000,
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson("/api/super-admin/orders/{$order->id}/complete");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'status'   => 'completed',
                    'has_sale' => true,
                ],
            ]);

        // 1. Order status is now 'completed'
        $this->assertEquals('completed', $order->fresh()->status);

        // 2. Sale created and linked to order
        $sale = Sale::where('order_id', $order->id)->first();
        $this->assertNotNull($sale);
        $this->assertEquals($this->farmer->id, $sale->user_id);
        $this->assertEquals($this->superAdmin->id, $sale->created_by);
        $this->assertEquals('processed', $sale->product_type);
        $this->assertEquals($this->product->id, $sale->processed_product_id);
        $this->assertEquals(10, (float) $sale->weight_kg);
        $this->assertEquals(15000, (float) $sale->price_per_kg);
        $this->assertEquals(150000, (float) $sale->total);
        $this->assertEquals('paid', $sale->payment_status);

        // 3. Stock decremented: 10 - 10 = 0
        $freshProduct = $this->product->fresh();
        $this->assertEquals(0, $freshProduct->stock);
        // Automatic status transition to out_of_stock
        $this->assertEquals('out_of_stock', $freshProduct->status);

        // 4. StockTransaction recorded
        $this->assertDatabaseHas('stock_transactions', [
            'user_id'              => $this->farmer->id,
            'processed_product_id' => $this->product->id,
            'type'                 => 'out',
            'amount'               => 10,
            'balance_after'        => 0,
            'reference'            => 'sale_' . $sale->id,
        ]);
    }

    /** @test */
    public function test_complete_order_is_idempotent_no_double_sale(): void
    {
        $order = Order::create([
            'order_code'       => Order::generateOrderCode(),
            'customer_name'    => 'Hendra',
            'customer_phone'   => '0822334455',
            'status'           => 'processing',
            'total_amount'     => 30000,
        ]);

        $order->items()->create([
            'processed_product_id' => $this->product->id,
            'quantity'             => 2,
            'price_snapshot'       => 15000,
            'subtotal'             => 30000,
        ]);

        Sanctum::actingAs($this->superAdmin);

        // First completion
        $res1 = $this->postJson("/api/super-admin/orders/{$order->id}/complete");
        $res1->assertStatus(200);

        $this->assertEquals(8, $this->product->fresh()->stock);
        $this->assertEquals(1, Sale::where('order_id', $order->id)->count());

        // Second completion MUST be rejected
        $res2 = $this->postJson("/api/super-admin/orders/{$order->id}/complete");
        $res2->assertStatus(422)
            ->assertJson(['success' => false]);

        // Stock MUST NOT be decremented twice!
        $this->assertEquals(8, $this->product->fresh()->stock);
        // Sale MUST NOT be duplicated!
        $this->assertEquals(1, Sale::where('order_id', $order->id)->count());
    }

    /** @test */
    public function test_cannot_complete_order_if_stock_became_insufficient(): void
    {
        $order = Order::create([
            'order_code'       => Order::generateOrderCode(),
            'customer_name'    => 'Joko',
            'customer_phone'   => '0811998877',
            'status'           => 'processing',
            'total_amount'     => 75000,
        ]);

        $order->items()->create([
            'processed_product_id' => $this->product->id,
            'quantity'             => 5,
            'price_snapshot'       => 15000,
            'subtotal'             => 75000,
        ]);

        // Simulate stock being reduced elsewhere to 2 units before order completes
        $this->product->update(['stock' => 2]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson("/api/super-admin/orders/{$order->id}/complete");

        $response->assertStatus(422)
            ->assertJson(['success' => false]);

        // Order remains uncompleted and stock unchanged
        $this->assertEquals('processing', $order->fresh()->status);
        $this->assertEquals(2, $this->product->fresh()->stock);
        $this->assertEquals(0, Sale::count());
    }

    /** @test */
    public function test_super_admin_can_cancel_order_but_cannot_cancel_completed_order(): void
    {
        $order = Order::create([
            'order_code'       => Order::generateOrderCode(),
            'customer_name'    => 'Kiki',
            'customer_phone'   => '0812345678',
            'status'           => 'pending',
            'total_amount'     => 15000,
        ]);

        Sanctum::actingAs($this->superAdmin);

        // Cancel pending order
        $resCancel = $this->postJson("/api/super-admin/orders/{$order->id}/cancel");
        $resCancel->assertStatus(200);
        $this->assertEquals('cancelled', $order->fresh()->status);

        // Now test completing a completed order cancel
        $completedOrder = Order::create([
            'order_code'       => Order::generateOrderCode(),
            'customer_name'    => 'Luki',
            'customer_phone'   => '0812345678',
            'status'           => 'completed',
            'total_amount'     => 15000,
        ]);

        $resCancelCompleted = $this->postJson("/api/super-admin/orders/{$completedOrder->id}/cancel");
        $resCancelCompleted->assertStatus(422);
        $this->assertEquals('completed', $completedOrder->fresh()->status);
    }

    /** @test */
    public function test_public_tracking_endpoint_masks_personal_customer_data(): void
    {
        $order = Order::create([
            'order_code'       => Order::generateOrderCode(),
            'customer_name'    => 'Bambang Sudrajat',
            'customer_phone'   => '081234567890',
            'customer_address' => 'Jl. Diponegoro No. 88, Surabaya, Jawa Timur 60241',
            'status'           => 'confirmed',
            'total_amount'     => 30000,
        ]);

        $order->items()->create([
            'processed_product_id' => $this->product->id,
            'quantity'             => 2,
            'price_snapshot'       => 15000,
            'subtotal'             => 30000,
        ]);

        $response = $this->getJson("/api/catalog/orders/{$order->order_code}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'order_code'    => $order->order_code,
                    'status'        => 'confirmed',
                    'customer_name' => 'Bambang S*******',
                    'customer_phone'=> '0812****7890',
                ],
            ]);

        // CRITICAL SECURITY / PRIVACY CHECK: Full address and full phone MUST NOT appear
        $response->assertDontSee('081234567890');
        $response->assertDontSee('Jl. Diponegoro No. 88, Surabaya');
    }

    /** @test */
    public function test_farmer_cannot_access_super_admin_orders(): void
    {
        Sanctum::actingAs($this->farmer);

        $resIndex = $this->getJson('/api/super-admin/orders');
        $resIndex->assertStatus(403);

        $order = Order::create([
            'order_code'     => Order::generateOrderCode(),
            'customer_name'  => 'User',
            'customer_phone' => '081111111',
            'status'         => 'pending',
            'total_amount'   => 15000,
        ]);

        $resShow = $this->getJson("/api/super-admin/orders/{$order->id}");
        $resShow->assertStatus(403);
    }
}
