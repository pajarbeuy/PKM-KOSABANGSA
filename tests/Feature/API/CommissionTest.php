<?php

namespace Tests\Feature\API;

use App\Models\Commission;
use App\Models\Order;
use App\Models\ProcessedProduct;
use App\Models\Sale;
use App\Models\User;
use App\Services\CommissionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CommissionTest extends TestCase
{
    use RefreshDatabase;

    private User $superAdmin;
    private User $farmerA;
    private User $farmerB;
    private ProcessedProduct $productA;
    private ProcessedProduct $productB;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superAdmin = User::factory()->create([
            'role'   => 'super_admin',
            'phone'  => '081234567890',
            'status' => 'active',
        ]);

        $this->farmerA = User::factory()->create([
            'role'      => 'user',
            'farm_name' => 'Kebun Tani Makmur',
            'phone'     => '089876543210',
            'status'    => 'active',
        ]);

        $this->farmerB = User::factory()->create([
            'role'      => 'user',
            'farm_name' => 'Kebun Tani Berkah',
            'phone'     => '089876543211',
            'status'    => 'active',
        ]);

        $this->productA = ProcessedProduct::create([
            'owner_id'    => $this->farmerA->id,
            'name'        => 'Jamur Crispy Original',
            'price'       => 20000,
            'stock'       => 50,
            'description' => 'Keripik jamur tiram renyah',
            'status'      => 'active',
        ]);

        $this->productB = ProcessedProduct::create([
            'owner_id'    => $this->farmerB->id,
            'name'        => 'Keripik Tempe Renyah',
            'price'       => 15000,
            'stock'       => 40,
            'description' => 'Keripik tempe gurih',
            'status'      => 'active',
        ]);
    }

    /** @test */
    public function test_completing_order_automatically_creates_exact_3_percent_commission(): void
    {
        // 1. Guest places order: 3 qty of productA (3 × 20,000 = 60,000)
        $orderResponse = $this->postJson('/api/catalog/orders', [
            'customer_name'        => 'Siti Aisyah',
            'customer_phone'       => '081233445566',
            'customer_address'     => 'Jl. Pahlawan No. 12, Malang',
            'processed_product_id' => $this->productA->id,
            'quantity'             => 3,
        ]);

        $orderResponse->assertStatus(201);
        $orderCode = $orderResponse->json('data.order_code');
        $order = Order::where('order_code', $orderCode)->firstOrFail();

        // 2. Super Admin completes the order
        Sanctum::actingAs($this->superAdmin);
        $completeResponse = $this->postJson("/api/super-admin/orders/{$order->id}/complete");

        $completeResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Pesanan berhasil diselesaikan. Transaksi penjualan dan pengurangan stok telah tercatat.',
            ]);

        // 3. Verify Sale was created
        $this->assertDatabaseHas('sales', [
            'order_id'             => $order->id,
            'user_id'              => $this->farmerA->id,
            'processed_product_id' => $this->productA->id,
            'total'                => 60000.00,
        ]);

        // 4. Verify Commission record was created automatically and exactly 3% (3% of 60,000 = 1,800)
        $this->assertDatabaseHas('commissions', [
            'order_id'          => $order->id,
            'user_id'           => $this->farmerA->id,
            'rate'              => 3.00,
            'base_amount'       => 60000.00,
            'commission_amount' => 1800.00,
            'net_farmer_amount' => 58200.00,
            'status'            => 'calculated',
        ]);

        $commission = Commission::where('order_id', $order->id)->first();
        $this->assertNotNull($commission);
        $this->assertEquals(60000.00, (float) $commission->base_amount);
        $this->assertEquals(1800.00, (float) $commission->commission_amount);
        $this->assertEquals(58200.00, (float) $commission->net_farmer_amount);
        $this->assertEquals(3.00, (float) $commission->rate);
    }

    /** @test */
    public function test_commission_service_idempotency_prevents_duplicate_commissions(): void
    {
        // Create a direct sale
        $sale = Sale::create([
            'user_id'              => $this->farmerA->id,
            'product_type'         => 'processed',
            'processed_product_id' => $this->productA->id,
            'date'                 => now()->toDateString(),
            'buyer_name'           => 'Pembeli Langsung',
            'weight_kg'            => 5,
            'price_per_kg'         => 20000,
            'total'                => 100000,
            'payment_status'       => 'paid',
        ]);

        $service = app(CommissionService::class);

        // First calculation (3% of 100,000 = 3,000)
        $comm1 = $service->calculateAndRecordCommission($sale);
        $this->assertEquals(3000.00, (float) $comm1->commission_amount);
        $this->assertEquals(97000.00, (float) $comm1->net_farmer_amount);
        $this->assertEquals(1, Commission::where('sale_id', $sale->id)->count());

        // Second calculation on the same sale
        $comm2 = $service->calculateAndRecordCommission($sale);
        $this->assertEquals($comm1->id, $comm2->id);

        // Ensure database still has strictly 1 commission record
        $this->assertEquals(1, Commission::where('sale_id', $sale->id)->count());
    }

    /** @test */
    public function test_one_million_rupiah_sale_yields_exact_thirty_thousand_commission(): void
    {
        $sale = Sale::create([
            'user_id'        => $this->farmerA->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli Grosir',
            'weight_kg'      => 100,
            'price_per_kg'   => 10000,
            'total'          => 1000000,
            'payment_status' => 'paid',
        ]);

        $service = app(CommissionService::class);
        $commission = $service->calculateAndRecordCommission($sale);

        // Formula: subtotal = 1.000.000, commission 3% = 30.000, farmer_amount = 970.000
        $this->assertEquals(1000000.00, (float) $commission->base_amount);
        $this->assertEquals(30000.00, (float) $commission->commission_amount);
        $this->assertEquals(970000.00, (float) $commission->net_farmer_amount);
        $this->assertEquals(3.00, (float) $commission->rate);
    }

    /** @test */
    public function test_zero_rupiah_sale_yields_zero_commission(): void
    {
        $sale = Sale::create([
            'user_id'        => $this->farmerA->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Sampel Gratis',
            'weight_kg'      => 1,
            'price_per_kg'   => 0,
            'total'          => 0,
            'payment_status' => 'paid',
        ]);

        $service = app(CommissionService::class);
        $commission = $service->calculateAndRecordCommission($sale);

        $this->assertEquals(0.00, (float) $commission->base_amount);
        $this->assertEquals(0.00, (float) $commission->commission_amount);
        $this->assertEquals(0.00, (float) $commission->net_farmer_amount);
        $this->assertEquals(3.00, (float) $commission->rate);
    }

    /** @test */
    public function test_historical_transactions_remain_intact_when_rate_changes(): void
    {
        // 1. Existing historical sale recorded under 10% rate
        $oldSale = Sale::create([
            'user_id'        => $this->farmerA->id,
            'date'           => '2026-08-01',
            'buyer_name'     => 'Old Buyer',
            'weight_kg'      => 10,
            'price_per_kg'   => 10000,
            'total'          => 100000,
            'payment_status' => 'paid',
        ]);

        $historicalCommission = Commission::create([
            'sale_id'           => $oldSale->id,
            'user_id'           => $this->farmerA->id,
            'rate'              => 10.00,
            'base_amount'       => 100000.00,
            'commission_amount' => 10000.00,
            'net_farmer_amount' => 90000.00,
            'status'            => 'calculated',
        ]);

        // 2. New sale recorded under current 3% rate
        $newSale = Sale::create([
            'user_id'        => $this->farmerA->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'New Buyer',
            'weight_kg'      => 10,
            'price_per_kg'   => 10000,
            'total'          => 100000,
            'payment_status' => 'paid',
        ]);

        $service = app(CommissionService::class);
        $newCommission = $service->calculateAndRecordCommission($newSale);

        // Verify historical record was NOT mutated retroactively
        $historicalCommission->refresh();
        $this->assertEquals(10.00, (float) $historicalCommission->rate);
        $this->assertEquals(10000.00, (float) $historicalCommission->commission_amount);
        $this->assertEquals(90000.00, (float) $historicalCommission->net_farmer_amount);

        // Verify new record strictly uses 3%
        $this->assertEquals(3.00, (float) $newCommission->rate);
        $this->assertEquals(3000.00, (float) $newCommission->commission_amount);
        $this->assertEquals(97000.00, (float) $newCommission->net_farmer_amount);
    }

    /** @test */
    public function test_super_admin_can_retrieve_all_commissions_and_aggregate_summary(): void
    {
        $sale1 = Sale::create([
            'user_id'      => $this->farmerA->id,
            'date'         => now()->toDateString(),
            'buyer_name'   => 'Pembeli A',
            'weight_kg'    => 1,
            'price_per_kg' => 100000,
            'total'        => 100000,
            'payment_status' => 'paid',
        ]);
        Commission::create([
            'sale_id'           => $sale1->id,
            'user_id'           => $this->farmerA->id,
            'rate'              => 3.00,
            'base_amount'       => 100000.00,
            'commission_amount' => 3000.00,
            'net_farmer_amount' => 97000.00,
            'status'            => 'calculated',
        ]);

        $sale2 = Sale::create([
            'user_id'      => $this->farmerB->id,
            'date'         => now()->toDateString(),
            'buyer_name'   => 'Pembeli B',
            'weight_kg'    => 1,
            'price_per_kg' => 200000,
            'total'        => 200000,
            'payment_status' => 'paid',
        ]);
        Commission::create([
            'sale_id'           => $sale2->id,
            'user_id'           => $this->farmerB->id,
            'rate'              => 3.00,
            'base_amount'       => 200000.00,
            'commission_amount' => 6000.00,
            'net_farmer_amount' => 194000.00,
            'status'            => 'calculated',
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->getJson('/api/commissions');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'summary' => [
                        'total_transactions'      => 2,
                        'total_gross_amount'      => 300000.00,
                        'total_commission_amount' => 9000.00,
                        'total_net_farmer_amount' => 291000.00,
                        'commission_rate_default' => 3.00,
                    ],
                ],
            ]);

        $this->assertCount(2, $response->json('data.commissions.data'));
    }

    /** @test */
    public function test_farmer_can_only_retrieve_own_commissions_multi_tenant_isolation(): void
    {
        // Commission for Farmer A
        $saleA = Sale::create([
            'user_id'        => $this->farmerA->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli A',
            'weight_kg'      => 1,
            'price_per_kg'   => 50000,
            'total'          => 50000,
            'payment_status' => 'paid',
        ]);
        Commission::create([
            'sale_id'           => $saleA->id,
            'user_id'           => $this->farmerA->id,
            'rate'              => 3.00,
            'base_amount'       => 50000.00,
            'commission_amount' => 1500.00,
            'net_farmer_amount' => 48500.00,
            'status'            => 'calculated',
        ]);

        // Commission for Farmer B
        $saleB = Sale::create([
            'user_id'        => $this->farmerB->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Pembeli B',
            'weight_kg'      => 1,
            'price_per_kg'   => 100000,
            'total'          => 100000,
            'payment_status' => 'paid',
        ]);
        Commission::create([
            'sale_id'           => $saleB->id,
            'user_id'           => $this->farmerB->id,
            'rate'              => 3.00,
            'base_amount'       => 100000.00,
            'commission_amount' => 3000.00,
            'net_farmer_amount' => 97000.00,
            'status'            => 'calculated',
        ]);

        // Farmer A requests commissions
        Sanctum::actingAs($this->farmerA);
        $response = $this->getJson('/api/commissions');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'summary' => [
                        'total_sales_count'         => 1,
                        'total_gross_sales'         => 50000.00,
                        'total_platform_commission' => 1500.00,
                        'total_net_received'        => 48500.00,
                    ],
                ],
            ]);

        $items = $response->json('data.commissions.data');
        $this->assertCount(1, $items);
        $this->assertEquals($this->farmerA->id, $items[0]['user_id']);
        $this->assertEquals(50000.00, (float) $items[0]['base_amount']);
    }

    /** @test */
    public function test_standalone_summary_endpoint_returns_correct_kpis(): void
    {
        $sale = Sale::create([
            'user_id'        => $this->farmerA->id,
            'date'           => now()->toDateString(),
            'buyer_name'     => 'Buyer Test',
            'weight_kg'      => 1,
            'price_per_kg'   => 80000,
            'total'          => 80000,
            'payment_status' => 'paid',
        ]);
        Commission::create([
            'sale_id'           => $sale->id,
            'user_id'           => $this->farmerA->id,
            'rate'              => 3.00,
            'base_amount'       => 80000.00,
            'commission_amount' => 2400.00,
            'net_farmer_amount' => 77600.00,
            'status'            => 'calculated',
        ]);

        Sanctum::actingAs($this->superAdmin);
        $response = $this->getJson('/api/commissions/summary');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'total_transactions'      => 1,
                    'total_gross_amount'      => 80000.00,
                    'total_commission_amount' => 2400.00,
                    'total_net_farmer_amount' => 77600.00,
                ],
            ]);
    }

    /** @test */
    public function test_unauthenticated_request_is_rejected(): void
    {
        $response = $this->getJson('/api/commissions');
        $response->assertStatus(401);
    }
}
