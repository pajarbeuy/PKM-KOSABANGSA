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
        Schema::table('harvests', function (Blueprint $table) {
            if (!Schema::hasColumn('harvests', 'quantity')) {
                $table->integer('quantity')->nullable()->default(0)->after('season_id');
            }
        });

        Schema::table('sales', function (Blueprint $table) {
            if (!Schema::hasColumn('sales', 'buyer_phone')) {
                $table->string('buyer_phone', 20)->nullable()->after('buyer_name');
            }
            if (!Schema::hasColumn('sales', 'notes')) {
                $table->text('notes')->nullable()->after('payment_status');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('harvests', function (Blueprint $table) {
            if (Schema::hasColumn('harvests', 'quantity')) {
                $table->dropColumn('quantity');
            }
        });

        Schema::table('sales', function (Blueprint $table) {
            $columns = [];
            if (Schema::hasColumn('sales', 'buyer_phone')) {
                $columns[] = 'buyer_phone';
            }
            if (Schema::hasColumn('sales', 'notes')) {
                $columns[] = 'notes';
            }
            if (!empty($columns)) {
                $table->dropColumn($columns);
            }
        });
    }
};
