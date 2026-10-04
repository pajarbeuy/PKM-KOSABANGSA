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
        // Performance & Scalability indexing for queries across >= 600 users
        Schema::table('sales', function (Blueprint $table) {
            $existing = array_column(Schema::getIndexes('sales'), 'name');

            if (!in_array('sales_user_date_idx', $existing)) {
                $table->index(['user_id', 'date'], 'sales_user_date_idx');
            }
            if (!in_array('sales_prodtype_date_idx', $existing)) {
                $table->index(['product_type', 'date'], 'sales_prodtype_date_idx');
            }
            if (!in_array('sales_payment_status_idx', $existing)) {
                $table->index(['payment_status'], 'sales_payment_status_idx');
            }
        });

        Schema::table('orders', function (Blueprint $table) {
            $existing = array_column(Schema::getIndexes('orders'), 'name');

            if (!in_array('orders_status_created_idx', $existing)) {
                $table->index(['status', 'created_at'], 'orders_status_created_idx');
            }
        });

        Schema::table('commissions', function (Blueprint $table) {
            $existing = array_column(Schema::getIndexes('commissions'), 'name');

            if (!in_array('commissions_status_idx', $existing)) {
                $table->index(['status'], 'commissions_status_idx');
            }
        });

        Schema::table('harvests', function (Blueprint $table) {
            $existing = array_column(Schema::getIndexes('harvests'), 'name');

            if (!in_array('harvests_user_date_idx', $existing)) {
                $table->index(['user_id', 'date'], 'harvests_user_date_idx');
            }
        });

        Schema::table('stock_transactions', function (Blueprint $table) {
            $existing = array_column(Schema::getIndexes('stock_transactions'), 'name');

            if (!in_array('stock_tx_user_created_idx', $existing)) {
                $table->index(['user_id', 'created_at'], 'stock_tx_user_created_idx');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            $table->dropIndex('sales_user_date_idx');
            $table->dropIndex('sales_prodtype_date_idx');
            $table->dropIndex('sales_payment_status_idx');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex('orders_status_created_idx');
        });

        Schema::table('commissions', function (Blueprint $table) {
            $table->dropIndex('commissions_status_idx');
        });

        Schema::table('harvests', function (Blueprint $table) {
            $table->dropIndex('harvests_user_date_idx');
        });

        Schema::table('stock_transactions', function (Blueprint $table) {
            $table->dropIndex('stock_tx_user_created_idx');
        });
    }
};
