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
        Schema::create('stock_transactions', function (Blueprint $table) {
            $table->id();
            $table->enum('type', ['in', 'out', 'adjustment'])->comment('in=panen/masuk, out=penjualan/keluar, adjustment=koreksi');
            $table->decimal('amount', 12, 2);
            $table->text('notes')->nullable();
            $table->string('reference')->nullable()->comment('reference ke harvest_id, sale_id, etc');
            $table->decimal('balance_after', 12, 2);
            $table->dateTime('date');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('stock_transactions');
    }
};
