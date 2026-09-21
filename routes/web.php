<?php

use App\Http\Controllers\PasswordResetController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
| Only the landing page and password reset flow are served via web.
| All other functionality is handled by the API (routes/api.php)
| consumed by the Flutter mobile client.
|--------------------------------------------------------------------------
*/

// Landing Page
Route::get('/', function () {
    $products = collect();
    $superAdminPhone = '6281234567890';

    try {
        if (\Illuminate\Support\Facades\Schema::hasTable('processed_products')) {
            $processedProductService = app(\App\Services\ProcessedProductService::class);
            $products = $processedProductService->getActiveCatalog([], 12);
        }
        if (\Illuminate\Support\Facades\Schema::hasTable('users')) {
            $superAdminUser = \App\Models\User::where('role', 'super_admin')->whereNotNull('phone')->first();
            if ($superAdminUser && $superAdminUser->phone) {
                $superAdminPhone = $superAdminUser->phone;
            }
        }
    } catch (\Throwable $e) {
        // Fallback gracefully if database table not yet migrated
    }

    return view('landing', compact('products', 'superAdminPhone'));
})->name('landing');

// Password Reset Flow (renders Blade views — required for email links)
Route::get('/forgot-password', [PasswordResetController::class, 'showForgotPasswordForm'])->name('password.request');
Route::post('/forgot-password', [PasswordResetController::class, 'sendResetLinkEmail'])->name('password.email');
Route::get('/reset-password/{token?}', [PasswordResetController::class, 'showResetPasswordForm'])->name('password.reset');
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword'])->name('password.update');
Route::get('/password-reset-success', [PasswordResetController::class, 'showResetSuccess'])->name('password.reset.success');
