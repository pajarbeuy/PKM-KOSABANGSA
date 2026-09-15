# 📱 Analisis Komprehensif: Flutter Mobile App (`mobile_app`)

> **Tanggal Analisis:** 15 September 2026  
> **Target:** Folder `d:\laragon\www\PKM\mobile_app`  
> **Teknologi:** Flutter 3.x / Dart 3.11+, Provider, HTTP, Material 3  

---

## Executive Summary

Aplikasi `mobile_app` adalah klien mobile (sekaligus responsif web/desktop) untuk sistem **SIMHPSK (Sistem Informasi Manajemen Hasil Pertanian dan Sistem Keuangan)**. Fitur aplikasi ini sangat lengkap (mulai dari manajemen panen, stok, penjualan, biaya, laporan PDF/Excel, AI Chatbot, hingga manajemen Super Admin dan landing page editor).

Namun, dari sisi arsitektur dan kualitas kode, terdapat **beberapa temuan kritis (High Severity)** yang dapat menyebabkan crash, kegagalan koneksi di perangkat fisik, penurunan performa, serta struktur kode yang sulit dirawat jika tidak segera ditata.

---

## 1. Temuan Kritis & Bug (High Severity)

### 🔴 1.1. Hardcoded IP `127.0.0.1` di `api_config.dart` (Blokir Device Fisik & Emulator)
* **Lokasi:** [`lib/api_config.dart:3`](file:///d:/laragon/www/PKM/mobile_app/lib/api_config.dart#L3)
* **Masalah:**
  ```dart
  static String get serverIp => '127.0.0.1'; // Bypassed
  ```
  Di dalam folder sudah disiapkan `api_config_platform_io.dart` yang menangani IP emulator Android (`10.0.2.2`) vs iOS (`127.0.0.1`), namun dilewati secara manual dengan hardcode `127.0.0.1`.
* **Dampak:** 
  - **Android Emulator** tidak bisa konek ke backend Laravel (harus `10.0.2.2`).
  - **Smartphone Fisik (Real Device)** tidak bisa konek sama sekali karena `127.0.0.1` merujuk ke ponsel itu sendiri, bukan ke laptop/server Laragon.

---

### 🔴 1.2. Unsafe JSON Casting di Model (Risiko Runtime Crash `TypeError`)
* **Lokasi:** [`lib/models/sale.dart:48`](file:///d:/laragon/www/PKM/mobile_app/lib/models/sale.dart#L48), [`lib/models/user.dart:24`](file:///d:/laragon/www/PKM/mobile_app/lib/models/user.dart#L24)
* **Masalah:**
  Model menggunakan casting langsung tanpa parsing aman:
  ```dart
  // sale.dart
  id: json['id'] as int, // Crash jika Laravel mengembalikan numeric string atau null
  seasonId: json['season_id'] as int?,
  
  // user.dart
  id: json['id'] as int,
  name: json['name'] as String,
  email: json['email'] as String,
  ```
  Bandingkan dengan [`lib/models/harvest.dart:28`](file:///d:/laragon/www/PKM/mobile_app/lib/models/harvest.dart#L28) yang sudah benar menggunakan `int.tryParse(json['id']?.toString() ?? '') ?? 0`.
* **Dampak:** Aplikasi langsung melempar exception `Unhandled Exception: type 'String' is not a subtype of type 'int' in type cast` saat respons backend sedikit bervariasi.

---

### 🔴 1.3. Async Gap & Context Leak (`use_build_context_synchronously`)
* **Lokasi:** [`lib/screens/stock_screen.dart:766-771`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/stock_screen.dart#L766-L771)
* **Masalah:**
  ```dart
  final result = await _apiService.addStockTransaction(...);
  if (mounted) {
    if (result['success']) {
      Navigator.pop(context); // Context modal sheet yang mungkin sudah unmounted
      _loadStock();
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  }
  ```
* **Dampak:** Warning static analysis dan risiko crash jika pengguna menutup modal sheet sebelum request HTTP selesai.

---

### 🔴 1.4. Keamanan Token: Penyimpanan Plain-Text di `SharedPreferences`
* **Lokasi:** [`lib/providers/auth_provider.dart:76`](file:///d:/laragon/www/PKM/mobile_app/lib/providers/auth_provider.dart#L76)
* **Masalah:** Token autentikasi `auth_token` dan token impersonasi `original_admin_token` disimpan dalam plain text di `SharedPreferences`.
* **Dampak:** Pada perangkat Android yang di-root atau melalui backup ADB, token Bearer admin/user dapat diekstraksi dengan mudah. Seharusnya menggunakan `flutter_secure_storage` (KeyStore / Keychain).

---

## 2. Struktur File & Kebersihan Proyek (Medium Severity)

### 🟡 2.1. Folder Platform `linux` Tersasar Masuk ke Dalam `lib/`
* **Lokasi:** [`lib/linux/`](file:///d:/laragon/www/PKM/mobile_app/lib/linux)
* **Temuan:** Folder platform Linux Flutter (berisi `CMakeLists.txt`, `runner/`, `flutter/`) tidak sengaja tergeser (drag-and-drop) ke dalam folder `lib/`.
* **Solusi:** Pindahkan `lib/linux` kembali ke root folder `mobile_app/linux` sejajar dengan `android/`, `ios/`, `windows/`.

---

### 🟡 2.2. File Sampah & Dead Code di Source Tree
1. **`lib/screens/home_screen.dart.bak` (33 KB):** File backup lama yang ditinggalkan di production tree.
2. **`lib/dashboard_screen.dart` (2.6 KB):** Dummy screen mockup awal yang sudah tidak lagi dipakai oleh sistem (routing menggunakan `HomeScreen` dan `SuperAdminDashboardScreen`).
3. **`lib/login_screen.dart` (14 KB):** Berada di root `lib/`, padahal ada folder `lib/screens/` di mana seluruh 25 screen lainnya berada.
4. **`lib/examples/` (16 KB):** File contoh (`login_example.dart`, `quick_test_example.dart`, `register_example.dart`) ikut ter-bundle dalam app.

---

## 3. Arsitektur & State Management (Medium Severity)

### 🟡 3.1. Monolithic God-Class `ApiService` (1.676 Baris)
* **Lokasi:** [`lib/services/api_service.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/services/api_service.dart)
* **Kondisi:**
  Satu file `api_service.dart` memuat **seluruh domain aplikasi**:
  - Auth & Password Reset
  - Season CRUD
  - Harvest CRUD
  - Stock & Transactions
  - Sales CRUD
  - Costs CRUD
  - Reports (Profit & Loss, Target vs Actual, PDF downloads)
  - Settings & Notifications
  - Chatbot AI
  - Super Admin (Users, Menus, Feedback, Landing Editor)
* **Solusi:** Pecah menjadi modular services:
  - `AuthApiService`
  - `HarvestApiService`
  - `SaleApiService`
  - `StockApiService`
  - `ReportApiService`
  - `SuperAdminApiService`

---

### 🟡 3.2. Provider Under-Utilized (State Management Terfragmentasi)
* **Kondisi:**
  Meskipun package `provider: ^6.0.0` dipasang di `pubspec.yaml`, hanya ada **1 Provider** di seluruh aplikasi yaitu `AuthProvider`.
* **Dampak:**
  - 25 screen lainnya mengelola state sendiri menggunakan `StatefulWidget` + `setState()`.
  - Terjadi duplikasi logika fetch, loading spinner, dan error handling di setiap screen (`harvest_screen.dart`, `sales_screen.dart`, `stock_screen.dart`, dll).
  - Tidak ada caching data. Jika user berpindah tab dari Panen ke Penjualan lalu kembali ke Panen, aplikasi selalu melakukan HTTP GET ulang dari nol.

---

### 🟡 3.3. Inefisiensi Navigasi (`Navigator.pushReplacement` di Sidebar)
* **Lokasi:** [`lib/utils/navigation_helper.dart:18-23`](file:///d:/laragon/www/PKM/mobile_app/lib/utils/navigation_helper.dart#L18-L23)
* **Kondisi:**
  Setiap kali user mengklik item menu sidebar atau bottom navigation, aplikasi memanggil:
  ```dart
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
  ```
* **Dampak:** Seluruh halaman, header, drawer, dan state dihancurkan dan dibuat ulang (destroy & rebuild), menyebabkan flicker dan beban jaringan berlebih. Seharusnya menggunakan `IndexedStack` atau persistent nested navigation.

---

## 4. Performa & Ukuran File Monster

### 🟠 4.1. `landing_screen.dart` (100 KB, 2.747 Baris)
* **Lokasi:** [`lib/screens/landing_screen.dart`](file:///d:/laragon/www/PKM/mobile_app/lib/screens/landing_screen.dart)
* **Kondisi:**
  - File berukuran 100 KB dengan 2.747 baris dalam satu file class.
  - Memuat 5 `AnimationController` (liquid blob morphing), custom painters, wave animations, dan seluruh section (Hero, Features, Stats, Workflow, Testimonial, CTA, Footer).
* **Rekomendasi:** Ekstraksi section menjadi widget terpisah di `lib/widgets/landing/` (`hero_section.dart`, `feature_section.dart`, `blob_background.dart`).

---

## 5. Hasil Static Analysis (`flutter analyze`)

Hasil uji `flutter analyze` mendeteksi **17 issues**:
- **10 Warning Unused Import** di `home_screen.dart` (mengimpor screen yang tidak dipakai langsung).
- **3 Warning Unused Field/Variable** di `home_screen.dart` (`_mobileNavIndex`, `_navTo`, `email`).
- **3 Info Asynchronous Context Violation** di `stock_screen.dart` (mengakses `context` setelah `await` tanpa `context.mounted` check yang tepat).

---

## 6. Checklist Prioritas Perbaikan

| No | Kategori | Tugas | Prioritas | Estimasi |
|:--:|:---|:---|:---:|:---:|
| 1 | **Bug / Network** | Pindahkan `serverIp` ke deteksi dinamis / fallback IP LAN & Emulator di `api_config.dart` | 🔴 **High** | 15 Menit |
| 2 | **Stabilitas** | Safe parsing di `Sale.fromJson` & `User.fromJson` (hindari crash `TypeError`) | 🔴 **High** | 20 Menit |
| 3 | **Struktur** | Pindahkan `lib/linux` kembali ke root `linux/` | 🔴 **High** | 5 Menit |
| 4 | **Hygiene** | Hapus `home_screen.dart.bak`, `dashboard_screen.dart`, dan pindahkan `login_screen.dart` ke `lib/screens/` | 🟡 **Medium** | 10 Menit |
| 5 | **Linter** | Bersihkan 17 warning di `home_screen.dart` & perbaiki context check di `stock_screen.dart` | 🟡 **Medium** | 15 Menit |
| 6 | **Arsitektur** | Modularisasi `api_service.dart` (pecah per domain) | 🟢 **Low/Enhancement** | 1 Jam |
| 7 | **Refactor** | Pecah `landing_screen.dart` (2.747 baris) menjadi sub-widget | 🟢 **Low/Enhancement** | 45 Menit |
