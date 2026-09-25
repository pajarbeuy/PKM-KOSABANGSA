# Walkthrough — Phase 5: Historical Market Price & Snapshotting

## 1. Executive Summary
Phase 5 mengimplementasikan sistem **Harga Pasar Acuan Historis (Historical Market Price)** dan **Snapshotting Otomatis Panen** pada platform **SumberTani berbasis AI**.

Tujuan utama dari fase ini adalah:
1. Menghubungkan komoditas hasil tani dengan harga acuan pasar pada tanggal efektif tertentu (`effective_date`).
2. Melakukan snapshotting harga pasar acuan secara otomatis saat panen dicatat (`effective_date <= harvest_date` terbaru).
3. Menjamin **immutability** snapshot: perubahan master harga pasar di masa depan tidak akan mengubah snapshot harga pada catatan panen lama.
4. Menerapkan proteksi integritas referensi: master harga pasar yang telah dirujuk oleh panen historis dilarang dihapus (`ON DELETE RESTRICT`) atau diubah nominal harganya.
5. Menegaskan larangan *cascade-delete* komoditas terhadap histori harga pasar acuan.
6. Memisahkan secara tegas konsep:
   - **Harga Panen** (Gross Harvest Value = $weight \times snapshot$) sebagai estimasi pendapatan kotor hasil bumi.
   - **Harga Transaksi Riil** (Order produk olahan via katalog & Penjualan langsung via harga per kg saat transaksi).
7. Memastikan aksesibilitas peran: Petani bersifat **READ-ONLY**, sedangkan pengelolaan master harga pasar dan pemicu sinkronisasi (*ingestion*) dibatasi ketat hanya untuk **Super Admin**.

---

## 2. Arsitektur & Alur Data

```mermaid
flowchart TD
    subgraph Market Price Ingestion
        Provider[MockMarketPriceProvider] --> Ingestion[MarketPriceIngestionService]
        Ingestion -->|Safe Mutation Rules| MPTable[(market_prices)]
        Admin[Super Admin] -->|Manual CRUD| MPController[MarketPriceController]
        MPController --> MPTable
    end

    subgraph Harvest Snapshotting Flow
        Petani[Petani] -->|POST /api/harvests| HService[HarvestService]
        HService -->|Lookup effective_date <= harvest_date| MPService[MarketPriceService]
        MPService -->|Ambil Harga Terkini Efektif| MPTable
        MPService -->|Return Snapshot & ID| HService
        HService -->|Kunci Snapshot & Gross Value| HTable[(harvests)]
    end

    subgraph Transaction Pipeline (No Duplication)
        Buyer[Customer] -->|Beli Produk Olahan| Catalog[Katalog Produk Olahan]
        Catalog -->|price_snapshot katalog| OrderItems[(order_items)]
        RawBuyer[Pembeli Mentah] -->|Beli Hasil Tani| SaleService[SaleService]
        SaleService -->|price_per_kg pada tanggal transaksi| Sales[(sales)]
    end
```

---

## 3. Komponen Backend yang Diimplementasikan

### A. Database Migrations
1. **`market_prices` Table**:
   - `commodity_id` foreign key ke `farmer_commodities` dengan **`ON DELETE RESTRICT`**. Menghapus komoditas yang memiliki histori harga pasar akan ditolak langsung oleh database.
   - `price` bertipe `DECIMAL(12, 2)`.
   - `effective_date` bertipe `DATE`.
   - `UNIQUE KEY uk_commodity_effective (commodity_id, effective_date)`: single source of truth yang deterministik.
2. **`harvests` Table Enhancements**:
   - `market_price_id` foreign key ke `market_prices` (`ON DELETE SET NULL`).
   - `market_price_snapshot` bertipe `DECIMAL(12, 2)`.
   - `market_price_effective_date` bertipe `DATE`.

### B. Ingestion Service & Safe Mutation Matrix
File: `app/Services/MarketPriceIngestionService.php`
- `same price` $\rightarrow$ **no-op** (idempoten, tidak melakukan write berlebih).
- `different price + unreferenced` $\rightarrow$ **update** (mengupdate harga dan metadata karena belum dirujuk panen).
- `different price + referenced` $\rightarrow$ **reject** (menolak mutasi demi integritas audit panen historis).
- Artisan command: `php artisan market-price:ingest [--date=YYYY-MM-DD] [--provider=mock]`.

### C. Harvest Snapshotting Integration
File: `app/Services/HarvestService.php`
- Saat panen dicatat via `createHarvest`, sistem mencari harga acuan pasar efektif dengan aturan: `commodity_id == $commId AND effective_date <= $harvestDate ORDER BY effective_date DESC LIMIT 1`.
- Jika ditemukan, `market_price_id`, `market_price_snapshot`, dan `market_price_effective_date` dikunci permanen.
- `formatHarvest` menghitung:
  $$\text{gross\_harvest\_value} = \text{weight\_kg} \times \text{market\_price\_snapshot}$$
- Saat `updateHarvest`, snapshot lama dipertahankan secara konsisten kecuali komoditas atau tanggal panen diubah.

