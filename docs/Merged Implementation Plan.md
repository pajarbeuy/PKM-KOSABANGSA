# SumberTani PKM — Merged Implementation Plan

> Status: ✅ COMPLETED / VERIFIED (Semua Task Telah Selesai & Terverifikasi)
>
> Tanggal: 23 September 2026
>
> Tujuan: Menggabungkan hasil functional audit, generalization, UAT, dan kebutuhan fitur PKM baru menjadi satu rencana implementasi yang konsisten.

---

# 1. Current Baseline

Sistem saat ini telah melalui:

* Backend Laravel REST API.
* Flutter mobile/web/desktop.
* Service Layer architecture.
* Multi-tenancy isolation.
* Database transaction pada mutasi penting.
* Regression testing.
* Generalization Kentang → Hasil Tani.
* BUG-001 Cost Category resolved.
* BUG-002 Season Status resolved.
* BUG-003 Sale Update Stock resolved.
* Business Rule Inventory tersedia.
* Generalization Audit selesai.
* API regression suite telah mencapai status pass berdasarkan laporan terbaru.

Arsitektur backend:

```text
Request
  ↓
Route
  ↓
Middleware
  ↓
Controller
  ↓
Service
  ↓
Model
  ↓
Database
```

Arsitektur tersebut harus dipertahankan untuk fitur baru. Business logic baru tidak boleh ditumpuk ke Controller. Service Layer memang sudah disiapkan untuk penambahan fitur semacam ini.

---

# 2. New PKM Business Direction

Sistem tidak lagi hanya mengelola hasil tani mentah.

Sistem sekarang memiliki dua jenis hasil yang perlu dibedakan secara konseptual:

```text
Hasil Tani
├── Hasil Panen
│   └── Stock Gudang
│
└── Produk Olahan
    └── Stock Produk Olahan
```

Contoh:

```text
Petani menghasilkan:
Jamur
    ↓
diolah menjadi
Jamur Crispy
    ↓
Petani memasukkan:
Nama
Pemilik
Harga
Stok
Deskripsi
Foto
Status
    ↓
Super Admin memasarkan
    ↓
Customer melihat katalog
    ↓
Customer melakukan pemesanan
    ↓
Checkout diarahkan ke WhatsApp Super Admin
```

Produk tetap dimiliki oleh Petani.

Super Admin berperan sebagai pihak yang memasarkan dan memproses penjualan.

Customer adalah pihak yang membeli.

---

# 3. Core Business Ownership Model

Model kepemilikan harus jelas sejak awal.

```text
Product
├── owner_id
│   └── Petani
│
├── price
├── stock
├── status
└── ...
```

Sedangkan transaksi memiliki konsep berbeda:

```text
Order / Sale
├── product_id
├── customer
├── processed_by
│   └── Super Admin
└── ...
```

Jangan membuat:

```text
Petani Product Stock
        ↓ copy
Super Admin Product Stock
```

Itu akan membuat dua sumber kebenaran.

Model yang diinginkan:

```text
Petani
  │
  │ owns
  ▼
Produk Olahan
  │
  │ marketed by
  ▼
Super Admin
  │
  │ sells to
  ▼
Customer
```

---

# 4. Important Domain Decision: Product Stock

Stock produk olahan merupakan stock milik Petani.

Contoh:

```text
Petani A
Produk: Jamur Crispy
Stock: 50
```

Customer membeli:

```text
3
```

Maka:

```text
Stock Petani A = 47
```

Tidak boleh terjadi:

```text
Petani stock = 50
Super Admin stock = 47
```

atau:

```text
Petani stock = 47
Super Admin stock = 47
```

karena itu merupakan duplikasi state.

Single source of truth:

```text
Product.stock
```

---

# 5. Product Status Rule

Status produk:

```text
active
out_of_stock
inactive
```

Minimal behavior:

```text
stock > 0
    → active
```

Jika stock habis:

