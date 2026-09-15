<?php

namespace App\Console\Commands;

use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\Season;
use App\Models\StockTransaction;
use App\Models\User;
use Illuminate\Console\Command;

class BackfillUserIdCommand extends Command
{
    protected $signature = 'app:backfill-user-id';
    protected $description = 'Backfill user_id untuk data yang sudah ada';

    public function handle()
    {
        // Get first user (any role), atau buat default jika tidak ada
        $defaultUser = User::where('role', 'user')->first() ?? User::first();

        if (!$defaultUser) {
            $this->error('No users found in database. Please create a user first.');
            return;
        }

        $userId = $defaultUser->id;
        $this->info("Using user ID: {$userId} ({$defaultUser->name})");

        // Backfill seasons
        $seasonCount = Season::whereNull('user_id')->count();
        if ($seasonCount > 0) {
            Season::whereNull('user_id')->update(['user_id' => $userId]);
            $this->info("Updated {$seasonCount} seasons");
        }

        // Backfill harvests
        $harvestCount = Harvest::whereNull('user_id')->count();
        if ($harvestCount > 0) {
            Harvest::whereNull('user_id')->update(['user_id' => $userId]);
            $this->info("Updated {$harvestCount} harvests");
        }

        // Backfill stock transactions
        $stockCount = StockTransaction::whereNull('user_id')->count();
        if ($stockCount > 0) {
            StockTransaction::whereNull('user_id')->update(['user_id' => $userId]);
            $this->info("Updated {$stockCount} stock transactions");
        }

        // Backfill sales
        $saleCount = Sale::whereNull('user_id')->count();
        if ($saleCount > 0) {
            Sale::whereNull('user_id')->update(['user_id' => $userId]);
            $this->info("Updated {$saleCount} sales");
        }

        // Backfill production costs
        $costCount = ProductionCost::whereNull('user_id')->count();
        if ($costCount > 0) {
            ProductionCost::whereNull('user_id')->update(['user_id' => $userId]);
            $this->info("Updated {$costCount} production costs");
        }

        $this->info('Backfill completed successfully!');
    }
}
