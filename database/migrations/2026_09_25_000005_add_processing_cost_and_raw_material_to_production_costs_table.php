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
        // 1. Tambah relasi bahan baku ke processed_products
        Schema::table('processed_products', function (Blueprint $table) {
            $table->foreignId('harvest_id')->nullable()->after('owner_id')->constrained('harvests')->nullOnDelete();
            $table->decimal('raw_material_weight_kg', 10, 2)->default(0)->after('stock')->comment('Total bobot panen mentah yang dialihkan sebagai bahan baku');
        });

        // 2. Tambah kolom biaya pengolahan dan rincian bahan penolong ke production_costs
        Schema::table('production_costs', function (Blueprint $table) {
            $table->enum('cost_type', ['farm', 'processing'])->default('farm')->after('user_id')->comment('farm: modal tanam kebun, processing: modal pengolahan produk');
            $table->foreignId('processed_product_id')->nullable()->after('season_id')->constrained('processed_products')->cascadeOnDelete();
            $table->foreignId('raw_material_harvest_id')->nullable()->after('processed_product_id')->constrained('harvests')->nullOnDelete();
            $table->decimal('raw_material_weight_kg', 10, 2)->nullable()->after('raw_material_harvest_id')->comment('Bobot bahan baku panen yang digunakan untuk olahan');
            $table->string('item_name', 150)->nullable()->after('category')->comment('Nama bahan penolong (contoh: Tepung Terigu, Minyak)');
            $table->decimal('quantity', 10, 2)->nullable()->after('item_name');
            $table->string('unit', 50)->nullable()->after('quantity');
            $table->decimal('price_per_unit', 12, 2)->nullable()->after('unit');
        });

        // Ubah category menjadi string agar fleksibel menampung kategori kebun dan olahan
        // (seed, fertilizer, pesticide, other, raw_material_addon, packaging, utility, labor)
        Schema::table('production_costs', function (Blueprint $table) {
            $table->string('category', 50)->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('production_costs', function (Blueprint $table) {
            $table->dropForeign(['processed_product_id']);
            $table->dropForeign(['raw_material_harvest_id']);
            $table->dropColumn([
                'cost_type',
                'processed_product_id',
                'raw_material_harvest_id',
                'raw_material_weight_kg',
                'item_name',
                'quantity',
                'unit',
                'price_per_unit',
            ]);
        });

        Schema::table('processed_products', function (Blueprint $table) {
            $table->dropForeign(['harvest_id']);
            $table->dropColumn([
                'harvest_id',
                'raw_material_weight_kg',
            ]);
        });
    }
};