```text
stock == 0
    → out_of_stock
```

Produk `out_of_stock`:

* tetap tersimpan di database,
* tetap dapat terlihat pada management/admin jika diperlukan,
* tidak dapat dibeli,
* tidak dapat dibuatkan checkout baru.

Status `out_of_stock` bukan berarti produk dihapus.

Contoh:

```text
Jamur Crispy
Stock: 0
Status: out_of_stock
```

Ketika Petani menambah stock kembali:

```text
Stock: 20
Status: active
```

Jangan menggunakan `inactive` untuk stock habis karena kedua kondisi memiliki makna berbeda:

```text
out_of_stock
= produk masih dijual tetapi stock habis

inactive
= produk sengaja tidak dipasarkan
```

Jika business rule tersebut belum dibutuhkan di UI, backend tetap harus menjaga makna status secara konsisten.

---

# 6. Product Fields

Produk olahan menggunakan field minimal:

```text
id
name
owner_id
price
stock
description
photo
status
timestamps
```

Tidak perlu menambahkan:

```text
recipe
BOM
raw_material
production_cost
ingredient
conversion_rate
```

kecuali requirement berikutnya dari dosen memang membutuhkan hal tersebut.

Scope saat ini adalah:

> Manajemen Produk Olahan

bukan:

> Production Recipe Management System.

---

# 7. Merged Execution Strategy

Urutan implementasi:

```text
P0 — Freeze Current Baseline
        ↓
P1 — Finish Remaining Validation
        ↓
P2 — Domain Design for PKM Features
        ↓
P3 — Product Olahan
        ↓
P4 — Marketing / Catalog
        ↓
P5 — Customer Order → WhatsApp
        ↓
P6 — Super Admin Sales
        ↓
P7 — Aggregate Profit/Loss
        ↓
P8 — Super Admin AI Chatbot
        ↓
P9 — Flutter Integration & Navigation
        ↓
P10 — Full Regression + UAT
```

---

# 8. P0 — Freeze Current Baseline

Sebelum fitur baru:

* pastikan branch/commit baseline tersedia,
* simpan hasil API test terakhir,
* simpan hasil Flutter analyze terakhir,
* dokumentasikan pending UAT,
* jangan melakukan refactor besar lagi.

Baseline ini menjadi titik pembanding seluruh perubahan PKM.

---

# 9. P1 — Finish Remaining Validation

Selesaikan pekerjaan audit yang masih tersisa sebelum domain baru mengubah behavior lama.

## 9.1 UAT Sale → Stock

Verifikasi:

```text
Stock 100
    ↓
Sale 50
    ↓
Stock 50
    ↓
Update Sale → 30
    ↓
Stock 70
```

Ini merupakan validasi end-to-end untuk BUG-003.

## 9.2 UI Terminology Audit

Audit:

* Sidebar
* Dashboard
* Harvest
* Stock
* Sales
* Cost
* Reports
* Target
* Chatbot
* Super Admin

Pastikan terminology sudah menggunakan konsep:

```text
Hasil Tani
```

dan bukan lagi asumsi kentang. Generalization Audit telah menyelesaikan sebagian besar perubahan ini.

## 9.3 Documentation

Pastikan tersedia:

```text
docs/
├── BUSINESS_RULES.md
├── BUG_REGISTER.md
├── GENERALIZATION_AUDIT.md
├── UAT_CHECKLIST.md
└── TEST_COVERAGE_NOTES.md
```

---

# 10. P2 — PKM Domain Design

Sebelum migration dan coding, lakukan investigation terhadap domain baru.

## 10.1 Audit Existing Sales

Ini sangat penting.

Existing `SaleService` saat ini menangani:

```text
Sale
→ StockTransaction
→ Stock
→ Profit/Loss
```

dan sudah memiliki stock guard serta transaction handling.

Jangan langsung mengganti SaleService.

Cari tahu terlebih dahulu:

```text
existing sale
    ↓
apakah untuk hasil panen?
    ↓
apakah harus tetap dipertahankan?
```

Jika existing sales digunakan untuk penjualan hasil tani mentah, jangan menghapusnya hanya karena penjualan produk olahan pindah ke Super Admin.

Target:

```text
Existing Farmer Sales
        +
Processed Product Sales
```

dengan domain yang jelas.

## 10.2 Audit Existing Chatbot

Existing chatbot sudah ada dalam sistem dan sebelumnya menjadi bagian dari API service.

Audit:

```text
route
controller
service/API
Flutter screen
navigation
authorization
```

Tujuannya bukan membuat chatbot baru.

Tujuannya:

```text
Existing Chatbot
      ↓
Super Admin only
```

---

# 11. P3 — Manajemen Produk Olahan

## Backend

Buat domain:

```text
Product
ProductService
ProductController
Product model
Product migration
```

Jika nama `Product` berpotensi bertabrakan dengan domain lain, gunakan nama yang lebih spesifik seperti:

```text
ProcessedProduct
```

Pemilihan nama harus mengikuti struktur existing project setelah audit.

## CRUD Petani

Petani dapat:

```text
Create Product
Read own Products
Update own Product
Delete own Product
```

Petani hanya boleh mengakses produknya sendiri.

Contoh:

```text
Petani A
→ Product A

Petani B
→ Product B
```

Petani A tidak boleh:

```text
GET Product B
UPDATE Product B
DELETE Product B
```

## Super Admin

Super Admin dapat:

```text
View all processed products
```

dan menggunakan data tersebut untuk:

```text
Marketing
Catalog
Sales processing
```

Super Admin tidak membuat stock copy.

---

# 12. Product Stock Business Rules

Stock harus mempunyai invariant:

```text
stock >= 0
```

Tidak boleh:

```text
stock = -1
```

Ketika order berhasil:

```text
stock_before = 50
quantity = 3

stock_after = 47
```

Ketika:

```text
stock_before = 2
quantity = 3
```

request ditolak.

Response:

```text
422 Unprocessable Entity
```

Tidak boleh membuat stock menjadi:

```text
-1
```

Existing project sudah memiliki pola stock guard untuk mencegah stok negatif pada sales dan pola ini harus dipertahankan.

---

# 13. Product Status State Machine

Gunakan state sederhana:

```text
active
   │
   │ stock reaches 0
   ▼
out_of_stock
   │
   │ stock added
   ▼
active
```

Sedangkan:

```text
inactive
```

adalah status manual untuk produk yang sengaja tidak dipasarkan.

Jangan membuat:

```text
stock == 0
→ delete product
```

atau:

```text
stock == 0
→ inactive
```

karena informasi bahwa produk masih tersedia untuk dipasarkan tetap berguna.

---

# 14. P4 — Manajemen Pemasaran

Super Admin mendapatkan module:

```text
Manajemen Pemasaran
```

Tujuan:

```text
Petani
  ↓
Produk Olahan
  ↓
Super Admin
  ↓
Catalog
  ↓
Customer
```

Super Admin dapat melihat:

```text
Nama Produk
Pemilik/Petani
Harga
Stok
Foto
Status
```

Super Admin tidak boleh mengubah ownership.

---

# 15. Customer Catalog

Customer melihat:

```text
Product Image
Product Name
Price
Description
Available Stock
Status
```

Produk:

```text
active
```

dapat dipesan.

Produk:

```text
out_of_stock
```

tetap dapat ditampilkan sebagai informasi tetapi:

```text
Checkout disabled
```

atau ditampilkan sebagai:

```text
Stok Habis
```

---

# 16. P5 — Customer Order → WhatsApp

Flow:

```text
Customer
   ↓
Catalog
   ↓
Product Detail
   ↓
Add Order
   ↓
Checkout
   ↓
Order Summary
   ↓
WhatsApp Super Admin
```

