# Implementation Plan Phase 5 — Historical Market Price & Snapshot (Locked v5 - Final)

## 1. Pendahuluan & Prinsip Arsitektur Harga

Sistem SumberTani membedakan secara tegas antara **Master Harga Pasar Acuan**, **Snapshot Evaluasi Ekonomi Panen (Gross Harvest Value)**, dan **Harga Transaksi Penjualan Riil**:

```text
                        ┌──────────────────────────────────────┐
                        │ MarketPriceProviderInterface (Mock)  │
                        │ (Development/Testing - Bukan API Nyata)
                        └──────────────────┬───────────────────┘
                                           │
                                           ▼
                       ┌───────────────────────────────────────┐
                       │      MarketPriceIngestionService      │
                       │   (Safe Mutation / Protected Ingest)  │
                       └──────────────────┬────────────────────┘
                                          │
                                          ▼
                             [ Master Market Prices ]
                    (commodity_id, effective_date, price, source)
                    *UNIQUE (commodity_id, effective_date)*
                                          │
                     ┌────────────────────┴────────────────────┐
                     ▼                                         ▼
           [ 1. Tanggal Panen ]                     [ 2. Tanggal Transaksi ]
                     │                                         │
        effective_date <= harvest_date            effective_date <= transaction_date
                     │                                         │
                     ▼                                         ▼
        [ Harvest Price Snapshot ]               [ Transaction Price Snapshot ]
      (harvests.market_price_snapshot)             (sales.price_per_kg / order)
                     │                                         │
                     ▼                                         ▼
           Gross Harvest Value                        Penjualan Riil
      (Estimasi Pendapatan Kotor Panen)         (Kas Masuk Riil / Revenue Kas)
```

---

## 2. Enam Penguncian Bisnis & Implementasi (Locked Business Rules)

### A. Terminologi yang Bersih: "Gross Harvest Value"
- Formula:
  $$\text{Gross Harvest Value} = \text{weight\_kg} \times \text{market\_price\_snapshot}$$
- Nilai ini merupakan **Estimasi Pendapatan Kotor Panen**, bukan laba bersih/yield ekonomi.
- Pada Phase 6 kelak, perhitungan laba/rugi menjadi konsisten:
  $$\text{Profit/Loss} = \text{Gross Harvest Value} - \text{Total Production Cost}$$

### B. Proteksi Immutability Record yang Telah Dirujuk (*Referenced Price Protection*)
- **Aturan Immutability**:
  Setelah suatu record `market_prices` digunakan sebagai referensi snapshot panen (`harvests.market_price_id`), record tersebut **tidak boleh diubah (`price`, `effective_date`, `commodity_id`) maupun dihapus secara destructive**.
- Snapshot panen tidak akan pernah dihitung ulang akibat fluktuasi atau perubahan master harga di masa depan.

### C. Proteksi Integritas Relasi: NO CASCADE DELETE dari `farmer_commodities`
- `farmer_commodities` **DILARANG** melakukan *cascade delete* ke `market_prices` yang memiliki histori.
- Di level database foreign key: `FOREIGN KEY (commodity_id) REFERENCES farmer_commodities(id) ON DELETE RESTRICT`.
- Jika suatu komoditas telah memiliki data harga acuan pasar historis yang terkunci ke panen, komoditas tersebut tidak dapat dihapus sembarangan.

### D. Aturan Penghapusan Deterministik (`DELETE /api/market-prices/{id}`)
- **Unreferenced Market Price** (belum pernah dirujuk oleh panen manapun):
  Boleh dihapus secara permanen atau soft-delete oleh Super Admin.
- **Referenced Market Price** (sudah dirujuk oleh setidaknya satu record panen):
  **DILARANG DIHAPUS**. API akan menolak permintaan dengan status HTTP 422:
  `"Harga pasar tidak dapat dihapus karena telah menjadi acuan pada data panen historis."`

