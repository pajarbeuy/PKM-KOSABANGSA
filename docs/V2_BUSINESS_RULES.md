# SumberTani v2 — Business Rules Inventory (Phase 1)

> **Dokumen:** V2 Business Rules & Invariants  
> **Tanggal:** 24 September 2026  
> **Status:** Terverifikasi & Mengikat (Binding Specification)  
> **Dasar:** Konfirmasi Spesifikasi User & Kajian Domain v2

---

## 1. Domain Kelompok Tani (Poktan)

* **BR-PKT-001 (Master Poktan Database):**
  Sistem memiliki 10 Kelompok Tani (Poktan 1 s/d Poktan 10) yang bersumber dari tabel database `farmer_groups`, bukan hardcode di sisi client.
* **BR-PKT-002 (Single Active Membership):**
  Satu user Petani terdaftar pada tepat 1 Kelompok Tani aktif melalui atribut `users.farmer_group_id`.
* **BR-PKT-003 (Mandatory Selection on Farmer Registration):**
  Pada saat pendaftaran akun Petani baru, pilihan Poktan wajib diisi dan divalidasi keberadaannya di database (`exists:farmer_groups,id`). Akun `super_admin` tidak diwajibkan memiliki Poktan.
* **BR-PKT-004 (Super Admin Visibility & Assignment):**
  Super Admin memiliki hak melihat Poktan tiap petani, melihat daftar anggota per Poktan, dan memindahkan keanggotaan Poktan petani jika diperlukan.

---

## 2. Domain Hasil Tani Mandiri (Farmer Commodity)

* **BR-CMD-001 (Multi-Tenancy Komoditas):**
  Petani memiliki kebebasan penuh membuat dan mengelola komoditas hasil taninya sendiri (contoh: Padi, Talas, Jeruk, Jamur, Pisang).
* **BR-CMD-002 (Larangan Enum Global):**
  Komoditas tidak boleh dibatasi oleh enum statis database. Komoditas "Jeruk" milik Petani A adalah entitas mandiri yang terpisah dari "Jeruk" milik Petani B.
* **BR-CMD-003 (Strict Ownership Isolation):**
  Petani hanya dapat melihat, mengedit, dan menghapus komoditas miliknya sendiri (`farmer_id = auth()->id()`). Petani tidak dapat mengakses atau memodifikasi komoditas petani lain.

---

## 3. Harga Pasar Historis (Market Price) vs Harga Transaksi

Sistem membedakan secara tegas antara harga untuk evaluasi ekonomi panen dan harga transaksi penjualan riil.

```text
                  [ Master Market Prices ]
                  (effective_date, price)
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   [ Tanggal Panen ]                 [ Tanggal Transaksi ]
            │                                 │
   effective_date <= harvest_date    effective_date <= transaction_date
            │                                 │
            ▼                                 ▼
[ Harvest Price Snapshot ]         [ Transaction Price Snapshot ]
            │                                 │
            ▼                                 ▼
   Kalkulasi Ekonomi Panen             Penjualan / Order Customer
```

* **BR-PRC-001 (Harvest Historical Price Snapshot):**
  Saat pencatatan hasil panen, sistem secara otomatis mencari harga pasar komoditas yang berlaku pada tanggal panen (`effective_date <= harvest_date` terdekat) dan menyimpannya sebagai `market_price_snapshot` pada record panen.
* **BR-PRC-002 (Permanensi Snapshot Panen):**
  Snapshot harga pasar pada data panen bersifat historis dan permanen. Perubahan master harga pasar di masa depan tidak boleh mengubah hasil evaluasi ekonomi panen yang telah dicatat di masa lalu.
* **BR-PRC-003 (Transaction Price Snapshot):**
  Saat customer membeli hasil tani mentah, harga transaksi mengikuti harga pasar yang berlaku pada **tanggal transaksi** (`effective_date <= transaction_date`), bukan harga snapshot panen lama. Nilai ini terkunci sebagai `price_per_kg` transaksi.

---

## 4. Alokasi Panen & Aturan Anti Double-Counting (Biaya Produksi)

```text
                     [ Total Harvest ] (Contoh: 30 kg Jamur)
                            │
               ┌────────────┴────────────┐
               ▼                         ▼
      [ 1. Direct Harvest Sale ]    [ 2. Internal Material Allocation ]
            (15 kg Jamur)                 (15 kg Jamur)
               │                         │
               │ (Jual Mentah)           ▼
               │                   [ Produk Olahan ] (Jamur Crispy)
               │                         │
               │                   + [ Additional Cost ] (Rp 44.000)
               │                     (Tepung, Minyak, Kemasan)
               │                         │
               ▼                         ▼
      Revenue Hasil Panen           Revenue Produk Olahan
```

* **BR-CST-001 (Harvest Production Cost):**
  Biaya produksi hasil tani (bibit, media tanam, pupuk, operasional) dicatat dalam 4 kategori resmi: `seed`, `fertilizer`, `pesticide`, `other`, dan terikat pada periode/musim panen komoditas bersangkutan.
* **BR-CST-002 (Internal Material Allocation):**
  Hasil panen dapat dialokasikan sebagian atau seluruhnya menjadi bahan baku Produk Olahan.
