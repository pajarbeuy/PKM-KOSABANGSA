# Walkthrough — PKM Refactoring

> Selesai pada: 2026-09-15 · Status: ✅ Semua changes diterapkan & PHP syntax valid

---

## Ringkasan Perubahan

### Phase 1 — High Priority Fixes

#### ✅ Composer Version Pinning
[composer.json](file:///d:/laragon/www/PKM/composer.json)
```diff
- "barryvdh/laravel-dompdf": "*",
+ "barryvdh/laravel-dompdf": "^3.1",
- "maatwebsite/excel": "*"
+ "maatwebsite/excel": "^3.1"
```
Mencegah `composer update` menarik versi major yang breaking secara tak sengaja.

---

#### ✅ N+1 Queries Fixed — 7 Method

Sebelum (N+1 — jika ada 50 season = 51 query):
```php
$seasons = Season::where('user_id', $userId)->get(); // 1 query
foreach ($seasons as $season) {
    $harvest = $season->harvests()->sum('weight_kg'); // +1 query per season!
}
```

Sesudah (selalu 2 query, berapapun jumlah season):
```php
$seasons = Season::where('user_id', $userId)
    ->withSum('harvests', 'weight_kg') // eager load dalam 1 query
    ->get();
foreach ($seasons as $season) {
    $harvest = $season->harvests_sum_weight_kg ?? 0; // dari memory
}
```

Method yang diperbaiki di [ReportController.php](file:///d:/laragon/www/PKM/app/Http/Controllers/ReportController.php):
- `targetVsActualApi()`
- `exportTargetVsActualExcel()`
- `exportTargetVsActualExcelApi()`
- `exportTargetVsActualPdf()`
- `exportTargetVsActualPdfApi()`

Method diperbaiki di [SuperAdminController.php](file:///d:/laragon/www/PKM/app/Http/Controllers/SuperAdmin/SuperAdminController.php):
- `updateLandingApi()` — diganti dari N×`updateOrCreate()` ke satu `upsert()` batch

---

### Phase 2 — Web Routes Cleanup

[web.php](file:///d:/laragon/www/PKM/routes/web.php) dipangkas dari **147 baris → 27 baris**.

| Sebelum | Sesudah |
|---------|---------|
| 40+ route (semua domain) | 6 route saja |
| Login/Register web routes | Dihapus (API-only) |
| Semua resource routes (season, harvest, dll) | Dihapus |
| Super Admin web routes | Dihapus |
| Landing page | ✅ Dipertahankan |
| Password reset flow | ✅ Dipertahankan (render Blade views) |

---

### Phase 3 — Service Layer (Semua Controller)

Dibuat folder baru `app/Services/` dengan **11 service files**:

| Service | Fungsi |
|---------|--------|
| [AuthService.php](file:///d:/laragon/www/PKM/app/Services/AuthService.php) | createUser, attemptLogin, createToken, formatUser |
| [CostService.php](file:///d:/laragon/www/PKM/app/Services/CostService.php) | createCost, updateCost, deleteCost, formatCost |
| [DashboardService.php](file:///d:/laragon/www/PKM/app/Services/DashboardService.php) | getSummary, getRecentHarvests, getRecentTransactions, getMonthlyStats |
| [FeedbackService.php](file:///d:/laragon/www/PKM/app/Services/FeedbackService.php) | createFeedback, getAllFeedbacks, markAsRead, deleteFeedback |
| [HarvestService.php](file:///d:/laragon/www/PKM/app/Services/HarvestService.php) | verifySeasonOwnership, createHarvest, updateHarvest, deleteHarvest, formatHarvest |
| [NotificationService.php](file:///d:/laragon/www/PKM/app/Services/NotificationService.php) | getUserNotifications, markOneAsRead, markAllAsRead |
| [ReportService.php](file:///d:/laragon/www/PKM/app/Services/ReportService.php) | getProfitLoss, getTargetVsActual, getTargetVsActualForExport, getProfitLossForExport |
| [SaleService.php](file:///d:/laragon/www/PKM/app/Services/SaleService.php) | normalizeData, hasSufficientStock, createSale, updateSale, deleteSale, formatSale |
| [SeasonService.php](file:///d:/laragon/www/PKM/app/Services/SeasonService.php) | createSeason, updateSeason, deleteSeason, formatSeason |
| [SettingService.php](file:///d:/laragon/www/PKM/app/Services/SettingService.php) | getSettings, updateProfile, updatePassword, updateGudang, updateNotifications, deleteAccount |
| [SuperAdminService.php](file:///d:/laragon/www/PKM/app/Services/SuperAdminService.php) | CRUD user, impersonate, landing content, dashboard menus |
| [StockService.php](file:///d:/laragon/www/PKM/app/Services/StockService.php) | getCurrentBalance, hasSufficientStock, addIncoming, addOutgoing, deleteTransaction |

#### Semua Controller Direfactor

| Controller | Sebelum | Sesudah | Pengurangan |
|-----------|---------|---------|-------------|
| [DashboardController](file:///d:/laragon/www/PKM/app/Http/Controllers/DashboardController.php) | 137 baris | ~35 baris | **-74%** |
| [ReportController](file:///d:/laragon/www/PKM/app/Http/Controllers/ReportController.php) | 361 baris | ~125 baris | **-65%** |
| [SaleController](file:///d:/laragon/www/PKM/app/Http/Controllers/SaleController.php) | 257 baris, CC=16 | ~130 baris, CC≈3 | **-49%** |
| [HarvestController](file:///d:/laragon/www/PKM/app/Http/Controllers/HarvestController.php) | 281 baris, CC=13 | ~130 baris, CC≈3 | **-54%** |
| [SeasonController](file:///d:/laragon/www/PKM/app/Http/Controllers/SeasonController.php) | 158 baris | ~90 baris | **-43%** |
| [CostController](file:///d:/laragon/www/PKM/app/Http/Controllers/CostController.php) | 146 baris | ~100 baris | **-32%** |
| [StockController](file:///d:/laragon/www/PKM/app/Http/Controllers/StockController.php) | 173 baris | ~100 baris | **-42%** |
| [AuthController](file:///d:/laragon/www/PKM/app/Http/Controllers/AuthController.php) | 205 baris | ~80 baris | **-61%** |
| [SettingController](file:///d:/laragon/www/PKM/app/Http/Controllers/SettingController.php) | 163 baris | ~85 baris | **-48%** |
| [SuperAdminController](file:///d:/laragon/www/PKM/app/Http/Controllers/SuperAdmin/SuperAdminController.php) | 296 baris | ~168 baris | **-43%** |
| [FeedbackController](file:///d:/laragon/www/PKM/app/Http/Controllers/FeedbackController.php) | 73 baris | ~65 baris | **-11%** |
| [NotificationController](file:///d:/laragon/www/PKM/app/Http/Controllers/NotificationController.php) | 64 baris | ~40 baris | **-38%** |

---

## Validasi

### ✅ PHP Syntax Check
```
php -l semua file di app/Services/ dan app/Http/Controllers/
→ 0 syntax errors
```

### ✅ Route List
```
php artisan route:list
→ Semua API routes load tanpa error
→ Web routes hanya: GET /, password reset (5 routes)
```

### ⚠️ PHPUnit Tests
- 15 dari 17 test gagal dengan `could not find driver (SQLite)`
- Ini adalah **masalah environment** (SQLite PDO extension tidak aktif di PHP Windows ini)
- **Bukan disebabkan oleh perubahan kita** — error sudah ada sebelum refactoring

---

## Arsitektur Baru

```
Request → Route (api.php / web.php)
        → Middleware (auth:sanctum / role:super_admin)
        → Controller (thin — validasi & response saja)
        → Service (business logic)
        → Model → Database
```

> [!TIP]
> Untuk menambah fitur baru di masa depan: buat method di Service, panggil dari Controller. Controller tidak perlu tahu tentang implementasi detail.