### E. Ingestion Idempoten & Aman (Bukan `updateOrCreate` Buta)
Proses ingestion pada `MarketPriceIngestionService` mematuhi 3 kondisi eksplisit:
```text
Cari record existing berdasarkan (commodity_id, effective_date):

1. JIKA TIDAK DITEMUKAN:
   → Insert record baru (MarketPrice::create).

2. JIKA DITEMUKAN DAN HARGA SAMA (same price):
   → Idempoten, NO-OP (tidak melakukan mutasi apa pun).

3. JIKA DITEMUKAN DAN HARGA BERBEDA (different price):
   ├─ JIKA BELUM DIRUJUK PANEN (unreferenced):
   │  → UPDATE DIIZINKAN (update price allowed).
   │
   └─ JIKA SUDAH DIRUJUK PANEN (referenced):
      → REJECT MUTATION (Tolak perubahan & log warning demi menjaga integritas historis).
```

### F. Kontrak Output `MarketPriceProviderInterface`
Abstraksi provider wajib mematuhi struktur array data yang jelas:
```php
namespace App\Contracts;

interface MarketPriceProviderInterface
{
    public function getIdentifier(): string;

    /**
     * Mengambil feed harga pasar untuk tanggal tertentu.
     *
     * @return array<int, array{
     *     commodity_id: int,
     *     price: float|numeric-string,
     *     unit: string,
     *     effective_date: string, // format YYYY-MM-DD
     *     source: string,
     *     notes: ?string
     * }>
     */
    public function fetchPricesForDate(\DateTimeInterface $date): array;

    /**
     * Mengambil feed harga pasar terkini.
     *
     * @return array<int, array{
     *     commodity_id: int,
     *     price: float|numeric-string,
     *     unit: string,
     *     effective_date: string, // format YYYY-MM-DD
     *     source: string,
     *     notes: ?string
     * }>
     */
    public function fetchLatestPrices(): array;
}
```
*Catatan:* `MockMarketPriceProvider` hanya untuk development/testing offline dan tidak mengklaim integrasi Bapanas asli sampai endpoint nyata diverifikasi.

### G. Constraint Audit Pricing: Hasil Tani Mentah vs Produk Olahan (No Duplicate Flow & Field)
Untuk menjaga kebersihan pipeline existing dan mencegah pembuatan field/tabel duplikat yang redundan:
1. **Explicit Audit Constraint (No Duplicate Flow/Field)**:
   - Pipeline data dan entitas transaksi existing (`orders`, `order_items`, `sales`) **wajib dipertahankan sepenuhnya**.
   - **DILARANG** membuat kolom atau tabel baru yang menduplikasi harga transaksi (seperti membuat `market_price_snapshot` pada `orders` atau membuat pipeline checkout paralel).
2. **Transaksi Produk Olahan (`ProcessedProduct` & `Order`)**:
   - Tetap menggunakan `order_items.price_snapshot` yang diambil dari harga jual katalog olahan.
   - **TIDAK TERPENGARUH** sama sekali oleh harga pasar komoditas mentah.
3. **Transaksi Penjualan Hasil Tani Mentah (`Sale` tipe raw)**:
   - Tetap menggunakan field `sales.price_per_kg`.
   - `MarketPrice` pada tanggal transaksi (`effective_date <= transaction_date`) bertindak sebagai **harga acuan/referensi pasar** yang disarankan sistem, bukan menggantikan atau menduplikasi pipeline `SaleService`.

### H. Constraint Integritas Relasi: Proteksi Komoditas (No Cascade Delete)
- Foreign key `commodity_id` pada tabel `market_prices` dikonfigurasi dengan **`ON DELETE RESTRICT`**.
- **Aturan Tegas**: Menghapus `farmer_commodities` yang telah memiliki histori `market_prices` **DILARANG / DITOLAK** oleh database engine (Foreign Key Constraint Violation) maupun domain layer. Histori harga pasar tidak boleh lenyap (*cascade-deleted*) hanya karena komoditas diubah atau dihapus.

---

## 3. Database Schema & Migrations

