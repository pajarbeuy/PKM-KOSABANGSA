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
        Schema::table('sales', function (Blueprint $table) {
            $table->foreignId('order_id')->nullable()->after('id')->constrained('orders')->nullOnDelete();
        });

        Schema::table('stock_transactions', function (Blueprint $table) {
            $table->foreignId('processed_product_id')->nullable()->after('user_id')->constrained('processed_products')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            $table->dropForeign(['order_id']);
            $table->dropColumn('order_id');
        });

        Schema::table('stock_transactions', function (Blueprint $table) {
            $table->dropForeign(['processed_product_id']);
            $table->dropColumn('processed_product_id');
        });
    }
};