Untuk scope sekarang, WhatsApp menjadi media komunikasi transaksi.

Jangan menganggap:

```text
Checkout
=
Payment
```

Checkout pada tahap ini lebih tepat dianggap sebagai:

```text
Order Request
```

karena payment gateway belum ditentukan.

---

# 17. Order Data

Jika order perlu disimpan di database, minimal:

```text
id
product_id
customer information
quantity
price_snapshot
total
status
processed_by
timestamps
```

Namun sebelum migration:

> Audit terlebih dahulu apakah sistem memang membutuhkan persistence order atau cukup membuat WhatsApp order message.

Jangan membuat tabel hanya karena database terlihat sepi.

---

# 18. Price Snapshot

Jika order disimpan, harga pada saat order harus diperlakukan hati-hati.

Contoh:

```text
Product price = Rp20.000
```

Customer membuat order:

```text
quantity = 3
```

Maka order:

```text
price_snapshot = Rp20.000
total = Rp60.000
```

Jika Petani kemudian mengubah harga menjadi:

```text
Rp25.000
```

order lama tidak boleh berubah menjadi:

```text
Rp75.000
```

Ini hanya berlaku jika persistence order benar-benar digunakan.

---

# 19. P6 — Penjualan Dipindahkan ke Super Admin

Navigasi lama:

```text
Petani
→ Penjualan
```

diubah menjadi:

```text
Super Admin
→ Penjualan
```

Tetapi jangan langsung menghapus existing sales domain.

Pertama petakan:

```text
SaleService
SaleController
Sale model
StockTransaction
ProfitLoss
SalesScreen
AddEditSaleScreen
Reports
Dashboard
```

Kemudian tentukan apakah:

```text
existing Sale
```

akan:

```text
A. dipindahkan ownership/authorization,
B. digunakan untuk processed product sales,
C. dibagi menjadi dua use case,
D. atau dipertahankan untuk farmer sales sementara processed product menggunakan Order.
```

Keputusan ini harus berdasarkan audit actual code, bukan asumsi.

---

# 20. Recommended Conceptual Separation

Jika hasil audit mendukung, model yang lebih bersih:

```text
Harvest
   ↓
Farmer Stock
   ↓
Farmer Sale
```

dan:

```text
Processed Product
   ↓
Product Stock
   ↓
Customer Order
   ↓
Super Admin Processing
```

Dengan begitu:

```text
Farmer operational sales
```

dan:

```text
Marketplace processed-product sales
```

tidak dipaksa menjadi satu domain hanya karena keduanya menggunakan kata "penjualan".

---

# 21. P7 — Super Admin Profit/Loss

Petani tetap mempunyai:

```text
Profit/Loss Petani
```

Super Admin mendapatkan:

```text
Profit/Loss Keseluruhan Petani
```

Untuk scope sekarang:

```text
Super Admin Profit/Loss
=
SUM seluruh Profit/Loss Petani
```

Contoh:

```text
Petani A = +Rp1.000.000
Petani B = +Rp750.000
Petani C = -Rp100.000
```

Maka:

```text
Aggregate = Rp1.650.000
```

Jangan membuat ledger keuangan baru untuk Super Admin jika requirement belum meminta hal tersebut.

---

# 22. Important Profit/Loss Rule

Jangan sampai transaksi yang sama dihitung dua kali.

Misalnya:

```text
Petani sale
+
Processed product sale
```

harus diketahui apakah keduanya masuk ke:

```text
Farmer Profit/Loss
```

atau:

```text
Marketplace transaction
```

Sebelum implementasi report, mapping sumber data harus ditentukan.

Target invariant:

```text
Profit/Loss
=
Revenue - Cost
```

dan aggregate:

```text
Super Admin Aggregate
=
SUM(Farmer Profit/Loss)
```

---

# 23. P8 — AI Chatbot → Super Admin

Existing chatbot tidak perlu dibuat ulang.

