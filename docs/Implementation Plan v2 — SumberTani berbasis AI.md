# SumberTani berbasis AI

## Implementation Plan v2 — Pengembangan Requirement Terbaru Dosen

> **Status:** Draft untuk implementasi
> **Tanggal:** 24 September 2026
> **Baseline:** Implementation Plan sebelumnya telah diterapkan dan diverifikasi.
> **Tujuan:** Mengimplementasikan requirement terbaru dosen tanpa merusak fitur existing P0–P10.

---

# 1. Baseline Sistem

Implementation Plan v2 dimulai dari kondisi bahwa fitur utama pada implementation plan sebelumnya telah diterapkan.

Baseline existing mencakup:

* Laravel REST API.
* Flutter mobile/web/desktop.
* Service Layer architecture.
* Multi-tenancy.
* Database transaction pada operasi mutasi penting.
* Business Rule Inventory.
* Generalisasi Kentang → Hasil Tani.
* Produk Olahan Petani.
* Katalog publik.
* Order pipeline.
* Sales terpusat.
* Stock mutation atomic.
* Farmer Profit/Loss dan Super Admin aggregate.
* TaniBot untuk Super Admin.
* Flutter integration.
* Automated testing.
* Manual UAT.

Laporan perubahan sebelumnya mencatat implementasi fitur baru SumberTani berbasis AI sebagai selesai dan terverifikasi, termasuk 97 API tests dan Flutter analyze tanpa issue.

Architecture existing wajib dipertahankan:

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

Business logic baru tidak boleh ditumpuk ke Controller.

---

# 2. Tujuan Requirement v2

Requirement terbaru memperluas sistem dari sekadar pengelolaan hasil tani dan produk olahan menjadi platform yang juga memahami:

```text
Kelompok Tani
      ↓
Petani
      ↓
Hasil Tani
      ↓
Biaya Produksi
      ↓
Panen
      ↓
Harga Pasar Historis
      ↓
Pendapatan
      ↓
Laba / Rugi
```

Serta:

```text
Petani
   ↓
Chatbot Pertanian

Super Admin
   ↓
Chatbot Bisnis / Platform
```

Dan:

```text
Transaksi
   ↓
Komisi 10%
```

Landing page juga dipisahkan secara konseptual dari katalog:

```text
Landing Page
= Sosialisasi / Edukasi Platform

Katalog
= Etalase Produk
```

---

# 3. Requirement Baru

## 3.1 Landing Page dan Katalog

Landing page tidak lagi berfungsi sebagai halaman katalog utama.

### Landing Page

Route:

```text
/
```

Fokus:

* pengenalan SumberTani berbasis AI,
* edukasi mengenai platform,
* manfaat bagi Petani,
* manfaat bagi Kelompok Tani,
* manfaat bagi Super Admin,
* penjelasan fitur,
* penjelasan alur sistem,
* informasi mengenai AI,
* CTA menuju aplikasi,
* CTA menuju katalog.

Landing page tidak menampilkan katalog produk secara penuh.

### Katalog

Route konseptual:

```text
/katalog
```

Katalog bertanggung jawab terhadap:

* daftar produk olahan,
* foto,
* nama produk,
* pemilik/petani,
* harga,
* stok,
* status ketersediaan,
* order.

Existing order pipeline harus dipertahankan.

Laporan sebelumnya mencatat katalog existing mengambil data produk secara dinamis dan order tidak langsung memotong stok ketika WhatsApp dibuka.

---

# 4. Domain Kelompok Tani (Poktan)

Sistem harus memiliki 10 Kelompok Tani:

```text
Poktan 1
Poktan 2
Poktan 3
...
Poktan 10
```

Poktan harus menjadi entity/domain tersendiri.

Conceptual relationship:

```text
Kelompok Tani
    │
    ├── Petani A
    ├── Petani B
    └── Petani C
```

