<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasColumn('processed_products', 'unit')) {
            Schema::table('processed_products', function (Blueprint $table) {
                $table->string('unit', 10)->default('pcs')->after('stock');
            });
        }

        if (!Schema::hasColumn('stock_transactions', 'unit')) {
            Schema::table('stock_transactions', function (Blueprint $table) {
                $table->string('unit', 10)->default('kg')->after('amount');
            });
        }

        // Backfill existing processed product transactions to 'pcs'
        DB::table('processed_products')->whereNull('unit')->update(['unit' => 'pcs']);
        DB::table('stock_transactions')->whereNotNull('processed_product_id')->update(['unit' => 'pcs']);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('processed_products', 'unit')) {
            Schema::table('processed_products', function (Blueprint $table) {
                $table->dropColumn('unit');
            });
        }

        if (Schema::hasColumn('stock_transactions', 'unit')) {
            Schema::table('stock_transactions', function (Blueprint $table) {
                $table->dropColumn('unit');
            });
        }
    }
};
