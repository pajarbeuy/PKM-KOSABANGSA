<?php

namespace App\Providers;

use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        ResetPassword::createUrlUsing(function ($user, string $token) {
            $frontend = env('FRONTEND_URL', config('app.url'));
            return rtrim($frontend, '/') . '/reset-password?token=' . $token . '&email=' . urlencode($user->email);
        });

        // Define gates for authorization
        Gate::define('super-admin', function ($user) {
            return $user && $user->role === 'super_admin';
        });

        Gate::define('admin', function ($user) {
            return $user && $user->role === 'super_admin';
        });
    }
}
