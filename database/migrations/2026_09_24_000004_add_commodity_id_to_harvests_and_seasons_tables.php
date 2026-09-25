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
        Schema::table('seasons', function (Blueprint $table) {
            $table->foreignId('commodity_id')
                ->nullable()
                ->after('user_id')
                ->constrained('farmer_commodities')
                ->nullOnDelete();
        });

        Schema::table('harvests', function (Blueprint $table) {
            $table->foreignId('commodity_id')
                ->nullable()
                ->after('season_id')
                ->constrained('farmer_commodities')
                ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('harvests', function (Blueprint $table) {
            $table->dropForeign(['commodity_id']);
            $table->dropColumn('commodity_id');
        });

        Schema::table('seasons', function (Blueprint $table) {
            $table->dropForeign(['commodity_id']);
            $table->dropColumn('commodity_id');
        });
    }
};