### A. Tabel Baru: `market_prices`
Migration: `database/migrations/2026_09_25_000002_create_market_prices_table.php`
```sql
CREATE TABLE market_prices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    commodity_id BIGINT UNSIGNED NOT NULL,
    price DECIMAL(12, 2) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'kg',
    effective_date DATE NOT NULL,
    source VARCHAR(100) NOT NULL DEFAULT 'manual', -- 'mock_feed', 'manual', 'pasar_lokal'
    notes TEXT NULL,
    created_by BIGINT UNSIGNED NULL, -- Super Admin ID
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (commodity_id) REFERENCES farmer_commodities(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uk_commodity_effective (commodity_id, effective_date),
    INDEX idx_commodity_effective (commodity_id, effective_date)
);
```

### B. Penambahan Kolom Snapshot pada Tabel `harvests`
Migration: `database/migrations/2026_09_25_000003_add_market_price_snapshot_to_harvests_table.php`
```sql
ALTER TABLE harvests
    ADD COLUMN market_price_id BIGINT UNSIGNED NULL AFTER commodity_id,
    ADD COLUMN market_price_snapshot DECIMAL(12, 2) NULL AFTER market_price_id,
    ADD COLUMN market_price_effective_date DATE NULL AFTER market_price_snapshot,
    ADD CONSTRAINT fk_harvests_market_price FOREIGN KEY (market_price_id) REFERENCES market_prices(id) ON DELETE SET NULL;
```

---

## 4. Backend Implementation Details

### A. Model: `app/Models/MarketPrice.php`
- `$fillable = ['commodity_id', 'price', 'unit', 'effective_date', 'source', 'notes', 'created_by']`
- `$casts = ['price' => 'decimal:2', 'effective_date' => 'date']`
- Relasi:
  - `commodity()`: `belongsTo(FarmerCommodity::class, 'commodity_id')`
  - `harvests()`: `hasMany(Harvest::class, 'market_price_id')`
- Helper:
  - `public function isReferenced(): bool`: mengecek apakah `harvests()->exists()`.
- Scope:
  - `scopeEffectiveForDate($query, $commodityId, $date)`:
    ```php
    return $query->where('commodity_id', $commodityId)
                 ->where('effective_date', '<=', $date)
                 ->latest('effective_date');
    ```

### B. Service: `app/Services/MarketPriceService.php`
- `findEffectivePrice(int $commodityId, string $date): ?MarketPrice`
- `createMarketPrice(array $data, int $userId): MarketPrice` (Super Admin)
- `updateMarketPrice(MarketPrice $marketPrice, array $data): MarketPrice`:
  - Jika `$marketPrice->isReferenced()`, tolak perubahan pada `price`, `effective_date`, dan `commodity_id`. Hanya catatan (`notes`) yang boleh diupdate.
- `deleteMarketPrice(MarketPrice $marketPrice): void`:
  - Jika `$marketPrice->isReferenced()`, lempar `DomainException("Harga pasar tidak dapat dihapus karena telah menjadi acuan pada data panen historis.")`.

### C. Ingestion Service: `app/Services/MarketPriceIngestionService.php`
- Mengimplementasikan alur safe mutation:
  - `same price` → no-op (idempoten).
  - `different price + unreferenced` → update allowed.
  - `different price + referenced` → reject mutation / log warning.
  - `not found` → insert.

### D. Harvest Service Integration: `app/Services/HarvestService.php`
- Saat `createHarvest`:
  - Jika `$commodityId` ada: cari harga pasar dengan `findEffectivePrice($commodityId, $harvestDate)`.
  - Jika ada, simpan snapshot `market_price_id`, `market_price_snapshot`, `market_price_effective_date`.
- Saat `updateHarvest`:
  - Jika `commodity_id` atau `date` tidak berubah: pertahankan snapshot lama secara konsisten.
- Di `formatHarvest`:
  - Tambahkan `'market_price_snapshot'` dan `'market_price_effective_date'`.

### E. Controller & Authorization: `app/Http/Controllers/Api/MarketPriceController.php`
- `GET /api/market-prices`: List harga pasar (Petani & Super Admin).
- `GET /api/market-prices/latest/{commodity_id}`: Harga aktif (Petani & Super Admin).
- `POST /api/market-prices`: Create (Super Admin only - 403 untuk Petani).
- `PUT /api/market-prices/{id}`: Update dengan guard referensi (Super Admin only).
- `DELETE /api/market-prices/{id}`: Delete dengan guard referensi (Super Admin only).
- `POST /api/market-prices/ingest`: Trigger ingestion (Super Admin only).

