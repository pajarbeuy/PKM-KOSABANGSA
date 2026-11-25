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

// Download Android Application (APK)
Route::get('/download/sumbersarihub.apk', function () {
    $path = public_path('download/sumbersarihub.apk');
    if (!file_exists($path)) {
        $fallback = public_path('download/simhpsk.apk');
        if (file_exists($fallback)) {
            return response()->download($fallback, 'sumbersarihub.apk', [
                'Content-Type' => 'application/vnd.android.package-archive',
            ]);
        }
        abort(404, 'File aplikasi belum tersedia. Silakan hubungi administrator.');
    }
    return response()->download($path, 'sumbersarihub.apk', [
        'Content-Type' => 'application/vnd.android.package-archive',
    ]);
})->name('download.apk');

// Password Reset Flow (renders Blade views — required for email links)
Route::get('/forgot-password', [PasswordResetController::class, 'showForgotPasswordForm'])->name('password.request');
Route::post('/forgot-password', [PasswordResetController::class, 'sendResetLinkEmail'])->name('password.email');
Route::get('/reset-password/{token?}', [PasswordResetController::class, 'showResetPasswordForm'])->name('password.reset');
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword'])->name('password.update');
Route::get('/password-reset-success', [PasswordResetController::class, 'showResetSuccess'])->name('password.reset.success');