### D. REST API Endpoints & Role Authorization
File: `app/Http/Controllers/Api/MarketPriceController.php`
- `GET /api/market-prices`: Terbuka untuk Petani & Super Admin (Read-Only).
- `GET /api/market-prices/latest/{commodity_id}`: Harga aktif terkini untuk komoditas.
- `POST /api/market-prices`: Dibatasi middleware `role:super_admin` (HTTP 403 untuk Petani).
- `PUT /api/market-prices/{id}`: Dibatasi `role:super_admin` + guard jika `isReferenced() == true` nominal harga tidak dapat diubah (HTTP 422).
- `DELETE /api/market-prices/{id}`: Dibatasi `role:super_admin` + guard jika `isReferenced() == true` penghapusan ditolak (HTTP 422).
- `POST /api/market-prices/ingest`: Trigger sinkronisasi feed harga (Super Admin only).

---

## 4. Hasil Pengujian Backend (PHPUnit)

File Test: `tests/Feature/API/MarketPriceTest.php`

| # | Test Scenario | Hasil |
|---|---|:---:|
| 1 | `test_super_admin_can_create_market_price` | **PASSED** |
| 2 | `test_ingestion_safe_mutation_rules` (same $\rightarrow$ no-op, diff+unreferenced $\rightarrow$ update, diff+referenced $\rightarrow$ reject) | **PASSED** |
| 3 | `test_farmer_is_forbidden_from_managing_market_prices` (Role Guard 403) | **PASSED** |
| 4 | `test_mock_market_price_provider_contract_and_command` (DTO array contract & artisan command) | **PASSED** |
| 5 | `test_harvest_automatically_snapshots_effective_market_price` (Snapshot lookup & Gross Harvest Value) | **PASSED** |
| 6 | `test_harvest_snapshot_remains_immutable_when_new_market_prices_are_added` | **PASSED** |
| 7 | `test_referenced_market_price_cannot_be_deleted` (HTTP 422 guard) | **PASSED** |
| 8 | `test_referenced_market_price_nominal_cannot_be_updated` (HTTP 422 guard & safe notes update) | **PASSED** |
| 9 | `test_commodity_cannot_be_deleted_if_it_has_market_prices_history` (ON DELETE RESTRICT & Domain guard) | **PASSED** |
| 10 | `test_date_separation_between_harvest_snapshot_and_transaction_date` | **PASSED** |
| 11 | `test_processed_product_order_uses_catalog_snapshot_without_market_price_interference` | **PASSED** |

**Total Phase 5 Tests**: 11/11 Passed (69 Assertions)  
**Total API Regression Suite**: 151/151 Passed (663 Assertions)

---

## 5. Implementasi Frontend Flutter

1. **Model `mobile_app/lib/models/market_price.dart`**:
   - Representasi entitas harga pasar acuan lengkap dengan parsing JSON, helper `isReferenced`.
2. **Model `mobile_app/lib/models/harvest.dart`**:
   - Ditambahkan atribut `marketPriceId`, `marketPriceSnapshot`, `marketPriceEffectiveDate`, `grossHarvestValue`, dan getter `calculatedGrossValue`.
3. **Service `mobile_app/lib/services/api/market_price_api_service.dart` & `api_service.dart`**:
   - Facade methods untuk mengambil daftar harga, harga terkini, CRUD, serta trigger sinkronisasi provider.
4. **Screen `mobile_app/lib/screens/market_price_screen.dart`**:
   - Tampilan responsif dengan estetika modern SumberTani.
   - Petani: Daftar harga acuan per komoditas, riwayat tanggal efektif, dan status keterikatan snapshot panen.
   - Super Admin: Tombol `Sync Provider`, Floating Action Button `+ Tambah Acuan`, form modal dialog dengan proteksi field terkunci untuk record yang sudah dirujuk panen.
5. **Pembaruan Layar Panen `mobile_app/lib/screens/harvest_screen.dart`**:
   - Mobile card: Menampilkan badge harga acuan `@ Rp15.000/kg (Pasar)` dan `Gross: Rp 1.500.000`.
   - Desktop table: Kolom `BERAT & NILAI PASAR` menampilkan rincian berat, snapshot harga acuan pasar, dan taksiran pendapatan kotor panen (*Gross Harvest Value*).
6. **Integrasi Navigasi `mobile_app/lib/utils/navigation_helper.dart`**:
   - Menu `Harga Acuan Pasar` aktif di sidebar Super Admin.
   - Menu `Harga Acuan` aktif di sidebar Petani.
7. **Flutter Analysis**:
   - Menjalankan `flutter analyze` $\rightarrow$ **0 issues found!**

---

## 6. Definition of Done Alignment
Pada dokumen `docs/Implementation Plan v2 — SumberTani berbasis AI.md` bagian 36:
- [x] Harga memiliki tanggal berlaku.
- [x] Harga yang digunakan mengikuti tanggal panen.
- [x] Historical price tidak berubah setelah master price diperbarui.
- [x] Price snapshot tersedia.
