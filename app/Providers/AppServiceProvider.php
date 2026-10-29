<?php

namespace App\Providers;

use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
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
        // Define rate limiter for auth endpoints (login, register, google, password reset)
        RateLimiter::for('auth', function (Request $request) {
            $key = strtolower($request->input('email', '')) . '|' . $request->ip();

            return Limit::perMinute(5)->by($key)->response(function () {
                return response()->json([
                    'success' => false,
                    'message' => 'Terlalu banyak percobaan. Silakan coba lagi dalam 1 menit.',
                ], 429);
            });
        });

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