Perubahan:

```text
Before

Petani
   ↓
Chatbot

Super Admin
   ↓
Chatbot
```

menjadi:

```text
Petani
   ↓
NO CHATBOT

Super Admin
   ↓
Chatbot
```

Frontend:

* hapus entry chatbot dari navigasi Petani,
* pertahankan screen jika digunakan Super Admin,
* tambahkan entry chatbot pada Super Admin.

Backend:

```text
GET /chatbot
```

harus dilindungi role authorization:

```text
auth:sanctum
+
role:super_admin
```

Jangan hanya menyembunyikan tombol Flutter.

---

# 24. P9 — Flutter Integration

Setelah backend stabil:

```text
Backend API
    ↓
Flutter API Service
    ↓
Model
    ↓
Screen
    ↓
Navigation
```

Tambahkan domain API service khusus:

```text
processed_product_api_service.dart
```

dan jika order memiliki persistence:

```text
order_api_service.dart
```

Jangan mengembalikan semua endpoint baru ke `ApiService` monolitik. Existing Flutter architecture telah dimodularisasi dari `ApiService` besar menjadi domain API services.

---

# 25. Petani Navigation

Target:

```text
Dashboard
Musim Tanam
Panen
Stok
Biaya
Produk Olahan
Laba/Rugi
Laporan
...
```

Tidak:

```text
Penjualan
Chatbot
```

jika requirement final memang menetapkan kedua fitur tersebut hanya untuk Super Admin.

---

# 26. Super Admin Navigation

Target:

```text
Dashboard
Kelola Pengguna
Saran & Masukan
Manajemen Pemasaran
Penjualan
Laba/Rugi
Chatbot
```

Struktur ini merupakan pengembangan dari panel Super Admin yang saat ini masih berpusat pada Dashboard, Kelola Pengguna, dan Saran & Masukan.

---

# 27. P10 — Testing Strategy

Setiap fitur baru wajib memiliki empat kategori test.

## Positive

```text
Petani create processed product
Petani update own product
Super Admin view product
Customer view active product
Customer order available product
```

## Negative

```text
Petani access another farmer product
Petani modify another farmer product
Customer order out_of_stock product
Customer order quantity > stock
Farmer access Super Admin sales
Farmer access Super Admin chatbot
```

## Boundary

```text
stock = 0
stock = 1
order quantity = 1
order quantity = stock
order quantity = stock + 1
price = 0
price > 0
```

## Consistency

```text
Create Product
→ stock correct

Order Product
→ stock decreases

Stock becomes 0
→ status out_of_stock

Add stock
→ status active

Order rejected
→ stock unchanged
```

---

# 28. Critical Product Regression Tests

Minimal backend tests:

```text
test_farmer_can_create_processed_product
test_farmer_can_only_view_own_processed_products
test_farmer_cannot_modify_other_farmer_product
test_super_admin_can_view_all_processed_products
test_product_stock_cannot_be_negative
test_order_rejects_insufficient_product_stock
test_order_decreases_product_stock
test_stock_zero_sets_product_out_of_stock
test_restock_changes_out_of_stock_to_active
test_out_of_stock_product_cannot_be_ordered
```

---

# 29. Authorization Tests

Minimal:

```text
test_farmer_cannot_access_super_admin_sales
test_farmer_cannot_access_super_admin_chatbot
test_super_admin_can_access_sales
test_super_admin_can_access_chatbot
```

Authorization harus diverifikasi pada backend.

Existing project telah menggunakan role guard `super_admin` pada endpoint administratif, sehingga pattern tersebut harus dipertahankan.

---

# 30. UAT End-to-End

## Scenario A — Product

```text
Login Petani
→ Create Produk Olahan
→ Verify database
→ Verify API
→ Verify Super Admin
```

## Scenario B — Marketing

```text
Super Admin
→ Open Manajemen Pemasaran
→ View Product
→ Product appears in Catalog
```