Satu Petani hanya memiliki satu Poktan aktif pada scope v2 kecuali requirement dosen berikutnya menyatakan sebaliknya.

### Data minimal Poktan

Conceptual:

```text
farmer_groups
├── id
├── name
├── code
├── status
├── description
├── created_at
└── updated_at
```

Nama dapat berupa:

```text
Poktan 1
...
Poktan 10
```

Tetapi jangan meng-hardcode angka Poktan ke frontend.

Poktan harus berasal dari database.

---

# 5. Relasi Petani → Poktan

User dengan role Petani harus memiliki relasi:

```text
users
   │
   └── farmer_group_id
           ↓
      farmer_groups
```

Pada proses registrasi Petani:

```text
Register Petani
      ↓
Pilih Poktan
      ↓
Validasi Poktan
      ↓
Simpan farmer_group_id
```

Super Admin harus dapat:

* melihat Poktan Petani,
* melihat anggota Poktan,
* mengubah assignment Poktan jika diizinkan oleh business rule,
* melihat jumlah anggota per Poktan.

Authorization tetap wajib berbasis backend.

---

# 6. Domain Hasil Tani

`Hasil Tani` tidak boleh menggunakan enum fixed seperti:

```text
padi
jagung
kentang
jeruk
mangga
...
```

Karena requirement mengharuskan Petani dapat membuat kategori/komoditas sendiri.

Conceptual entity:

```text
farmer_commodities
├── id
├── farmer_id
├── name
├── unit
├── description
├── status
├── created_at
└── updated_at
```

Relationship:

```text
Petani A
 ├── Jeruk
 ├── Mangga
 └── Pisang

Petani B
 ├── Padi
 └── Jeruk

Petani C
 ├── Jamur
 └── Talas
```

Dengan demikian:

```text
1 Petani
   ↓
N Hasil Tani
```

Nama `Jeruk` milik Petani A tidak boleh diasumsikan sebagai kategori global yang otomatis sama dengan `Jeruk` milik Petani B.

---

# 7. Pemisahan Hasil Tani dan Produk Olahan

Jangan menggabungkan:

```text
Hasil Tani
```

dengan:

```text
Produk Olahan
```

Keduanya memiliki lifecycle berbeda.

Contoh:

```text
Petani A
   │
   ├── Hasil Tani
   │     └── Talas
   │
   └── Produk Olahan
         └── Keripik Talas
```

`Talas` adalah hasil tani.

`Keripik Talas` adalah produk olahan.

Produk Olahan existing tetap menggunakan domain `ProcessedProduct`.

Jangan membuat duplicate stock atau mengganti domain `ProcessedProduct` hanya karena Hasil Tani baru ditambahkan.

---

# 8. Domain Biaya Produksi dan Panen

Petani harus dapat mencatat biaya yang berkaitan dengan produksi hasil tani.

Existing production cost domain harus diaudit terlebih dahulu sebelum diperluas.

Existing system sudah memiliki empat kategori biaya resmi:

```text
seed
fertilizer
pesticide
other
```

dan kategori legacy `equipment` serta `transport` telah dihapus dari aturan bisnis.

Jangan mengubah kategori tersebut tanpa business rule baru yang eksplisit.

Requirement v2 menambahkan hubungan konseptual:

```text
Hasil Tani
    ↓
Produksi
    ↓
Biaya
    ↓
Panen
```

Satu panen harus dapat diketahui:

* hasil tani apa,
* jumlah hasil panen,
* unit,
* tanggal panen,
* biaya yang digunakan untuk menghasilkan panen tersebut.

---

# 9. Model Panen v2

Existing `Harvest` harus diaudit sebelum membuat entity baru.

Jangan membuat `FarmerHarvest` jika existing `Harvest` masih dapat diperluas secara aman.

Target relationship:

```text
Farmer
   │
   └── Commodity
          │
          └── Harvest
                ├── harvest_date
                ├── quantity
                ├── unit
                └── production_cost
```

