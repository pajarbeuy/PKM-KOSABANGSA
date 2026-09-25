<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CostController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\FeedbackController;
use App\Http\Controllers\HarvestController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\PasswordResetController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SaleController;
use App\Http\Controllers\SeasonController;
use App\Http\Controllers\SettingController;
use App\Http\Controllers\StockController;
use App\Http\Controllers\SuperAdmin\SuperAdminController;
use App\Http\Controllers\ProcessedProductController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\Api\ChatbotController;
use App\Http\Controllers\Api\FarmerGroupController;
use App\Http\Controllers\Api\FarmerCommodityController;
use App\Http\Controllers\Api\MarketPriceController;
use App\Http\Controllers\Api\FarmerEconomicResultController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// ─── Public Routes ───────────────────────────────────────────────────────────

Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login',    [AuthController::class, 'login']);

Route::post('/auth/forgot-password', [PasswordResetController::class, 'sendResetLinkEmailApi']);
Route::post('/auth/reset-password',  [PasswordResetController::class, 'resetPasswordApi']);

Route::get('/landing',  [SuperAdminController::class, 'getLanding']);
Route::get('/farmer-groups', [FarmerGroupController::class, 'index']);
Route::get('/catalog/processed-products', [ProcessedProductController::class, 'publicCatalog']);
Route::post('/catalog/orders',            [OrderController::class, 'storePublic']);
Route::get('/catalog/orders/{code}',      [OrderController::class, 'trackPublic']);

// Media / Storage file serving with CORS support for mobile & web apps
Route::get('/storage/{path}', function (string $path) {
    $cleanPath = ltrim($path, '/');
    if (!\Illuminate\Support\Facades\Storage::disk('public')->exists($cleanPath)) {
        abort(404, 'File not found');
    }

    $fullPath = \Illuminate\Support\Facades\Storage::disk('public')->path($cleanPath);
    $mime = mime_content_type($fullPath) ?: 'application/octet-stream';

    return response()->file($fullPath, [
        'Content-Type' => $mime,
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        'Access-Control-Allow-Headers' => '*',
        'Cache-Control' => 'public, max-age=86400',
    ]);
})->where('path', '.*');

