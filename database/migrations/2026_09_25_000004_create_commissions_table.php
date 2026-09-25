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
        Schema::create('commissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_id')->constrained('sales')->cascadeOnDelete();
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete(); // Petani pemilik produk/hasil tani
            $table->decimal('rate', 5, 2)->default(10.00); // 10.00%
            $table->decimal('base_amount', 14, 2); // Gross transaction total (subtotal/total penjualan)
            $table->decimal('commission_amount', 14, 2); // 10% dari base_amount
            $table->decimal('net_farmer_amount', 14, 2); // base_amount - commission_amount
            $table->string('status', 30)->default('calculated'); // 'calculated', 'settled'
            $table->text('notes')->nullable();
            $table->timestamps();

            // Idempotency: One commission record strictly per sale
            $table->unique('sale_id');
            $table->index(['user_id', 'created_at']);
            $table->index(['order_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('commissions');
    }
};
