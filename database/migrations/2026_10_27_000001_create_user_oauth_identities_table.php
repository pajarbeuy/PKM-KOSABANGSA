<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Creates the user_oauth_identities table to store external OAuth provider
 * identities (e.g. Google) linked to local user accounts.
 *
 * Design decisions:
 * - Separate table (not columns on users) to support multiple providers per user
 *   in the future without schema bloat.
 * - Unique constraint on (provider, provider_user_id) to prevent one Google
 *   account from being linked to multiple local accounts.
 * - Does NOT store passwords, Google ID tokens, refresh tokens, or any secret.
 * - provider_user_id is the stable Google "sub" claim (never changes per account).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_oauth_identities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // e.g. 'google' — extensible for future providers
            $table->string('provider', 32);

            // Google's stable "sub" claim — immutable identifier per Google account
            $table->string('provider_user_id', 255);

            $table->timestamps();

            // One external identity can only belong to one local account
            $table->unique(['provider', 'provider_user_id']);

            // Efficient lookup: find identity by user
            $table->index(['user_id', 'provider']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_oauth_identities');
    }
};
