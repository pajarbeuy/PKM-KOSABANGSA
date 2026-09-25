# Laporan Komprehensif Pembaruan & Refaktorisasi Sistem (Master Changelog)

**Proyek:** SIMHPSK (Sistem Informasi Manajemen Panen dan Stok Kentang) / PKM-Kosabangsa  
**Cakupan:** Laravel Backend RESTful API & Flutter Mobile/Desktop Client (`mobile_app`)  
**Status Ekosistem:** ✅ **Clean Architecture & Production Ready** (0 Lints, 34/34 API Tests Passed)


---

## 📌 Daftar Isi
1. [Ringkasan Eksekutif](#1-ringkasan-eksekutif)
2. [Pembaruan & Penguatan Backend (Laravel)](#2-pembaruan--penguatan-backend-laravel)
   - [A. Penguatan Keamanan Reset Password (OWASP)](#a-penguatan-keamanan-reset-password-owasp)
   - [B. Audit & Perbaikan 6 Bug Logika Bisnis Backend](#b-audit--perbaikan-6-bug-logika-bisnis-backend)
   - [C. Arsitektur Service Layer & Eliminasi N+1 Queries](#c-arsitektur-service-layer--eliminasi-n1-queries)
   - [D. Pembersihan Route & Penguncian Versi Dependensi](#d-pembersihan-route--penguncian-versi-dependensi)
3. [Penyederhanaan & Pembersihan Super Admin Panel](#3-penyederhanaan--pembersihan-super-admin-panel)
   - [A. Eliminasi Kartu Dashboard Non-Esensial](#a-eliminasi-kartu-dashboard-non-esensial)
   - [B. Penghapusan Fitur yang Tidak Relevan](#b-penghapusan-fitur-yang-tidak-relevan)
   - [C. Struktur 3 Tab Inti Super Admin](#c-struktur-3-tab-inti-super-admin)
4. [Solusi End-to-End Fitur Lupa Password](#4-solusi-end-to-end-fitur-lupa-password)
   - [A. Alur Mobile: Wizard 2-Langkah](#a-alur-mobile-wizard-2-langkah)
   - [B. Reset Password Langsung oleh Super Admin](#b-reset-password-langsung-oleh-super-admin)
5. [Refaktorisasi & Polish UI/UX Frontend (Flutter)](#5-refaktorisasi--polish-uiux-frontend-flutter)
   - [A. Dynamic Platform IP Resolution](#a-dynamic-platform-ip-resolution)
   - [B. Safe JSON Model Deserialization](#b-safe-json-model-deserialization)
   - [C. Modularisasi God Classes (`ApiService` & `LandingScreen`)](#c-modularisasi-god-classes-apiservice--landingscreen)
   - [D. Ekstraksi Central Responsive Scaffold (`AppShell`)](#d-ekstraksi-central-responsive-scaffold-appshell)
   - [E. Eliminasi Duplikasi UI & Transisi Navigasi Halus](#e-eliminasi-duplikasi-ui--transisi-navigasi-halus)
6. [Rangkaian Pengujian Otomatis & Status Verifikasi](#6-rangkaian-pengujian-otomatis--status-verifikasi)
7. [Resolusi Bug Kategori Biaya (BUG-001) & Status Musim Tanam (BUG-002)](#7-resolusi-bug-kategori-biaya-bug-001--status-musim-tanam-bug-002)
   - [A. BUG-001: Sinkronisasi Kategori Biaya Produksi (Eliminasi Chart Artifacts)](#a-bug-001-sinkronisasi-kategori-biaya-produksi-eliminasi-chart-artifacts)
   - [B. BUG-002: Transisi Status Otomatis Musim Tanam & Cancelled-Awareness](#b-bug-002-transisi-status-otomatis-musim-tanam--cancelled-awareness)
8. [Penyusunan Inventaris Aturan Bisnis (Business Rule Inventory)](#8-penyusunan-inventaris-aturan-bisnis-business-rule-inventory)
9. [Resolusi BUG-003: SaleService updateSale $oldWeight undefined](#9-resolusi-bug-003-undefined-oldweight-di-saleserviceupdatesale)
10. [📊 Status Progres Roadmap PKM](#10--status-progres-roadmap-pkm)
11. [Implementasi Fitur Baru PKM (SumberTani berbasis AI)](#11-implementasi-fitur-baru-pkm-sumbertani-berbasis-ai)
12. [Penyempurnaan Upload Foto Produk Olahan & Restrukturisasi Total Landing Page](#12-penyempurnaan-upload-foto-produk-olahan--restrukturisasi-total-landing-page)
   - [A. End-to-End Image Pipeline Produk Olahan](#a-end-to-end-image-pipeline-produk-olahan)
   - [B. Restrukturisasi Total Landing Page Web (`landing.blade.php`)](#b-restrukturisasi-total-landing-page-web-landingbladephp)
   - [C. Status Verifikasi Pengujian](#c-status-verifikasi-pengujian)

---

## 1. Ringkasan Eksekutif

Laporan ini menyatukan seluruh riwayat pembaruan, refaktorisasi kode (*technical debt elimination*), penguatan standar keamanan, dan pengujian sistem yang dilakukan pada proyek SIMHPSK:
- **Keamanan & Otorisasi:** Mengadopsi standar industri OWASP pada alur reset password (mencegah *email enumeration*, isolasi token pada environment non-debug, penolakan *token reuse/expiry*, validasi konfirmasi password, serta pengamanan role guard `super_admin`).
- **Logika Bisnis & Integritas Data:** Menutup celah isolasi data *Multi-Tenancy*, mengatasi *race condition* kalkulasi saldo stok, membungkus mutasi data dalam transaksi database (`DB::transaction`), mengimplementasikan method `show` yang sebelumnya hilang pada seluruh RESTful resources, dan menjaga presisi desimal bobot komoditas.
- **Penyederhanaan Super Admin:** Memangkas fitur-fitur mubazir (*Landing Editor* & *Shortcut Manager*) dan kartu informasi yang membingungkan, memusatkan fokus admin pada **Dashboard**, **Kelola Pengguna**, dan **Saran & Masukan**.
- **Refaktorisasi Frontend:** Menghilangkan *spaghetti code* pada 15+ screen menggunakan central `AppShell`, memecah file monolitik ribuan baris menjadi domain modular, serta memoles UX navigasi agar bebas kedip dan tanpa hentakan (*smooth fade*).
- **Pengujian Faktual:** Membangun test suite komprehensif di `tests/Feature/API/` dengan hasil **25 Tests Passed (91 Assertions)** dan analisis statis Flutter **0 Warnings**.

---

## 2. Pembaruan & Penguatan Backend (Laravel)

### A. Penguatan Keamanan Reset Password (OWASP)
- **File:** [`app/Http/Controllers/PasswordResetController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/PasswordResetController.php)
1. **Pencegahan Email Enumeration:**
   - Endpoint `POST /api/auth/forgot-password` selalu mengembalikan status HTTP 200 dengan pesan generik yang sama persis:
     > *"Jika email Anda terdaftar di sistem, instruksi reset password telah dikirimkan ke email Anda."*
   - Baik email terdaftar maupun tidak terdaftar di database menghasilkan respon identik sehingga penyerang tidak dapat memindai keberadaan akun.
2. **Pemisahan Environment (Production vs Development):**
   - Token reset **TIDAK PERNAH** diekspos melalui respons API pada environment production (`!app()->isProduction() && config('app.debug')`).
   - Pada environment lokal/testing (debug aktif), token disertakan dalam payload khusus agar pengujian dapat berjalan mulus tanpa ketergantungan pada server SMTP pihak ketiga.
3. **Penanganan Transport Email yang Aman:**
   - Pengiriman email dibungkus dalam blok `try-catch` sehingga jika mailer offline atau gagal terkoneksi, error dicatat ke log tanpa merusak respons API atau membocorkan internal stack trace ke klien.
4. **Alur Tanpa Auto-Login:**
   - Endpoint `POST /api/auth/reset-password` hanya memperbarui hash kata sandi dan menghapus token terkait. Sistem tidak menerbitkan Sanctum auth token; pengguna wajib login secara mandiri dengan kredensial baru.

---

### B. Audit & Perbaikan 6 Bug Logika Bisnis Backend

Selama audit kode backend, ditemukan 6 kelemahan logika yang telah diselesaikan secara tuntas:

#### 1. Celah Isolasi Multi-Tenancy pada `SaleController` & `CostController`
- **Sebelum:** Validasi `season_id` hanya memeriksa keberadaan musim di database (`exists:seasons,id`) tanpa memeriksa kepemilikan user. Petani A bisa menautkan penjualan atau pengeluarannya ke musim milik Petani B.
- **Sesudah:** Ditambahkan validasi kepemilikan:
  ```php
  if (!empty($validated['season_id'])) {
      $seasonExists = Season::where('id', $validated['season_id'])
          ->where('user_id', $request->user()->id)
          ->exists();
      if (!$seasonExists) {
          return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik Anda.');
      }
  }
  ```
- **Hasil:** Data penjualan dan biaya produksi terisolasi penuh secara aman per pengguna.

#### 2. Race Condition pada Perhitungan Saldo Stok (`StockTransaction::getCurrentBalance`)
- **Sebelum:** Saldo stok gudang diambil dengan query `$query->latest('date')->first()`. Ketika terjadi 2 transaksi pada detik yang sama (misal panen dan penjualan cepat), database tidak memecah *tie-break* berdasarkan ID, sehingga berisiko mengembalikan saldo lama.
- **Sesudah:** Query diperbarui menjadi:
  ```php
  $latest = $query->orderByDesc('date')->orderByDesc('id')->first();
  return (float) ($latest?->balance_after ?? 0);
  ```
- **Hasil:** Saldo stok gudang selalu dijamin konsisten dan akurat secara kronologis.

#### 3. Atomicity & Database Transaction (`DB::transaction`)
- **Sebelum:** Pada `SaleService` (`createSale`, `updateSale`, `deleteSale`) dan `HarvestService` (`createHarvest`, `updateHarvest`, `deleteHarvest`), proses mutasi panen/penjualan dan pemotongan/penambahan saldo stok berjalan tanpa transaksi database. Jika salah satu query gagal di tengah jalan, stok gudang dan catatan transaksi menjadi tidak sinkron.
- **Sesudah:** Seluruh operasi ganda dibungkus dalam `DB::transaction(function() { ... })`.
- **Hasil:** Menjamin sifat *all-or-nothing* (*atomic*), mencegah desinkronisasi stok dan catatan transaksi selamanya.

#### 4. Missing Method `show` pada RESTful API Resources
- **Sebelum:** `routes/api.php` mendeklarasikan `Route::apiResource` untuk `seasons`, `harvests`, `sales`, dan `costs`. Namun keempat controller tersebut belum mengimplementasikan method `show`. Pemanggilan detail seperti `GET /api/seasons/{id}` memicu crash error 500 (`Method show does not exist`).
- **Sesudah:** Diimplementasikan method `show(Request $request, Model $model)` lengkap dengan validasi otorisasi kepemilikan data (`$model->user_id !== $request->user()->id -> forbiddenResponse`).
- **Hasil:** Endpoint RESTful resource kini lengkap dan mendukung query detail secara aman.

#### 5. Pemotongan Nilai Koma (*Integer Truncation*) pada Bobot Panen & Stok
- **Sebelum:** Di `StockController` dan `DashboardService`, bobot komoditas di-cast paksa ke `(int)`. Jika petani mencatat panen `15.75` kg, angka terpotong menjadi `15` kg (kehilangan 750 gram).
- **Sesudah:** Diubah menjadi format `(float)` sehingga angka desimal tetap akurat.

#### 6. Standardisasi Kebijakan Panjang Kata Sandi
- **Sebelum:** `SettingController::updatePassword` sebelumnya membolehkan password minimal 6 karakter (`min:6`), sedangkan registrasi dan reset password mewajibkan 8 karakter (`min:8`).
- **Sesudah:** Seluruh endpoint distandardisasi mewajibkan minimal 8 karakter (`min:8|confirmed`).

---

### C. Arsitektur Service Layer & Eliminasi N+1 Queries
- **12 Controller Refactored ke Service Layer:**
  Logika bisnis yang sebelumnya menumpuk di controller monolitik dipisahkan ke layer terdedikasi di `app/Services/`:
  - `HarvestService.php`
  - `SaleService.php`
  - `StockService.php`
  - `CostService.php`
  - `SeasonService.php`
  - `ReportService.php`
  - `DashboardService.php`
  - `SuperAdminService.php`
  - `SettingService.php`
  - `FeedbackService.php`
  - `NotificationService.php`
  - `AuthService.php`
- **Eliminasi N+1 Queries:**
  Query relasi berulang diubah menggunakan Eager Loading `with(['user', 'season'])` dan agregasi langsung via database `withSum('harvests', 'weight_kg')` pada laporan dan dashboard.

---

### D. Pembersihan Route & Penguncian Versi Dependensi
- **Pembersihan `routes/web.php`:**
  Dipangkas dari 147 baris menjadi 27 baris, hanya menyisakan view landing page dan alur fallback web. Seluruh fungsionalitas dialihkan murni ke API-first di `routes/api.php`.
- **Penguncian Versi `composer.json`:**
  Dependensi library (`barryvdh/laravel-dompdf`, `maatwebsite/excel`, dll.) diubah dari versi *wildcard* (`*`) menjadi versi tersemat (`^3.1`) guna mencegah breaking changes saat instalasi di server produksi.

---

## 3. Penyederhanaan & Pembersihan Super Admin Panel

### A. Eliminasi Kartu Dashboard Non-Esensial
- **File:** [`mobile_app/lib/screens/super_admin_dashboard_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/super_admin_dashboard_screen.dart)
- Kartu *"Status Ekosistem & Informasi Operasional"* dan fungsi `_buildInfoItem` dihapus karena dinilai tidak memberikan nilai operasional dan membuat tampilan padat.
- Dashboard Super Admin kini menampilkan 4 metrik utama yang esensial: **Total Petani**, **Petani Aktif**, **Status Layanan**, dan **Hak Akses**.

### B. Penghapusan Fitur yang Tidak Relevan
- **Fitur yang Dihapus dari Navigasi:**
  1. *Edit Landing Page* (`LandingEditorScreen`)
  2. *Kelola Menu Shortcut* (`CustomMenusScreen`)
- **File Terkait yang Dibersihkan:**
  - `super_admin_dashboard_screen.dart`: Dihapus dari sidebar desktop, drawer mobile, dan IndexedStack.
  - `user_management_screen.dart`: Dihapus dari sidebar standalone.
  - `feedback_management_screen.dart`: Dihapus dari sidebar standalone.

### C. Struktur 3 Tab Inti Super Admin
Panel Super Admin kini memiliki struktur navigasi terpadu yang konsisten di semua resolusi layar:
1. **Index 0 — Dashboard:** Ringkasan statistik operasional dan kesehatan sistem.
2. **Index 1 — Kelola Pengguna:** Manajemen data petani, pendaftaran akun baru, aktivasi status, dan reset password manual.
3. **Index 2 — Saran & Masukan:** Monitoring keluhan, masukan, dan laporan kendala teknis dari petani.

---

## 4. Solusi End-to-End Fitur Lupa Password

### A. Alur Mobile: Wizard 2-Langkah
- **File:** [`mobile_app/lib/screens/forgot_password_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/forgot_password_screen.dart)
- Menggantikan alur lama (yang hanya meminta email lalu kembali ke login tanpa ada form reset) dengan **Wizard 2-Langkah Interaktif**:
  - **Langkah 1 (Kirim Permintaan):**
    - Input email terdaftar.
    - Tombol *"Kirim Token Reset"*.
    - Tombol cepat *"Sudah memiliki Token Reset? Klik di sini"*.
  - **Langkah 2 (Input Token & Kata Sandi Baru):**
    - Input email terkonfirmasi.
    - Input **Token Reset Password** (dilengkapi tombol *Paste* dari clipboard & auto-fill otomatis saat mode testing/debug).
    - Input **Password Baru** (minimal 8 karakter) dengan toggle sembunyikan/tampilkan sandi.
    - Input **Konfirmasi Password Baru** dengan toggle visibilitas sandi.
    - Tombol *"Perbarui Password"*.
    - Tombol kembali *"« Ubah Email / Minta Token Baru"*.
  - Setelah sukses, dialog konfirmasi ditampilkan dan pengguna dialihkan ke `LoginScreen` untuk login mandiri.

### B. Reset Password Langsung oleh Super Admin
- **File:** [`mobile_app/lib/widgets/users/user_form_bottom_sheet.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/widgets/users/user_form_bottom_sheet.dart)
- Pada modal edit data petani, ditambahkan field:
  - **Reset Password Baru (Opsional)**
  - **Konfirmasi Password Baru**
- Super Admin dapat langsung meresetkan kata sandi petani yang mengalami kendala akses tanpa perlu petani membuka email.
- Endpoint dilindungi middleware `role:super_admin` (`SuperAdminController::updateUser`) dengan validasi kecocokan konfirmasi password (`min:8|confirmed`).

---

## 5. Refaktorisasi & Polish UI/UX Frontend (Flutter)

### A. Dynamic Platform IP Resolution
- **File:** `lib/services/api_config.dart` & `api_config_platform_io.dart`
- Menghilangkan hardcoded IP `10.0.2.2` yang sebelumnya membuat aplikasi gagal koneksi saat dibuka via Web Browser, Windows Desktop, atau Perangkat Fisik.
- Sistem kini secara otomatis mendeteksi platform runtime:
  - Android Emulator: `10.0.2.2:8000`
  - Desktop (Windows/macOS/Linux) & iOS Simulator: `127.0.0.1:8000`
  - Web Browser: URL host browser saat aplikasi berjalan
  - Runtime override via `ApiConfig.customServerIp`.

### B. Safe JSON Model Deserialization
- Seluruh model data (`Sale`, `User`, `Cost`, `Stock`, `Season`, `Dashboard`) diamankan menggunakan parser defensif `int.tryParse()` / `num.tryParse()` / *null fallback*.
- Menghindari *red screen crash* (`TypeError: num is not a subtype of double`) akibat inkonsistensi tipe numerik dari JSON backend.

### C. Modularisasi God Classes (`ApiService` & `LandingScreen`)
- **`api_service.dart` (1.676 Baris):**
  Dipecah menjadi 10 Domain API Services terpisah di `lib/services/api/` (`auth_api_service.dart`, `season_api_service.dart`, `harvest_api_service.dart`, dll.), dengan `ApiService` bertindak sebagai Facade Singleton tanpa merusak pemanggil yang sudah ada.
- **`landing_screen.dart` (2.747 Baris):**
  Dipecah menjadi 10 sub-widget independen di `lib/widgets/landing/` (`landing_header.dart`, `hero_section.dart`, `features_section.dart`, dll.).

### D. Ekstraksi Central Responsive Scaffold (`AppShell`)
- **File:** `lib/widgets/app_shell.dart`
- Menghilangkan duplikasi puluhan baris `LayoutBuilder(maxWidth >= 900)`, deklarasi `AppSidebar`, `AppDrawer`, `AppMobileAppBar`, dan dialog logout di 10+ layar utama (`SeasonScreen`, `HarvestScreen`, `StockScreen`, `SalesScreen`, `CostsScreen`, `ReportsScreen`, `ProfileScreen`, `SettingsScreen`, `FeedbackScreen`, dll.).

### E. Eliminasi Duplikasi UI & Transisi Navigasi Halus
- **Navigasi Ganda Dieliminasi:** `bottomNavigationBar` pada desktop disembunyikan sehingga desktop hanya menampilkan sidebar kiri.
- **Banner Kembar Dieliminasi:** Header duplikat di dalam layout konten `sales_screen.dart` dan `harvest_screen.dart` dihapus, tombol aksi dipindahkan ke header atas terpadu.
- **Avatar Dobel Dieliminasi:** Avatar profil di kanan atas disembunyikan saat sidebar kiri aktif.
- **Hentakan Navigasi Dihilangkan:** Mengganti animasi push native OS dengan `PageRouteBuilder` transisi **Fade** halus (150ms) di `lib/utils/navigation_helper.dart`.

---

## 6. Rangkaian Pengujian Otomatis & Status Verifikasi

Untuk memastikan stabilitas sistem secara faktual, dibangun dan dijalankan test suite otomatis:

### A. Pengujian Otomatis Backend (PHPUnit)
Direktori: `tests/Feature/API/`

1. **[`ComprehensiveApiTest.php`](file:///d:/laragon/www/PKM/tests/Feature/API/ComprehensiveApiTest.php) (12 Tests):**
   - `test_user_can_register`: Registrasi akun baru, validasi password min 8 karakter & status aktif.
   - `test_user_login_success_and_token_generation`: Autentikasi token Sanctum Bearer.
   - `test_inactive_user_cannot_login`: Penolakan akun non-aktif dengan status 403 Forbidden.
   - `test_user_me_and_logout`: Pengambilan profil pengguna & pembersihan token saat logout.
   - `test_season_crud_lifecycle`: Siklus lengkap CRUD musim tanam.
   - `test_season_multi_tenancy_isolation`: Pengujian pencegahan akses data musim antar user.
   - `test_harvest_creates_and_manages_inventory_stock`: Otomasi penambahan stok saat panen, penyesuaian bobot panen, dan rollback stok saat data panen dihapus.
   - `test_cannot_attach_harvest_to_other_users_season`: Pencegahan manipulasi musim tanam pada panen.
   - `test_sale_rejects_when_insufficient_stock_and_succeeds_when_available`: Validasi pencegahan stok minus dan pemotongan stok otomatis saat penjualan.
   - `test_sale_season_ownership_isolation`: Pencegahan manipulasi musim tanam pada penjualan.
   - `test_cost_crud_and_season_isolation`: Siklus CRUD biaya produksi dan isolasi musim.
   - `test_dashboard_and_profit_loss_calculations`: Akurasi kalkulasi pendapatan, pengeluaran, laba/rugi, dan saldo stok.

2. **[`PasswordResetSecurityTest.php`](file:///d:/laragon/www/PKM/tests/Feature/API/PasswordResetSecurityTest.php) (9 Tests):**
   - `test_prevents_email_enumeration`: Respons generik identik untuk email terdaftar vs tidak terdaftar.
   - `test_token_not_exposed_in_production`: Token tidak pernah bocor saat debug mati / production.
   - `test_reset_password_with_valid_token`: Reset password dengan token valid.
   - `test_reset_password_token_reuse_fails`: Penolakan penggunaan kembali token yang sudah dipakai.
   - `test_reset_password_token_expired_fails`: Penolakan token yang kedaluwarsa (400).
   - `test_reset_password_email_mismatch_fails`: Penolakan token user A yang dipakai untuk user B.
   - `test_super_admin_update_requires_password_confirmation`: Validasi konfirmasi password pada admin reset.
   - `test_unauthorized_regular_user_cannot_access_admin_user_update`: Penolakan user biasa pada endpoint admin (403).
   - `test_reset_password_does_not_issue_auto_login_token`: Verifikasi tidak adanya auto-login setelah reset.

3. **[`SeasonApiTest.php`](file:///d:/laragon/www/PKM/tests/Feature/API/SeasonApiTest.php) (4 Tests):**
   - List musim tanam via API, create musim tanam, penolakan akses tanpa token (401), penolakan token invalid (401).

4. **[`BugFixRegressionTest.php`](file:///d:/laragon/www/PKM/tests/Feature/API/BugFixRegressionTest.php) (6 Tests):**
   - `test_cost_creation_accepts_all_official_categories`: Penerimaan seluruh 4 kategori resmi (`seed`, `fertilizer`, `pesticide`, `other`).
   - `test_cost_creation_rejects_legacy_chart_categories`: Penolakan kategori artefak chart `equipment` dan `transport` dengan kode 422.
   - `test_season_compute_status_unit_logic`: Verifikasi menyeluruh pemetaan status dinamis (`belum_dimulai`, `active`, `completed`, dan isolasi status `cancelled`).
   - `test_season_api_includes_computed_status`: Keberadaan field `computed_status` pada endpoint show dan list API.
   - `test_dashboard_active_season_ignores_stale_and_cancelled_seasons`: Pengabaian musim kadaluwarsa atau dibatalkan pada perhitungan target panen dashboard.
   - `test_harvest_index_active_season_ignores_stale_and_cancelled_seasons`: Keakuratan musim aktif pada header pencatatan panen.

#### Hasil Eksekusi Test Suite:
```bash
php -d extension=pdo_sqlite -d extension=sqlite3 vendor/phpunit/phpunit/phpunit tests/Feature/API
```
```json
{
  "tool": "phpunit",
  "result": "passed",
  "tests": 31,
  "passed": 31,
  "assertions": 122,
  "duration_ms": 3213
}
```
**Status: 31 TESTS PASSED, 122 ASSERTIONS, 0 FAILURES, 0 ERRORS.**

---

### B. Analisis Statis Frontend (Flutter)
```bash
cd mobile_app
flutter analyze
```
```
Analyzing mobile_app...
No issues found! (ran in 41.9s)
```
**Status: 0 Errors, 0 Warnings.**

---

## 7. Resolusi Bug Kategori Biaya (BUG-001) & Status Musim Tanam (BUG-002)

### A. BUG-001: Sinkronisasi Kategori Biaya Produksi (Eliminasi Chart Artifacts)

#### 1. Deskripsi Masalah & Temuan Audit
- **Gejala:** Pada layar Biaya Produksi (`costs_screen.dart`), diagram *breakdown* menampilkan batang kategori **Peralatan** (`equipment`) dan **Transportasi** (`transport`) yang selalu bernilai Rp 0 (0%), sementara kategori **Lainnya** (`other`) tidak muncul pada diagram progress bar sama sekali.
- **Hasil Investigasi Menyeluruh:**
  - **Database Migration:** `database/migrations/2024_01_02_000003_create_production_costs_table.php` mendefinisikan kolom:
    `$table->enum('category', ['seed', 'fertilizer', 'pesticide', 'other']);`
  - **Backend Controller:** `CostController.php` memvalidasi kategori dengan aturan:
    `'category' => 'required|in:seed,fertilizer,pesticide,other'`
  - **Flutter Form:** `add_edit_cost_screen.dart` hanya menyediakan 4 pilihan resmi: Bibit (`seed`), Pupuk (`fertilizer`), Pestisida (`pesticide`), dan Lainnya (`other`).
  - **Audit Data Riil Database:** Query data live menunjukkan bahwa hanya 4 kategori tersebut yang pernah tersimpan di database, dengan 0 catatan berkategori `equipment` atau `transport`.
- **Akar Masalah:** Kategori `equipment` dan `transport` merupakan artefak visual UI (*hardcoded placeholder*) yang tertinggal di `costs_screen.dart`. Karena progress bar untuk kategori `other` lupa dirender, setiap kali pengguna mencatat biaya dengan kategori "Lainnya", total biaya bertambah namun tidak terlihat pada diagram batang breakdown.

#### 2. Solusi & Perubahan Implementasi
- **File:** [`mobile_app/lib/screens/costs_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/costs_screen.dart)
  - Menghapus `'equipment': 0.0` dan `'transport': 0.0` dari inisialisasi Map akumulasi kategori pada `_loadData()`.
  - Mengganti pemanggilan progress bar peralatan & transportasi dengan progress bar resmi untuk kategori **Lainnya** (`_buildProgressBar('Lainnya', 'other')`).
  - Memperbarui palet warna dan label pada `getCategoryColor()` serta `_CategoryPill` agar memetakan 4 kategori resmi dengan rapi dan konsisten (Bibit: Hijau Tua `#166534`, Pupuk: Hijau `#22C55E`, Pestisida: Merah `#DC2626`, Lainnya: Slate Grey `#6B7280`).

---

### B. BUG-002: Transisi Status Otomatis Musim Tanam & Cancelled-Awareness

#### 1. Deskripsi Masalah & Temuan Audit
- **Gejala:** Musim tanam yang masa berlakunya telah berakhir (tanggal hari ini telah melewati `end_date`) tetap berstatus `'active'` di database dan antarmuka.
- **Hasil Investigasi Menyeluruh:**
  - **Semantics Status `cancelled`:** Status `cancelled` merupakan aksi bisnis manual yang disengaja oleh pengguna (misalnya musim tanam dibatalkan karena bencana/gagal sebelum panen) yang disimpan secara permanen di database. Jika status ditimpa secara naif hanya berdasarkan tanggal, musim yang berstatus `cancelled` akan keliru kembali menjadi `active` atau `completed`.
  - **Direct SQL Bypass:** Ditemukan 2 query SQL langsung yang membaca kolom `WHERE status = 'active'` mentah di backend:
    - [`app/Services/DashboardService.php`](file:///d:/laragon/www/PKM/app/Services/DashboardService.php) (L19): menentukan target panen aktif pada dashboard ringkasan.
    - [`app/Http/Controllers/HarvestController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/HarvestController.php) (L27): menentukan musim aktif pada header pencatatan panen.
    Query ini menggunakan `->first()`, sehingga jika ada musim lama dengan status database `'active'`, musim lama dengan ID lebih kecil yang akan selalu terpilih meskipun tanggalnya sudah lewat.
  - **Analisis Zona Waktu & Tanggal:** PHP beroperasi pada UTC (`config('app.timezone') = UTC`) sedangkan MySQL mengikuti OS WIB (`UTC+7`). Namun karena kolom `start_date` dan `end_date` bertipe `DATE` murni (tanpa komponen jam), perbandingan kalender tanggal murni di Eloquent (`Carbon::today()` vs tanggal cast model) bersifat mandiri dan konsisten tanpa memerlukan pergeseran konfigurasi timezone aplikasi.

#### 2. Solusi & Perubahan Implementasi
1. **Model `Season` ([`app/Models/Season.php`](file:///d:/laragon/www/PKM/app/Models/Season.php)):**
   - Menambahkan method `computeStatus(): string` yang *cancelled-aware*:
     ```php
     public function computeStatus(): string
     {
         $currentStatus = $this->getRawOriginal('status') ?? $this->status;
         if ($currentStatus === 'cancelled') {
             return 'cancelled'; // Tetap dipertahankan, tidak boleh ditimpa tanggal
         }

         if (!$this->start_date || !$this->end_date) {
             return $currentStatus ?? 'active';
         }

         $today = Carbon::today();
         if ($today->lt($this->start_date)) {
             return 'belum_dimulai';
         }
         if ($today->gt($this->end_date)) {
             return 'completed';
         }
         return 'active';
     }
     ```
   - Mendaftarkan `$appends = ['computed_status']` dan accessor `getComputedStatusAttribute()` agar field ini otomatis ter-serialize saat model diubah menjadi array/JSON.
2. **Format API Respon ([`app/Services/SeasonService.php`](file:///d:/laragon/www/PKM/app/Services/SeasonService.php)):**
   - Menambahkan key `'computed_status' => $season->computeStatus()` pada `formatSeason()`, sembari tetap mempertahankan nilai raw `'status'` untuk keperluan form edit.
3. **Penyempurnaan Query Musim Aktif ([`DashboardService.php`](file:///d:/laragon/www/PKM/app/Services/DashboardService.php) & [`HarvestController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/HarvestController.php)):**
   - Mengganti query statis menjadi query rentang tanggal kalender aktif dan mengecualikan status `cancelled`:
     ```php
     Season::where('user_id', $userId)
         ->where('status', '!=', 'cancelled')
         ->whereDate('start_date', '<=', today())
         ->whereDate('end_date', '>=', today())
         ->latest('start_date')
         ->first();
     ```
4. **Model & Layar Flutter Client ([`mobile_app/lib/models/season.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/season.dart) & [`mobile_app/lib/screens/season_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/season_screen.dart)):**
   - Model `Season` membaca `computedStatus` dari JSON (`json['computed_status'] ?? json['status']`).
   - `season_screen.dart` menampilkan badge dinamis dan menghitung ringkasan musim aktif/selesai berdasarkan `computedStatus`.
   - `_buildStatusBadge()` diperkaya dengan penanganan styling eksplisit untuk status `cancelled` ('Dibatalkan', merah) dan `belum_dimulai` ('Belum Dimulai', amber).
   - Form modal edit ([`season_form_bottom_sheet.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/widgets/seasons/season_form_bottom_sheet.dart)) tetap menggunakan status raw database sehingga petani tetap dapat mengubah status secara bebas.

---

## 8. Penyusunan Inventaris Aturan Bisnis (Business Rule Inventory)

Sebagai tindak lanjut dari panduan eksekusi fase transisi PKM ([`docs/SIMHPSK_PKM_Next_Step_Execution_Plan.md`](file:///d:/laragon/www/PKM/docs/SIMHPSK_PKM_Next_Step_Execution_Plan.md)), telah disusun dokumen inventaris aturan bisnis resmi pada:
👉 **[`docs/BUSINESS_RULES.md`](file:///d:/laragon/www/PKM/docs/BUSINESS_RULES.md)**

### Ringkasan Cakupan Inventaris:
1. **Musim Tanam (Season):**
   - Definisi skema, aturan validasi `start_date` & `end_date`, aturan boundary tanggal aktif, prioritas status manual `cancelled`, serta query pemilihan musim aktif kalender di dashboard & panen.
2. **Pencatatan Panen (Harvest):**
   - Validasi kepemilikan musim lintas user, dukungan presisi desimal bobot panen, integrasi mutasi stok otomatis (`in`) dalam `DB::transaction`, penyesuaian selisih bobot saat update, dan *rollback* stok saat panen dihapus.
   - Validasi kepemilikan musim lintas user, dukungan presisi desimal bobot panen, integrasi mutasi stok otomatis (`in`) dalam `DB::transaction`, penyesuaian selisih bobot saat update, dan *rollback* stok saat data panen dihapus.
3. **Manajemen Stok Gudang (Stock):**
   - Formula *ledger* invariant kronologis, eliminasi race condition via tie-break ID, serta pemicu notifikasi otomatis ambang batas minimum (`min_stock`) dan maksimum (`max_stock`).
4. **Penjualan (Sales):**
   - Pemeriksaan ketersediaan stok (*stock guard*) untuk mencegah stok negatif (penolakan 422), kalkulasi harga server-side, mutasi stok keluar (`out`), dan pengembalian stok saat penjualan dihapus.
5. **Biaya Produksi (Production Cost):**
   - Penegakan 4 kategori resmi (`seed`, `fertilizer`, `pesticide`, `other`), konsistensi total vs breakdown kategori,   - Penghapusan permanen artefak legacy `equipment`/`transport`.
6. **Laporan & Dashboard (Reports & Analytics):**
   - Penyelarasan formula pendapatan, pengeluaran, laba rugi, dan evaluasi persentase pencapaian target panen per musim.
7. **Cross-Module Invariants & Multi-Tenancy:**
   - Penegakan 5 invarian inti (Stok, Biaya, Laba Bersih, Isolasi Musim, Atomisitas Transaksi) dan isolasi ketat kepemilikan data antar petani berbasis `user_id`.

---

## 9. Resolusi BUG-003: Undefined `$oldWeight` di `SaleService::updateSale()`

**Tanggal:** 19 September 2026  
**Ditemukan dalam:** Phase 3 – Core Business Domain Audit  
**Severity:** Critical (Silent logic failure)

### Masalah

Pada method `SaleService::updateSale()` (file: `app/Services/SaleService.php`), variabel `$oldWeight` digunakan di dalam closure `DB::transaction()`, tetapi **tidak pernah didefinisikan di scope luar** dan tidak dicapture via `use()`:

```php
// SEBELUM (BUGGY) — $oldWeight undefined dalam closure
return DB::transaction(function () use ($sale, $dbData, $userId, $oldWeight) {
    // $oldWeight tidak ada → PHP 8: Undefined variable
    if (isset($dbData['weight_kg']) && $oldWeight != $dbData['weight_kg']) {
        ...
    }
    return $sale;
});
```

### Dampak

| Kondisi | Dampak Aktual |
|---|---|
| Pengguna mengubah bobot penjualan (naik/turun) | Penyesuaian stok gudang **tidak terjadi** → saldo stok salah |
| Bobot penjualan dikurangi | Sisa stok tidak bertambah → stok gudang **defisit** |
| Bobot penjualan ditambah | Stok gudang tidak berkurang → stok **fiktif** (lebih banyak dari kenyataan) |
| Di PHP 8.x | Kemungkinan `ErrorException: Undefined variable $oldWeight` |

Ini melanggar **Invarian 1: Keseimbangan Stok (Stock Ledger Invariant)** dan **Invarian 5: Atomisitas Transaksi** yang didokumentasikan di `BUSINESS_RULES.md`.

### Root Cause

Variable `$oldWeight` perlu diambil dari nilai `$sale->weight_kg` sebelum closure dieksekusi, lalu dicapture eksplisit dalam `use()`. Hal ini terlewat pada saat penulisan service layer.

### Perbaikan

```php
// SESUDAH (FIXED) — $oldWeight didefinisikan dan dicapture dengan benar
$oldWeight = $sale->weight_kg;          // ← ditambahkan

return DB::transaction(function () use ($sale, $dbData, $userId, $oldWeight) {
    $sale->update($dbData);

    if (isset($dbData['weight_kg']) && $oldWeight != $dbData['weight_kg']) {
        $difference = $oldWeight - $dbData['weight_kg'];
        StockTransaction::addTransaction(
            $difference > 0 ? 'in' : 'out',
            abs($difference),
            'Penjualan diupdate',
            'sale_' . $sale->id,
            $userId
        );
    }

    return $sale;
});
```

### File yang Diubah

| File | Baris | Perubahan |
|---|---|---|
| `app/Services/SaleService.php` | 130 | Tambah `$oldWeight = $sale->weight_kg;` sebelum closure |
| `tests/Feature/API/BugFixRegressionTest.php` | 270–380 | Tambah 3 regression test BUG-003 |
| `phpunit.xml` | 26–27 | Switch DB_CONNECTION dari `sqlite` ke `mysql` (`pkm_test`) |

### Regression Test

3 test baru ditambahkan ke `BugFixRegressionTest`:

| Test | Skenario | Assertion |
|---|---|---|
| `test_update_sale_weight_decrease_returns_stock_to_warehouse` | 100 kg masuk → jual 50 → update ke 30 | Balance = 70 (20 kg kembali) |
| `test_update_sale_weight_increase_deducts_additional_stock` | 200 kg masuk → jual 50 → update ke 80 | Balance = 120 (30 kg tambahan keluar) |
| `test_update_sale_non_weight_fields_leaves_stock_unchanged` | Update nama/harga, bobot tetap | Balance tidak berubah |

### Hasil Test

```
Tests: 9 passed (BugFixRegressionTest), 34/34 passed (API test suite)
Assertions: 43 (BugFixRegression), 134 (API suite)
```

### Status

✅ **Resolved & Verified** — Bug diperbaiki, 3 regression test ditambahkan, seluruh API test suite hijau.

---

## 10. 📊 Status Progres Roadmap PKM

> Referensi penuh: [`docs/SIMHPSK_PKM_Next_Step_Execution_Plan.md`](file:///d:/laragon/www/PKM/docs/SIMHPSK_PKM_Next_Step_Execution_Plan.md)  
> Diperbarui: 19 September 2026

### Ringkasan Status Per Phase

| # | Phase | Status | Keterangan |
|---|---|---|---|
| P0 | Baseline & Freeze | ✅ Selesai | Kondisi awal tercatat; bug register dibuat |
| P1-A | BUG-001: Cost Category | ✅ Selesai | 4 kategori resmi ditegakkan; regression test hijau |
| P1-B | BUG-002: Season Status | ✅ Selesai | `computeStatus()` + date-range query; UAT passed |
| P1-C | Business Rule Inventory | ✅ Selesai | `docs/BUSINESS_RULES.md` tersedia; 6 domain terdokumentasi |
| P1-D | Core Domain Audit | ✅ Selesai | BUG-003 ditemukan & diperbaiki di `SaleService` |
| P1-E | Cross-Module Consistency | ✅ Selesai | 5 invariants verified; 34/34 API tests pass |
| P1-F | Regression Test Expansion | ✅ Selesai | 64/64 API tests pass (termasuk multi-harvest aggregation test) |
| P2-A | Generalization: Kentang→Hasil Tani | ✅ Selesai | 15 file diubah, 23 perubahan; `docs/GENERALIZATION_AUDIT.md` dibuat; Bug #1, #2, #3 terselesaikan |
| P2-B | Audit UI Terminology | ⏳ Belum | Label sidebar/dashboard belum diaudit |
| P2-C | UAT / E2E | 🔄 Sebagian | BUG-001 & BUG-002 UAT selesai; Scenario 3 (Sale update stock) belum diverifikasi manual |
| P3 | PKM Feature Development | ⏳ Belum | Menunggu P2 selesai |

### Definition of Done — Status Saat Ini

```text
Core Domain:       ✅✅✅✅✅✅  (6/6)
Consistency:       ✅✅✅✅✅⏳  (5/6 — API↔Flutter partial)
Security:          ✅✅✅        (3/3)
Testing:           ✅✅✅✅✅✅⏳  (5 done, 1 partial — UAT pending)
Generalization:    ✅✅⏳⏳      (2/4 — [GENERAL] audit ✅, terminology ⏳)
UAT:               ✅✅⏳⏳      (2/4)
```

### 📌 Step Selanjutnya (Next Action)

Berdasarkan urutan prioritas P2:

1. **🔄 Lanjutkan: UAT Scenario 3 (Sale → Stock)**  
   Verifikasi manual bahwa update bobot penjualan di UI benar-benar mengubah saldo stok (membuktikan BUG-003 fix berjalan end-to-end).

2. **⏳ Audit UI Terminology (P2-B)**  
   Audit label sidebar/dashboard untuk terminology yang belum konsisten.

3. **⏳ Buat dokumen output yang belum ada:**  
   - `docs/BUG_REGISTER.md`  
   - `docs/UAT_CHECKLIST.md`  
   - `docs/TEST_COVERAGE_NOTES.md`

4. **⏳ P3: PKM Feature Development**  
   Setelah P2 selesai, mulai pengembangan fitur PKM.

---

## Phase 5 — Generalization Audit: Kentang → Hasil Tani

**Tanggal:** 2026-09-20  
**Status:** ✅ Selesai  
**Detail:** Lihat [`docs/GENERALIZATION_AUDIT.md`](GENERALIZATION_AUDIT.md)

### Ringkasan Perubahan

**Total:** 15 file diubah, 23 perubahan string/code.

#### Backend (5 file)
- `ChatbotController.php`: Removed `'jual kentang'` intent keyword, generalized greeting/about/farewell replies
- `landing.blade.php`: Hero fallback text generalized (`'Stok Kentang'` → `'Stok Hasil Tani'`)
- `DatabaseSeeder.php`: Default hero_title & hero_description generalized
- `profit-loss-pdf.blade.php`: Footer generalized (`'Pertanian Kentang'` → `'SIMHPSK'`)
- `target-vs-actual-pdf.blade.php`: Footer generalized

#### Flutter (10 file)
- `add_edit_harvest_screen.dart`: **[BUG]** Removed unused `_komoditasController` hardcoded `'Kentang'`
- `harvest_screen.dart`: **[BUG]** Removed fake KOMODITAS column from harvest table
- `add_edit_sale_screen.dart`: Hint text generalized
- `chatbot_screen.dart`: Quick reply generalized
- `feedback_management_screen.dart`: farm_name fallback generalized (2 occurrences)
- `feedback_screen.dart`: Platform description generalized
- `register_screen.dart`: Subtitle generalized
- `settings_screen.dart`: Notification description generalized
- `stock_screen.dart`: Shrinkage hint generalized
- `target_screen.dart`: AppHeader subtitle generalized

### Verification
- **Backend:** `php artisan test tests/Feature/API` → ✅ 63/63 PASSED
- **Flutter:** `flutter analyze` → ✅ No issues found!
- **Post-change grep:** 0 unintended production/user-facing occurrences

### Technical Debt Logged
- `n8n/TaniBot_Chat_Workflow.json` AI system prompt masih mengandung asumsi komoditas kentang (out-of-scope Phase 5)
- Persisted DB landing content tidak dimigrate

---

## 11. Implementasi Fitur Baru PKM (SumberTani berbasis AI)

**Tanggal:** 21 September 2026  
**Status:** ✅ **100% Selesai & Terverifikasi (Production Ready)**  
**Hasil Pengujian:**
- **Backend PHPUnit API Suite:** ✅ **97 Tests Passed (292 Assertions)**
- **Flutter Client (`flutter analyze`):** ✅ **No issues found! (0 Errors, 0 Warnings, 0 Infos)**

### A. Ringkasan Kepatuhan Terhadap 6 Minor Notes

1. **Audit FK Deletion Policy (Restrict):**
   - Kolom `processed_products.owner_id` dan `sales.processed_product_id` dikonfigurasi dengan `onDelete('restrict')`.
   - Menjamin bahwa riwayat audit transaksi dan kepemilikan stok petani tidak terhapus secara kaskade yang tidak terkontrol.
2. **Katalog Publik Tetap Menampilkan Produk Stok Habis:**
   - Query katalog publik menggunakan scope `scopeForCatalog` (`active` dan `out_of_stock`).
   - Kartu katalog web menampilkan badge peringatan `"Stok Habis"` dan tombol WhatsApp disabled jika stok = 0. Produk hanya disembunyikan jika status eksplisit `inactive`.
3. **WhatsApp Bukan Sistem Integrasi / Order Backend:**
   - Tombol "Pesan via WhatsApp" semata-mata mengarahkan browser ke `https://wa.me/{phone}?text=...`.
   - Menggunakan nomor telepon `User.phone` dari akun yang memiliki `role: super_admin`.
   - Tidak ada pengurangan stok otomatis atau pembuatan record pesanan backend saat tautan diklik.
4. **Formula Profit/Loss Konsisten:**
   - Laba / Rugi Agregat dihitung dengan formula baku:  
     $$\text{Net Profit/Loss} = \text{Total Pendapatan (Komoditas + Produk Olahan)} - \text{Total Biaya Produksi}$$
   - Formula ini diimplementasikan secara identik di backend (`SuperAdminService::getFarmerProfitLossAggregate`) dan di Flutter UI (`SuperAdminProfitLossScreen`).
5. **Standardisasi Status Kode HTTP:**
   - Endpoint pembuatan resource baru mengembalikan `HTTP 201 Created` (bukan 200).
   - Akses ilegal mengembalikan `HTTP 403 Forbidden`.
   - Validasi bisnis mengembalikan `HTTP 422 Unprocessable Content`.
6. **Pertahankan Modularisasi API Flutter:**
   - Menambahkan file service modular baru:
     - `mobile_app/lib/services/api/processed_product_api_service.dart`
     - Perluasan `mobile_app/lib/services/api/super_admin_api_service.dart`
   - Facade `ApiService` hanya bertindak sebagai gateway delegasi tanpa mencemari pemisahan tanggung jawab (*Separation of Concerns*).

### B. Komponen yang Dibangun & Dimigrasikan

#### 1. Backend Laravel
- **Migrasi:**
  - `database/migrations/2026_09_21_000000_create_processed_products_table.php`
  - `database/migrations/2026_09_21_000001_add_processed_product_and_created_by_to_sales_table.php`
- **Model & Event:**
  - `app/Models/ProcessedProduct.php`: State machine transisi stok, scope katalog, validasi stok negatif di hook `saving`.
  - `app/Models/Sale.php`: Relasi `processedProduct` dan `creator`.
- **Services:**
  - `app/Services/ProcessedProductService.php`: Single Source of Truth stok olahan petani, mutasi atomik ber-lock.
  - `app/Services/SaleService.php`: Penjualan terpusat oleh Super Admin dengan pelacakan `created_by` dan pemotongan stok otomatis.
  - `app/Services/SuperAdminService.php`: Agregasi laba/rugi seluruh petani.
- **Controllers & Routing:**
  - `app/Http/Controllers/ProcessedProductController.php` (CRUD Petani & Public Catalog).
  - `app/Http/Controllers/SaleController.php` (Penjualan terpusat untuk Super Admin, Petani read-only).
  - `app/Http/Controllers/SuperAdminController.php` (Endpoint Laba/Rugi Agregat).
  - `app/Http/Controllers/ChatbotController.php` (Rebranded: Asisten Operasional Super Admin).
  - `routes/api.php` & `routes/web.php`.
  - `resources/views/landing.blade.php` (Bagian `#katalog` dengan integrasi WhatsApp Super Admin).

#### 2. Flutter Mobile & Desktop (`mobile_app`)
- **Model:** `mobile_app/lib/models/processed_product.dart`.
- **Services:** `ProcessedProductApiService`, `SuperAdminApiService`, `ApiService`.
- **Screen Petani:** `mobile_app/lib/screens/processed_products_screen.dart` (CRUD, status filter, guard validasi).
- **Screen Super Admin:**
  - `mobile_app/lib/screens/super_admin_marketing_screen.dart` (Katalog web, nomor WhatsApp, ringkasan produk).
  - `mobile_app/lib/screens/super_admin_profit_loss_screen.dart` (Ringkasan KPI dan rincian per petani).
  - `mobile_app/lib/screens/super_admin_dashboard_screen.dart` (7 Tab operasional lengkap dengan Quick Action Cards).
- **Penyesuaian Hak Akses Navigasi:**
  - `mobile_app/lib/utils/navigation_helper.dart` & `mobile_app/lib/widgets/app_bottom_nav.dart`:
    - Petani: Menu `Produk Olahan` disematkan; menu `Penjualan` dan `TaniBot AI` dihilangkan dari navigasi petani.
    - Super Admin: 7 modul operasional dapat diakses langsung.

---

## 12. Penyempurnaan Upload Foto Produk Olahan & Restrukturisasi Total Landing Page

**Tanggal:** 22 September 2026  
**Status:** ✅ **100% Selesai & Terverifikasi (Production Ready)**  
**Hasil Pengujian:**
- **Backend PHPUnit API Suite:** ✅ **14/14 Processed Product Tests Passed (31 Assertions)**
- **Blade Template Compilation (`view:cache`):** ✅ **Compiled Successfully without Errors**
- **Flutter Client (`flutter analyze`):** ✅ **No issues found! (0 Errors, 0 Warnings, 0 Infos)**

### A. End-to-End Image Pipeline Produk Olahan (Flutter & Laravel)

1. **Pemilih Gambar (Image Picker) di Modal Tambah & Edit Produk Olahan:**
   - **File:** [`mobile_app/lib/screens/processed_products_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/processed_products_screen.dart)
   - Mengintegrasikan package `image_picker` langsung pada form modal bottom sheet.
   - Menyediakan area upload foto interaktif di atas kolom *Nama Produk*.
   - **Pratinjau Seketika (Real-Time Memory Preview):** Menggunakan `Image.memory` untuk foto yang baru dipilih dari galeri perangkat dan `Image.network` untuk foto produk yang sudah tersimpan di database server.
   - Dilengkapi tombol ganti foto dan tombol hapus (**✕**) untuk membatalkan pemilihan foto sebelum form disimpan.

2. **Pengiriman Data Multipart & Method Spoofing:**
   - **File:** [`mobile_app/lib/services/api/processed_product_api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api/processed_product_api_service.dart) & [`mobile_app/lib/services/api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api_service.dart)
   - Mendukung parameter `XFile? photoFile` pada `createProcessedProduct` dan `updateProcessedProduct`.
   - Menggunakan `http.MultipartRequest` dengan field `_method: PUT` dan header `X-HTTP-Method-Override: PUT` khusus saat pembaruan (edit) produk, mengatasi batasan native PHP yang tidak mem-parsing `multipart/form-data` pada request HTTP PUT langsung.

3. **Symlink Storage & Dynamic URL Resolution:**
   - **Symlink Laravel:** Menjalankan `php artisan storage:link` sehingga direktori `storage/app/public` terhubung resmi ke `public/storage` pada web server.
   - **Model URL Accessor:** Di [`app/Models/ProcessedProduct.php`](file:///d:/laragon/www/PKM/app/Models/ProcessedProduct.php), method `getPhotoUrlAttribute` diperbarui secara dinamis mendeteksi host dan port aktif dari request HTTP (`request()->schemeAndHttpHost()`).
   - **Client URL Resolver (`ApiConfig.resolveUrl`):** Di [`mobile_app/lib/api_config.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/api_config.dart), ditambahkan helper method statis `ApiConfig.resolveUrl(String? rawUrl)` yang secara cerdas mendeteksi dan memetakan `localhost` / `127.0.0.1` ke host IP aktif perangkat (misal `10.0.2.2:8000` di emulator Android atau IP LAN Wi-Fi di real device).

4. **Redesain Kartu Produk Olahan (Showcase Product Card):**
   - **Petani Screen (`ProcessedProductsScreen`):**
     - Mengubah kartu produk dari kotak ikon kecil 48x48 menjadi kartu produk modern bertaraf e-commerce dengan **cover banner foto 140px**.
     - Badge status ketersediaan melayang (*Tersedia (X unit)* / *Stok Habis*) di sudut kanan atas banner.
     - Price tag melayang dengan latar semi-transparan di sudut kiri bawah banner.
     - **Interactive Full-Resolution Preview Dialog:** Mengetuk foto produk atau ikon fullscreen akan membuka dialog pratinjau foto resolusi penuh yang dapat di-zoom secara interaktif.
   - **Super Admin Marketing Screen (`SuperAdminMarketingScreen`):**
     - Thumbnail foto diperbesar menjadi 60x60 dengan sudut membulat (*rounded border*) dan dukungan tap-to-preview gambar penuh.

---

### B. Restrukturisasi Total Landing Page Web (`landing.blade.php`)

Menata ulang seluruh arsitektur dan konten landing page publik ([`resources/views/landing.blade.php`](file:///d:/laragon/www/PKM/resources/views/landing.blade.php)) agar 100% selaras dengan spesifikasi sistem SumberTani berbasis AI:

1. **NAVBAR:**
   - **Identitas:** Logo resmi dan nama *SumberTani berbasis AI*.
   - **Menu Navigasi:** `Beranda` (`#beranda`), `Fitur` (`#fitur`), `Katalog Produk` (`#katalog`), `Cara Kerja` (`#cara-kerja`), `Tentang SumberTani` (`#tentang`).
   - **Tombol Aksi:** Tombol `Masuk Aplikasi` dengan efek animasi partikel dan deep linking ke aplikasi mobile.
   - **Menu Responsif:** Dilengkapi tombol toggle hamburger untuk pengalaman browsing optimal di perangkat seluler.

2. **HERO SECTION (`#beranda`):**
   - **Headline & Value Proposition:** Menekankan hilirisasi produk hasil tani dan manajemen pertanian modern terintegrasi AI.
   - **Dua Tombol CTA Utama:**
     - 🛒 **"Lihat Katalog"**: Mengarahkan pengunjung langsung ke etalase produk olahan (`#katalog`).
     - 📲 **"Masuk Aplikasi"**: Menjalankan aksi instalasi/pembukaan aplikasi mobile.
   - **Mockup Dashboard Interaktif:** Menampilkan status terkini persediaan panen mentah, tonase panen, produk olahan, dan estimasi laba bersih petani secara estetis.

3. **FITUR UNGGULAN (`#fitur` - 6 Modul Lengkap):**
   - 🌾 **Manajemen Musim Tanam**: Perencanaan jadwal tanam, pemilihan varietas bibit, dan pencatatan blok kebun.
   - 📸 **Pencatatan Panen**: Dokumentasi panen riil dengan foto, berat timbangan (kg), dan riwayat per blok.
   - 📦 **Manajemen Stok**: Kontrol stok gudang hasil panen mentah dan produk olahan dengan riwayat mutasi transparan.
   - 🥔 **Produk Olahan**: Pendaftaran aneka komoditas olahan bernilai tambah tinggi lengkap dengan harga dan kuota stok.
   - 🛒 **Penjualan & Pemasaran**: Pemasaran terpusat oleh Super Admin melalui katalog daring dan verifikasi pesanan.
   - 📊 **Laporan & Analitik**: Analisis pendapatan, rekonsiliasi pengeluaran, dan laporan laba/rugi per musim tanam.

4. **KATALOG PRODUK OLAHAN TANI (`#katalog`):**
   - Menampilkan daftar produk olahan milik petani secara dinamis dari database (`ProcessedProductService::getActiveCatalog`).
   - Informasi lengkap tiap kartu:
     - Foto produk tajam dari asset storage publik.
     - Nama produk dan nama petani pemilik (`owner_id`).
     - Harga resmi per kemasan dan kuota stok aktual.
     - Badge status ketersediaan (*Tersedia* atau *Stok Habis*).
     - Tombol **"Pesan via WhatsApp"** yang langsung membuka aplikasi WhatsApp Super Admin (`wa.me/{phone}`) dengan pesan yang telah diformat otomatis (nama produk, harga, dan permintaan konfirmasi). Tombol secara otomatis nonaktif (*disabled*) jika stok produk habis.

5. **CARA KERJA (`#cara-kerja` - 8-Step Visual Pipeline):**
   Menyajikan alur kerja ekosistem hilirisasi dalam bentuk 8 langkah terhubung secara visual:
   $$\text{Petani} \rightarrow \text{Produk Olahan} \rightarrow \text{Katalog Publik} \rightarrow \text{Customer} \rightarrow \text{WhatsApp} \rightarrow \text{Super Admin} \rightarrow \text{Penjualan} \rightarrow \text{Stock Update}$$
   - Menegaskan prinsip bahwa klik WhatsApp tidak memotong stok secara instan, melainkan stok hanya berkurang ketika Super Admin memverifikasi dan mencatat transaksi penjualan resmi di sistem.

6. **TENTANG / MANFAAT (`#tentang` - 3 Pilar Pemangku Kepentingan):**
   - **Untuk Petani:** Menjamin hak milik stok olahan tetap pada petani, pencatatan keuangan transparan tanpa beban operasional penjualan eceran, dan peningkatan margin keuntungan dari produk olahan.
   - **Untuk Super Admin:** Sentralisasi kontrol pemasaran, validasi transaksi resmi, asisten operasional cerdas berbasis AI, serta agregat laporan laba-rugi seluruh mitra tani.
   - **Untuk Customer:** Memperoleh produk olahan asli & higienis langsung dari tangan petani binaan, kepastian stok aktual, dan kemudahan pemesanan cepat via WhatsApp tanpa kewajiban pendaftaran akun.

7. **CTA & FOOTER:**
   - **Call-to-Action:** Menghadirkan ajakan bertindak *"Temukan Produk Olahan Hasil Tani"* dengan opsi jelajah katalog atau masuk ke aplikasi.
   - **Footer:** Identitas terstandarisasi **SumberTani berbasis AI**, tautan cepat menuju setiap seksi, dan penegasan hak cipta 2026.

---

### C. Status Verifikasi Pengujian

| Pengujian | Cakupan | Hasil |
|---|---|---|
| **PHPUnit Test Suite** | `ProcessedProductApiTest.php` (CRUD, Multipart Upload, Catalog Scope, Mutasi Stok) | ✅ **14/14 Passed (31 Assertions)** |
| **Laravel View Compiler** | `php artisan view:cache` (`landing.blade.php`) | ✅ **Compiled Successfully** |
| **Flutter Static Analysis** | `flutter analyze` (`mobile_app/`) | ✅ **0 Errors, 0 Warnings, 0 Infos** |
| **Storage Asset Access** | `Test-Path public/storage/processed_products/{file}` | ✅ **True (Accessible)** |

---

## 13. Implementasi Tracking Pembelian Produk Olahan (Order Pipeline)

**Tanggal:** 22 September 2026  
**Status:** ✅ **100% Selesai & Terverifikasi (Production Ready)**  

### A. Latar Belakang & Tujuan
Menambahkan mekanisme pencatatan dan pelacakan pesanan produk olahan (*Order Domain*) dari katalog publik landing page hingga penyelesaian transaksi dan pemotongan stok secara atomik oleh Super Admin.

### B. Prinsip & Arsitektur Utama
1. **Reuse Domain `Sale`:** Tidak membuat tabel `ProcessedProductSale` baru. Relasi dibentuk melalui kolom `sales.order_id` (foreign key nullable merujuk ke `orders.id`).
2. **Single Source of Truth Stok:** Stok produk olahan tetap bersumber 100% pada `processed_products.stock`. Tidak ada stok duplikat untuk Super Admin.
3. **Pemisahan Tanggung Jawab (Separation of Concerns):**
   - `OrderService`: Mengelola siklus hidup `Order` (`pending`, `confirmed`, `processing`, `completed`, `cancelled`). Tidak pernah memotong stok secara langsung.
   - `SaleService`: Satu-satunya service yang berhak memicu pemotongan stok via `ProcessedProductService`, mencatat `Sale`, dan membukukan `StockTransaction`.
   - `ProcessedProductService`: Satu-satunya domain service yang memutasi saldo `processed_products.stock` menggunakan row-locking `lockForUpdate()`.
   - `StockTransaction`: Mencatat histori audit mutasi stok produk olahan (`processed_product_id`).
4. **Pemisahan Tegas `PATCH status` vs `POST complete`:**
   - `PATCH /api/super-admin/orders/{id}/status`: Hanya mengizinkan status operasional `confirmed` atau `processing`. Menolak nilai `completed` dan tidak menyentuh stok.
   - `POST /api/super-admin/orders/{id}/complete`: Satu-satunya endpoint penyelesaian pesanan yang memicu `SaleService` untuk mencatat `Sale` dan memotong stok.
5. **Idempotency Guard:** Jika pesanan sudah `completed` atau telah memiliki `Sale`, pemanggilan ulang endpoint complete ditolak dengan aman (mencegah double sale dan double stock decrement).
6. **Price Snapshot:** Harga saat pemesanan dikunci pada `order_items.price_snapshot`. Perubahan harga produk di masa mendatang tidak mengubah riwayat pesanan lama.
7. **Privasi Pelacakan Publik (Privacy Guard):** Endpoint `GET /api/catalog/orders/{order_code}` menyamarkan data pribadi customer (nama dan nomor telepon disamarkan, alamat dilindungi).

### C. Daftar File yang Dibuat & Dimodifikasi

#### 1. Database Migrations
- `database/migrations/2026_09_22_000001_create_orders_and_order_items_tables.php`: Skema tabel `orders` dan `order_items`.
- `database/migrations/2026_09_22_000002_add_order_id_to_sales_and_product_to_stock_transactions.php`: Foreign key `order_id` pada `sales`, dan `processed_product_id` pada `stock_transactions`.

#### 2. Backend Models & Services
- `app/Models/Order.php`: Model Order dengan relasi `items()`, `sale()`, dan helper generator kode `ORD-YYYYMMDD-XXXX`.
- `app/Models/OrderItem.php`: Model OrderItem dengan relasi `order()` dan `processedProduct()`.
- `app/Models/Sale.php`: Menambahkan `order_id` ke `$fillable` dan relasi `order()`.
- `app/Models/StockTransaction.php`: Menambahkan `processed_product_id`, relasi `processedProduct()`, penyesuaian `getCurrentBalance()` untuk mengabaikan produk olahan, dan method `recordProcessedProductTransaction()`.
- `app/Services/SaleService.php`: Menambahkan method `createSaleFromOrder()`, integrasi pencatatan `StockTransaction`, dan format respons `order_id`.
- `app/Services/OrderService.php`: Logika bisnis pemesanan publik, transisi status, delegasi penyelesaian pesanan ke `SaleService`, pembatalan, dan masking privasi.
- `app/Http/Controllers/OrderController.php`: Endpoint publik (`storePublic`, `trackPublic`) dan Super Admin (`index`, `show`, `updateStatus`, `complete`, `cancel`).
- `routes/api.php`: Pendaftaran rute API katalog publik dan Super Admin orders.

#### 3. Landing Page Blade Integration
- `resources/views/landing.blade.php`:
  - Modal checkout pemesanan langsung dari kartu katalog produk olahan.
  - Form submit ke `POST /api/catalog/orders` → generate `order_code` unik → redirect ke WhatsApp Super Admin dengan pesan resmi rapi.
  - Bar pelacakan pesanan publik (`GET /api/catalog/orders/{code}`) dengan modal status aman.
  - Pembersihan seluruh residual string `simhpsk` (`simhpsk://open` → `sumbertani://open`, `simhpsk.apk` → `sumbertani.apk`).

#### 4. Frontend Flutter Client
- `mobile_app/lib/models/order_model.dart`: Model Dart `OrderModel` dan `OrderItemModel`.
- `mobile_app/lib/services/api/order_api_service.dart`: Layanan modular API pesanan Super Admin.
- `mobile_app/lib/services/api_service.dart`: Integrasi `OrderApiService` ke singleton facade `ApiService`.
- `mobile_app/lib/screens/super_admin_orders_screen.dart`: Layar manajemen pesanan dengan filter status, pencarian, aksi konfirmasi/proses/batal, dialog konfirmasi penyelesaian pesanan, dan kontak customer.
- `mobile_app/lib/screens/super_admin_dashboard_screen.dart`: Integrasi tab **Pesanan Masuk** di sidebar, drawer, quick cards, dan `IndexedStack`.

### D. Hasil Verifikasi Pengujian

| Pengujian | Cakupan | Hasil |
|---|---|---|
| **Order Management Feature Tests** | `tests/Feature/API/OrderManagementApiTest.php` (12 test cases) | ✅ **12/12 Passed (72 Assertions)** |
| **All API Regression Tests** | `tests/Feature/API` (seluruh modul: Auth, Harvest, Stock, Sale, Cost, Report, Product, Order) | ✅ **107/107 Passed (356 Assertions)** |
| **Landing Page Catalog Test** | `tests/Feature/LandingPageCatalogTest.php` | ✅ **1/1 Passed (7 Assertions)** |
| **Flutter Static Analysis** | `flutter analyze` (`mobile_app/`) | ✅ **0 Errors, 0 Warnings, 0 Issues** |

---

## 13. Pembaruan 23 September 2026: Resolusi CORS, Generalisasi Branding, Auto-Refresh & Dashboard Analytics Charts

### A. Resolusi Isu CORS & Header Duplikasi
1. **Akar Masalah**: Penambahan router `server.php` pada built-in PHP web server mencegat preflight `OPTIONS` dengan daftar `Access-Control-Allow-Headers` terbatas (tanpa `Cache-Control`) serta menyebabkan duplikasi header `Access-Control-Allow-Origin: *, *` saat diteruskan ke middleware Laravel `HandleCors`.
2. **Solusi Teknis**:
   - `server.php` diperbarui agar secara dinamis merefleksikan requested headers (`$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'] ?? '*'`) pada request `OPTIONS` dan file statis storage.
   - Header CORS untuk request normal didelegasikan sepenuhnya ke Laravel `HandleCors` middleware, mengeliminasi duplikasi nilai origin.

### B. Pembersihan Sisa Teks Branding & Generalisasi Komoditas
1. **Blade Views (`resources/views/auth`)**:
   - Menyelaraskan teks judul `<title>` dan pesan sukses di `reset-password.blade.php` dan `reset-success.blade.php` dari `SIMHPSK` menjadi `SumberTani`.
2. **Frontend Flutter (`mobile_app/lib`)**:
   - `reports_screen.dart`: Menggeneralisasi subtitle dari *"Penjualan kentang terverifikasi"* dan *"Akumulasi ubi kentang"* menjadi istilah hasil tani umum.
   - `chatbot_screen.dart`: Mengubah sapaan bot dari *"budidaya kentang"* menjadi *"budidaya hasil tani"*.
   - `landing_hero.dart`: Mengubah testimoni *"Petani Kentang"* menjadi *"Petani Mitra"*.
   - `processed_products_screen.dart`: Mengubah placeholder produk olahan menjadi *"Keripik Jamur Crispy"*.

### C. Auto-Refresh State & Desktop Header Synchronization
1. **Masalah**: `IndexedStack` pada layar Super Admin mempertahankan state memori lama, sehingga transaksi penjualan baru hasil penyelesaian pesanan tidak langsung tampil saat tab `Penjualan Terpusat` dibuka.
2. **Solusi**: Memasang dynamic key berbasis index dan `_refreshTick` serta mengaktifkan tombol refresh (🔄) pada desktop header agar langsung memuat data terbaru secara otomatis.

### D. Fitur Analitik Dashboard Super Admin (Bar Chart & Line Chart)
1. **Bar Chart Produk Olahan Terjual Bulanan**:
   - Menampilkan visualisasi diagram batang 12 bulan (Jan–Des) untuk volume penjualan produk olahan (pcs/unit).
   - Dilengkapi interaksi hover tooltip unit terjual dan badge info pembaruan.
2. **Line Chart Akumulasi Penghasilan Petani**:
   - Menampilkan grafik kurva halus (*smooth cubic bezier*) area bergradien untuk memvisualisasikan pertumbuhan akumulasi (*cumulative running revenue*) pendapatan seluruh petani mitra.
   - Dilengkapi titik koordinat interaktif dengan tooltip format Rupiah (`Rp xxx.xxx`).
3. **Optimasi Caching 1 Jam di Backend**:
   - Menggunakan `Cache::remember('superadmin_dashboard_stats', 3600, ...)` di `SuperAdminService.php`.
   - Mengurangi beban komputasi query database agregat berat agar tidak dieksekusi setiap menit.
   - Menyediakan parameter `?refresh=true` untuk on-demand cache invalidation.

### E. Hasil Verifikasi Akhir
- **Backend API Test Suite**: `php artisan test tests/Feature/API` ➔ ✅ **109/109 Passed (378 assertions)**.
- **Flutter Static Analysis**: `flutter analyze` ➔ ✅ **No issues found! (0 errors, 0 warnings)**.
- **UAT End-to-End**: Seluruh Skenario 1 s/d 7 berstatus ✅ **[x] PASSED**.

---

## 14. Pembaruan 23 September 2026: Pemisahan Dua Grafik Dashboard Petani (Bahan Mentah kg & Produk Olahan pcs/Rp)

### A. Latar Belakang & Kebutuhan
Sebelumnya, grafik di dashboard petani menggabungkan pencatatan panen (kg) dan penjualan (yang dapat berupa bahan mentah kg maupun produk olahan pcs) ke dalam satu diagram tunggal, sehingga skala dan interpretasi data menjadi tercampur. User menghendaki pemisahan menjadi dua grafik terpisah yang tegas:
1. **Grafik 1 (Bahan Mentah)**: Khusus memvisualisasikan volume panen dan penjualan bahan mentah dalam satuan **kg**.
2. **Grafik 2 (Produk Olahan)**: Khusus memvisualisasikan volume penjualan produk olahan dalam satuan **pcs** dan nilai penjualan dalam bentuk nominal **Rupiah (Rp)**.

### B. Perubahan Backend (`app/Services/DashboardService.php`)
1. **`getMonthlyStats(int $userId)`**:
   - Menghitung secara terpisah per bulan selama 6 bulan terakhir:
     - `harvest_kg`: total bobot panen (kg).
     - `harvest_sales_kg`: total volume penjualan komoditas mentah (`product_type = 'harvest'`) dalam kg.
     - `harvest_sales_rp`: total omset rupiah dari penjualan bahan mentah (Rp).
     - `processed_sales_pcs`: total kuantitas penjualan produk olahan (`product_type = 'processed'`) dalam pcs.
     - `processed_sales_rp`: total omset rupiah dari penjualan produk olahan (Rp).
2. **`getSummary(int $userId)`**:
   - Menambahkan field ringkasan: `totalRawSalesKg`, `totalRawSalesRp`, `totalProcessedSalesPcs`, `totalProcessedSalesRp`.
3. **Automated Testing (`tests/Feature/API/FarmerDashboardChartsTest.php`)**:
   - Menambahkan feature test komprehensif yang memvalidasi pembagian kalkulasi bahan mentah (kg & Rp) serta produk olahan (pcs & Rp) pada endpoint `GET /api/dashboard`.

### C. Perubahan Frontend Flutter (`mobile_app/lib`)
1. **Model (`mobile_app/lib/models/dashboard.dart`)**:
   - Memperluas class `DashboardData` dan `MonthlyStat` dengan field `harvestKg`, `harvestSalesKg`, `harvestSalesRp`, `processedSalesPcs`, dan `processedSalesRp`.
2. **Grafik Bahan Mentah (`mobile_app/lib/widgets/harvest_chart.dart`)**:
   - Dikhususkan untuk **Bahan Mentah** dengan badge satuan **kg**.
   - Menampilkan perbandingan Panen (kg) dan Penjualan (kg) baik dalam mode Area maupun Bar.
   - Tooltip dan sumbu Y secara tegas menampilkan nilai dalam format `kg`.
3. **Widget Baru Grafik Produk Olahan (`mobile_app/lib/widgets/charts/processed_sales_chart.dart`)**:
   - Komponen chart responsif dengan custom painter Vanilla Flutter:
     - **Dual Scale Visual**: Bar chart elegan untuk volume terjual (pcs, sumbu Y kiri) dan Line kurva halus bergradien untuk nominal pendapatan (Rp, sumbu Y kanan).
     - **Mode Switcher**: Pilihan tampilan `Semua` (kombinasi), `pcs` (fokus unit), dan `Rp` (fokus nominal).
     - **Interactive Tooltip**: Menampilkan detail kuantitas terjual (pcs) dan total nominal Rupiah saat di-hover/tap.
     - **Empty State**: Menampilkan ilustrasi dan pesan informatif yang ramah jika belum ada data transaksi produk olahan.
4. **Layout Dashboard (`mobile_app/lib/screens/home_screen.dart`)**:
   - Pada layar Desktop (lebar >= 900px): Kedua grafik ditampilkan berdampingan (*side-by-side*) dengan pembagian flex 1 : 1, diikuti oleh baris Ringkasan Keuangan dan Transaksi Stok Terbaru.
   - Pada layar Mobile: Ditata vertikal bertingkat secara ergonomis.

### D. Hasil Verifikasi Akhir
- **Backend API Test Suite**: `php artisan test tests/Feature/API` ➔ ✅ **110/110 Passed (437 assertions)**.
- **Flutter Widget Tests**: `flutter test` ➔ ✅ **All 5 tests passed**.
- **Flutter Static Analysis**: `flutter analyze` ➔ ✅ **No issues found! (0 errors, 0 warnings)**.

---

## 15. Pembaruan 24 September 2026: Resolusi Overflow Bulan Chart Dashboard, Opsi Satuan Produk Olahan (pcs / kg), & Satuan Transaksi Stok

### A. Latar Belakang Masalah
1. **Grafik Produk Olahan Kosong Padahal Ada Transaksi**:
   - Di database terdapat transaksi penjualan produk olahan pada bulan September (misal tanggal 21 & 23 September 2026).
   - Namun, terdapat juga data panen di masa depan pada tanggal `2026-10-31` (tanggal 31).
   - Saat logika `getMonthlyStats` melakukan `$referenceDate->subMonths($i)` dari tanggal 31 Oktober, Carbon mengalami *month date overflow* saat mengurangi 1 bulan ke September (karena September hanya memiliki 30 hari). Tanggal 31 September otomatis meluap kembali menjadi tanggal 1 Oktober!
   - Akibatnya, iterasi bulan melewati September sama sekali dan melompat dari Oktober ke Agustus, sehingga transaksi produk olahan bulan September tidak pernah masuk ke chart.
2. **Keterangan Satuan Stok Keluar Tercampur**:
   - Transaksi stok keluar yang berasal dari penjualan produk olahan tertulis `40 kg`, `4 kg`, dan `3 kg`, padahal produk olahan tersebut dijual dalam satuan unit/pcs.
   - Angka ringkasan `Total Keluar` di halaman Data Stok gudang raw harvest ikut menjumlahkan unit pcs produk olahan ke dalam total kilogram bahan mentah.
3. **Ketiadaan Opsi Satuan pada Produk Olahan**:
   - Produk olahan petani tidak selalu berupa kemasan pcs (misal olahan tepung singkong atau pakan ternak dapat dijual dalam kg). Form input produk olahan belum menyediakan pemilihan satuan.

### B. Solusi & Perubahan Backend (Laravel)
1. **Resolusi Date Subtraction Overflow (`app/Services/DashboardService.php`)**:
   - Mengubah komputasi iterasi bulan menjadi `$date = $referenceDate->copy()->startOfMonth()->subMonths($i);`.
   - Hal ini menjamin setiap bulan selalu dihitung dari hari pertama bulan tersebut (`01`), mengeliminasi bug date overflow. Bulan September kini selalu tercakup dengan tepat.
2. **Database Migration & Backfill (`database/migrations/2026_09_23_235000_add_unit_to_processed_products_and_stock_transactions.php`)**:
   - Menambahkan kolom `unit` (varchar, default `'pcs'`) pada tabel `processed_products`.
   - Menambahkan kolom `unit` (varchar, default `'kg'`) pada tabel `stock_transactions`.
   - Menjalankan migrasi database dan melakukan *backfill* otomatis pada transaksi historis produk olahan ke unit `'pcs'`.
3. **Pembaruan Model & Service**:
   - [`app/Models/ProcessedProduct.php`](file:///d:/laragon/www/PKM/app/Models/ProcessedProduct.php): Menambahkan `unit` ke `$fillable`.
   - [`app/Models/StockTransaction.php`](file:///d:/laragon/www/PKM/app/Models/StockTransaction.php): Menambahkan `unit` ke `$fillable`; method `recordProcessedProductTransaction` otomatis mengisi unit sesuai produk olahan (`$product->unit ?? 'pcs'`), dan `addTransaction` mengisi `'kg'`.
   - [`app/Services/ProcessedProductService.php`](file:///d:/laragon/www/PKM/app/Services/ProcessedProductService.php): Memasukkan `unit` pada `createForOwner` dan `formatProduct`.
   - [`app/Http/Controllers/ProcessedProductController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/ProcessedProductController.php): Validasi `store` dan `update` menerima `'unit' => 'nullable|string|in:pcs,kg'`.
   - [`app/Http/Controllers/StockController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/StockController.php): `totalIncoming` dan `totalOutgoing` difilter dengan `whereNull('processed_product_id')` agar saldo stok gudang hasil panen mentah murni mencatat komoditas mentah (kg), serta menyertakan `unit` pada daftar riwayat transaksi.
   - [`app/Services/DashboardService.php`](file:///d:/laragon/www/PKM/app/Services/DashboardService.php): `getRecentTransactions` memetakan atribut `unit` transaksi.

### C. Solusi & Perubahan Frontend Flutter (`mobile_app/lib`)
1. **Model Deserialization**:
   - [`mobile_app/lib/models/processed_product.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/processed_product.dart): Ditambahkan field `unit` (default `'pcs'`).
   - [`mobile_app/lib/models/stock.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/stock.dart): Ditambahkan field `unit` pada `StockTransaction` (default `'kg'`).
   - [`mobile_app/lib/models/dashboard.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/dashboard.dart): Ditambahkan field `unit` pada `TransactionSummary` (default `'kg'`).
2. **Form Tambah & Edit Produk Olahan (`mobile_app/lib/screens/processed_products_screen.dart`)**:
   - Ditambahkan field pilihan satuan (Dropdown dengan 2 opsi: `pcs` atau `kg`) berdampingan dengan form kuantitas Stok.
   - Pengiriman parameter `unit` pada fungsi create dan update produk olahan via API service.
   - Kartu katalog produk kini menampilkan satuan dinamis: `Tersedia (X pcs/kg)`, `Harga (Rp) / unit`, dan sisa stok.
3. **Dashboard (`mobile_app/lib/screens/home_screen.dart`)**:
   - Kartu Transaksi Stok Terbaru menampilkan satuan dinamis: `${txn.quantity} ${txn.unit}` (menghasilkan `1000 kg` untuk panen masuk dan `40 pcs`, `4 pcs`, `3 pcs` untuk penjualan produk olahan).
4. **Data Stok Gudang (`mobile_app/lib/screens/stock_screen.dart`)**:
   - Label kolom tabel diubah dari `Jumlah (Kg)` menjadi `Jumlah`.
   - Kuantitas baris transaksi menampilkan `${transaction.quantity} ${transaction.unit}`.
5. **Super Admin Marketing Screen (`mobile_app/lib/screens/super_admin_marketing_screen.dart`)**:
   - Menampilkan sisa stok dinamis sesuai satuan produk: `Sisa Stok: ${p.stock} ${p.unit}`.

### D. Hasil Pengujian & Status Verifikasi
- **Backend API Tests**: `php artisan test tests/Feature/API/FarmerDashboardChartsTest.php` ➔ ✅ **3/3 Passed (67 assertions)** (mencakup verifikasi overflow bulan dan CRUD satuan unit).
- **Processed Product Tests**: `php artisan test tests/Feature/API/ProcessedProductApiTest.php` ➔ ✅ **14/14 Passed (31 assertions)**.
- **Flutter Static Analysis**: `flutter analyze` ➔ ✅ **No issues found! (0 errors, 0 warnings)**.
- **UAT Checklist**: Skenario 9 ditambahkan dan berstatus ✅ **[x] PASSED**.

---

## 13. Implementasi V2: Phase 1 & Phase 2 (Domain Kelompok Tani / Poktan 1–10)

### A. Phase 1: Domain & Business Rule Audit
- **Audit File & Rule Inventory**:
  - Diterbitkan [`docs/V2_DOMAIN_AUDIT.md`](file:///d:/laragon/www/PKM/docs/V2_DOMAIN_AUDIT.md) yang menginventarisasi 10 entitas domain, data contract, serta titik kritis integrasi.
  - Diterbitkan [`docs/V2_BUSINESS_RULES.md`](file:///d:/laragon/www/PKM/docs/V2_BUSINESS_RULES.md) yang mengunci 12 aturan bisnis absolut (Komisi 10% Gross, Dual Market Price, Invarian Anti Double-Counting, Tenant Poktan Guard, dll).

### B. Phase 2: Domain Kelompok Tani (Poktan 1–10)
1. **Database Schema & Migrations**:
   - Migration [`database/migrations/2026_09_24_000001_create_farmer_groups_table.php`](file:///d:/laragon/www/PKM/database/migrations/2026_09_24_000001_create_farmer_groups_table.php): Membuat tabel `farmer_groups` (`id`, `name`, `code` unique, `village`, `district`, `regency`, `province`, `leader_name`, `is_active`, timestamps).
   - Migration [`database/migrations/2026_09_24_000002_add_farmer_group_id_to_users_table.php`](file:///d:/laragon/www/PKM/database/migrations/2026_09_24_000002_add_farmer_group_id_to_users_table.php): Menambahkan relasi foreign key `farmer_group_id` pada tabel `users`.
   - Seeder [`database/seeders/FarmerGroupSeeder.php`](file:///d:/laragon/www/PKM/database/seeders/FarmerGroupSeeder.php): Mendaftarkan 10 Kelompok Tani resmi (`POKTAN-01` s/d `POKTAN-10`) di Desa Sumber Brantas, Bumiaji, Kota Batu.
2. **Backend Domain Logic & Services**:
   - Model [`app/Models/FarmerGroup.php`](file:///d:/laragon/www/PKM/app/Models/FarmerGroup.php) & Update [`app/Models/User.php`](file:///d:/laragon/www/PKM/app/Models/User.php).
   - Service [`app/Services/FarmerGroupService.php`](file:///d:/laragon/www/PKM/app/Services/FarmerGroupService.php): Mengelola listing aktif, agregasi statistik keanggotaan Super Admin, detail anggota Poktan, dan pemindahan anggota.
   - Controller [`app/Http/Controllers/Api/FarmerGroupController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/Api/FarmerGroupController.php): Endpoint publik `GET /api/farmer-groups`, dan guard admin `GET /api/super-admin/farmer-groups`, `POST /api/super-admin/farmer-groups` (Create), `GET /api/super-admin/farmer-groups/{id}` (Detail), `PUT /api/super-admin/farmer-groups/{id}` (Update), `DELETE /api/super-admin/farmer-groups/{id}` (Delete with member guard), `POST /api/super-admin/users/{id}/assign-poktan`.
   - Update [`app/Services/AuthService.php`](file:///d:/laragon/www/PKM/app/Services/AuthService.php) & [`app/Http/Controllers/AuthController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/AuthController.php): Registrasi petani wajib memilih Poktan (`farmer_group_id` required).
   - Update [`app/Services/SuperAdminService.php`](file:///d:/laragon/www/PKM/app/Services/SuperAdminService.php): Eager load relasi `farmerGroup` untuk daftar pengguna.
3. **Frontend Flutter Mobile & Desktop Client**:
   - Model [`mobile_app/lib/models/farmer_group.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/farmer_group.dart) & Update [`mobile_app/lib/models/user.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/user.dart).
   - Service [`mobile_app/lib/services/api/farmer_group_api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api/farmer_group_api_service.dart) & Facade [`mobile_app/lib/services/api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api_service.dart): Lengkap dengan method `createFarmerGroup`, `updateFarmerGroup`, dan `deleteFarmerGroup`.
   - Registrasi Petani [`mobile_app/lib/screens/register_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/register_screen.dart): Dropdown pilihan 10 Poktan wajib dipilih saat mendaftar.
   - Manajemen Pengguna Super Admin:
     - [`mobile_app/lib/widgets/users/user_form_bottom_sheet.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/widgets/users/user_form_bottom_sheet.dart): Pilihan Poktan saat admin membuat/mengubah user petani.
     - [`mobile_app/lib/screens/user_management_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/user_management_screen.dart): Menampilkan badge/teks Kelompok Tani pada Card Mobile dan Kolom Data Table Desktop.
   - **Layar Dedicated CRUD Kelompok Tani Super Admin**:
     - [`mobile_app/lib/screens/farmer_group_management_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/farmer_group_management_screen.dart): Panel manajemen Poktan lengkap dengan stat card, live search, filter status, dialog form tambah/edit Poktan, dialog list detail anggota petani terdaftar, serta penghapusan aman dengan peringatan jika Poktan masih beranggotakan petani.
     - Terintegrasi langsung pada Navigasi Sidebar, Drawer, Quick Navigation Card, dan IndexedStack [`mobile_app/lib/screens/super_admin_dashboard_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/super_admin_dashboard_screen.dart).
4. **Hasil Pengujian & Verifikasi**:
   - **Farmer Group API Tests**: `php vendor/bin/phpunit tests/Feature/API/FarmerGroupTest.php` ➔ ✅ **11/11 Passed (86 assertions)** (mencakup Create, Update, Delete kosong, Delete guard beranggota, Reassign, Otorisasi 403).
   - **Comprehensive API Tests**: `php vendor/bin/phpunit tests/Feature/API/ComprehensiveApiTest.php` ➔ ✅ **12/12 Passed (53 assertions)**.
   - **Full API Suite**: `php vendor/bin/phpunit tests/Feature/API/` ➔ ✅ **123/123 Passed (531 assertions)**.
   - **Flutter Static Analysis**: `flutter analyze` ➔ ✅ **No issues found! (0 errors, 0 warnings)**.

---

## 14. Implementasi V2: Phase 3 (Domain Hasil Tani / Farmer Commodity)

### A. Prinsip Bisnis & Backward Compatibility
- **Tanpa Backfill Asumtif**: Data historis panen dan musim tanam lama tidak dimanipulasi atau diisi komoditas secara tebakan. Kolom `commodity_id` pada tabel `harvests` dan `seasons` dibuat `nullable` demi integritas data historis.
- **Pemisahan Kuantitas & Satuan (`unit`)**: Data baru wajib menentukan kuantitas dan satuan (`kg`, `kuintal`, `ton`, `ikat`, `pcs`) dengan default form UI `kg`.
- **Dinamis & Bebas Enum Global**: Setiap petani bebas mendaftarkan komoditas hasil tani sendiri tanpa dibatasi enum kaku. Petani A dapat memiliki "Jeruk", "Mangga", "Pisang", dan Petani B dapat memiliki "Padi" serta "Jeruk" tanpa konflik.

### B. Database Schema & Migrations
1. Migration [`database/migrations/2026_09_24_000003_create_farmer_commodities_table.php`](file:///d:/laragon/www/PKM/database/migrations/2026_09_24_000003_create_farmer_commodities_table.php):
   - Kolom: `id`, `user_id` (FK cascade ke users), `name`, `code` nullable, `unit` (default `kg`), `description`, `status` (`active`/`inactive`), timestamps, soft deletes.
   - Index komposit: `['user_id', 'status']` dan `['user_id', 'name']`.
2. Migration [`database/migrations/2026_09_24_000004_add_commodity_id_to_harvests_and_seasons_tables.php`](file:///d:/laragon/www/PKM/database/migrations/2026_09_24_000004_add_commodity_id_to_harvests_and_seasons_tables.php):
   - Menambahkan foreign key `commodity_id` (nullable, `nullOnDelete`) ke tabel `harvests` dan `seasons`.

### C. Backend Domain Logic, Controller & Routes
- Model [`app/Models/FarmerCommodity.php`](file:///d:/laragon/www/PKM/app/Models/FarmerCommodity.php) dan relasi `commodities()` pada [`app/Models/User.php`](file:///d:/laragon/www/PKM/app/Models/User.php).
- Service [`app/Services/FarmerCommodityService.php`](file:///d:/laragon/www/PKM/app/Services/FarmerCommodityService.php): Mengelola validasi keunikan nama per petani, isolasi tenant data petani, guard proteksi penghapusan komoditas berpanen, dan agregasi data untuk Super Admin.
- Controller [`app/Http/Controllers/Api/FarmerCommodityController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/Api/FarmerCommodityController.php):
  - Endpoints Petani: `GET /api/commodities`, `POST /api/commodities`, `GET /api/commodities/{id}`, `PUT /api/commodities/{id}`, `DELETE /api/commodities/{id}`.
  - Endpoints Super Admin: `GET /api/super-admin/commodities` (monitoring per petani) dan `PUT /api/super-admin/commodities/{id}` (penyesuaian data).
- Routes [`routes/api.php`](file:///d:/laragon/www/PKM/routes/api.php): Didaftarkan di bawah auth guard `auth:sanctum`.

### D. Frontend Flutter Mobile & Desktop Client
- Model [`mobile_app/lib/models/farmer_commodity.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/farmer_commodity.dart).
- Service [`mobile_app/lib/services/api/farmer_commodity_api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api/farmer_commodity_api_service.dart) & Facade [`mobile_app/lib/services/api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api_service.dart).
- Screen [`mobile_app/lib/screens/farmer_commodity_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/farmer_commodity_screen.dart):
  - Kartu Modern (Mobile) & Data Table (Desktop).
  - Dialog Tambah & Edit Hasil Tani (Pilihan satuan fleksibel: `kg`, `kuintal`, `ton`, `ikat`, `pcs`).
  - Search bar dan Filter Status Aktif/Nonaktif.
  - Konfirmasi penghapusan aman.
- Integrasi Navigasi: Menu "Hasil Tani" (icon `Icons.grass_rounded`) di [`mobile_app/lib/utils/navigation_helper.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/utils/navigation_helper.dart).

### E. Hasil Pengujian & Status Verifikasi
- **Farmer Commodity Tests**: `php vendor/bin/phpunit tests/Feature/API/FarmerCommodityTest.php` ➔ ✅ **9/9 Passed (32 assertions)**.
- **Full Backend API Suite**: `php vendor/bin/phpunit tests/Feature/API/` ➔ ✅ **132/132 Passed (563 assertions)**.
- **Flutter Static Analysis**: `flutter analyze` ➔ ✅ **No issues found! (0 errors, 0 warnings)**.

---

## 15. Implementasi V2: Phase 4 (Integrasi Panen & Biaya Produksi / Harvest & Cost Integration)

### A. Prinsip Bisnis & Backward Compatibility
- **Rantai Nilai Terintegrasi**: Menghubungkan secara eksplisit `Petani` → `Hasil Tani (Commodity)` → `Musim Tanam (Season)` → `Biaya Produksi (Cost)` → `Hasil Panen (Harvest)`.
- **Pewarisan Otomatis Komoditas**: Saat mencatat panen tanpa menyertakan `commodity_id`, panen secara cerdas mewarisi `commodity_id` dari musim tanam (`seasons.commodity_id`) jika musim tersebut telah mengaitkan komoditas.
- **Pemisahan Kuantitas & Satuan Unit**: Form panen mendukung input kuantitas numerik (`quantity`) dan satuan terpisah (`unit`: `kg`, `kuintal`, `ton`, `ikat`, `pcs`), dengan berat baku penyimpanan gudang (`weight_kg`) tetap dipertahankan untuk menjamin integritas stok.
- **Atribusi Biaya ke Komoditas via Musim**: Biaya produksi (`production_costs`) kini memuat atribusi komoditas hasil tani secara konsisten melalui relasi musim tanam (`season_id -> commodity_id`).
- **Integritas Historis (Tanpa Backfill Asumtif)**: Data panen dan biaya lama tetap valid (`commodity_id = NULL`), tidak memicu error kalkulasi, dan mutasi stok gudang (`StockTransaction`) tetap akurat dengan presisi desimal 2 angka.

### B. Database Schema & Migrations
1. Migration [`database/migrations/2026_09_25_000001_add_unit_to_harvests_table.php`](file:///d:/laragon/www/PKM/database/migrations/2026_09_25_000001_add_unit_to_harvests_table.php):
   - Menambahkan kolom `unit` (nullable string: `kg`, `kuintal`, `ton`, `ikat`, `pcs`) pada tabel `harvests`.

### C. Backend Domain Logic, Controller & Services
- **Models**:
  - [`app/Models/Harvest.php`](file:///d:/laragon/www/PKM/app/Models/Harvest.php): `$fillable` menambahkan `commodity_id` dan `unit`, relasi `commodity()`, eager load `$with = ['season', 'commodity']`.
  - [`app/Models/Season.php`](file:///d:/laragon/www/PKM/app/Models/Season.php): `$fillable` menambahkan `commodity_id`, relasi `commodity()`, eager load `$with = ['commodity']`.
- **Harvest Service & Controller**:
  - [`app/Services/HarvestService.php`](file:///d:/laragon/www/PKM/app/Services/HarvestService.php): Logika pewarisan otomatis komoditas musim, penanganan `unit`, dan pembaruan format respon API.
  - [`app/Http/Controllers/HarvestController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/HarvestController.php): Validasi ketat kepemilikan komoditas (`user_id` guard) dan validasi enum satuan `unit`.
- **Cost Service & Controller**:
  - [`app/Services/CostService.php`](file:///d:/laragon/www/PKM/app/Services/CostService.php) & [`app/Http/Controllers/CostController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/CostController.php): Eager loading `season.commodity` serta penambahan `commodity_id` dan `commodity_name` pada format output biaya produksi.

### D. Frontend Flutter Mobile & Desktop Client
- **Models**:
  - [`mobile_app/lib/models/harvest.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/harvest.dart): Ditambahkan `commodityId`, `commodityName`, dan `unit`.
  - [`mobile_app/lib/models/season.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/season.dart): Ditambahkan `commodityId` dan `commodityName`.
  - [`mobile_app/lib/models/cost.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/cost.dart): Ditambahkan `commodityId` dan `commodityName`.
- **API Client & Facade**:
  - [`mobile_app/lib/services/api/harvest_api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api/harvest_api_service.dart), [`mobile_app/lib/services/api/season_api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api/season_api_service.dart), dan [`mobile_app/lib/services/api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api_service.dart).
- **UI Screens & Form Sheets**:
  - [`mobile_app/lib/widgets/seasons/season_form_bottom_sheet.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/widgets/seasons/season_form_bottom_sheet.dart): Dropdown pilihan komoditas hasil tani pada form musim tanam.
  - [`mobile_app/lib/screens/add_edit_harvest_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/add_edit_harvest_screen.dart): Form dialog panen lengkap dengan dropdown komoditas, jumlah panen, dropdown satuan (`kg`, `kuintal`, `ton`, `ikat`, `pcs`), dan input berat baku kg.
  - [`mobile_app/lib/screens/harvest_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/harvest_screen.dart): Badge komoditas dan ringkasan satuan pada kartu mobile serta kolom tabel desktop.
  - [`mobile_app/lib/screens/season_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/season_screen.dart): Indikator komoditas hasil tani pada kartu mobile dan kolom tabel desktop.

### E. Hasil Pengujian & Status Verifikasi
- **Integration Tests**: `php vendor/phpunit/phpunit/phpunit tests/Feature/API/HarvestCostIntegrationTest.php` ➔ ✅ **8/8 Passed (31 assertions)**.
- **Full Backend API Suite**: `php vendor/phpunit/phpunit/phpunit tests/Feature/API/` ➔ ✅ **140/140 Passed (594 assertions)**.
- **Flutter Static Analysis**: `flutter analyze` ➔ ✅ **No issues found! (0 errors, 0 warnings)**.

---

## 16. Implementasi V2: Phase 5 (Historical Market Price & Snapshotting)

**Tanggal:** 25 September 2026  
**Status:** ✅ **100% Selesai & Terverifikasi (Production Ready)**  
**Hasil Pengujian:**
- **Feature Tests Phase 5**: `php vendor/phpunit/phpunit/phpunit tests/Feature/API/MarketPriceTest.php` ➔ ✅ **11/11 Passed (69 assertions)**
- **Full Backend API Suite**: `php vendor/phpunit/phpunit/phpunit tests/Feature/API/` ➔ ✅ **151/151 Passed (663 assertions)**
- **Flutter Static Analysis**: `flutter analyze` ➔ ✅ **No issues found! (0 errors, 0 warnings)**

### A. Prinsip Bisnis & Kepatuhan Arsitektur
1. **Harga Acuan Pasar Berbasis Tanggal Efektif**: Setiap harga acuan terikat pada `commodity_id` dan `effective_date`. Database menerapkan constraint `UNIQUE (commodity_id, effective_date)` sebagai sumber kebenaran tunggal (*single source of truth*) yang deterministik.
2. **Snapshotting Otomatis Panen**: Saat panen dicatat, sistem secara otomatis mengunci harga acuan pasar terbaru yang berlaku (`effective_date <= harvest_date`).
3. **Immutability Panen Historis**: Snapshot pada panen lama tidak akan pernah berubah meskipun master harga pasar di masa depan dimutasi atau diterbitkan harga baru.
4. **Proteksi Integritas Referensi**:
   - Master harga pasar yang telah dirujuk oleh catatan panen historis (`isReferenced() == true`) **dilarang dihapus (HTTP 422)**.
   - Nominal harga dan tanggal pada master harga yang sudah dirujuk **dilarang diubah (HTTP 422)**, hanya catatan (*notes*) yang diizinkan untuk dikoreksi secara non-destruktif.
5. **Proteksi Komoditas (No Cascade Delete)**: Foreign key `market_prices.commodity_id` menggunakan **`ON DELETE RESTRICT`**. Menghapus komoditas yang memiliki histori harga acuan pasar ditolak di tingkat domain service maupun oleh database engine.
6. **Pemisahan Tegas Harga Panen vs Harga Transaksi**:
   - $\text{Gross Harvest Value} = \text{weight\_kg} \times \text{market\_price\_snapshot}$ adalah estimasi pendapatan kotor hasil bumi saat panen (bukan net economic profit).
   - Transaksi jual beli produk olahan tetap menggunakan harga katalog olahan (`order_items.price_snapshot`).
   - Penjualan hasil tani mentah mengacu pada harga pasar tanggal transaksi (`effective_date <= transaction_date`), tanpa membuat duplikasi tabel/field transaksi baru.
7. **Otorisasi Ketat**: Petani bersifat **READ-ONLY**, form manipulasi CRUD dan pemicu sinkronisasi (*ingestion*) hanya dapat diakses oleh **Super Admin** (`role: super_admin`).

### B. Database Schema & Migrations
1. Migration [`database/migrations/2026_09_25_000002_create_market_prices_table.php`](file:///d:/laragon/www/PKM/database/migrations/2026_09_25_000002_create_market_prices_table.php):
   - Tabel `market_prices` dengan `commodity_id`, `price`, `unit`, `effective_date`, `source`, `notes`, `created_by`, `ON DELETE RESTRICT`.
2. Migration [`database/migrations/2026_09_25_000003_add_market_price_snapshot_to_harvests_table.php`](file:///d:/laragon/www/PKM/database/migrations/2026_09_25_000003_add_market_price_snapshot_to_harvests_table.php):
   - Menambahkan `market_price_id`, `market_price_snapshot`, `market_price_effective_date` pada tabel `harvests`.

### C. Backend Providers, Services & API
- Contract & Mock: [`app/Contracts/MarketPriceProviderInterface.php`](file:///d:/laragon/www/PKM/app/Contracts/MarketPriceProviderInterface.php) dan [`app/Services/MarketPrice/MockMarketPriceProvider.php`](file:///d:/laragon/www/PKM/app/Services/MarketPrice/MockMarketPriceProvider.php).
- Ingestion Service: [`app/Services/MarketPriceIngestionService.php`](file:///d:/laragon/www/PKM/app/Services/MarketPriceIngestionService.php) dengan aturan mutasi aman: *same price* $\rightarrow$ no-op, *different + unreferenced* $\rightarrow$ update, *different + referenced* $\rightarrow$ reject.
- Artisan Command: [`app/Console/Commands/IngestMarketPricesCommand.php`](file:///d:/laragon/www/PKM/app/Console/Commands/IngestMarketPricesCommand.php) (`php artisan market-price:ingest`).
- Domain Services & Models: [`app/Models/MarketPrice.php`](file:///d:/laragon/www/PKM/app/Models/MarketPrice.php), [`app/Services/MarketPriceService.php`](file:///d:/laragon/www/PKM/app/Services/MarketPriceService.php), dan integrasi snapshotting pada [`app/Services/HarvestService.php`](file:///d:/laragon/www/PKM/app/Services/HarvestService.php).
- REST Controller: [`app/Http/Controllers/Api/MarketPriceController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/Api/MarketPriceController.php) dengan 6 endpoints dilindungi middleware `auth:sanctum` & `role:super_admin`.

### D. Frontend Flutter Client
- Models: [`mobile_app/lib/models/market_price.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/market_price.dart) dan pembaruan [`mobile_app/lib/models/harvest.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/harvest.dart).
- Services: [`mobile_app/lib/services/api/market_price_api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api/market_price_api_service.dart) dan facade [`mobile_app/lib/services/api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api_service.dart).
- Screens:
  - [`mobile_app/lib/screens/market_price_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/market_price_screen.dart): Layar pemantauan harga acuan pasar, filter komoditas, dialog CRUD dan tombol sync Super Admin.
  - [`mobile_app/lib/screens/harvest_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/harvest_screen.dart): Menampilkan badge harga acuan pasar dan taksiran pendapatan kotor panen (*Gross Harvest Value*).
  - [`mobile_app/lib/utils/navigation_helper.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/utils/navigation_helper.dart): Pendaftaran menu sidebar untuk Petani dan Super Admin.

---

## 17. Implementasi V2: Phase 6 (Farmer Economic Result)

**Tanggal:** 25 September 2026  
**Status:** ✅ **100% Selesai & Terverifikasi (Production Ready)**  
**Hasil Pengujian:**
- **Feature Tests Phase 6**: `php vendor/phpunit/phpunit/phpunit tests/Feature/API/FarmerEconomicResultTest.php` ➔ ✅ **11/11 Passed (70 assertions)**
- **Full Backend API Suite**: `php vendor/phpunit/phpunit/phpunit tests/Feature/API/` ➔ ✅ **164/164 Passed (743 assertions)**
- **Flutter Static Analysis**: `flutter analyze` ➔ ✅ **No issues found! (0 errors, 0 warnings)**

### A. Prinsip Bisnis & Formula Perhitungan
1. **Formula Perhitungan Panen (Harvest)**:
   $$\text{Revenue} = \text{weight\_kg} \times \text{Historical Market Price Snapshot}$$
   $$\text{Harvest Allocated Cost} = \left(\frac{\text{harvest.weight\_kg}}{\text{total\_season\_harvest\_weight\_kg}}\right) \times \text{season\_total\_cost}$$
   $$\text{Harvest Profit/Loss} = \text{Harvest Revenue} - \text{Harvest Allocated Cost}$$
2. **Aturan Khusus Nilai NULL (Anti Asumsi 0)**:
   - Jika `market_price_snapshot = NULL`:
     - $\text{Revenue} = \text{NULL}$
     - $\text{Profit/Loss} = \text{NULL}$
     - *(Sistem tidak menganggap Revenue = 0)*.
3. **Formula Perhitungan Musim (Season Summary)**:
   $$\text{Season Revenue} = \sum \text{harvest revenue yang valid}$$
   $$\text{Season Production Cost} = \text{total biaya produksi musim}$$
   $$\text{Season Profit/Loss} = \text{Season Revenue} - \text{Season Production Cost}$$
4. **Preservasi Snapshot Historis (Phase 5)**:
   - Mekanisme Phase 5 tetap dipertahankan utuh: harga yang digunakan adalah harga pada snapshot panen, bukan harga pasar terkini.
5. **Agregasi Multi-Tingkat**:
   - Per-Harvest: Analisis ekonomi per catatan panen.
   - Per-Season: Agregasi per musim tanam (`has_complete_price_data` flag menandai apakah seluruh panen telah memiliki snapshot harga pasar).
   - Farmer Overall: Ringkasan seluruh musim milik petani aktif.
   - Super Admin Aggregate: Monitoring performa ekonomi makro seluruh petani di platform.
6. **Isolasi Tenant & Keamanan Otorisasi**:
   - Petani hanya dapat mengakses panen dan musim milik dirinya sendiri (HTTP 403 jika cross-tenant).
   - Endpoint agregat platform dilindungi middleware `auth:sanctum` & `role:super_admin` (HTTP 403 jika diakses petani).

### B. Backend Services, Controller & Routes
- Service: [`app/Services/FarmerEconomicResultService.php`](file:///d:/laragon/www/PKM/app/Services/FarmerEconomicResultService.php)
- Controller: [`app/Http/Controllers/Api/FarmerEconomicResultController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/Api/FarmerEconomicResultController.php)
- Routes [`routes/api.php`](file:///d:/laragon/www/PKM/routes/api.php):
  - `GET /api/harvests/{harvest}/economic-result`
  - `GET /api/seasons/{season}/economic-summary`
  - `GET /api/farmer/economic-summary`
  - `GET /api/super-admin/economic-aggregate`
- Feature Tests: [`tests/Feature/API/FarmerEconomicResultTest.php`](file:///d:/laragon/www/PKM/tests/Feature/API/FarmerEconomicResultTest.php)

### C. Frontend Flutter Mobile & Desktop Client
- Models: [`mobile_app/lib/models/economic_result.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/economic_result.dart) (`HarvestEconomicResult`, `SeasonEconomicSummary`, `FarmerEconomicSummary`)
- Services: [`mobile_app/lib/services/api/farmer_economic_result_api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api/farmer_economic_result_api_service.dart) & Facade [`mobile_app/lib/services/api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api_service.dart)
- UI Presentation:
  - [`mobile_app/lib/screens/harvest_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/harvest_screen.dart): Ditambahkan aksi **Hasil Ekonomi** (icon `analytics_outlined`) pada kartu mobile & tabel desktop.
  - Dialog Bottom Sheet `_EconomicResultSheet` menyajikan 5 komponen rapi:
    1. **Hasil Panen** (`weight_kg` dasar kalkulasi)
    2. **Harga Pasar** (Snapshot harga acuan pasar / NULL)
    3. **Revenue** (`weight_kg * snapshot` / NULL)
    4. **Allocated Production Cost** (Alokasi biaya proporsional musim)
    5. **Profit/Loss** (`Revenue - Allocated Cost` / NULL)

### D. Optimasi Responsivitas UI (Mobile & Desktop)
- [`mobile_app/lib/screens/harvest_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/harvest_screen.dart):
  - **Tabel Desktop**: Menghilangkan RenderFlex overflow stripe 5.1px dengan `FittedBox` scaleDown pada tombol aksi dan `SingleChildScrollView` horizontal dengan batasan `minWidth: 920`.
  - **Desktop Summary Stat Cards**: Menggunakan `LayoutBuilder` untuk mengonversi baris 3 kartu menjadi kolom saat lebar layar < 900px, mencegah penyusutan elemen angka/teks.
  - **Mobile Harvest Cards**: Header kartu memisahkan tanggal dan nama komoditas secara rapi, serta menggunakan `Wrap` pada baris gross snapshot untuk mencegah teks terpotong di layar HP berdimensi sempit.
  - **Modal Rincian Ekonomi**: `_DetailRow` menggunakan `Flexible` dengan perataan teks kanan untuk angka/nilai besar agar tidak overflow di layar sempit.
- [`mobile_app/lib/screens/add_edit_harvest_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/add_edit_harvest_screen.dart):
  - Mengadopsi `LayoutBuilder`: saat lebar dialog < 380px, bidang form yang berdampingan (Tanggal & Musim, Jumlah & Satuan) otomatis berubah menjadi susunan vertikal (stack) yang ergonomis dan mudah disentuh.
  - Ditambahkan `isExpanded: true` dan `overflow: TextOverflow.ellipsis` pada seluruh dropdown menu item agar nama komoditas dan musim yang panjang tidak menyebabkan RenderFlex overflow.
- [`mobile_app/lib/screens/market_price_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/market_price_screen.dart):
  - Mengubah baris komoditas & harga pada kartu menjadi `Wrap`, memastikan harga per satuan turun rapi di bawah nama komoditas saat layar sempit tanpa memicu overflow.
  - Dialog tambah/ubah harga acuan diberi `isExpanded: true` dan pemotongan teks ellipsis pada opsi dropdown komoditas.

---

## 18. Phase 8: Standard Platform Commission 10% (Backend & Mobile/Web UI)

### A. Konsep & Arsitektur Bisnis Komisi Platform (10%)
1. **Kalkulasi Server-Side Standar & Imutabel**:
   - Komisi platform ditetapkan standar sebesar **10%** dari total bruto penjualan (`base_amount × 10%`).
   - Pendapatan bersih petani (*net farmer amount*) dihitung otomatis:
     $$\text{net\_farmer\_amount} = \text{base\_amount} - \text{commission\_amount}$$
   - Nilai komisi dan persentase bersifat imutabel (*read-only*) setelah tercatat untuk kepastian audit keuangan.
2. **Pemisahan Tegas dari Biaya Produksi & Stok**:
   - Komisi platform tidak memotong atau mencemari komponen biaya produksi petani (`costs` / `allocated_cost`) yang berasal dari sarana produksi/tenaga kerja di kebun.
   - Komisi platform murni memotong dari perolehan transaksi penjualan pada lapisan distribusi/pasar.
3. **Idempotensi & Proteksi Potongan Ganda**:
   - Kolom `sale_id` pada tabel `commissions` diproteksi indeks `UNIQUE`.
   - `CommissionService::calculateAndRecordCommission()` dijalankan di dalam `DB::transaction()` dengan `lockForUpdate()`. Jika penyelesaian pesanan dipanggil ulang (*retry* atau pemanggilan ganda), record komisi tidak akan digandakan.

### B. Skema Database & Migrasi
- **File Migrasi:** [`database/migrations/2026_09_25_000004_create_commissions_table.php`](file:///d:/laragon/www/PKM/database/migrations/2026_09_25_000004_create_commissions_table.php)
  - `sale_id`: Foreign key ke `sales`, `unique()`.
  - `order_id`: Foreign key ke `orders`, `nullable()`.
  - `user_id`: Foreign key ke `users` (petani pemilik produk).
  - `rate`: Decimal(5,2), default `10.00`.
  - `base_amount`: Decimal(15,2) (Nilai kotor transaksi penjualan).
  - `commission_amount`: Decimal(15,2) (Nominal komisi platform 10%).
  - `net_farmer_amount`: Decimal(15,2) (Nominal bersih diterima petani 90%).
  - `status`: Enum (`pending`, `collected`, `waived`), default `collected`.
  - `notes`: Text nullable.

### C. Backend Models & Service Integration
- **Model:**
  - [`app/Models/Commission.php`](file:///d:/laragon/www/PKM/app/Models/Commission.php): Mendefinisikan relasi `sale()`, `order()`, `farmer()`, `user()` dan casting tipe decimal/datetime.
  - [`app/Models/Sale.php`](file:///d:/laragon/www/PKM/app/Models/Sale.php): Relasi `hasOne(Commission::class)`.
  - [`app/Models/Order.php`](file:///d:/laragon/www/PKM/app/Models/Order.php): Relasi `hasMany(Commission::class)`.
- **Service Layer:**
  - [`app/Services/CommissionService.php`](file:///d:/laragon/www/PKM/app/Services/CommissionService.php):
    - `calculateAndRecordCommission(Sale $sale)`: Menghitung 10% dan menyimpan record komisi secara idempoten.
    - `getCommissionsForSuperAdmin()`: Mengambil seluruh riwayat komisi platform dengan filter pencarian, status, dan tanggal.
    - `getCommissionsForFarmer()`: Mengambil komisi khusus petani yang sedang login.
    - `getSummaryForSuperAdmin()` & `getSummaryForFarmer()`: Mengagregasi KPI metrik (total volume transaksi, total komisi terkumpul, total pendapatan petani).
  - [`app/Services/SaleService.php`](file:///d:/laragon/www/PKM/app/Services/SaleService.php):
    - Diinjeksikan `CommissionService`.
    - Otomatis mencatat komisi 10% pada saat pemenuhan pesanan katalog (`createSaleFromOrder()`) maupun pencatatan penjualan langsung petani (`createSale()`).

### D. RESTful API & Otorisasi
- **Controller:** [`app/Http/Controllers/Api/CommissionController.php`](file:///d:/laragon/www/PKM/app/Http/Controllers/Api/CommissionController.php)
- **Routes [`routes/api.php`](file:///d:/laragon/www/PKM/routes/api.php):**
  - `GET /api/commissions`: Mendapatkan daftar komisi (multi-tenant aware: Super Admin melihat seluruh sistem, Petani hanya melihat miliknya).
  - `GET /api/commissions/summary`: Ringkasan metrik finansial komisi.
  - `GET /api/super-admin/commissions` & `GET /api/super-admin/commissions/summary`: Route alias untuk Super Admin dashboard.

### E. Frontend Flutter Client
- **Model:** [`mobile_app/lib/models/commission.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/models/commission.dart) (`Commission`, `CommissionSummary`).
- **Service:** [`mobile_app/lib/services/api/commission_api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api/commission_api_service.dart) & Facade [`mobile_app/lib/services/api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api_service.dart).
- **UI Screen:** [`mobile_app/lib/screens/super_admin_commission_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/super_admin_commission_screen.dart)
  - Menampilkan 4 Kartu KPI Finansial Responsif (Total Transaksi, Komisi Platform 10%, Hak Bersih Petani, Rata-rata Komisi) yang mengalir adaptif saat lebar layar mengecil.
  - Search bar interaktif dengan debouncing query pencarian (kode pesanan, nama pembeli, nama petani).
  - Daftar transaksi komisi dengan pill status dinamis (`collected`, `pending`, `waived`).
  - Dialog rincian komisi dengan rincian lengkap nilai bruto, rate (10%), potongan komisi, dan hak bersih petani.
- **Navigasi:**
  - Ditambahkan ke [`mobile_app/lib/utils/navigation_helper.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/utils/navigation_helper.dart) untuk Super Admin dan Petani.
  - Diintegrasikan ke [`mobile_app/lib/screens/super_admin_dashboard_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/super_admin_dashboard_screen.dart) pada Tab 10, Quick Action Card, dan Sidebar Drawer.

### F. Pengujian Otomatis
- **Test Suite:** [`tests/Feature/API/CommissionTest.php`](file:///d:/laragon/www/PKM/tests/Feature/API/CommissionTest.php)
  - `test_order_completion_automatically_records_ten_percent_commission`: Verifikasi otomatis komisi 10% saat order diselesaikan.
  - `test_commission_creation_is_idempotent_and_prevents_duplicate_records`: Memverifikasi idempotensi dan pencegahan komisi duplikat.
  - `test_direct_sale_automatically_records_commission`: Verifikasi komisi tercatat pada direct sale produk panen/olahan.
  - `test_super_admin_can_view_all_commissions_and_filter`: Memastikan Super Admin dapat melihat dan memfilter seluruh komisi.
  - `test_farmer_can_only_view_own_commissions`: Verifikasi isolasi multi-tenant antar petani.
  - `test_commission_summary_calculates_correct_kpis`: Verifikasi agregasi matematis KPI ringkasan.
  - `test_unauthenticated_user_cannot_access_commissions`: Proteksi otentikasi Sanctum (401 Unauthorized).
- **Hasil:** **7/7 Passed (28 Assertions)**, serta seluruh 171 test suite sistem lulus 100%. Flutter analyze **0 Issues**.



