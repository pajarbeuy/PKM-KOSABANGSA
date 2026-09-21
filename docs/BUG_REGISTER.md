# Register Bug & Masalah Teridentifikasi (Bug Register)

**Proyek:** SumberTani berbasis AI (sebelumnya SIMHPSK)  
**Dokumen:** `docs/BUG_REGISTER.md`  
**Status:** Canonical Living Document  
**Terakhir Diperbarui:** 21 September 2026  

---

## 📌 Ringkasan Status Bug

| ID Bug | Deskripsi Singkat | Severity | Status | Tanggal Selesai | Regresi / Verifikasi |
|---|---|---|---|---|---|
| **BUG-001** | Ketidaksinkronan Kategori Biaya (Chart artifact: `equipment`, `transport`) | Medium | ✅ RESOLVED | 18 Sep 2026 | `tests/Feature/API/BugFixRegressionTest.php` |
| **BUG-002** | Status Musim Tanam Tidak Otomatis Berpindah & Mengabaikan Musim Lampau | High | ✅ RESOLVED | 18 Sep 2026 | `tests/Feature/API/BugFixRegressionTest.php` |
| **BUG-003** | Undefined `$oldWeight` di `SaleService::updateSale()` (Gagal update saldo stok) | Critical | ✅ RESOLVED | 19 Sep 2026 | `tests/Feature/API/BugFixRegressionTest.php` |
| **BUG-004** | Tooltip Grafik Panen & Penjualan Menampilkan Rasio Persen Semu / Menyesatkan | Low | ✅ RESOLVED | 20 Sep 2026 | `mobile_app/lib/widgets/harvest_chart.dart` |
| **BUG-005** | Kolom Total Panen di Layar Musim Tanam Menampilkan 0 kg (`harvests_sum_weight_kg`) | High | ✅ RESOLVED | 20 Sep 2026 | `mobile_app/test/models/season_model_test.dart` |
| **BUG-006** | Realisasi Target Panen Menampilkan 1 kg (0.5%) karena Mengambil `quantity` | High | ✅ RESOLVED | 20 Sep 2026 | `tests/Feature/API/SeasonApiTest.php` & Flutter unit test |

---

## 🔍 Detail Setiap Bug

### BUG-001: Sinkronisasi Kategori Biaya Produksi (Eliminasi Chart Artifact)
- **Komponen:** Frontend Flutter (`mobile_app/lib/screens/costs_screen.dart`).
- **Masalah:** Antarmuka Flutter menginisialisasi kategori non-resmi `'equipment'` dan `'transport'` ke dalam Map akumulasi progres bar, padahal backend dan database hanya mengakui 4 kategori resmi: Bibit (`seed`), Pupuk (`fertilizer`), Pestisida (`pesticide`), dan Lainnya (`other`).
- **Akar Masalah:** Sisa artefak kode chart lama yang tidak diselaraskan dengan enum database.
- **Perbaikan:** Menghapus kategori `equipment` dan `transport` dari Flutter, menggantinya dengan pemanggilan kategori `other` ("Lainnya"), serta menyesuaikan helper warna dan badge.
- **Verifikasi:** Test `test_cost_creation_accepts_all_official_categories` dan `test_cost_creation_rejects_legacy_chart_categories` PASS.

---

### BUG-002: Transisi Status Otomatis Musim Tanam & Cancelled-Awareness
- **Komponen:** Backend Laravel (`app/Models/Season.php`, `app/Services/SeasonService.php`, `app/Services/DashboardService.php`, `app/Http/Controllers/HarvestController.php`) & Flutter (`mobile_app/lib/screens/season_screen.dart`).
- **Masalah:** Musim tanam masa lampau tetap tercatat sebagai aktif jika tanggal selesai terlewat tanpa update manual di database, dan dashboard tetap menampilkan target dari musim tanam yang sudah berstatus `cancelled`.
- **Akar Masalah:** Status musim hanya dibaca statis dari kolom database tanpa evaluasi rentang tanggal aktif dan penanganan status dibatalkan.
- **Perbaikan:** Menambahkan method `computeStatus()` pada model `Season`, query aktif berbasis rentang tanggal `start_date <= today <= end_date` dan `status != 'cancelled'`, serta menambahkan accessor `computed_status` pada response API dan model Flutter.
- **Verifikasi:** Test `test_season_compute_status_unit_logic`, `test_season_api_includes_computed_status`, dan `test_dashboard_active_season_ignores_stale_and_cancelled_seasons` PASS.

