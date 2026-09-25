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

use App\Http\Controllers\WebController;

// Platform Landing Page
Route::get('/', [WebController::class, 'landing'])->name('landing');

// Dedicated Public Product Catalog
Route::get('/katalog', [WebController::class, 'catalog'])->name('catalog');
Route::get('/catalog', fn() => redirect()->route('catalog'));

// Password Reset Flow (renders Blade views — required for email links)
Route::get('/forgot-password', [PasswordResetController::class, 'showForgotPasswordForm'])->name('password.request');
Route::post('/forgot-password', [PasswordResetController::class, 'sendResetLinkEmail'])->name('password.email');
Route::get('/reset-password/{token?}', [PasswordResetController::class, 'showResetPasswordForm'])->name('password.reset');
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword'])->name('password.update');
Route::get('/password-reset-success', [PasswordResetController::class, 'showResetSuccess'])->name('password.reset.success');