Presisi desimal existing harus dipertahankan.

Sistem sebelumnya sudah memperbaiki truncation bobot panen dari integer menjadi float agar data seperti `15.75 kg` tidak berubah menjadi `15 kg`.

Jangan mengembalikan bug tersebut.

---

# 10. Historical Market Price

Harga pasar tidak boleh hanya menggunakan harga saat ini.

Requirement:

```text
Tanggal Panen
      ↓
Cari harga pasar yang berlaku pada tanggal tersebut
      ↓
Gunakan harga tersebut untuk revenue
```

Contoh:

```text
Panen:
Juni 2026

Harga padi Juni 2026:
Rp15.000/kg

Panen:
100 kg

Revenue:
100 × 15.000
= Rp1.500.000
```

Harga bulan September tidak boleh menggantikan harga Juni pada laporan historis.

---

# 11. Domain Market Price

Conceptual entity:

```text
market_prices
├── id
├── commodity_id
├── price
├── unit
├── effective_date
├── source
├── created_at
└── updated_at
```

Namun sebelum migration dibuat, lakukan audit terhadap kebutuhan:

* apakah harga berlaku per tanggal,
* per bulan,
* per komoditas,
* per wilayah,
* apakah harga global atau spesifik Poktan,
* sumber harga,
* apakah satuan harga selalu kg.

Jika requirement dosen belum menentukan wilayah pasar, jangan mengarang field wilayah dan jangan mengunci desain terlalu kompleks.

---

# 12. Price Snapshot

Harga historis yang digunakan dalam transaksi/panen harus disimpan sebagai snapshot.

Conceptual:

```text
Harvest
├── quantity
├── market_price_snapshot
├── market_price_effective_date
└── ...
```

Tujuannya:

```text
Harga Juni = Rp15.000

↓ panen dicatat

snapshot = Rp15.000

↓ harga pasar berubah

Harga Juni di master:
Rp17.000

↓ laporan lama

Tetap menggunakan:
Rp15.000
```

Historical calculation tidak boleh berubah hanya karena master price diperbarui.

---

# 13. Formula Ekonomi Petani

Formula wajib:

```text
Revenue
=
Harvest Quantity × Market Price Snapshot
```

Kemudian:

```text
Profit/Loss
=
Revenue - Total Production Cost
```

Contoh requirement:

```text
Modal:
Rp2.000.000

Panen:
100 kg

Harga:
Rp15.000/kg

Revenue:
100 × 15.000
= Rp1.500.000

Profit/Loss:
1.500.000 - 2.000.000
= -Rp500.000
```

Hasil:

```text
Rugi Rp500.000
```

Jangan menggunakan:

```text
Modal - Revenue
```

sebagai formula profit.

Jika angka tersebut ingin ditampilkan sebagai nilai negatif/positif, gunakan konvensi:

```text
Profit = positive
Loss   = negative
```

---

# 14. Cost Allocation

Ini merupakan salah satu business rule yang harus dikunci sebelum implementasi.

Jika satu Petani memiliki:

```text
Padi
Jeruk
Mangga
```

dan biaya:

```text
Rp2.000.000
```

sistem harus mengetahui biaya tersebut milik produksi yang mana.

Minimum requirement:

```text
Cost
   ↓
Commodity / Season
```

Jangan menghitung semua biaya Petani sebagai biaya setiap komoditas karena akan menyebabkan double counting.

Jika biaya masih mengikuti existing `season_id`, audit apakah hubungan:

```text
Season → Commodity
```

sudah cukup untuk requirement dosen.

Jika belum, tambahkan relasi minimal yang diperlukan.

---

# 15. Chatbot Architecture v2

Chatbot sekarang memiliki dua konteks berbeda.

## Petani

Fokus:

```text
Pertanian
```

Contoh domain:

