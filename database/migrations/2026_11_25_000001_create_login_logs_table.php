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
        Schema::create('login_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('farmer_group_id')->nullable()->constrained('farmer_groups')->nullOnDelete();
            $table->string('login_method', 32)->default('password'); // password, google
            $table->string('ip_address', 45)->nullable();
            $table->string('location', 255)->nullable();
            $table->string('user_agent', 500)->nullable();
            $table->timestamp('logged_in_at')->useCurrent();
            $table->timestamps();

            $table->index('logged_in_at', 'idx_login_logs_logged_in_at');
            $table->index(['user_id', 'logged_in_at'], 'idx_login_logs_user_date');
            $table->index(['farmer_group_id', 'logged_in_at'], 'idx_login_logs_group_date');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('login_logs');
    }
};
