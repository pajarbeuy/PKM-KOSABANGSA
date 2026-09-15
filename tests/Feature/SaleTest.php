<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Sale;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SaleTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'admin']);
    }

    /** @test */
    public function user_can_view_sales_list()
    {
        $response = $this->actingAs($this->user)
            ->get('/sales');

        $response->assertStatus(200);
        $response->assertViewIs('sales.index');
    }

    /** @test */
    public function user_can_record_sale()
    {
        $response = $this->actingAs($this->user)
            ->post('/sales', [
                'date' => '2024-03-15',
                'buyer_name' => 'Toko Sayuran Jaya',
                'quantity_kg' => 100,
                'price_per_kg' => 5000,
                'total_price' => 500000,
                'payment_status' => 'paid',
                'notes' => 'Penjualan harian',
            ]);

        $this->assertDatabaseHas('sales', [
            'user_id' => $this->user->id,
            'buyer_name' => 'Toko Sayuran Jaya',
            'quantity_kg' => 100,
            'price_per_kg' => 5000,
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');
    }

    /** @test */
    public function user_can_view_sale_details()
    {
        $sale = Sale::factory()->create(['user_id' => $this->user->id]);

        $response = $this->actingAs($this->user)
            ->get("/sales/{$sale->id}");

        $response->assertStatus(200);
        $response->assertViewHas('sale', $sale);
    }

    /** @test */
    public function user_can_update_sale()
    {
        $sale = Sale::factory()->create([
            'user_id' => $this->user->id,
            'quantity_kg' => 100,
        ]);

        $response = $this->actingAs($this->user)
            ->put("/sales/{$sale->id}", [
                'date' => '2024-03-20',
                'buyer_name' => 'Updated Buyer',
                'quantity_kg' => 150,
                'price_per_kg' => 5000,
                'total_price' => 750000,
                'payment_status' => 'pending',
                'notes' => 'Updated',
            ]);

        $this->assertDatabaseHas('sales', [
            'id' => $sale->id,
            'quantity_kg' => 150,
            'buyer_name' => 'Updated Buyer',
        ]);

        $response->assertRedirect();
    }

    /** @test */
    public function user_can_delete_sale()
    {
        $sale = Sale::factory()->create(['user_id' => $this->user->id]);

        $response = $this->actingAs($this->user)
            ->delete("/sales/{$sale->id}");

        $this->assertDatabaseMissing('sales', ['id' => $sale->id]);
        $response->assertRedirect();
    }

    /** @test */
    public function sale_requires_valid_quantity()
    {
        $response = $this->actingAs($this->user)
            ->post('/sales', [
                'date' => '2024-03-15',
                'buyer_name' => 'Buyer',
                'quantity_kg' => -50,
                'price_per_kg' => 5000,
                'total_price' => -250000,
                'payment_status' => 'paid',
                'notes' => 'Test',
            ]);

        $response->assertSessionHasErrors('quantity_kg');
    }

    /** @test */
    public function sale_requires_valid_price()
    {
        $response = $this->actingAs($this->user)
            ->post('/sales', [
                'date' => '2024-03-15',
                'buyer_name' => 'Buyer',
                'quantity_kg' => 100,
                'price_per_kg' => -5000,
                'total_price' => -500000,
                'payment_status' => 'paid',
                'notes' => 'Test',
            ]);

        $response->assertSessionHasErrors('price_per_kg');
    }

    /** @test */
    public function sale_payment_status_must_be_valid()
    {
        $response = $this->actingAs($this->user)
            ->post('/sales', [
                'date' => '2024-03-15',
                'buyer_name' => 'Buyer',
                'quantity_kg' => 100,
                'price_per_kg' => 5000,
                'total_price' => 500000,
                'payment_status' => 'invalid_status',
                'notes' => 'Test',
            ]);

        $response->assertSessionHasErrors('payment_status');
    }

    /** @test */
    public function unauthenticated_user_cannot_view_sales()
    {
        $response = $this->get('/sales');
        $response->assertRedirect('/login');
    }

    /** @test */
    public function user_can_only_see_own_sales()
    {
        $otherUser = User::factory()->create();
        Sale::factory(3)->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($this->user)
            ->get('/sales');

        $sales = $response->viewData('sales');
        $this->assertCount(0, $sales);
    }

    /** @test */
    public function total_price_is_calculated_correctly()
    {
        $sale = Sale::factory()->create([
            'user_id' => $this->user->id,
            'quantity_kg' => 100,
            'price_per_kg' => 5000,
            'total_price' => 500000,
        ]);

        $this->assertEquals(500000, $sale->total_price);
        $this->assertEquals(100 * 5000, $sale->total_price);
    }
}