* budidaya,
* hasil tani,
* panen,
* musim tanam,
* hama,
* pemupukan,
* pertanyaan pertanian umum.

Chatbot Petani tidak boleh mendapatkan konteks bisnis internal Super Admin.

## Super Admin

Fokus:

```text
Bisnis / Platform
```

Contoh:

* produk,
* order,
* penjualan,
* stok,
* pemasaran,
* data operasional,
* ringkasan platform.

Existing chatbot Super Admin harus dipertahankan sebagai baseline, kemudian konteksnya diperjelas.

Backend authorization wajib membedakan:

```text
role = farmer
→ farmer chatbot

role = super_admin
→ super admin chatbot
```

Jangan hanya menampilkan dua UI berbeda tetapi menggunakan endpoint yang sama tanpa role/context enforcement.

---

# 16. Chatbot Context Isolation

Target:

```text
                Chatbot API
                    │
             Role Resolver
               /       \
              /         \
         Petani       Super Admin
            │              │
      Agricultural      Business /
        Context          Platform
```

Petani tidak boleh meminta data internal seperti:

```text
total order platform
total sales semua petani
data customer
informasi operasional admin
```

Super Admin chatbot tidak boleh menggunakan konteks personal Petani sebagai data global tanpa authorization.

---

# 17. Commission 10%

Requirement baru:

```text
10% commission per transaction
```

Commission merupakan business rule baru dan tidak lagi berstatus TBD.

Namun sebelum implementasi, basis perhitungannya wajib dikunci.

Candidate:

```text
A.
Commission = 10% × transaction gross

B.
Commission = 10% × farmer profit

C.
Commission = 10% × net transaction value
```

Jangan memilih salah satu berdasarkan asumsi teknis.

Untuk implementation v2, requirement literal dicatat sebagai:

```text
Commission Rate = 10%
Commission Basis = NEEDS BUSINESS RULE CONFIRMATION
```

Setelah basis dikonfirmasi, formula harus menjadi invariant.

Contoh jika basis akhirnya transaction gross:

```text
Transaction:
Rp500.000

Commission:
10% × 500.000
= Rp50.000
```

Tetapi angka ini belum boleh dijadikan implementasi final sebelum basis resmi dikunci.

---

# 18. Commission Ownership

Commission harus dipisahkan dari:

```text
Farmer Profit/Loss
```

dan:

```text
Processed Product Stock
```

Conceptual:

```text
Order
   ↓
Sale
   ↓
Commission
```

Commission tidak boleh mengubah:

```text
product stock
```

dan tidak boleh diam-diam mengubah:

```text
production cost
```

Jika commission merupakan biaya platform, maka pencatatannya harus memiliki domain/field yang eksplisit.

Jangan menyelipkan commission ke kolom `production_cost`.

---

# 19. Existing Order Pipeline

Order pipeline existing dipertahankan.

Existing architecture:

```text
Customer
   ↓
Order
   ↓
Super Admin
   ↓
Complete
   ↓
Sale
   ↓
Stock Decrement
```

Existing design menggunakan:

* `orders`
* `order_items`
* `sales.order_id`
* `order_items.price_snapshot`
* `SaleService`
* `ProcessedProductService`
* `StockTransaction`

dan menggunakan idempotency guard untuk mencegah duplicate completion.

Commission harus diintegrasikan setelah transaksi resmi terbentuk, bukan ketika Customer hanya membuka WhatsApp.

---

# 20. Git Workflow v2

Git Rules digunakan mulai dari requirement v2.

Branch utama:

```text
main
```

Branch development:

```text
feature/v2-poktan
feature/v2-farmer-commodities
feature/v2-market-price
feature/v2-farmer-profit-loss
feature/v2-chatbot-context
feature/v2-commission
feature/v2-landing-catalog
```

Tidak melakukan seluruh requirement dalam satu branch raksasa.

Gunakan atomic commits.

Contoh:

```text
feat(poktan): add farmer group domain
feat(farmer): assign farmer to group
feat(commodity): add farmer commodity management
feat(market): add historical market price
feat(harvest): attach harvest to commodity
feat(profit): calculate farmer economic result
feat(chatbot): add farmer agricultural context
feat(chatbot): separate super admin business context
feat(commission): add transaction commission
feat(web): separate landing page and catalog
test(poktan): add authorization and membership tests
test(profit): add historical price calculation tests
```

Tidak membuat commit seperti:

```text
update
fix
changes
final
final2
fixfix
```

---

# 21. Phase 0 — Cleanup & Baseline

Sebelum v2:

* Bersihkan residual branding `SIMHPSK`.
* Pastikan aplikasi existing tetap berjalan.
* Jalankan existing test suite.
* Jalankan `flutter analyze`.
* Commit baseline menggunakan Git Rules.

Acceptance:

```text
Existing tests PASS
Flutter analyze PASS
Branding konsisten
Git baseline tersedia
```

---

# 22. Phase 1 — Domain & Business Rule Audit

Audit actual code sebelum migration.

Audit:

```text
User
Season
Harvest
Cost
Sale
ProcessedProduct
Order
OrderItem
StockTransaction
Chatbot
ProfitLoss
```

Tujuan:

* menemukan entity yang bisa direuse,
* menghindari duplicate model,
* mengetahui foreign key existing,
* menentukan ownership,
* menentukan titik integrasi.

Output:

```text
docs/V2_DOMAIN_AUDIT.md
docs/V2_BUSINESS_RULES.md
```

---

# 23. Phase 2 — Poktan

Implement:

```text
FarmerGroup
```

Tahapan:

1. migration,
2. model,
3. relationship,
4. service,
5. controller,
6. API,
7. authorization,
8. seed Poktan 1–10,
9. backend tests,
10. Flutter API service,
11. Flutter UI.

Acceptance:

* 10 Poktan tersedia.
* Petani dapat memiliki Poktan.
* Petani tidak dapat memilih Poktan invalid.
* Super Admin dapat melihat anggota.
* Petani tidak dapat mengubah data Poktan secara ilegal.

---

# 24. Phase 3 — Farmer Commodity / Hasil Tani

Implement:

```text
FarmerCommodity
```

Tahapan:

1. migration,
2. model,
3. relation,
4. service,
5. API,
6. authorization,
7. CRUD Flutter,
8. tests.

Acceptance:

```text
Petani A
 ├── Jeruk
 ├── Mangga
 └── Pisang
```

dan:

```text
Petani B
 ├── Padi
 └── Jeruk
```

harus valid.

Tidak boleh ada global enum commodity yang membatasi Petani.

---

# 25. Phase 4 — Harvest & Cost Integration

Hubungkan:

```text
Petani
 ↓
Commodity
 ↓
Season
 ↓
Cost
 ↓
Harvest
```

Audit existing `HarvestService` dan `CostService` terlebih dahulu.

Jangan membuat ulang domain existing tanpa alasan.

Acceptance:

* Panen terkait Petani.
* Panen terkait hasil tani.
* Biaya dapat diatribusikan dengan benar.
* Existing stock behavior tetap berjalan.
* Existing season isolation tetap berjalan.
* Existing decimal precision tetap berjalan.

---

# 26. Phase 5 — Historical Market Price

Implement:

```text
MarketPrice
```

Kemampuan:

* create,
* update,
* list,
* lookup berdasarkan commodity,
* lookup berdasarkan effective date.

Lookup:

```text
findApplicablePrice(
    commodity,
    harvestDate
)
```

harus deterministik.

Jika terdapat beberapa harga yang valid:

```text
effective_date <= harvest_date
```

gunakan record yang paling relevan berdasarkan business rule yang telah dikunci.

Harga yang digunakan saat panen disimpan sebagai snapshot.

---