* **BR-CST-003 (Anti Double-Counting Invariant - KRUSIAL):**
  Pengalihan hasil panen menjadi bahan baku produk olahan **BUKAN merupakan pengeluaran kas baru**. Nilai atau bobot bahan baku tersebut tidak boleh dimasukkan kembali sebagai pengeluaran kas pada biaya produksi produk olahan.
* **BR-CST-004 (Additional Production Cost Produk Olahan):**
  Biaya produksi produk olahan hanya mencatat biaya riil tambahan (*incremental cash out*) yang dikeluarkan selama pengolahan (seperti tepung, minyak goreng, bumbu, kemasan, atau stiker label).
* **BR-CST-005 (Pemisahan Domain Biaya):**
  Record biaya panen mentah (`production_costs`) dan biaya tambahan produk olahan tidak boleh digabungkan tanpa atribut konteks yang jelas.

---

## 5. Formula Ekonomi & Perhitungan Laba Bersih Terpadu

* **BR-FIN-001 (Economic Valuation of Harvest):**
  Evaluasi nilai ekonomi hasil panen dihitung dengan rumus:
  $$\text{Harvest Revenue} = \text{Harvest Quantity} \times \text{Harvest Market Price Snapshot}$$
  $$\text{Harvest Profit/Loss} = \text{Harvest Revenue} - \text{Harvest Production Cost}$$
  Jika biaya lebih besar daripada revenue, nilai profit/loss bernilai negatif (*Loss*).
* **BR-FIN-002 (Net Profit Keseluruhan Mitra Tani):**
  Laba bersih keseluruhan dari rangkaian operasional pertanian dan hilirisasi dihitung dengan formula terpadu:
  $$\text{Total Revenue} = \text{Direct Harvest Revenue} + \text{Processed Product Revenue}$$
  $$\text{Total Actual Cost} = \text{Harvest Production Cost} + \text{Additional Processed Product Cost}$$
  $$\text{Net Profit} = \text{Total Revenue} - \text{Total Actual Cost}$$

---

## 6. Komisi Transaksi 10% (Platform Commission)

* **BR-COM-001 (Basis Komisi Gross):**
  Komisi platform sebesar **10%** dihitung dari total nilai transaksi kotor (*Gross Amount*) pesanan produk olahan:
  $$\text{Commission Amount} = 10\% \times \text{Order Total Amount}$$
* **BR-COM-002 (Pembagian Hasil):**
  Dari total pembayaran pesanan, Petani menerima 90% dan platform mengalokasikan 10% sebagai komisi operasional/koperasi.
* **BR-COM-003 (Server-Side Computation):**
  Komisi wajib dihitung dan divalidasi di sisi server (Laravel Backend), tidak boleh dikirim atau dimanipulasi dari client.
* **BR-COM-004 (Execution & Idempotency Guard):**
  Komisi hanya dibentuk saat pesanan beralih ke status `completed` melalui `OrderService::completeOrder`. Upaya menyelesaikan ulang (*retry*) pesanan yang sama tidak boleh membuat komisi ganda.
* **BR-COM-005 (Isolasi Akun Komisi):**
  Komisi platform dicatat dalam tabel khusus `commissions` dan tidak boleh diselipkan ke dalam kolom `production_cost` petani.

---

## 7. Chatbot AI Dua Konteks (Dual-Context Chatbot)

* **BR-BOT-001 (Agricultural Context untuk Petani):**
  Chatbot untuk user Petani difokuskan murni pada asistensi teknis pertanian (tips budidaya komoditas, pencegahan hama, rekomendasi pemupukan, manajemen musim tanam, penanganan pascapanen).
* **BR-BOT-002 (Business/Platform Context untuk Super Admin):**
  Chatbot untuk Super Admin difokuskan pada pemantauan operasional bisnis (manajemen pemasaran, pesanan, pergerakan stok, kinerja penjualan agregat platform).
* **BR-BOT-003 (Backend Context Isolation):**
  Pemisahan respon wajib ditegakkan di backend berdasarkan role akun login (`auth()->user()->role`). Petani tidak boleh dapat mengakses data ringkasan bisnis platform melalui prompt chatbot.

---

## 8. Pemisahan Halaman Publik (Landing Page vs Katalog)

* **BR-WEB-001 (Route `/` - Edukasi & Sosialisasi):**
  Halaman utama (`/`) berfokus pada pengenalan program PKM SumberTani berbasis AI, profil Kelompok Tani binaan, alur hilirisasi komoditas, edukasi fitur platform, dan tombol navigasi (CTA). Halaman ini tidak menampilkan katalog belanja penuh.
* **BR-WEB-002 (Route `/katalog` - Etalase Produk Olahan):**
  Halaman etalase belanja publik bertempat di `/katalog` yang menampilkan kartu produk aktif/habis, pencarian, detail produk, dan alur pemesanan ke WhatsApp Super Admin.
* **BR-WEB-003 (Integritas Order Pipeline):**
  Pemisahan URL katalog tidak boleh mengubah kontrak API `POST /api/public/orders` dan tidak boleh memotong stok saat klik tautan WhatsApp.