---

## 5. Frontend Flutter Implementation

### A. Models
- Model `mobile_app/lib/models/market_price.dart`
- Pembaruan `mobile_app/lib/models/harvest.dart` dengan field snapshot.

### B. Service & Facade
- `mobile_app/lib/services/api/market_price_api_service.dart`
- Facade `mobile_app/lib/services/api_service.dart`.

### C. UI Components
1. **Screen Pantauan Harga Pasar (`mobile_app/lib/screens/market_price_screen.dart`)**:
   - Petani: Menampilkan daftar harga acuan pasar per komoditas miliknya secara informatif (read-only).
   - Super Admin: Form input harga manual dan tombol sinkronisasi ingest.
2. **Pembaruan Layar Panen (`mobile_app/lib/screens/harvest_screen.dart`)**:
   - Menampilkan badge harga snapshot: `@ Rp15.000/kg (Pasar)`.
   - Menampilkan taksiran nilai kotor panen: `Gross Harvest Value`.

---

## 6. Skenario Pengujian (Testing Matrix)

File test: `tests/Feature/API/MarketPriceTest.php`
1. **Positive Test**: Super Admin dapat menambah master harga pasar dengan `effective_date`.
2. **Ingestion Safe Mutation Test**:
   - `same price` → no-op (idempoten, tidak ada operasi write berlebih).
   - `different + unreferenced` → update (mengupdate harga dan metadata karena belum ada panen yang merujuk).
   - `different + referenced` → reject (menolak perubahan harga karena sudah ada panen yang merujuk snapshot tanggal tersebut demi integritas historis).
3. **Role Authorization Guard**: Petani dilarang menambah, mengubah, atau menghapus master harga (HTTP 403).
4. **Mock Ingestion Service**: Ingestion mengimpor data terstruktur dengan kontrak array DTO.
5. **Harvest Automatic Snapshot Lookup**: Panen otomatis mengunci harga pasar dengan `effective_date <= harvest_date` terbaru.
6. **Harvest Snapshot Immutability**: Perubahan master harga pasar di masa depan tidak mengubah snapshot panen lama.
7. **Referenced Price Delete Guard**: Menghapus harga pasar yang sudah dirujuk panen ditolak dengan HTTP 422.
8. **Referenced Price Update Guard**: Mengubah nominal harga pasar yang sudah dirujuk panen ditolak dengan HTTP 422.
9. **Restrict Cascade Delete from Commodity**: Menghapus komoditas yang memiliki harga pasar acuan terikat ditolak oleh foreign key RESTRICT.
10. **Date Separation (Harvest vs Transaction)**:
    - Panen tanggal 1 Juni mengunci harga 1 Juni.
    - Transaksi jual-beli pada 15 September mengacu pada harga efektif 15 September.
11. **Processed Product Price Isolation**: Order/Sale produk olahan tidak terpengaruh oleh harga pasar komoditas mentah.

---

## 7. Rencana Eksekusi Bertahap

1. Checkout branch git: `feature/v2-historical-market-price`.
2. Jalankan database migrations (`market_prices` dengan `ON DELETE RESTRICT` dan kolom snapshot `harvests`).
3. Implementasikan `MarketPriceProviderInterface`, `MockMarketPriceProvider`, `MarketPriceIngestionService`, dan artisan command.
4. Implementasikan `MarketPrice.php`, `MarketPriceService.php`, dan `MarketPriceController.php` dengan seluruh guard immutability.
5. Integrasikan snapshotting di `HarvestService.php`.
6. Eksekusi `MarketPriceTest.php` (11 test skenario) hingga 100% lulus.
7. Implementasikan model, service, dan UI Flutter (`market_price_screen.dart` & indikator panen).
8. Jalankan `flutter analyze` hingga 0 issues.
9. Susun Walkthrough Phase 5 dan tandai Definition of Done.
10. Atomic commit dan push ke remote origin GitHub.