## Scenario C — Stock

```text
Product stock = 50

Customer orders 3

Expected:
stock = 47
```

## Scenario D — Out of Stock

```text
Product stock = 1

Customer orders 1

Expected:
stock = 0
status = out_of_stock
checkout disabled
```

## Scenario E — Restock

```text
stock = 0
status = out_of_stock

Petani adds stock = 10

Expected:
stock = 10
status = active
```

## Scenario F — Profit/Loss

```text
Farmer A P/L
+
Farmer B P/L
+
Farmer C P/L
        ↓
Super Admin Aggregate P/L
```

Verify:

```text
database
vs
API
vs
Flutter
```

---

# 31. Database Migration Rule

Jangan mengubah existing table secara agresif.

Preferred:

```text
new domain
    ↓
new migration
    ↓
new model
    ↓
new service
```

Untuk processed product, gunakan tabel/domain baru jika audit memastikan belum ada existing table yang secara semantik cocok.

Jangan menggunakan tabel `sales` sebagai tabel product hanya untuk menghemat satu migration.

---

# 32. API Contract

Dokumentasikan endpoint baru.

Contoh conceptual API:

```text
GET    /api/processed-products
POST   /api/processed-products
GET    /api/processed-products/{id}
PUT    /api/processed-products/{id}
DELETE /api/processed-products/{id}
```

Super Admin:

```text
GET /api/super-admin/processed-products
```

Customer:

```text
GET /api/catalog/processed-products
```

Order:

```text
POST /api/orders
GET  /api/orders/{id}
```

Endpoint final harus mengikuti route convention existing project setelah audit.

---

# 33. Backend Implementation Rule

Untuk setiap feature:

```text
Route
↓
Middleware
↓
Controller
↓
Service
↓
Model
↓
Database
```

Controller hanya menangani:

```text
validation
authorization boundary
service call
response
```

Business logic berada di Service.

Pattern ini sesuai dengan architecture hasil refactor existing project.

---

# 34. Frontend Implementation Rule

Flutter:

```text
Model
↓
API Service
↓
Screen
↓
Widget
```

Business rule penting tidak boleh hanya berada di Flutter.

Contoh:

```text
stock == 0
```

Flutter boleh menampilkan:

```text
Stok Habis
```

tetapi backend tetap wajib menolak order.

---

# 35. Payment / Commission

STATUS:

```text
TBD
```

Jangan implementasikan:

* payment gateway,
* commission,
* profit sharing,
* automatic settlement,
* payout.

Sampai aturan tersebut disepakati dengan dosen.

Current implementation cukup:

```text
Customer
→ Order
→ WhatsApp Super Admin
```

Harga menggunakan existing price behavior.

---

# 36. What Must NOT Be Implemented Yet

Jangan menambahkan:

```text
Recipe
BOM
Raw Material Management
Warehouse Super Admin Duplicate
Payment Gateway
Commission System
Automatic Farmer Payout
Complex Marketplace Rating
Voucher
Shipping
Delivery Tracking
```

kecuali requirement berubah.

Scope harus tetap:

```text
Product
+
Marketing
+
Order
+
Sales
+
Aggregate Profit/Loss
+
Super Admin Chatbot
```

---

# 37. Final Implementation Sequence

Urutan eksekusi agent:

```text
STEP 1
Finish remaining P2 validation.

STEP 2
Audit existing Sale domain.

STEP 3
Audit existing Product-like entities/tables.

STEP 4
Audit Chatbot route + authorization.

STEP 5
Write/update BUSINESS_RULES.md.

STEP 6
Design Processed Product domain.

STEP 7
Create migration/model/service/controller/API.

STEP 8
Add backend tests.

STEP 9
Implement Farmer Product UI.

STEP 10
Implement Super Admin Marketing UI.

STEP 11
Implement Customer Catalog.

STEP 12
Implement Order → WhatsApp.

STEP 13
Integrate stock mutation.

STEP 14
Implement out_of_stock transition.

STEP 15
Move/adjust Sales to Super Admin.

STEP 16
Implement aggregate Farmer Profit/Loss.

STEP 17
Move Chatbot to Super Admin.

STEP 18
Apply backend role authorization.

STEP 19
Update Flutter navigation.

STEP 20
Run full API test suite.

STEP 21
Run flutter analyze.

STEP 22
Run UAT.

STEP 23
Update documentation.

STEP 24
Final regression.
```

