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
        Schema::create('market_prices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('commodity_id')
                ->constrained('farmer_commodities')
                ->onDelete('restrict');
            $table->decimal('price', 12, 2);
            $table->string('unit', 20)->default('kg');
            $table->date('effective_date');
            $table->string('source', 100)->default('manual');
            $table->text('notes')->nullable();
            $table->foreignId('created_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['commodity_id', 'effective_date'], 'uk_commodity_effective');
            $table->index(['commodity_id', 'effective_date'], 'idx_commodity_effective');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('market_prices');
    }
};
