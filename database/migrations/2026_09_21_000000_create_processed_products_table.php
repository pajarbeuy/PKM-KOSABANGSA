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
        Schema::create('processed_products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_id')->constrained('users')->onDelete('restrict');
            $table->string('name');
            $table->decimal('price', 12, 2);
            $table->integer('stock')->default(0);
            $table->text('description')->nullable();
            $table->string('photo')->nullable();
            $table->enum('status', ['active', 'out_of_stock', 'inactive'])->default('out_of_stock');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('processed_products');
    }
};