# 27. Phase 6 — Farmer Economic Result

Implement:

```text
Revenue
Profit/Loss
```

Formula:

```text
Revenue = Quantity × Historical Market Price

Profit/Loss = Revenue - Allocated Production Cost
```

API harus mengembalikan minimal:

```text
quantity
unit
market_price
market_price_date
revenue
production_cost
profit_loss
```

Flutter menampilkan:

```text
Modal
Hasil Panen
Harga Pasar
Pendapatan
Total Biaya
Laba/Rugi
```

---

# 28. Phase 7 — Farmer Chatbot

Pisahkan chatbot Petani dari Super Admin.

Petani:

```text
Agricultural Assistant
```

Super Admin:

```text
Business / Platform Assistant
```

Backend:

```text
GET/POST /chatbot/farmer
GET/POST /chatbot/super-admin
```

atau struktur endpoint lain yang tetap memberikan separation of context.

Authorization wajib diuji.

Acceptance:

```text
Petani
→ farmer chatbot
→ agricultural context

Super Admin
→ super admin chatbot
→ business/platform context
```

---

# 29. Phase 8 — Commission

Setelah business rule basis commission dikunci:

Implement:

```text
Commission
```

Minimum data:

```text
id
transaction_id
rate
base_amount
commission_amount
created_at
```

Commission harus:

* dihitung server-side,
* tidak dapat dimanipulasi client,
* immutable setelah transaksi final jika business rule mengharuskan,
* tidak menyebabkan duplicate commission ketika order complete dipanggil ulang.

Acceptance:

```text
Transaction completed once
→ exactly one commission
```

Retry:

```text
complete same order again
→ no duplicate commission
```

---

# 30. Phase 9 — Landing Page / Catalog Separation

Refactor:

```text
/
```

menjadi:

```text
Platform Landing Page
```

dan:

```text
/katalog
```

menjadi:

```text
Product Catalog
```

Landing page:

* edukasi,
* value proposition,
* feature explanation,
* ecosystem,
* AI,
* Poktan,
* Petani,
* CTA.

Catalog:

* product listing,
* product detail,
* availability,
* order.

Existing order pipeline tidak boleh rusak.

---

# 31. Phase 10 — Flutter Integration

Setelah backend stabil:

```text
Backend API
    ↓
API Service
    ↓
Model
    ↓
Screen
    ↓
Navigation
```

Domain service baru harus mengikuti modularisasi existing.

Jangan memasukkan seluruh endpoint v2 kembali ke monolithic `ApiService`.

Existing project telah menggunakan domain-specific API services dan facade `ApiService`.

---

# 32. Phase 11 — Testing

Setiap phase wajib memiliki test.

Minimum:

### Positive

* valid Poktan assignment,
* valid commodity creation,
* valid harvest,
* valid market price,
* valid economic calculation,
* valid chatbot access,
* valid commission.

### Negative

* invalid Poktan,
* farmer accessing another farmer's commodity,
* invalid price,
* missing historical price,
* unauthorized chatbot,
* duplicate commission,
* negative stock.

### Boundary

* zero harvest,
* decimal harvest,
* zero cost,
* loss condition,
* exact market-price effective date,
* price changes after harvest,
* transaction retry.

### Consistency

```text
Harvest
→ Price Snapshot
→ Revenue
→ Profit/Loss
```

must remain consistent after market price master changes.

---

# 33. Regression Testing

Fitur v2 tidak boleh merusak:

```text
Season
Harvest
Stock
Sale
Cost
Processed Product
Order
Marketing
Super Admin
Authentication
Password Reset
Chatbot
Reports
```

Existing API test suite harus tetap pass.

Flutter:

```bash
flutter analyze
```

harus:

```text
No issues found
```

---

# 34. UAT v2

UAT harus menguji alur end-to-end.

## Scenario 1 — Poktan

