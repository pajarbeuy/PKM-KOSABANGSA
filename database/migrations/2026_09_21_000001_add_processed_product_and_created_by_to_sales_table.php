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
            if (!Schema::hasColumn('sales', 'product_type')) {
                $table->enum('product_type', ['harvest', 'processed'])->default('harvest')->after('season_id');
            }
            if (!Schema::hasColumn('sales', 'processed_product_id')) {
                $table->foreignId('processed_product_id')->nullable()->after('product_type')->constrained('processed_products')->onDelete('restrict');
            }
            if (!Schema::hasColumn('sales', 'created_by')) {
                $table->foreignId('created_by')->nullable()->after('notes')->constrained('users')->onDelete('set null');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            if (Schema::hasColumn('sales', 'processed_product_id')) {
                $table->dropForeign(['processed_product_id']);
                $table->dropColumn('processed_product_id');
            }
            if (Schema::hasColumn('sales', 'created_by')) {
                $table->dropForeign(['created_by']);
                $table->dropColumn('created_by');
            }
            if (Schema::hasColumn('sales', 'product_type')) {
                $table->dropColumn('product_type');
            }
        });
    }
};
