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
        Schema::table('password_reset_requests', function (Blueprint $table) {
            if (!Schema::hasColumn('password_reset_requests', 'contact_info')) {
                $table->string('contact_info', 100)->nullable()->after('farmer_group_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('password_reset_requests', function (Blueprint $table) {
            if (Schema::hasColumn('password_reset_requests', 'contact_info')) {
                $table->dropColumn('contact_info');
            }
        });
    }
};