```text
Super Admin
→ create/seed Poktan 1–10

Petani
→ register
→ choose Poktan
→ login

Super Admin
→ verify membership
```

## Scenario 2 — Hasil Tani

```text
Petani A
→ create Jeruk
→ create Mangga
→ create Pisang

Petani B
→ create Padi
→ create Jeruk
```

## Scenario 3 — Economic Result

```text
Cost = Rp2.000.000
Harvest = 100 kg
Harvest Date = June
June Price = Rp15.000/kg

Revenue = Rp1.500.000
Profit/Loss = -Rp500.000
```

## Scenario 4 — Historical Price

```text
June:
Rp15.000

September:
Rp20.000

Existing June harvest:
→ tetap menggunakan Rp15.000
```

## Scenario 5 — Chatbot

```text
Petani
→ agricultural chatbot

Super Admin
→ business/platform chatbot
```

## Scenario 6 — Commission

```text
Transaction
→ complete
→ commission 10%

Retry complete
→ commission tetap satu
```

## Scenario 7 — Landing / Catalog

```text
/
→ education

/katalog
→ products
```

---

# 35. Documentation

Dokumentasi v2 minimal:

```text
docs/
├── V2_DOMAIN_AUDIT.md
├── V2_BUSINESS_RULES.md
├── V2_API_NOTES.md
├── V2_UAT_CHECKLIST.md
└── V2_TEST_COVERAGE.md
```

Dokumentasi harus diperbarui setelah implementasi aktual, bukan ditulis seolah-olah fitur sudah selesai sebelum kode benar-benar selesai.

---

# 36. Definition of Done

## Poktan

* [x] Poktan 1–10 tersedia.
* [x] Poktan berasal dari database.
* [x] Petani dapat dikaitkan dengan Poktan.
* [x] Authorization assignment benar.
* [x] Super Admin dapat melihat anggota Poktan.

## Hasil Tani

* [x] Petani dapat membuat Hasil Tani.
* [x] Satu Petani dapat memiliki banyak Hasil Tani.
* [x] Hasil Tani tidak dibatasi enum global.
* [x] Petani hanya dapat mengelola miliknya sendiri.
* [x] Hasil Tani terpisah dari Produk Olahan.

## Panen & Biaya

* [ ] Panen dapat dikaitkan dengan Hasil Tani.
* [ ] Biaya dapat diatribusikan secara benar.
* [ ] Existing Season behavior tidak rusak.
* [ ] Decimal quantity tetap akurat.
* [ ] Existing stock behavior tidak rusak.

## Historical Price

* [ ] Harga memiliki tanggal berlaku.
* [ ] Harga yang digunakan mengikuti tanggal panen.
* [ ] Historical price tidak berubah setelah master price diperbarui.
* [ ] Price snapshot tersedia.

## Economic Result

* [ ] Revenue = quantity × historical price.
* [ ] Profit/Loss = revenue − allocated cost.
* [ ] Loss dapat bernilai negatif.
* [ ] Tidak terjadi double counting biaya.

## Chatbot

* [ ] Petani memiliki chatbot.
* [ ] Fokus Petani = pertanian.
* [ ] Super Admin memiliki chatbot.
* [ ] Fokus Super Admin = bisnis/platform.
* [ ] Context isolation diterapkan.
* [ ] Backend authorization diuji.

## Commission

* [ ] Rate = 10%.
* [ ] Commission basis telah dikunci secara resmi.
* [ ] Commission dihitung server-side.
* [ ] Tidak ada duplicate commission.
* [ ] Commission terhubung dengan transaksi yang benar.

## Web

* [ ] `/` menjadi landing page edukatif.
* [ ] `/katalog` menjadi katalog.
* [ ] Order pipeline existing tetap berjalan.
* [ ] Landing page tidak menjadi katalog utama.

## Git

* [ ] Feature branch digunakan.
* [ ] Atomic commits.
* [ ] Conventional Commits.
* [ ] Tidak bekerja langsung pada `main`.
* [ ] Pull Request digunakan untuk merge.

