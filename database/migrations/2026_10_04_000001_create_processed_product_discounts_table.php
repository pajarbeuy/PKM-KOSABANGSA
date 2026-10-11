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
        Schema::create('processed_product_discounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('processed_product_id')->constrained('processed_products')->cascadeOnDelete();
            $table->decimal('discount_percentage', 5, 2); // e.g. 5.00, 7.50, 12.50, 25.00
            $table->date('start_date');
            $table->date('end_date');
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->index(['processed_product_id', 'start_date', 'end_date'], 'prod_disc_dates_idx');
            $table->index(['start_date', 'end_date'], 'disc_date_range_idx');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('processed_product_discounts');
    }
};