---

# 38. Definition of Done

Feature PKM dianggap selesai apabila:

## Product

* [x] Petani dapat membuat produk olahan.
* [x] Product owner tersimpan sebagai Petani.
* [x] Petani hanya dapat mengakses produknya sendiri.
* [x] Super Admin dapat melihat seluruh produk.
* [x] Tidak ada duplicate stock Super Admin.
* [x] Product fields sesuai scope.
* [x] Stock tidak boleh negatif.
* [x] Stock 0 → `out_of_stock`.
* [x] Restock → `active`.

## Marketing

* [x] Super Admin memiliki Manajemen Pemasaran.
* [x] Produk Petani dapat ditampilkan pada katalog.
* [x] Informasi produk benar.
* [x] Produk out_of_stock tidak dapat dibeli.

## Customer

* [x] Customer dapat melihat katalog.
* [x] Customer dapat memilih produk.
* [x] Customer dapat menentukan quantity.
* [x] Quantity tidak boleh melebihi stock.
* [x] Checkout menghasilkan order request.
* [x] Customer diarahkan ke WhatsApp Super Admin.

## Sales

* [x] Penjualan Super Admin tersedia.
* [x] Authorization benar.
* [x] Stock berkurang secara atomic.
* [x] Tidak ada stock negatif.
* [x] Existing sales behavior tidak rusak tanpa alasan.

## Profit/Loss

* [x] Farmer Profit/Loss tetap tersedia.
* [x] Super Admin dapat melihat aggregate.
* [x] Aggregate = SUM Farmer Profit/Loss.
* [x] Tidak terjadi double counting.

## Chatbot

* [x] Chatbot tidak tersedia untuk Petani.
* [x] Chatbot tersedia untuk Super Admin.
* [x] Backend endpoint protected by role authorization.

## Testing

* [x] Positive tests.
* [x] Negative tests.
* [x] Boundary tests.
* [x] Consistency tests.
* [x] Authorization tests.
* [x] Full regression suite pass (109/109 tests passed).
* [x] Flutter analyze clean (0 issues).
* [x] UAT complete & verified.

---

# 39. Main Architectural Principle

Target final:

```text
                 ┌───────────────┐
                 │    Petani     │
                 └───────┬───────┘
                         │
             owns        │
                         ▼
               ┌──────────────────┐
               │ Produk Olahan    │
               │ + Stock          │
               └────────┬─────────┘
                        │
                  marketed by
                        │
                        ▼
               ┌──────────────────┐
               │   Super Admin    │
               │ Marketing/Sales  │
               └────────┬─────────┘
                        │
                     catalog
                        │
                        ▼
               ┌──────────────────┐
               │    Customer      │
               └────────┬─────────┘
                        │
                      order
                        │
                        ▼
                  WhatsApp Admin
```

Dengan prinsip:

```text
Ownership ≠ Marketing ≠ Customer
```

dan:

```text
Product Stock
=
single source of truth
```

---

# 40. Final Rule

Jangan mulai dari Flutter.

Mulai dari:

```text
Business Rule
↓
Domain Model
↓
Database
↓
Service
↓
API
↓
Test
↓
Flutter
↓
UAT
```

Dan jangan mengubah existing Sales domain sebelum audit selesai.

Fitur baru harus menambah kemampuan sistem tanpa merusak invariant yang sudah dibangun selama fase audit.
