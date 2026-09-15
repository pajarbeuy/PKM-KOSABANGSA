<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Auth;

class AuthorizationServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Middleware to check if user is super admin
        \Illuminate\Support\Facades\Route::middleware(['web'])->group(function () {
            // Define gates for authorization
            \Illuminate\Support\Facades\Gate::define('super-admin', function ($user) {
                return $user->role === 'super_admin';
            });
        });
    }
}