---

### BUG-003: Undefined `$oldWeight` di `SaleService::updateSale()`
- **Komponen:** Backend Laravel (`app/Services/SaleService.php`).
- **Masalah:** Saat mengedit bobot penjualan, penyesuaian selisih stok gudang gagal secara silent dan memicu error runtime PHP 8.
- **Akar Masalah:** Variabel `$oldWeight` digunakan dalam closure `DB::transaction()` tetapi tidak pernah di-passing via `use()`.
- **Perbaikan:** Menangkap nilai `$oldWeight = $sale->weight_kg;` sebelum closure dan menyertakannya ke dalam scope `function () use ($sale, $dbData, $userId, $oldWeight)`.
- **Verifikasi:** UAT manual dan test skenario edit bobot penjualan memvalidasi saldo stok gudang terkoreksi secara presisi.

---

### BUG-004: Tooltip Grafik Dashboard Menampilkan Persen Rasio Semu
- **Komponen:** Frontend Flutter (`mobile_app/lib/widgets/harvest_chart.dart`).
- **Masalah:** Tooltip pada titik grafik menampilkan persentase `percent0(value, other)` yang menghitung rasio panen vs jual pada bulan yang sama. Ketika penjualan bernilai 0 di bulan panen, muncul tulisan `Penjualan: 0 kg (0.0%)` yang menyesatkan pengguna seolah-olah data penjualan gagal dimuat.
- **Akar Masalah:** Rumus persentase tidak memiliki makna bisnis yang relevan untuk perbandingan dua metrik independen.
- **Perbaikan:** Menghapus fungsi `percent0()` dan murni menampilkan nilai volume dinamis aktual bulan yang di-hover (misal: `Panen: 2.000 kg` dan `Penjualan: 0 kg`).
- **Verifikasi:** `flutter analyze` PASS dan inspeksi UI bersih.

---

### BUG-005: Kolom Total Panen di Layar Musim Tanam Bernilai 0 kg
- **Komponen:** Frontend Flutter (`mobile_app/lib/models/season.dart`).
- **Masalah:** Layar Musim Tanam menampilkan `Total Panen: 0 kg` meskipun panen 2.000 kg sudah dicatat pada musim tersebut.
- **Akar Masalah:** Backend mengirim hasil agregasi via `withSum('harvests', 'weight_kg')` dengan key bawaan Laravel `harvests_sum_weight_kg`, sementara model Flutter hanya membaca `total_harvest_kg`.
- **Perbaikan:** Memperbarui `Season.fromJson` agar membaca `(json['harvests_sum_weight_kg'] ?? json['total_harvest_kg'])`.
- **Verifikasi:** Test unit Flutter `Season.fromJson parses harvests_sum_weight_kg correctly` PASS.

---

### BUG-006: Target Panen Realisasi Menampilkan 1 kg (0.5%)
- **Komponen:** Frontend Flutter (`mobile_app/lib/screens/target_screen.dart`).
- **Masalah:** Realisasi target panen menampilkan `1 kg (0.5% Terpenuhi)` padahal hasil panen adalah 2.000 kg dari target 200 kg.
- **Akar Masalah:** Fungsi `_getActualForSeason()` menjumlahkan `h.quantity` (yang bernilai default `1` dari form panen) bukan `h.weightKg` (yang bernilai `2000.0`). Selain itu, persentase teks numerik terpotong 100% karena mengambil nilai clamped progress bar.
- **Perbaikan:** Menjumlahkan `h.weightKg` untuk seluruh harvest pada musim terkait, serta memisahkan *visual progress indicator* (`clamp(0.0, 1.0)`) dengan *true mathematical achievement percentage* (`(actual / target) * 100` -> `1000.0% Terpenuhi`).
- **Verifikasi:** Test `test_season_and_target_aggregate_multiple_harvests_correctly` di backend PASS (64/64) dan test unit Flutter PASS.
