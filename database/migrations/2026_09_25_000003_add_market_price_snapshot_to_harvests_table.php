<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('harvests', function (Blueprint $table) {
            $table->foreignId('market_price_id')
                ->nullable()
                ->after('commodity_id')
                ->constrained('market_prices')
                ->nullOnDelete();
            $table->decimal('market_price_snapshot', 12, 2)
                ->nullable()
                ->after('market_price_id');
            $table->date('market_price_effective_date')
                ->nullable()
                ->after('market_price_snapshot');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('harvests', function (Blueprint $table) {
            $table->dropForeign(['market_price_id']);
            $table->dropColumn([
                'market_price_id',
                'market_price_snapshot',
                'market_price_effective_date',
            ]);
        });
    }
};