## Testing

* [ ] Positive tests.
* [ ] Negative tests.
* [ ] Boundary tests.
* [ ] Authorization tests.
* [ ] Historical consistency tests.
* [ ] Commission idempotency tests.
* [ ] Full regression pass.
* [ ] Flutter analyze clean.
* [ ] UAT complete.

---

# 37. Implementation Order

Urutan implementasi final:

```text
P0 — Cleanup & Baseline
        ↓
P1 — Domain & Business Rule Audit
        ↓
P2 — Poktan
        ↓
P3 — Farmer Hasil Tani
        ↓
P4 — Harvest + Cost Integration
        ↓
P5 — Historical Market Price
        ↓
P6 — Farmer Economic Result
        ↓
P7 — Farmer Chatbot
        ↓
P8 — Commission
        ↓
P9 — Landing / Catalog Separation
        ↓
P10 — Flutter Integration
        ↓
P11 — Regression Testing
        ↓
P12 — UAT
        ↓
P13 — Documentation & Final Review
```

---

# 38. Critical Constraints

1. Jangan menghapus atau mengganti domain existing tanpa audit.
2. Jangan membuat duplicate entity jika existing entity masih dapat digunakan.
3. Jangan membuat global commodity enum.
4. Jangan menggabungkan Hasil Tani dengan Produk Olahan.
5. Jangan menggunakan harga pasar terkini untuk histori panen.
6. Jangan menghitung ulang historical revenue menggunakan harga yang berubah.
7. Jangan memasukkan commission ke production cost.
8. Jangan membuat duplicate stock.
9. Jangan membatasi chatbot hanya melalui UI.
10. Jangan membuat satu chatbot dengan context yang tercampur.
11. Jangan menambahkan commission sebelum basis perhitungannya dikunci.
12. Jangan mengubah existing Order → Sale → Stock pipeline tanpa alasan.
13. Jangan mengorbankan existing multi-tenancy.
14. Jangan menumpuk business logic ke Controller.
15. Jangan mengerjakan seluruh v2 dalam satu branch.
16. Jangan menganggap dokumentasi sebagai bukti implementasi. Source of truth adalah kode + test + UAT.

---

# 39. Target Architecture

```text
                         SumberTani
                              │
             ┌────────────────┼────────────────┐
             │                │                │
          Landing          Katalog           App
             │                │                │
        Education          Products       Authenticated
             │                │                │
             │                │       ┌────────┴─────────┐
             │                │       │                  │
             │                │    Petani           Super Admin
             │                │       │                  │
             │                │       │                  │
             │                │   Poktan             Platform
             │                │       │               Business
             │                │   Hasil Tani         Management
             │                │       │                  │
             │                │     Panen             Order
             │                │       │                  │
             │                │     Cost               Sale
             │                │       │                  │
             │                │  Market Price         Commission
             │                │       │
             │                │  Profit/Loss
             │                │
             │                └──── Processed Product
             │                         │
             │                       Order
             │                         │
             └─────────────────────────┴───────────────
```

Chatbot:

```text
                 Chatbot Layer
                      │
             ┌────────┴────────┐
             │                 │
          Petani          Super Admin
             │                 │
      Pertanian Context   Business Context
```

---

# 40. Final Principle

Implementation v2 harus mengikuti prinsip:

```text
Audit
  ↓
Business Rule
  ↓
Domain Design
  ↓
Migration
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
  ↓
Documentation
```

Bukan:

```text
Requirement
  ↓
langsung coding
  ↓
database berubah
  ↓
baru bingung kenapa semua fitur lama rusak
```

Baseline P0–P10 dianggap sebagai sistem existing yang harus dilindungi.

Requirement terbaru dosen menjadi incremental domain expansion, bukan alasan untuk melakukan rewrite terhadap sistem existing.
