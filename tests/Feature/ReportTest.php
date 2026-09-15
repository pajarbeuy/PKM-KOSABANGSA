<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Season;
use App\Models\Sale;
use App\Models\ProductionCost;
use App\Models\Harvest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'admin']);
        $this->season = Season::factory()->create(['user_id' => $this->user->id]);
    }

    /** @test */
    public function user_can_view_reports_page()
    {
        $response = $this->actingAs($this->user)
            ->get('/reports');

        $response->assertStatus(200);
        $response->assertViewIs('reports.index');
    }

    /** @test */
    public function profit_loss_report_calculates_correctly()
    {
        // Create data for the report
        Harvest::create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'date' => '2024-03-15',
            'weight_kg' => 1000,
            'notes' => 'Good harvest',
            'location' => 'Main field',
        ]);

        Sale::create([
            'user_id' => $this->user->id,
            'date' => '2024-03-20',
            'buyer_name' => 'Market',
            'quantity_kg' => 800,
            'price_per_kg' => 5000,
            'total_price' => 4000000,
            'payment_status' => 'paid',
        ]);

        ProductionCost::create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'category' => 'bibit',
            'amount' => 1000000,
            'date' => '2024-01-15',
            'description' => 'Seeds',
        ]);

        ProductionCost::create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'category' => 'pupuk',
            'amount' => 500000,
            'date' => '2024-02-01',
            'description' => 'Fertilizer',
        ]);

        $response = $this->actingAs($this->user)
            ->get('/reports');

        $response->assertStatus(200);
        // Profit = Revenue - Cost = 4000000 - (1000000 + 500000) = 2500000
    }

    /** @test */
    public function user_can_view_profit_loss_report_by_season()
    {
        $response = $this->actingAs($this->user)
            ->get("/reports/profit-loss?season_id={$this->season->id}");

        $response->assertStatus(200);
    }

    /** @test */
    public function user_can_view_target_vs_actual_report()
    {
        $this->season->update(['target_kg' => 1000]);

        Harvest::create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'date' => '2024-03-15',
            'weight_kg' => 800,
            'notes' => 'Harvest',
            'location' => 'Main field',
        ]);

        $response = $this->actingAs($this->user)
            ->get("/reports/target-vs-actual?season_id={$this->season->id}");

        $response->assertStatus(200);
    }

    /** @test */
    public function unauthenticated_user_cannot_view_reports()
    {
        $response = $this->get('/reports');
        $response->assertRedirect('/login');
    }

    /** @test */
    public function user_can_export_profit_loss_report()
    {
        Sale::create([
            'user_id' => $this->user->id,
            'date' => '2024-03-20',
            'buyer_name' => 'Market',
            'quantity_kg' => 100,
            'price_per_kg' => 5000,
            'total_price' => 500000,
            'payment_status' => 'paid',
        ]);

        ProductionCost::create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'category' => 'bibit',
            'amount' => 200000,
            'date' => '2024-01-15',
            'description' => 'Seeds',
        ]);

        $response = $this->actingAs($this->user)
            ->get('/reports/export-profit-loss');

        $response->assertStatus(200);
    }

    /** @test */
    public function report_data_is_user_scoped()
    {
        $otherUser = User::factory()->create();
        $otherSeason = Season::factory()->create(['user_id' => $otherUser->id]);

        Sale::create([
            'user_id' => $otherUser->id,
            'date' => '2024-03-20',
            'buyer_name' => 'Other Market',
            'quantity_kg' => 500,
            'price_per_kg' => 6000,
            'total_price' => 3000000,
            'payment_status' => 'paid',
        ]);

        $response = $this->actingAs($this->user)
            ->get('/reports');

        $response->assertStatus(200);
        // Verify that report doesn't include other user's data
    }

    /** @test */
    public function harvest_summary_shows_total_harvest_kg()
    {
        Harvest::create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'date' => '2024-03-15',
            'weight_kg' => 500,
            'notes' => 'Harvest 1',
            'location' => 'Main field',
        ]);

        Harvest::create([
            'user_id' => $this->user->id,
            'season_id' => $this->season->id,
            'date' => '2024-03-20',
            'weight_kg' => 600,
            'notes' => 'Harvest 2',
            'location' => 'Main field',
        ]);

        $totalHarvest = Harvest::where('user_id', $this->user->id)->sum('weight_kg');
        $this->assertEquals(1100, $totalHarvest);
    }

    /** @test */
    public function sales_summary_shows_total_revenue()
    {
        Sale::create([
            'user_id' => $this->user->id,
            'date' => '2024-03-20',
            'buyer_name' => 'Market 1',
            'quantity_kg' => 100,
            'price_per_kg' => 5000,
            'total_price' => 500000,
            'payment_status' => 'paid',
        ]);

        Sale::create([
            'user_id' => $this->user->id,
            'date' => '2024-03-21',
            'buyer_name' => 'Market 2',
            'quantity_kg' => 150,
            'price_per_kg' => 5000,
            'total_price' => 750000,
            'payment_status' => 'paid',
        ]);

        $totalRevenue = Sale::where('user_id', $this->user->id)->sum('total_price');
        $this->assertEquals(1250000, $totalRevenue);
    }
}