// ─── Protected Routes ─────────────────────────────────────────────────────────

Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me',      [AuthController::class, 'me']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::get('/menus',     [SuperAdminController::class, 'indexMenus']);

    // Resources (standard Laravel resource method names)
    Route::apiResource('seasons',            SeasonController::class)->names('api.seasons');
    Route::apiResource('harvests',           HarvestController::class)->names('api.harvests');
    Route::apiResource('sales',              SaleController::class)->names('api.sales');
    Route::apiResource('costs',              CostController::class)->names('api.costs');
    Route::apiResource('processed-products', ProcessedProductController::class)->names('api.processed-products');
    Route::apiResource('commodities',        FarmerCommodityController::class)->names('api.commodities');

    // Market Prices (Phase 5 - Historical Market Price & Snapshot)
    Route::get('/market-prices',                      [MarketPriceController::class, 'index']);
    Route::get('/market-prices/latest/{commodity_id}', [MarketPriceController::class, 'latest']);
    Route::middleware('role:super_admin')->group(function () {
        Route::post('/market-prices',         [MarketPriceController::class, 'store']);
        Route::put('/market-prices/{id}',     [MarketPriceController::class, 'update']);
        Route::delete('/market-prices/{id}',  [MarketPriceController::class, 'destroy']);
        Route::post('/market-prices/ingest',  [MarketPriceController::class, 'ingest']);
    });

    // Economic Result (Phase 6 - Farmer Economic Result)
    Route::get('/harvests/{harvest}/economic-result',  [FarmerEconomicResultController::class, 'harvestEconomicResult']);
    Route::get('/seasons/{season}/economic-summary',   [FarmerEconomicResultController::class, 'seasonEconomicSummary']);
    Route::get('/farmer/economic-summary',             [FarmerEconomicResultController::class, 'farmerEconomicSummary']);

    // Stock (custom routes — not a standard CRUD resource)
    Route::get('/stock',                      [StockController::class, 'index']);
    Route::post('/stock/in',                  [StockController::class, 'storeIncoming']);
    Route::post('/stock/out',                 [StockController::class, 'storeOutgoing']);
    Route::delete('/stock/{transaction}',     [StockController::class, 'destroyTransaction']);

    // Reports
    Route::get('/reports/profit-loss',                    [ReportController::class, 'profitLoss']);
    Route::get('/reports/target-vs-actual',               [ReportController::class, 'targetVsActual']);
    Route::get('/reports/export/profit-loss/excel',       [ReportController::class, 'exportProfitLossExcel']);
    Route::get('/reports/export/profit-loss/pdf',         [ReportController::class, 'exportProfitLossPdf']);
    Route::get('/reports/export/target-vs-actual/excel',  [ReportController::class, 'exportTargetVsActualExcel']);
    Route::get('/reports/export/target-vs-actual/pdf',    [ReportController::class, 'exportTargetVsActualPdf']);

    // Settings
    Route::get('/settings',                [SettingController::class, 'index']);
    Route::post('/settings/profile',       [SettingController::class, 'updateProfile']);
    Route::post('/settings/password',      [SettingController::class, 'updatePassword']);
    Route::post('/settings/gudang',        [SettingController::class, 'updateGudang']);
    Route::post('/settings/notifications', [SettingController::class, 'updateNotifications']);
    Route::delete('/settings/account',     [SettingController::class, 'deleteAccount']);

    // Notifications
    Route::get('/notifications',       [NotificationController::class, 'index']);
    Route::post('/notifications/read', [NotificationController::class, 'markAsRead']);

    // Feedback
    Route::post('/feedback', [FeedbackController::class, 'store']);

    // ─── Super Admin ─────────────────────────────────────────────────────────────

    Route::middleware('role:super_admin')->prefix('super-admin')->group(function () {
        Route::get('/dashboard', [SuperAdminController::class, 'dashboard']);

        // User Management
        Route::get('/users',                      [SuperAdminController::class, 'indexUsers']);
        Route::post('/users',                     [SuperAdminController::class, 'storeUser']);
        Route::put('/users/{user}',               [SuperAdminController::class, 'updateUser']);
        Route::delete('/users/{user}',            [SuperAdminController::class, 'destroyUser']);
        Route::post('/users/{user}/impersonate',  [SuperAdminController::class, 'impersonate']);

        // Landing Content
        Route::get('/landing',  [SuperAdminController::class, 'getLanding']);
        Route::post('/landing', [SuperAdminController::class, 'updateLanding']);

        // Dashboard Menus
        Route::get('/menus',              [SuperAdminController::class, 'indexMenus']);
        Route::post('/menus',             [SuperAdminController::class, 'storeMenu']);
        Route::put('/menus/{menu}',       [SuperAdminController::class, 'updateMenu']);
        Route::delete('/menus/{menu}',    [SuperAdminController::class, 'destroyMenu']);

        // Processed Products Marketing Management
        Route::get('/processed-products',                           [ProcessedProductController::class, 'superAdminIndex']);
        Route::patch('/processed-products/{processedProduct}/status', [ProcessedProductController::class, 'superAdminUpdateStatus']);

        // Orders Management & Tracking
        Route::get('/orders',                  [OrderController::class, 'index']);
        Route::get('/orders/{order}',          [OrderController::class, 'show']);
        Route::patch('/orders/{order}/status', [OrderController::class, 'updateStatus']);
        Route::post('/orders/{order}/complete',[OrderController::class, 'complete']);
        Route::post('/orders/{order}/cancel',  [OrderController::class, 'cancel']);

        // Feedbacks
        Route::get('/feedbacks',                           [FeedbackController::class, 'indexSuperAdmin']);
        Route::post('/feedbacks/{feedback}/read',          [FeedbackController::class, 'markAsRead']);
        Route::delete('/feedbacks/{feedback}',             [FeedbackController::class, 'destroy']);

        // Reports Aggregate
        Route::get('/reports/farmer-profit-loss-aggregate', [SuperAdminController::class, 'farmerProfitLossAggregate']);

        // Economic Aggregate (Phase 6)
        Route::get('/economic-aggregate', [FarmerEconomicResultController::class, 'superAdminEconomicAggregate']);

        // Farmer Groups (Poktan) Management
        Route::get('/farmer-groups',              [FarmerGroupController::class, 'adminIndex']);
        Route::get('/farmer-groups/{id}',         [FarmerGroupController::class, 'show']);
        Route::post('/farmer-groups',             [FarmerGroupController::class, 'store']);
        Route::put('/farmer-groups/{id}',         [FarmerGroupController::class, 'update']);
        Route::delete('/farmer-groups/{id}',      [FarmerGroupController::class, 'destroy']);
        Route::post('/users/{id}/assign-poktan',  [FarmerGroupController::class, 'assignMember']);

        // Commodities Management & Monitoring
        Route::get('/commodities',                [FarmerCommodityController::class, 'adminIndex']);
        Route::put('/commodities/{id}',           [FarmerCommodityController::class, 'adminUpdate']);

        // Chatbot AI Operational Assistant
        Route::post('/chat', [ChatbotController::class, 'chat']);
    });

    // Chatbot endpoint protected for Super Admin
    Route::middleware('role:super_admin')->post('/chat', [ChatbotController::class, 'chat']);
});
