<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\StockTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StockTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'admin']);
    }

    /** @test */
    public function user_can_view_stock_status()
    {
        $response = $this->actingAs($this->user)
            ->get('/stock');

        $response->assertStatus(200);
        $response->assertViewIs('stock.index');
    }

    /** @test */
    public function user_can_record_incoming_stock()
    {
        $response = $this->actingAs($this->user)
            ->post('/stock/transactions', [
                'type' => 'in',
                'amount' => 500,
                'date' => '2024-03-15',
                'reference' => 'Panen',
                'notes' => 'Dari panen musim 1',
            ]);

        $this->assertDatabaseHas('stock_transactions', [
            'user_id' => $this->user->id,
            'type' => 'in',
            'amount' => 500,
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');
    }

    /** @test */
    public function user_can_record_outgoing_stock()
    {
        // First add incoming stock
        StockTransaction::create([
            'user_id' => $this->user->id,
            'type' => 'in',
            'amount' => 1000,
            'date' => '2024-03-15',
            'reference' => 'Panen',
            'notes' => 'Initial stock',
        ]);

        $response = $this->actingAs($this->user)
            ->post('/stock/transactions', [
                'type' => 'out',
                'amount' => 100,
                'date' => '2024-03-16',
                'reference' => 'Penjualan',
                'notes' => 'Jual ke pasar',
            ]);

        $this->assertDatabaseHas('stock_transactions', [
            'user_id' => $this->user->id,
            'type' => 'out',
            'amount' => 100,
        ]);

        $response->assertRedirect();
    }

    /** @test */
    public function user_can_view_stock_transactions()
    {
        StockTransaction::factory(3)->create(['user_id' => $this->user->id]);

        $response = $this->actingAs($this->user)
            ->get('/stock');

        $transactions = $response->viewData('transactions');
        $this->assertCount(3, $transactions);
    }

    /** @test */
    public function stock_balance_is_calculated_correctly()
    {
        // Add incoming stock
        StockTransaction::create([
            'user_id' => $this->user->id,
            'type' => 'in',
            'amount' => 1000,
            'date' => '2024-03-15',
            'reference' => 'Panen',
            'notes' => 'From harvest',
        ]);

        // Remove outgoing stock
        StockTransaction::create([
            'user_id' => $this->user->id,
            'type' => 'out',
            'amount' => 300,
            'date' => '2024-03-16',
            'reference' => 'Penjualan',
            'notes' => 'Sold to market',
        ]);

        $balance = StockTransaction::getCurrentBalance($this->user->id);
        $this->assertEquals(700, $balance);
    }

    /** @test */
    public function user_cannot_record_zero_stock()
    {
        $response = $this->actingAs($this->user)
            ->post('/stock/transactions', [
                'type' => 'in',
                'amount' => 0,
                'date' => '2024-03-15',
                'reference' => 'Panen',
                'notes' => 'Test',
            ]);

        $response->assertSessionHasErrors('amount');
    }

    /** @test */
    public function user_cannot_record_negative_stock()
    {
        $response = $this->actingAs($this->user)
            ->post('/stock/transactions', [
                'type' => 'in',
                'amount' => -100,
                'date' => '2024-03-15',
                'reference' => 'Panen',
                'notes' => 'Test',
            ]);

        $response->assertSessionHasErrors('amount');
    }

    /** @test */
    public function unauthenticated_user_cannot_view_stock()
    {
        $response = $this->get('/stock');
        $response->assertRedirect('/login');
    }

    /** @test */
    public function user_can_only_see_own_stock_transactions()
    {
        $otherUser = User::factory()->create();
        StockTransaction::factory(3)->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($this->user)
            ->get('/stock');

        $transactions = $response->viewData('transactions');
        $this->assertCount(0, $transactions);
    }

    /** @test */
    public function stock_transaction_requires_valid_date()
    {
        $response = $this->actingAs($this->user)
            ->post('/stock/transactions', [
                'type' => 'in',
                'amount' => 500,
                'date' => 'invalid-date',
                'reference' => 'Panen',
                'notes' => 'Test',
            ]);

        $response->assertSessionHasErrors('date');
    }
}
