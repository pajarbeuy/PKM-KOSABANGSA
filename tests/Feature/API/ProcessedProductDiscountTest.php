<?php

namespace Tests\Feature\API;

use App\Models\ProcessedProduct;
use App\Models\ProcessedProductDiscount;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProcessedProductDiscountTest extends TestCase
{
    use RefreshDatabase;

    private User $superAdmin;
    private User $farmer;
    private ProcessedProduct $product;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superAdmin = User::factory()->create([
            'role'   => 'super_admin',
            'status' => 'active',
        ]);

        $this->farmer = User::factory()->create([
            'role'   => 'user',
            'status' => 'active',
        ]);

        $this->product = ProcessedProduct::create([
            'owner_id'    => $this->farmer->id,
            'name'        => 'Keripik Pisang Coklat',
            'price'       => 20000.00,
            'stock'       => 50,
            'status'      => 'active',
            'description' => 'Keripik pisang aneka rasa',
        ]);
    }

    /** @test */
    public function test_super_admin_can_create_valid_discount(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/super-admin/discounts', [
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 10.00,
            'start_date'           => now()->toDateString(),
            'end_date'             => now()->addDays(7)->toDateString(),
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'processed_product_id' => $this->product->id,
                    'discount_percentage'  => '10.00',
                ],
            ]);

        $this->assertDatabaseHas('processed_product_discounts', [
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 10.00,
            'created_by'           => $this->superAdmin->id,
        ]);
    }

    /** @test */
    public function test_supports_decimal_percentage_accurately(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/super-admin/discounts', [
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 7.50,
            'start_date'           => now()->toDateString(),
            'end_date'             => now()->addDays(5)->toDateString(),
        ]);

        $response->assertStatus(201);
        $this->assertEquals(7.50, (float) $response->json('data.discount_percentage'));
    }

    /** @test */
    public function test_rejects_discount_greater_than_100_percent(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/super-admin/discounts', [
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 105.00,
            'start_date'           => now()->toDateString(),
            'end_date'             => now()->addDays(7)->toDateString(),
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['discount_percentage']);
    }

    /** @test */
    public function test_rejects_discount_less_than_or_equal_to_zero(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $responseZero = $this->postJson('/api/super-admin/discounts', [
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 0,
            'start_date'           => now()->toDateString(),
            'end_date'             => now()->addDays(7)->toDateString(),
        ]);
        $responseZero->assertStatus(422)->assertJsonValidationErrors(['discount_percentage']);

        $responseNegative = $this->postJson('/api/super-admin/discounts', [
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => -5,
            'start_date'           => now()->toDateString(),
            'end_date'             => now()->addDays(7)->toDateString(),
        ]);
        $responseNegative->assertStatus(422)->assertJsonValidationErrors(['discount_percentage']);
    }

    /** @test */
    public function test_rejects_start_date_greater_than_end_date(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/super-admin/discounts', [
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 15.00,
            'start_date'           => '2026-10-10',
            'end_date'             => '2026-10-05',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['end_date']);
    }

    /** @test */
    public function test_rejects_overlapping_discount_period(): void
    {
        Sanctum::actingAs($this->superAdmin);

        // 1. Create first discount: 1 Oct - 10 Oct
        ProcessedProductDiscount::create([
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 10.00,
            'start_date'           => '2026-10-01',
            'end_date'             => '2026-10-10',
            'created_by'           => $this->superAdmin->id,
        ]);

        // 2. Attempt overlapping discount: 5 Oct - 15 Oct (must be rejected)
        $overlapResponse = $this->postJson('/api/super-admin/discounts', [
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 20.00,
            'start_date'           => '2026-10-05',
            'end_date'             => '2026-10-15',
        ]);

        $overlapResponse->assertStatus(422)
            ->assertJsonValidationErrors(['start_date']);
    }

    /** @test */
    public function test_active_discount_calculation_and_non_destructive_original_price(): void
    {
        // Active discount: 10% on Rp 20.000 -> Rp 2.000 discount, effective price Rp 18.000
        ProcessedProductDiscount::create([
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 10.00,
            'start_date'           => now()->subDay()->toDateString(),
            'end_date'             => now()->addDays(5)->toDateString(),
            'created_by'           => $this->superAdmin->id,
        ]);

        $freshProduct = $this->product->fresh(['activeDiscount']);

        // Original price must remain untouched (Source of Truth)
        $this->assertEquals(20000.00, (float) $freshProduct->price);
        $this->assertEquals(20000.00, $freshProduct->original_price);

        // Effective price calculation
        $this->assertEquals(18000.00, $freshProduct->effective_price);
        $this->assertEquals(2000.00, $freshProduct->discount_amount);
        $this->assertEquals(10.00, $freshProduct->discount_percentage);
        $this->assertTrue($freshProduct->is_discounted);
    }

    /** @test */
    public function test_expired_discount_automatically_falls_back_to_original_price(): void
    {
        // Expired discount: ended yesterday
        ProcessedProductDiscount::create([
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 25.00,
            'start_date'           => now()->subDays(10)->toDateString(),
            'end_date'             => now()->subDay()->toDateString(),
            'created_by'           => $this->superAdmin->id,
        ]);

        $freshProduct = $this->product->fresh(['activeDiscount']);

        $this->assertEquals(20000.00, (float) $freshProduct->price);
        $this->assertEquals(20000.00, $freshProduct->effective_price);
        $this->assertEquals(0.00, $freshProduct->discount_amount);
        $this->assertNull($freshProduct->discount_percentage);
        $this->assertFalse($freshProduct->is_discounted);
    }

    /** @test */
    public function test_future_discount_falls_back_to_original_price_until_active(): void
    {
        // Future discount starts next week
        ProcessedProductDiscount::create([
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 50.00,
            'start_date'           => now()->addDays(7)->toDateString(),
            'end_date'             => now()->addDays(14)->toDateString(),
            'created_by'           => $this->superAdmin->id,
        ]);

        $freshProduct = $this->product->fresh(['activeDiscount']);

        $this->assertEquals(20000.00, $freshProduct->effective_price);
        $this->assertFalse($freshProduct->is_discounted);
    }

    /** @test */
    public function test_super_admin_can_update_and_delete_discount(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $discount = ProcessedProductDiscount::create([
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 10.00,
            'start_date'           => now()->toDateString(),
            'end_date'             => now()->addDays(3)->toDateString(),
            'created_by'           => $this->superAdmin->id,
        ]);

        // Update discount percentage to 15%
        $updateResponse = $this->putJson("/api/super-admin/discounts/{$discount->id}", [
            'discount_percentage' => 15.00,
        ]);

        $updateResponse->assertStatus(200);
        $this->assertEquals(15.00, (float) $discount->fresh()->discount_percentage);

        // Delete discount
        $deleteResponse = $this->deleteJson("/api/super-admin/discounts/{$discount->id}");
        $deleteResponse->assertStatus(200);

        $this->assertDatabaseMissing('processed_product_discounts', ['id' => $discount->id]);
    }

    /** @test */
    public function test_unauthorized_farmer_cannot_create_or_modify_discounts(): void
    {
        Sanctum::actingAs($this->farmer);

        $response = $this->postJson('/api/super-admin/discounts', [
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 10.00,
            'start_date'           => now()->toDateString(),
            'end_date'             => now()->addDays(7)->toDateString(),
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function test_public_catalog_returns_discount_information_when_active(): void
    {
        ProcessedProductDiscount::create([
            'processed_product_id' => $this->product->id,
            'discount_percentage'  => 10.00,
            'start_date'           => now()->subDay()->toDateString(),
            'end_date'             => now()->addDays(7)->toDateString(),
            'created_by'           => $this->superAdmin->id,
        ]);

        $response = $this->getJson('/api/catalog/processed-products');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'products' => [
                        '*' => [
                            'id',
                            'name',
                            'price',
                            'original_price',
                            'effective_price',
                            'discount_percentage',
                            'discount_amount',
                            'is_discounted',
                        ],
                    ],
                ],
            ]);

        $productData = collect($response->json('data.products'))->firstWhere('id', $this->product->id);
        $this->assertNotNull($productData);
        $this->assertEquals(20000.00, (float) $productData['original_price']);
        $this->assertEquals(18000.00, (float) $productData['effective_price']);
        $this->assertEquals(10.00, (float) $productData['discount_percentage']);
        $this->assertTrue($productData['is_discounted']);
    }
}
