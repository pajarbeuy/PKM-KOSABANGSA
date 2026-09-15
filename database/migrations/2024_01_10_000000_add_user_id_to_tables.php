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
        // Add user_id to seasons
        Schema::table('seasons', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('id')->constrained()->onDelete('cascade');
        });

        // Add user_id to harvests
        Schema::table('harvests', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('id')->constrained()->onDelete('cascade');
        });

        // Add user_id to stock_transactions
        Schema::table('stock_transactions', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('id')->constrained()->onDelete('cascade');
        });

        // Add user_id to sales
        Schema::table('sales', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('id')->constrained()->onDelete('cascade');
        });

        // Add user_id to production_costs
        Schema::table('production_costs', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('id')->constrained()->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('seasons', function (Blueprint $table) {
            $table->dropForeignIdFor('User');
            $table->dropColumn('user_id');
        });

        Schema::table('harvests', function (Blueprint $table) {
            $table->dropForeignIdFor('User');
            $table->dropColumn('user_id');
        });

        Schema::table('stock_transactions', function (Blueprint $table) {
            $table->dropForeignIdFor('User');
            $table->dropColumn('user_id');
        });

        Schema::table('sales', function (Blueprint $table) {
            $table->dropForeignIdFor('User');
            $table->dropColumn('user_id');
        });

        Schema::table('production_costs', function (Blueprint $table) {
            $table->dropForeignIdFor('User');
            $table->dropColumn('user_id');
        });
    }
};
