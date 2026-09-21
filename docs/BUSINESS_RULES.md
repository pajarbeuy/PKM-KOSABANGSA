# Inventaris Aturan Bisnis Sistem (Business Rule Inventory)

**Proyek:** SumberTani berbasis AI (sebelumnya SIMHPSK) / PKM-Kosabangsa  
**Dokumen:** `docs/BUSINESS_RULES.md`  
**Status:** Canonical Reference & Verified against Active Codebase  
**Tanggal:** 21 September 2026  

---

## 📌 Daftar Isi
1. [Pendahuluan & Konsep Inti Domain](#1-pendahuluan--konsep-inti-domain)
2. [Domain 1: Musim Tanam (Season)](#2-domain-1-musim-tanam-season)
3. [Domain 2: Pencatatan Panen (Harvest)](#3-domain-2-pencatatan-panen-harvest)
4. [Domain 3: Manajemen Stok Gudang Hasil Panen (Stock & Inventory)](#4-domain-3-manajemen-stok-gudang-hasil-panen-stock--inventory)
5. [Domain 4: Manajemen Produk Olahan (Processed Product)](#5-domain-4-manajemen-produk-olahan-processed-product)
6. [Domain 5: Pemasaran, Katalog Publik & Pemesanan WhatsApp](#6-domain-5-pemasaran-katalog-publik--pemesanan-whatsapp)
7. [Domain 6: Sentralisasi Penjualan (Centralized Sales)](#7-domain-6-sentralisasi-penjualan-centralized-sales)
8. [Domain 7: Biaya Produksi (Production Cost)](#8-domain-7-biaya-produksi-production-cost)
9. [Domain 8: Laporan Keuangan, Laba Rugi & Realisasi Target](#9-domain-8-laporan-keuangan-laba-rugi--realisasi-target)
10. [Domain 9: Asisten Operasional TaniBot AI (Super Admin)](#10-domain-9-asisten-operasional-tanibot-ai-super-admin)
11. [Cross-Module Invariants & Integritas Sistem](#11-cross-module-invariants--integritas-sistem)
12. [Aturan Keamanan, Otorisasi, & Multi-Tenancy](#12-aturan-keamanan-otorisasi--multi-tenancy)

---

## 1. Pendahuluan & Konsep Inti Domain

Sistem **SumberTani berbasis AI** mengelola alur operasional agribisnis hulu ke hilir: mulai dari perencanaan masa tanam, pemantauan modal, pencatatan hasil panen mentah, pembuatan produk olahan bernilai tambah, pemasaran katalog publik, hingga pemrosesan penjualan terpusat oleh Super Admin.

### Alur Keterhubungan Entitas (Business Flow Pipeline)
```text
Perencanaan Musim (Season)
   │
   ├─► Pencatatan Biaya Produksi (Production Cost) ──► Total Pengeluaran
   │
   └─► Pencatatan Panen (Harvest) 
          │
          ▼ (Otomatis menambah stok: in)
       Saldo Stok Gudang (Stock Balance)
          │
          ▼ (Otomatis mengurangi stok: out)
       Pencatatan Penjualan (Sales) ──► Total Pendapatan
                                               │
                                               ▼
             Laporan Laba Rugi = Pendapatan - Pengeluaran
```

---

## 2. Domain 1: Musim Tanam (Season)

Entitas `Season` merepresentasikan siklus periode bercocok tanam dari masa persiapan bibit hingga selesai panen.

### 2.1 Definisi Skema & Atribut
- **Model:** `App\Models\Season`
- **Tabel:** `seasons`
- **Atribut:**
  - `id` (bigint, PK, autoincrement)
  - `user_id` (bigint, FK -> `users.id`, non-nullable)
  - `name` (string, max 255, required)
  - `start_date` (date, required)
  - `end_date` (date, required, must be `after:start_date`)
  - `status` (enum: `active`, `completed`, `cancelled`, default: `active`)
  - `target_kg` (decimal:2 / numeric, required, min: 0)
  - `created_at`, `updated_at`, `deleted_at` (SoftDeletes)

### 2.2 Aturan Validasi Input
1. **Nama:** Wajib diisi, string, maksimal 255 karakter.
2. **Tanggal:**
   - `start_date`: Wajib format tanggal valid (`Y-m-d`).
   - `end_date`: Wajib format tanggal valid dan secara mutlak harus lebih besar dari `start_date` (`after:start_date`).
3. **Target Panen:** Wajib numerik, nilai minimum `0` (tidak boleh negatif).
4. **Status Input:** Wajib salah satu dari: `active`, `completed`, `cancelled`.

### 2.3 Perhitungan Status Dinamis (`computed_status`)
Untuk mengatasi musim kedaluwarsa tanpa merusak hak pembatalan manual oleh pengguna, sistem menerapkan hierarki logika:
1. **Status Dibatalkan (`cancelled`):**
   - Merupakan aksi bisnis manual yang disengaja (*persistent override*).
   - Jika kolom database bernilai `cancelled`, sistem **selalu mengembalikan `cancelled`**, terlepas dari rentang tanggal.
2. **Status Berbasis Tanggal Kalender (Jika status DB bukan `cancelled`):**
   - **`belum_dimulai`**: Jika tanggal hari ini (`today()`) secara kalender **kurang dari** `start_date` (`today < start_date`).
   - **`active`**: Jika tanggal hari ini berada dalam rentang `start_date` hingga `end_date` (`start_date <= today <= end_date`).
     - *Boundary Rule*: Hari pertama (`today == start_date`) dan hari terakhir (`today == end_date`) dihitung berstatus **`active`**.
   - **`completed`**: Jika tanggal hari ini telah melewati `end_date` (`today > end_date`).
3. **Penyajian API & UI:**
   - Field `computed_status` diserialisasi otomatis melalui `$appends = ['computed_status']` dan method `computeStatus()`.
   - UI menampilkan badge:
     - `active` → Hijau ("Aktif")
     - `completed` → Biru ("Selesai")
     - `belum_dimulai` → Kuning/Amber ("Belum Dimulai")
     - `cancelled` → Merah ("Dibatalkan")

### 2.4 Query Musim Aktif Berjalan (Active Season Query)
Pada `DashboardService` dan `HarvestController`, musim aktif ditentukan bukan dari kolom status mentah, melainkan dari query rentang tanggal kalender aktif:
```php
Season::where('user_id', $userId)
    ->where('status', '!=', 'cancelled')
    ->whereDate('start_date', '<=', today())
    ->whereDate('end_date', '>=', today())
    ->latest('start_date')
    ->first();
```
- **Tie-breaker**: Jika terdapat lebih dari satu musim yang mencakup hari ini, musim dengan tanggal `start_date` terbaru yang dipilih secara deterministik.

### 2.5 Aturan Siklus Hidup & Relasi
- Musim dapat memiliki banyak panen (`harvests`) dan biaya produksi (`costs`).
- Menghapus musim menggunakan mekanisme *Soft Deletes* (`deleted_at`), menjaga integritas riwayat panen dan penjualan terdahulu.

---

## 3. Domain 2: Pencatatan Panen (Harvest)

Entitas `Harvest` mencatat kuantitas hasil tani yang dipetik dari lahan pada tanggal tertentu.

### 3.1 Definisi Skema & Atribut
- **Model:** `App\Models\Harvest`
- **Tabel:** `harvests`
- **Atribut:**
  - `id` (bigint, PK, autoincrement)
  - `user_id` (bigint, FK -> `users.id`, non-nullable)
  - `season_id` (bigint, FK -> `seasons.id`, non-nullable)
  - `date` / `harvest_date` (date, default: `now()`)
  - `weight_kg` (decimal:2, required, min: 0.01)
  - `quantity` (decimal/numeric, opsional)
  - `status` (enum: `recorded`, `verified`, `cancelled`, default: `recorded`)
  - `notes` (text, opsional)
  - `photo` (string path gambar, opsional)
  - `created_at`, `updated_at`, `deleted_at` (SoftDeletes)

### 3.2 Aturan Validasi Input
1. **Kepemilikan Musim (`verifySeasonOwnership`):**
   - `season_id` wajib ada di tabel `seasons` dan **harus dimiliki oleh user yang bersangkutan** (`user_id = auth()->id()`).
   - Percobaan menautkan panen ke musim petani lain menghasilkan respon HTTP 403 Forbidden.
2. **Bobot Panen (`weight_kg`):**
   - Wajib bernilai numerik dan lebih besar dari 0 (`min:0.01`).
   - Mendukung presisi pecahan desimal (contoh: `150.75` kg).

### 3.3 Sinkronisasi Otomatis dengan Stok Gudang
Operasi panen terikat secara atomik (*atomic transaction*) dengan saldo stok gudang:
1. **Saat Panen Dibuat (`createHarvest`):**
   - Dibungkus dalam `DB::transaction`.
   - Menghasilkan mutasi stok masuk (`StockTransaction::addTransaction('in', weight_kg, 'Panen masuk', 'harvest_{id}', userId)`).
2. **Saat Panen Diperbarui (`updateHarvest`):**
   - Jika `weight_kg` berubah dari bobot lama ($W_{lama}$) ke bobot baru ($W_{baru}$):
     - Dihitung selisih: $\Delta W = W_{baru} - W_{lama}$.
     - Jika $\Delta W > 0$: dicatat mutasi masuk (`in`) sebesar $\Delta W$.
     - Jika $\Delta W < 0$: dicatat mutasi keluar (`out`) sebesar $|\Delta W|$.
3. **Saat Panen Dihapus (`deleteHarvest`):**
   - Dibungkus dalam `DB::transaction`.
   - Mengurangi stok kembali melalui mutasi keluar (`out`) sebesar $\min(W_{harvest}, \text{Saldo Saat Ini})$.
   - Record panen dihapus secara *soft delete*.

---

## 4. Domain 3: Manajemen Stok Gudang (Stock & Inventory)

Entitas `StockTransaction` mencatat buku besar (*ledger*) mutasi keluar masuk komoditas di gudang secara kronologis.

### 4.1 Definisi Skema & Atribut
- **Model:** `App\Models\StockTransaction`
- **Tabel:** `stock_transactions`
- **Atribut:**
  - `id` (bigint, PK, autoincrement)
  - `user_id` (bigint, FK -> `users.id`, non-nullable)
  - `type` (enum: `in`, `out`)
  - `amount` (decimal:2, strictly positive)
  - `balance_after` (decimal:2, saldo kumulatif setelah transaksi)
  - `reference` (string, referensi dokumen e.g. `harvest_1`, `sale_2`, `manual`)
  - `notes` (text, catatan mutasi)
  - `date` (datetime, timestamp waktu mutasi)
  - `created_at`, `updated_at`, `deleted_at`

### 4.2 Aturan Perhitungan Saldo (Balance Calculation)
1. **Formula Invariant:**
   $$\text{Current Balance} = \text{Saldo Awal} + \sum \text{Amount}_{in} - \sum \text{Amount}_{out}$$
2. **Pencegahan Race Condition:**
   - Saldo terkini diambil dengan pemecah *tie-break* ID:
     ```php
     $latest = StockTransaction::where('user_id', $userId)
         ->orderByDesc('date')
         ->orderByDesc('id')
         ->first();
     return (float) ($latest?->balance_after ?? 0);
     ```
3. **Penyimpanan Mutasi Baru:**
   - Transaksi `in`: $\text{Balance Baru} = \text{Balance Lama} + \text{Amount}$
   - Transaksi `out`: $\text{Balance Baru} = \text{Balance Lama} - \text{Amount}$
   - Nilai $\text{Balance Baru}$ langsung disimpan pada kolom `balance_after`.

### 4.3 Ambang Batas Stok & Notifikasi Otomatis
- **Batas Minimum (`min_stock`):** Nilai default 100 kg (dikonfigurasi via `Setting`).
  - Ketika mutasi keluar menyebabkan saldo melintasi batas minimum dari atas ($\text{Old} > \text{Min}$ dan $\text{New} \le \text{Min}$), sistem otomatis memicu notifikasi `low_stock`.
- **Batas Maksimum (`max_stock`):** Nilai default 5.000 kg.
  - Ketika mutasi masuk menyebabkan saldo mencapai/melebihi kapasitas ($\text{Old} < \text{Max}$ dan $\text{New} \ge \text{Max}$), sistem memicu notifikasi `high_stock`.

---

## 4. Domain 3: Manajemen Stok Gudang Hasil Panen (Stock & Inventory)
<!-- existing content for harvest stock remains intact -->

---

## 5. Domain 4: Manajemen Produk Olahan (Processed Product)

Entitas `ProcessedProduct` merepresentasikan produk olahan turunan hasil tani (misal: Jamur Crispy, Keripik Kentang, Olahan Sayur) yang diproduksi dan dimiliki oleh Petani untuk dipasarkan melalui platform.

### 5.1 Definisi Skema & Atribut
- **Model:** `App\Models\ProcessedProduct`
- **Tabel:** `processed_products`
- **Atribut:**
  - `id` (bigint, PK, autoincrement)
  - `owner_id` (bigint, FK -> `users.id`, non-nullable, `onDelete('restrict')`)
  - `name` (string:255, required)
  - `price` (decimal:12,2, required, min: 0)
  - `stock` (integer, unsigned, default: 0)
  - `description` (text, opsional)
  - `photo` (string:255, opsional)
  - `status` (enum: `active`, `out_of_stock`, `inactive`, default: `out_of_stock`)
  - `created_at`, `updated_at`, `deleted_at` (SoftDeletes)

### 5.2 Kepemilikan & Single Source of Truth
1. **Kepemilikan Mutlak:** Setiap produk olahan terikat pada petani pembuatnya (`owner_id = Petani`). Petani hanya dapat melihat, menambah, mengubah, dan menghapus produk miliknya sendiri (multi-tenant isolation).
2. **Single Source of Truth Saldo Stok:** Kolom `processed_products.stock` adalah satu-satunya saldo aktual stok produk olahan. Super Admin tidak memiliki stok duplikat terpisah. `StockTransaction` murni berfungsi sebagai histori/audit trail mutasi.

### 5.3 Aturan Transisi Status (State Machine)
1. **Transisi Otomatis:**
   - Produk berstatus `active` yang stoknya berkurang hingga $0$ otomatis bertransisi menjadi `out_of_stock`.
   - Produk berstatus `out_of_stock` yang ditambah stoknya ($> 0$) otomatis bertransisi kembali menjadi `active`.
2. **Preservasi Status Manual (`inactive`):**
   - Status `inactive` adalah keputusan manual Petani/Admin untuk menarik produk dari peredaran.
   - Penambahan stok pada produk `inactive` **tidak boleh** mengubah statusnya menjadi `active` secara otomatis (tetap `inactive` hingga diaktifkan secara manual oleh pengguna).

---

## 6. Domain 5: Manajemen Pesanan & Katalog Publik (Order & Purchasing Pipeline)

### 6.1 Skema & Struktur Entitas Pesanan (Order & OrderItem)
Untuk membedakan niat pembelian pelanggan dengan transaksi penjualan riil yang telah selesai, sistem menyediakan domain `Order`:
- **Model:** `App\Models\Order` & `App\Models\OrderItem`
- **Tabel:** `orders` & `order_items`
- **Atribut `orders`:**
  - `id` (bigint PK)
  - `order_code` (string:50, unique, indexed — format: `ORD-YYYYMMDD-XXXX`)
  - `customer_name` (string:255, required)
  - `customer_phone` (string:50, required)
  - `customer_address` (text, opsional)
  - `status` (enum: `pending`, `confirmed`, `processing`, `completed`, `cancelled`, default: `pending`)
  - `total_amount` (decimal:12,2)
  - `notes` (text, opsional)
  - Timestamps & SoftDeletes
- **Atribut `order_items`:**
  - `id` (bigint PK)
  - `order_id` (foreignId -> `orders.id`, cascadeOnDelete)
  - `processed_product_id` (foreignId -> `processed_products.id`)
  - `quantity` (integer, unsigned, min: 1)
  - `price_snapshot` (decimal:12,2, mandatory)
  - `subtotal` (decimal:12,2)
  - Timestamps

### 6.2 Price Snapshot (Kekekalan Riwayat Harga)
- Pada saat pesanan dibuat (`createPublicOrder`), harga produk saat itu dikunci di kolom `order_items.price_snapshot`.
- Perubahan harga produk di masa mendatang tidak boleh mengubah harga atau subtotal pada pesanan yang sudah tercatat.

### 6.3 Siklus Hidup Pesanan (Order State Machine)
- `pending`: Pelanggan baru mengajukan pesanan via katalog publik. Stok **TIDAK BERKURANG**.
- `confirmed`: Super Admin mengonfirmasi ketersediaan dan detail pesanan. Stok **TIDAK BERKURANG**.
- `processing`: Super Admin / Mitra sedang menyiapkan barang pesanan. Stok **TIDAK BERKURANG**.
- `completed`: Transaksi benar-benar selesai. **Hanya pada status ini stok berkurang, Sale tercatat, dan StockTransaction dibukukan**.
- `cancelled`: Pesanan dibatalkan (hanya diizinkan bila belum `completed`). Stok **TIDAK BERUBAH**.
- **Aturan Transisi Ilegal:** Pesanan `completed` atau `cancelled` bersifat terminal dan tidak boleh diubah ke status lain. `PATCH /status` secara tegas menolak nilai `completed`.

### 6.4 Pemisahan Tanggung Jawab (Separation of Concerns)
- **`OrderService`**: Mengelola siklus hidup pesanan (`createPublicOrder`, `updateStatus`, `cancelOrder`, format data). Tidak memotong stok secara langsung.
- **`SaleService`**: Mengelola transaksi penjualan (`Sale`). Satu-satunya yang berhak memicu pemotongan stok melalui `ProcessedProductService` dan membukukan `StockTransaction`.
- **`ProcessedProductService`**: Satu-satunya domain service yang memutasi `processed_products.stock`.
- **`StockTransaction`**: Mencatat log audit mutasi persediaan.

### 6.5 Idempotency Guard (Pencegahan Double Sale)
- Relasi 1-to-1 dibentuk melalui `sales.order_id`.
- Pemanggilan endpoint `/orders/{id}/complete` dilindungi guard: jika pesanan sudah `completed` atau telah memiliki relasi `Sale`, sistem menolak permintaan ulang (HTTP 422) untuk mencegah penjualan duplikat dan pemotongan stok ganda.

### 6.6 Katalog Publik & Tautan WhatsApp
- Calon pembeli mengisi formulir pemesanan cepat pada modal katalog landing page.
- Saat formulir disubmit, sistem mencatat `Order` berstatus `pending` (`POST /api/catalog/orders`) dan membuka WhatsApp Super Admin dengan pesan resmi berformat rapi memuat Kode Pesanan, rincian produk, kuantitas, harga, dan data pemesan.
- **Klik WhatsApp ≠ Order, Order ≠ Sale.** Membuka WhatsApp tidak memotong stok sama sekali.

### 6.7 Perlindungan Privasi pada Pelacakan Publik (Privacy Guard)
- Endpoint pelacakan publik `GET /api/catalog/orders/{order_code}` **wajib menyamarkan (masking) data pribadi pembeli**:
  - Nama: disamarkan (misal `Budi S****`)
  - No. HP: disamarkan (misal `0812****7890`)
  - Alamat: disamarkan (`Alamat terlindungi untuk privasi pelanggan`)
  - Hanya menampilkan progres status, rincian item, dan total biaya.

---

## 7. Domain 6: Sentralisasi Penjualan (Centralized Sales)

Seluruh aktivitas transaksi penjualan komoditas dan produk olahan dipusatkan dan dikelola secara eksklusif oleh **Super Admin**.

### 7.1 Aturan Otorisasi
- Petani **dilarang keras** mencatat atau mengubah transaksi penjualan (Akses rute `/api/sales` menghasilkan HTTP 403 Forbidden bagi Petani).
- Super Admin mencatat penjualan berdasarkan realisasi pesanan yang masuk.

### 7.2 Pemotongan Stok Atomik
- Ketika Super Admin mencatat penjualan produk olahan, stok produk pada akun Petani pemilik berkurang secara atomik di dalam `DB::transaction`.
- Validasi stok: jika kuantitas penjualan melebihi sisa stok (`quantity > stock`), request ditolak dengan HTTP 422 Unprocessable Entity.

---

## 8. Domain 7: Biaya Produksi (Production Cost)

Entitas `ProductionCost` mencatat seluruh pengeluaran operasional budidaya pertanian.

### 8.1 Definisi Skema & Atribut
- **Model:** `App\Models\ProductionCost`
- **Tabel:** `production_costs`
- **Atribut:**
  - `id` (bigint, PK, autoincrement)
  - `user_id` (bigint, FK -> `users.id`, non-nullable)
  - `season_id` (bigint, FK -> `seasons.id`, nullable)
  - `date` (date, required)
  - `category` (enum: `seed`, `fertilizer`, `pesticide`, `other`, required)
  - `amount` (decimal:2, required, min: 0.01)
  - `notes` (text, opsional)
  - `created_at`, `updated_at`, `deleted_at` (SoftDeletes)

### 8.2 Standar Resmi Kategori Biaya (Official Categories)
Hanya ada **4 kategori biaya resmi** di seluruh ekosistem backend dan mobile client:
| Kategori Kode | Label Indonesia | Kode Warna UI | Keterangan |
|---|---|---|---|
| `seed` | Bibit | `#166534` (Hijau Tua) | Pengadaan benih / bibit komoditas |
| `fertilizer` | Pupuk | `#22C55E` (Hijau) | Pembelian pupuk organik / anorganik |
| `pesticide` | Pestisida | `#DC2626` (Merah) | Obat pengendali hama dan penyakit |
| `other` | Lainnya | `#6B7280` (Abu-abu Slate) | Sewa alat, tenaga kerja, bensin, dll. |

### 8.3 Aturan Agregasi & Konsistensi Breakdown
- **Total Pengeluaran:**
  $$\text{Total Cost} = \sum \text{amount}$$
- **Breakdown Kategori:**
  $$\text{Total Cost} = \text{Cost}_{seed} + \text{Cost}_{fertilizer} + \text{Cost}_{pesticide} + \text{Cost}_{other}$$
- Setiap pengeluaran bertipe `other` wajib terakumulasi ke dalam diagram batang "Lainnya" tanpa terlewat.

---

## 9. Domain 8: Laporan Keuangan, Laba Rugi & Realisasi Target

### 9.1 Laporan Laba / Rugi Petani (Farmer Profit & Loss)
- **Model / Service:** `ReportService::getProfitLoss($userId, $seasonId)`
- **Formula:**
  $$\text{Total Revenue} = \sum \text{Sale.total}$$
  $$\text{Total Cost} = \sum \text{ProductionCost.amount}$$
  $$\text{Profit / Loss} = \text{Total Revenue} - \text{Total Cost}$$
- **Filter Musim:**
  - Jika parameter `season_id` diberikan, query pendapatan dan biaya dibatasi hanya pada transaksi yang terkait dengan musim tersebut.
  - Jika tidak ada parameter `season_id`, kalkulasi mencakup seluruh data pengguna aktif secara menyeluruh (*all seasons*).

### 9.2 Laba / Rugi Agregat Super Admin (Aggregate Farmer Profit & Loss)
- **Endpoint:** `GET /api/super-admin/reports/farmer-profit-loss-aggregate`
- **Formula:**
  $$\text{Aggregate Profit/Loss} = \sum_{f \in \text{Farmers}} \text{ProfitLoss}(f)$$
- **Aturan Integritas:**
  - Merupakan representasi performa ekonomi petani binaan, bukan pendapatan/laba pribadi Super Admin.
  - Dilarang keras terjadi perhitungan ganda (*double-counting*).

### 9.3 Laporan Target vs Realisasi (Target vs Actual)
- **Model / Service:** `ReportService::getTargetVsActual($userId)`
- **Formula:**
  - $\text{Actual Harvest} = \sum \text{Harvest.weight\_kg}$ (dihitung per musim via `withSum('harvests', 'weight_kg')`).
  - $\text{Target Harvest} = \text{Season.target\_kg}$.
  - $\text{Percentage} = \left(\frac{\text{Actual Harvest}}{\text{Target Harvest}}\right) \times 100\%$.
- **Status Evaluasi:**
  - $\text{Percentage} \ge 100\%$ → Status: `success` ("Tercapai").
  - $70\% \le \text{Percentage} < 100\%$ → Status: `warning` ("Hampir").
  - $\text{Percentage} < 70\%$ → Status: `danger` ("Kurang").

---

## 10. Domain 9: Asisten Operasional TaniBot AI (Super Admin)

Layanan kecerdasan buatan interaktif diposisikan sebagai asisten operasional bagi Super Admin dalam mengelola ekosistem SumberTani berbasis AI.

### 10.1 Hak Akses & Keamanan
- Endpoint chat (`POST /api/super-admin/chat`) dilindungi secara ketat oleh middleware `auth:sanctum` dan `role:super_admin`.
- Akses dari pengguna non-super-admin (termasuk Petani) atau unauthenticated ditolak dengan status HTTP 403 / 401.

### 10.2 Ruang Lingkup Knowledge Base
- Memberikan rekapitulasi data kelompok tani binaan.
- Memberikan panduan dan rekomendasi strategi pemasaran produk olahan.
- Membantu pemantauan anomali stok gudang dan tindak lanjut transaksi WhatsApp.

---

## 11. Cross-Module Invariants & Integritas Sistem

Sistem menjamin 7 hukum invarian yang tidak boleh dilanggar oleh operasi apapun:

### Invarian 1: Keseimbangan Stok Fisik Panen Mentah
$$\text{Current Harvest Stock} = \sum_{\text{all in}} \text{Amount} - \sum_{\text{all out}} \text{Amount} \ge 0$$
- Stok gudang hasil panen tidak boleh bernilai minus.

### Invarian 2: Keseimbangan Kategori Biaya
$$\text{Total Cost} = \sum_{c \in \{\text{seed, fertilizer, pesticide, other}\}} \text{CategoryCost}(c)$$

### Invarian 3: Konsistensi Laba Bersih
$$\text{Estimated Profit (Dashboard)} = \text{Profit (Laporan Laba Rugi)}$$

### Invarian 4: Isolasi Musim Kedaluwarsa & Dibatalkan
- Musim yang telah melewati tanggal selesai (`today > end_date`) atau berstatus `cancelled` **tidak boleh** terpilih sebagai `active_season`.

### Invarian 5: Atomisitas Mutasi Transaksi
- Seluruh mutasi ganda wajib dibungkus dalam `DB::transaction`.

### Invarian 6: Single Source of Truth Stok Produk Olahan
$$\text{Available Stock} = \text{ProcessedProduct.stock} \ge 0$$
- Super Admin tidak memiliki tabel stok duplikat untuk produk olahan. Stok dipotong langsung dari saldo produk petani pemilik saat penjualan dikonfirmasi.

### Invarian 7: Pemisahan Order Intent vs Pengurangan Stok
- Membuka tautan WhatsApp pesanan berstatus *order request intent* dan tidak mengurangi stok produk olahan. Pengurangan stok murni terjadi saat penjualan dicatat di sistem.

---

## 12. Aturan Keamanan, Otorisasi, & Multi-Tenancy

### 12.1 Isolasi Multi-Tenancy
- Setiap data operasional terikat pada `user_id` / `owner_id`.
- Akses atau manipulasi lintas pengguna tanpa otorisasi ditolak dengan **HTTP 403 Forbidden**.

### 12.2 Otorisasi Role Pengguna
- **Role `user` / `admin` (Petani):** Mengelola operasional kebun (musim, panen, biaya, produk olahan miliknya). Dilarang mengakses fitur penjualan terpusat dan chatbot operasional.
- **Role `super_admin`:** Mengelola pengguna, menyetujui akun, memantau manajemen pemasaran produk olahan, memproses penjualan, meninjau laba/rugi agregat petani, dan berkonsultasi via TaniBot AI operasional.

### 12.3 Keamanan Otentikasi & Reset Password
- Token API menggunakan Laravel Sanctum Bearer Token.
- Endpoint reset password menerapkan pencegahan *email enumeration*.
- Token reset password kedaluwarsa atau reuse ditolak tegas dengan HTTP 400.

