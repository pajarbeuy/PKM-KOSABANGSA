# 📘 PANDUAN PENGGUNA LENGKAP SumberTani
## Sistem Informasi Manajemen Hasil Pertanian Berbasis AI

**Versi:** 2.0  
**Tanggal:** 28 Oktober 2026  
**Target:** Petani & Super Admin  
**Status:** Siap Operasional

---

## 📑 DAFTAR ISI

1. [Pendahuluan](#1-pendahuluan)
2. [Memulai Aplikasi](#2-memulai-aplikasi)
3. [Panduan Petani](#3-panduan-petani)
4. [Panduan Super Admin](#4-panduan-super-admin)
5. [Fitur Lanjutan](#5-fitur-lanjutan)
6. [Troubleshooting & FAQ](#6-troubleshooting--faq)

---

## 1. PENDAHULUAN

### 1.1 Apa itu SumberTani?

**SumberTani** adalah platform digital yang membantu Petani dan Kelompok Tani (Poktan) mengelola usaha pertanian dari hulu (budidaya) hingga hilir (penjualan produk olahan). Platform ini dilengkapi asisten AI (TaniBot) untuk mendukung keputusan bisnis.

### 1.2 Fitur Utama

| Fitur | Petani | Super Admin |
|-------|--------|------------|
| Manajemen Musim Tanam | ✅ | 👁️ Pantau |
| Pencatatan Panen & Stok | ✅ | 👁️ Pantau |
| Biaya Produksi | ✅ | 👁️ Pantau |
| Produk Olahan & Katalog | ✅ | ✅ Kelola |
| Laporan Laba/Rugi | ✅ | ✅ Agregat |
| Pesanan & Komisi | ✅ | ✅ Proses |
| TaniBot AI | ✅ Pertanian | ✅ Bisnis |
| Verifikasi Akun | ❌ | ✅ |

### 1.3 Peran Pengguna

**👨‍🌾 Petani (User)**
- Mencatat operasional kebun dan panen
- Kelola produk olahan hasil tani
- Lihat analisis laba/rugi pribadi
- Konsultasi TaniBot pertanian

**👨‍💼 Super Admin**
- Verifikasi akun petani baru
- Kelola master data (harga pasar, komisi, berita)
- Proses penjualan terpusat
- Pantau performa semua petani
- Konsultasi TaniBot bisnis

---

## 2. MEMULAI APLIKASI

### 2.1 Akses Aplikasi

Buka browser dan kunjungi:
```
http://localhost:5000
```

Atau gunakan link publik jika tersedia (hubungi Super Admin).

### 2.2 Login / Register

#### **Petani Baru: Daftar via Google**

1. Klik tombol hijau **"Masuk dengan Google"**
2. Pilih akun Google Anda
3. **Jika email belum terdaftar:**
   - Sistem otomatis membuka formulir pendaftaran
   - Nama & Email sudah terisi dari profil Google (terkunci)
   - Isi data wajib:
     - **Kelompok Tani (Poktan):** Pilih dari dropdown
     - **Nama Kebun/Lahan:** Contoh: "Kebun Jamur Sejahtera"
     - **Nomor HP:** Contoh: 081234567890
     - **Password:** Buat password kuat (min 8 karakter)
   - ✅ Centang **"Saya menyetujui Kebijakan Akun Baru"**
   - Klik **"Daftar Sekarang"**

4. **Tunggu Persetujuan Super Admin**
   - Status akun = *Pending* selama menunggu verifikasi
   - Anda belum bisa login sampai Super Admin setuju

5. **Setelah Disetujui:**
   - Coba login lagi dengan tombol "Masuk dengan Google"
   - Atau gunakan email & password yang didaftarkan

#### **Petani Lama: Login Email & Password**

1. Di halaman login, isi:
   - **Email:** Email terdaftar Anda
   - **Password:** Password yang dibuat saat daftar
2. Klik **"Login"**

#### **Super Admin: Login**

1. Gunakan akun Super Admin khusus (diberikan oleh admin sistem)
2. Email & password sesuai kredensial yang diberikan
3. Klik **"Login"**

### 2.3 Dashboard Pertama Kali

Setelah berhasil login, Anda akan melihat **Dashboard** dengan ringkasan:

**Untuk Petani:**
- Musim tanam aktif saat ini
- Total stok gudang panen
- Biaya produksi bulan ini
- Ringkasan laba/rugi

**Untuk Super Admin:**
- Jumlah petani aktif
- Total penjualan platform
- Notifikasi pesanan baru
- Statistik komisi

---

## 3. PANDUAN PETANI

### 3.1 Manajemen Musim Tanam (Season)

#### **Membuat Musim Tanam Baru**

1. Buka menu **"Musim Tanam"** (sidebar kiri)
2. Klik tombol **"+ Tambah Musim Tanam"** atau **"+ New Season"**
3. Isi formulir:
   - **Nama Musim:** Contoh: "Panen Jamur Januari 2026"
   - **Tanggal Mulai:** Pilih tanggal awal musim tanam
   - **Tanggal Selesai:** Pilih tanggal akhir panen (harus setelah tanggal mulai)
   - **Target Panen (kg):** Contoh: 100 (kg yang ingin dicapai)
4. Klik **"Simpan Musim Tanam"**

#### **Status Musim Tanam**

Setiap musim memiliki status otomatis:

| Status | Warna | Arti |
|--------|-------|------|
| **Belum Dimulai** | 🟡 Kuning | Hari ini sebelum tanggal mulai |
| **Aktif** | 🟢 Hijau | Hari ini dalam rentang musim |
| **Selesai** | 🔵 Biru | Hari ini sudah melewati tanggal akhir |
| **Dibatalkan** | 🔴 Merah | Musim dibatalkan manual |

#### **Membatalkan Musim Tanam**

1. Buka daftar musim tanam
2. Klik musim yang ingin dibatalkan
3. Klik tombol **"Batalkan Musim"**
4. Konfirmasi pembatalan

> ⚠️ Pembatalan tidak menghapus data panen & biaya yang sudah dicatat. Data tetap tersimpan untuk riwayat.

---

### 3.2 Pencatatan Biaya Produksi (Production Cost)

#### **Menambah Biaya Baru**

1. Buka menu **"Biaya Produksi"** (sidebar kiri)
2. Klik **"+ Tambah Biaya"**
3. Isi data:
   - **Tanggal:** Kapan pengeluaran terjadi
   - **Kategori:** Pilih salah satu:
     - 🟢 **Bibit** - Benih/bibit komoditas
     - 🟢 **Pupuk** - Pupuk organik/anorganik
     - 🔴 **Pestisida** - Obat pengendali hama
     - ⚫ **Lainnya** - Sewa alat, tenaga kerja, dll
   - **Jumlah (Rp):** Berapa rupiah yang dikeluarkan
   - **Catatan (Opsional):** Deskripsi detail (contoh: "Pupuk organik jenis A")
   - **Musim Tanam (Opsional):** Pilih musim yang terkait (kosong jika tidak ada)

4. Klik **"Simpan Biaya"**

#### **Melihat Ringkasan Biaya**

Di halaman Biaya Produksi, Anda bisa melihat:
- Total biaya per kategori (grafik batang)
- Riwayat lengkap semua pengeluaran
- Filter per musim tanam

---

### 3.3 Pencatatan Panen (Harvest)

#### **Mencatat Hasil Panen Baru**

1. Buka menu **"Panen"** (sidebar kiri)
2. Klik **"+ Tambah Panen"** atau **"+ Record Harvest"**
3. Isi formulir:
   - **Musim Tanam:** Pilih musim aktif (sistem auto-suggest)
   - **Tanggal Panen:** Pilih tanggal panen
   - **Bobot (kg):** Berapa kg hasil panen (bisa desimal, contoh: 15.5)
   - **Catatan (Opsional):** Deskripsi (contoh: "Jamur tiram putih, berkualitas A")
   - **Foto (Opsional):** Upload foto dokumentasi

4. Klik **"Simpan Panen"**

#### **Apa yang Terjadi di Balik Layar?**

✅ Sistem **otomatis**:
- Mencatat data panen di database
- **Menambah stok gudang** hasil panen mentah sebesar bobot yang dicatat
- Mengambil **harga pasar acuan** yang berlaku pada tanggal panen (jika tersedia)
- Menghitung **nilai kotor panen** = Bobot × Harga Pasar

#### **Menghapus Data Panen**

1. Buka daftar panen
2. Klik panen yang ingin dihapus
3. Klik **"Hapus"** atau **"Delete"**
4. Konfirmasi penghapusan

> ⚠️ Jika panen sudah dialihkan ke produk olahan, tidak bisa dihapus. Harus batalkan konversi dulu.

---

### 3.4 Manajemen Stok Gudang

#### **Melihat Saldo Stok Terkini**

1. Buka menu **"Stok Gudang"** atau **"Stock"** (sidebar kiri)
2. Lihat **Saldo Terkini** di atas (total kg hasil panen mentah)
3. Lihat **Riwayat Pergerakan Stok** (tabel):
   - Tanggal transaksi
   - Jenis transaksi (Masuk / Keluar)
   - Jumlah (kg)
   - Saldo setelah transaksi
   - Referensi (panen, penjualan, konversi, dll)

#### **Apa yang Mempengaruhi Stok?**

| Peristiwa | Efek | Catatan |
|-----------|------|--------|
| Panen dicatat | ➕ Masuk | Stok bertambah |
| Panen dihapus | ➖ Keluar | Stok berkurang |
| Panen dialihkan ke olahan | ➖ Keluar | Stok berkurang (konversi) |
| Penjualan langsung | ➖ Keluar | Stok berkurang |

#### **Peringatan Stok Rendah**

Jika stok jatuh di bawah **100 kg** (atau batas minimum yang diatur):
- 🔔 Notifikasi **"Stok Rendah"** muncul di dashboard
- Pertimbangkan untuk panen lagi atau jual sebelum stok habis

---

### 3.5 Manajemen Produk Olahan (Processed Product)

#### **Membuat Produk Olahan Baru**

1. Buka menu **"Produk Olahan"** (sidebar kiri)
2. Klik **"+ Tambah Produk"** atau **"+ New Product"**
3. Isi data:
   - **Nama Produk:** Contoh: "Jamur Crispy Premium"
   - **Harga Jual (Rp):** Contoh: 5000
   - **Satuan:** Pilih **pcs** (piece) atau **kg**
   - **Deskripsi (Opsional):** Detail produk
   - **Foto (Opsional):** Upload gambar produk

4. Klik **"Simpan Produk"**

#### **Status Produk Olahan**

| Status | Arti |
|--------|------|
| 🟢 **Aktif** | Stok > 0, tersedia untuk dijual |
| ⚫ **Habis** | Stok = 0 |
| 🔴 **Tidak Aktif** | Manual ditarik dari peredaran |

#### **Mengubah Harga Produk**

1. Buka daftar produk olahan
2. Klik produk yang ingin diubah
3. Ubah harga di kolom **"Harga Jual"**
4. Klik **"Simpan"**

> 💡 Perubahan harga hanya berlaku untuk **pesanan baru**. Pesanan lama tetap menggunakan harga saat pesanan dibuat (*price snapshot*).

---

### 3.6 Konversi Panen ke Produk Olahan (Zero Double-Counting)

#### **Apa itu Konversi?**

Konversi adalah **pengalihan sebagian hasil panen mentah menjadi bahan baku produk olahan** tanpa menghitung biaya dua kali:

**Contoh:**
- Anda panen 30 kg Jamur Tiram
- Modal tanam = Rp 200.000
- 15 kg dialihkan menjadi 150 pcs Jamur Crispy
- Sisa 15 kg dijual langsung

**Penting:** Nilai 15 kg bahan baku **TIDAK dihitung sebagai pengeluaran kas baru** (Rp 0). Modal Rp 200.000 sudah dihitung di biaya tanam.

#### **Melakukan Konversi**

1. Buka menu **"Konversi Panen"** atau **"Convert Harvest"** (biasanya di Produk Olahan atau dashboard)
2. Pilih **Panen Sumber:**
   - Dropdown menampilkan daftar panen yang tersedia
   - Sistem otomatis tampilkan stok terkini & harga pasar

3. Pilih **Produk Olahan Tujuan:**
   - Pilih produk yang sudah ada, atau **"Buat Produk Baru"**
   - Isi jumlah kg yang dialihkan (contoh: 15)

4. **Isi Bahan Penolong (Incremental Cost):**
   - Sistem akan menampilkan tabel untuk input biaya tambahan:
     - Tepung: Rp 20.000
     - Minyak Goreng: Rp 24.000
     - Kemasan: Rp 5.000
   - **Total Biaya Tambahan: Rp 49.000** (bukan termasuk bahan baku)

5. Lihat **Banner Edukasi:**
   > "Bahan baku 15 kg dialihkan dengan nilai Rp 0 (Prinsip Zero Double-Counting). Hanya biaya tambahan yang tercatat."

6. Klik **"Lakukan Konversi"**

#### **Apa yang Terjadi di Balik Layar?**

✅ Sistem otomatis:
- **Kurangi stok gudang panen mentah** sebesar 15 kg
- **Catat biaya produksi:** Bahan baku 15 kg = Rp 0 (zero double-counting)
- **Catat biaya produksi:** Bahan penolong = Rp 49.000 (tepung, minyak, kemasan)
- **Tambah stok produk olahan** sebesar 150 pcs (jika 1 kg = 10 pcs)

---

### 3.7 Analisis Laba/Rugi Petani

#### **Laporan Laba/Rugi per Musim**

1. Buka menu **"Laporan"** atau **"Reports"** (sidebar kiri)
2. Pilih **"Laporan Laba/Rugi"** atau **"Profit & Loss"**
3. Pilih **Musim Tanam** dari dropdown (atau "Semua Musim")

4. Lihat ringkasan:
   - **Total Pendapatan:** Jumlah semua penjualan
   - **Total Biaya:** Jumlah semua pengeluaran
   - **Laba/Rugi Bersih:** Pendapatan - Biaya
   - **Margin (%):** (Laba/Pendapatan) × 100%

#### **Laporan Target vs Realisasi**

1. Di menu **"Laporan"**, pilih **"Target vs Realisasi"** atau **"Target vs Actual"**
2. Lihat perbandingan:
   - **Target Panen (kg):** Target yang ditetapkan saat musim dibuat
   - **Realisasi Panen (kg):** Total panen yang sudah dicatat
   - **Persentase Capaian:** (Realisasi / Target) × 100%
   - **Status:**
     - 🟢 **Tercapai** (≥ 100%)
     - 🟡 **Hampir** (70% - 99%)
     - 🔴 **Kurang** (< 70%)

#### **Laporan Terintegrasi Hulu + Hilir**

1. Buka menu **"Laporan"**, pilih **"Laporan Terintegrasi"** atau **"Integrated Economic Summary"**
2. Lihat analisis lengkap:

   **Bagian Hulu (Kebun):**
   - Modal Tanam: Rp XXX
   - Nilai Panen Kotor: Rp XXX
   - Laba Bersih Hulu: Rp XXX

   **Bagian Hilir (Produk Olahan):**
   - Bahan Baku (Rp 0): Prinsip Zero Double-Counting
   - Modal Bahan Penolong: Rp XXX
   - Omset Penjualan Olahan: Rp XXX
   - Laba Bersih Hilir: Rp XXX

   **Total Agribisnis Terpadu:**
   - 🎯 **Laba Bersih Total: Rp XXX** (Hulu + Hilir)

---

### 3.8 Melihat Komisi Platform

#### **Riwayat Transaksi Komisi**

1. Buka menu **"Komisi"** atau **"Commission"** (sidebar kiri)
2. Lihat tabel riwayat:
   - **Tanggal Transaksi:** Kapan pesanan selesai
   - **Nomor Pesanan:** Order code (contoh: ORD-20261028-001)
   - **Nilai Transaksi:** Harga total pesanan
   - **Komisi Platform (10%):** Potongan platform
   - **Penerimaan Anda (90%):** Sisa yang masuk ke Anda

#### **Contoh Perhitungan Komisi**

Jika Anda menjual 10 pcs Jamur Crispy @ Rp 5.000:
- **Total Transaksi:** Rp 50.000
- **Komisi Platform 10%:** Rp 5.000
- **Penerimaan Anda 90%:** Rp 45.000

---

### 3.9 TaniBot AI - Asisten Pertanian

#### **Membuka Chat dengan TaniBot**

1. Buka menu **"TaniBot"** atau **"Chatbot"** (sidebar kiri)
2. Ketik pertanyaan tentang pertanian dalam Bahasa Indonesia:
   - "Bagaimana cara mencegah hama pada jamur tiram?"
   - "Pupuk apa yang baik untuk kentang?"
   - "Kapan waktu terbaik menanam cabai?"

3. TaniBot akan memberikan jawaban berdasarkan pengetahuan pertanian

#### **Topik yang Bisa Ditanyakan**

✅ Tips budidaya komoditas  
✅ Penanganan hama dan penyakit  
✅ Rekomendasi pupuk & pestisida  
✅ Manajemen musim tanam  
✅ Penanganan pascapanen

> 🚫 TaniBot **TIDAK** bisa menjawab pertanyaan tentang bisnis/penjualan. Hubungi Super Admin untuk itu.

---

## 4. PANDUAN SUPER ADMIN

### 4.1 Dashboard Super Admin

Setelah login sebagai Super Admin, Anda akan melihat dashboard dengan:
- 📊 **Statistik Petani:** Jumlah aktif, pending, ditolak
- 💰 **Kinerja Penjualan:** Total omset, komisi, rata-rata
- 📋 **Notifikasi:** Pesanan baru, akun pending, stok rendah
- 📈 **Grafik:** Tren penjualan, performa per poktan

---

### 4.2 Verifikasi & Manajemen Akun Petani

#### **Melihat Daftar Akun Pending**

1. Buka menu **"Manajemen Pengguna"** atau **"User Management"** (sidebar kiri)
2. Pilih tab **"Pending"** atau **"Menunggu Verifikasi"**
3. Lihat daftar petani yang baru daftar:
   - Nama lengkap
   - Email
   - Kelompok Tani
   - Tanggal pendaftaran

#### **Menyetujui Akun Petani**

1. Klik akun petani yang ingin disetujui
2. Baca data yang diminta:
   - Email terhubung Google atau email lokal?
   - Poktan sesuai?
   - Data lengkap?

3. Klik tombol **"Setujui"** atau **"Approve"**
4. Petani sekarang **bisa login**

#### **Menolak atau Menonaktifkan Akun**

1. Buka data akun petani
2. Klik **"Tolak"** (jika masih pending) atau **"Nonaktifkan"** (jika sudah aktif)
3. Isi alasan penolakan (opsional)
4. Konfirmasi tindakan

---

### 4.3 Manajemen Harga Pasar (Market Price)

#### **Menambah Harga Pasar Baru**

1. Buka menu **"Master Data"** atau **"Settings"** (sidebar kiri)
2. Pilih **"Harga Pasar"** atau **"Market Price"**
3. Klik **"+ Tambah Harga"** atau **"+ Add Price"**
4. Isi data:
   - **Komoditas:** Pilih dari dropdown (Jamur Tiram, Kentang, dll)
   - **Harga (Rp/kg):** Contoh: 10000
   - **Tanggal Berlaku:** Mulai kapan harga ini berlaku
   - **Sumber (Opsional):** Dari mana data harga (Pasar Tradisional, E-commerce, dll)

5. Klik **"Simpan"**

#### **Update Harga Harian**

1. Buka daftar harga pasar
2. Klik harga yang ingin diubah
3. Ubah nilai di kolom **"Harga"**
4. Update **"Tanggal Berlaku"** jika diperlukan
5. Klik **"Simpan"**

> 💡 **Catatan Penting:**
> - Harga lama tetap tercatat sebagai riwayat historis
> - Perubahan harga **HANYA** berlaku untuk panen baru (panen lama tetap pakai harga saat panen)
> - Ini memastikan evaluasi ekonomi panen akurat sesuai waktu panen

---

### 4.4 Pemrosesan Pesanan & Penjualan

#### **Melihat Pesanan Baru Masuk**

1. Buka menu **"Pesanan"** atau **"Orders"** (sidebar kiri)
2. Filter pesanan berdasarkan status:
   - **Pending:** Baru masuk, belum dikonfirmasi
   - **Confirmed:** Dikonfirmasi, siap proses
   - **Processing:** Sedang dikemas/disiapkan
   - **Completed:** Selesai dikirim
   - **Cancelled:** Dibatalkan

#### **Mengkonfirmasi Pesanan**

1. Buka pesanan dengan status **"Pending"**
2. Lihat detail:
   - Nama pembeli & kontak
   - Daftar produk yang dipesan
   - Total harga
   - Catatan khusus (jika ada)

3. Verifikasi stok produk tersedia
4. Klik **"Konfirmasi Pesanan"** atau **"Confirm Order"**
5. Status berubah menjadi **"Confirmed"**

#### **Menyelesaikan Pesanan (Complete Order)**

1. Setelah barang disiapkan/dikirim, buka pesanan
2. Klik **"Selesaikan Pesanan"** atau **"Complete Order"**
3. Sistem **otomatis**:
   - ✅ Mencatat transaksi penjualan (Sale)
   - ✅ Mengurangi stok produk olahan petani
   - ✅ **Menghitung komisi platform 10%** dari nilai transaksi
   - ✅ Mencatat komisi di database

4. Kirim notifikasi ke petani (penjualan selesai)

#### **Membatalkan Pesanan**

1. Buka pesanan dengan status "Pending" atau "Confirmed"
2. Klik **"Batalkan Pesanan"** atau **"Cancel Order"**
3. Isi alasan pembatalan (opsional)
4. Konfirmasi

> ⚠️ **Pesanan yang sudah `Completed` atau `Cancelled` tidak bisa diubah.**

---

### 4.5 Pencatatan Penjualan Langsung

#### **Merekam Penjualan ke Tengkulak/Pasar**

Jika Petani menjual langsung ke tengkulak (bukan via katalog), Super Admin bisa merekamnya:

1. Buka menu **"Penjualan"** atau **"Sales"** (sidebar kiri)
2. Klik **"+ Tambah Penjualan"** atau **"+ Record Sale"**
3. Isi data:
   - **Petani:** Pilih petani pemilik
   - **Tanggal Penjualan:** Kapan transaksi terjadi
   - **Jenis Produk:** Pilih komoditas/produk olahan
   - **Jumlah (kg atau pcs):** Berapa banyak
   - **Harga (Rp/unit):** Harga jual
   - **Total (Rp):** Otomatis terhitung (Jumlah × Harga)
   - **Pembeli:** Nama pembeli (tengkulak/pasar)
   - **Catatan (Opsional):** Detail transaksi

4. Klik **"Simpan Penjualan"**

#### **Dampak Penjualan pada Stok**

✅ Sistem otomatis:
- Mengurangi stok produk olahan petani
- Mencatat transaksi di riwayat stok
- Jika ada komisi platform, hitung otomatis

---

### 4.6 Manajemen Komisi Platform

#### **Melihat Ringkasan Komisi Agregat**

1. Buka menu **"Komisi"** atau **"Commission"** (sidebar kiri)
2. Pilih **"Ringkasan Komisi"** atau **"Commission Summary"**
3. Lihat data agregat:
   - **Total Transaksi Kotor:** Rp XXX
   - **Komisi Platform 10%:** Rp XXX
   - **Penerimaan Petani 90%:** Rp XXX
   - **Per Petani:** Breakdown komisi masing-masing

#### **Aturan Komisi Platform**

| Item | Nilai |
|------|-------|
| **Basis Komisi** | Total nilai transaksi (Gross) |
| **Persentase** | 10% |
| **Pemicu** | Saat pesanan status "Completed" |
| **Penerima Petani** | 90% dari nilai transaksi |
| **Idempotency** | Komisi dihitung 1x, tidak ada dobel |

---

### 4.7 Laporan Agregat Petani

#### **Melihat Laba/Rugi Semua Petani**

1. Buka menu **"Laporan"** atau **"Reports"** (sidebar kiri)
2. Pilih **"Laba/Rugi Agregat"** atau **"Aggregate Profit & Loss"**
3. Lihat tabel:
   - **Nama Petani**
   - **Poktan**
   - **Total Pendapatan**
   - **Total Biaya**
   - **Laba/Rugi Bersih**
   - **Margin (%)**

4. Klik nama petani untuk drill-down ke detail musim

#### **Melihat Target vs Realisasi Semua Petani**

1. Di menu **"Laporan"**, pilih **"Target vs Realisasi Agregat"** atau **"Target vs Actual (All)"**
2. Lihat grafik & tabel:
   - Perbandingan target vs realisasi per petani
   - Identifikasi petani dengan performa di bawah target
   - Siapa yang perlu bimbingan/intervensi

---

### 4.8 Manajemen Berita & Landing Page

#### **Menambah Berita Terbaru**

1. Buka menu **"Berita"** atau **"News"** (sidebar kiri)
2. Klik **"+ Tambah Berita"** atau **"+ New Article"**
3. Isi konten:
   - **Judul:** Contoh: "Tips Merawat Jamur Tiram di Musim Hujan"
   - **Isi/Konten:** Deskripsi lengkap (bisa pakai text editor)
   - **Gambar (Opsional):** Upload thumbnail
   - **Kategori (Opsional):** Pilihan (Tips, Berita, Promo, dll)

4. Klik **"Publikasikan"** atau **"Publish"**

#### **Mengedit Landing Page Publik**

1. Buka menu **"Pengaturan Landing"** atau **"Landing Settings"**
2. Edit konten:
   - **Judul Halaman Utama**
   - **Deskripsi Program PKM**
   - **Foto Hero** (banner besar di atas)
   - **Daftar Poktan yang Ditampilkan**

3. Klik **"Simpan"**
4. Terbuka di halaman publik: `http://localhost/` (tanpa login)

---

### 4.9 TaniBot AI - Asisten Bisnis

#### **Membuka Chat TaniBot untuk Admin**

1. Buka menu **"TaniBot Admin"** atau **"Chatbot (Business)"** (sidebar kiri)
2. Ketik pertanyaan tentang bisnis/operasional platform:
   - "Berapa total omset penjualan bulan ini?"
   - "Poktan mana yang paling banyak menjual?"
   - "Siapa petani dengan laba terbesar?"
   - "Berapa total komisi yang terkumpul?"

3. TaniBot akan analisis data & berikan insight

#### **Topik yang Bisa Ditanyakan**

✅ Statistik penjualan & omset  
✅ Performa per petani / poktan  
✅ Analisis komisi platform  
✅ Tren stok & pesanan  
✅ Rekomendasi strategi pemasaran  

> 🚫 TaniBot **TIDAK** bisa menjawab pertanyaan teknis sistem. Hubungi developer untuk itu.

---

## 5. FITUR LANJUTAN

### 5.1 Pengaturan Profil & Keamanan

#### **Mengubah Profil Pribadi (Petani)**

1. Buka menu **"Profil"** atau **"Settings"** (klik avatar di atas kanan)
2. Pilih **"Edit Profil"**
3. Ubah data:
   - Nama lengkap
   - Nomor telepon
   - Nama kebun/lahan
   - Foto profil (opsional)

4. Klik **"Simpan Perubahan"**

#### **Mengubah Password**

1. Di menu **"Profil"** / **"Settings"**, pilih **"Ubah Password"** atau **"Change Password"**
2. Isi:
   - **Password Lama:** Password saat ini
   - **Password Baru:** Password baru (min 8 karakter, campur huruf+angka)
   - **Konfirmasi Password Baru:** Ulangi password baru

3. Klik **"Ubah Password"**

#### **Logout**

1. Buka menu profil (klik avatar)
2. Klik **"Logout"** atau **"Keluar"**
3. Anda akan diarahkan ke halaman login

---

### 5.2 Ekspor Data ke Excel/PDF

#### **Ekspor Laporan Laba/Rugi ke Excel**

1. Buka menu **"Laporan"** > **"Laporan Laba/Rugi"**
2. Pilih musim tanam (atau "Semua")
3. Klik tombol **"📥 Ekspor ke Excel"** atau **"Export to Excel"**
4. File `.xlsx` otomatis terunduh ke komputer Anda

#### **Ekspor Laporan Target vs Realisasi ke PDF**

1. Buka menu **"Laporan"** > **"Target vs Realisasi"**
2. Klik tombol **"📥 Ekspor ke PDF"** atau **"Export to PDF"**
3. File `.pdf` terbuka di browser atau terunduh

> 💡 Gunakan untuk presentasi kepada stakeholder atau arsip kertas.

---

### 5.3 Notifikasi & Alert

#### **Jenis Notifikasi**

| Notifikasi | Dikirim Kepada | Kondisi |
|-----------|----------------|---------|
| 🔔 Stok Rendah | Petani | Stok panen jatuh di bawah 100 kg |
| 📩 Pesanan Baru | Super Admin | Ada pesanan katalog masuk |
| ✅ Akun Disetujui | Petani | Super Admin approve akun pending |
| 💰 Penjualan Selesai | Petani | Pesanan dinyatakan completed |
| 🚨 Stok Habis | Super Admin | Produk olahan stok = 0 |

#### **Mengatur Notifikasi (Opsional)**

1. Buka menu **"Pengaturan"** > **"Notifikasi"** atau **"Notification Settings"**
2. Pilih notifikasi yang ingin diterima/dimatikan
3. Klik **"Simpan"**

---

## 6. TROUBLESHOOTING & FAQ

### ❓ Pertanyaan Umum (FAQ)

#### **Q1: Saya baru daftar, tapi tidak bisa login?**

**A:** Akun Anda sedang menunggu persetujuan Super Admin. Silakan hubungi Super Admin dan minta approval. Setelah disetujui, coba login lagi.

---

#### **Q2: Bagaimana cara reset password jika lupa?**

**A:** 
1. Di halaman login, klik **"Lupa Password?"** atau **"Forgot Password?"**
2. Masukkan email Anda
3. Cek email untuk link reset
4. Ikuti instruksi di email untuk buat password baru

---

#### **Q3: Biaya bahan baku produk olahan kok Rp 0? Apa itu benar?**

**A:** **Ya, itu benar!** Ini adalah prinsip **"Zero Double-Counting"**. Jika Anda sudah bayar modal tanam Rp 200.000 untuk panen 30 kg, maka 15 kg yang dialihkan ke produk olahan **tidak dihitung lagi sebagai pengeluaran kas baru**. Yang dicatat hanya **biaya tambahan real** (tepung, minyak, kemasan, dll). Ini memastikan perhitungan laba/rugi akurat.

---

#### **Q4: Kenapa harga panen berubah-ubah?**

**A:** Harga yang ditampilkan adalah **snapshot harga pasar** yang berlaku pada **tanggal panen**. Super Admin memperbarui master harga pasar secara berkala. Perubahan harga **tidak** mengubah nilai panen lama (riwayat tetap).

---

#### **Q5: Bagaimana caranya melihat stok produk olahan real-time?**

**A:** 
1. Buka menu **"Produk Olahan"** (untuk Petani)
2. Lihat kolom **"Stok"** di setiap produk
3. Atau buka menu **"Stok Gudang"** untuk lihat riwayat pergerakan stok detail

---

#### **Q6: Apakah TaniBot bisa menjawab soal penjualan/bisnis?**

**A:** 
- **Untuk Petani:** TaniBot fokus pertanian saja (budidaya, hama, pupuk). Pertanyaan bisnis hubungi Super Admin.
- **Untuk Super Admin:** TaniBot bisa menjawab soal bisnis/operasional platform (omset, komisi, performa).

---

#### **Q7: Bisa kah pesanan dibatalkan setelah status Completed?**

**A:** **Tidak.** Pesanan dengan status `Completed` atau `Cancelled` bersifat **terminal** (final), tidak bisa diubah. Jika ada kesalahan, hubungi Super Admin untuk investigasi & tindak lanjut manual.

---

#### **Q8: Komisi 10% dihitung dari apa?**

**A:** Komisi dihitung dari **total nilai transaksi kotor** (Gross Amount). Contoh:
- Penjualan 10 pcs @ Rp 5.000 = Rp 50.000
- Komisi 10% = Rp 5.000
- Petani terima = Rp 45.000 (90%)

---

### 🐛 Troubleshooting Umum

#### **Masalah: Login tidak bisa, error "Email belum terdaftar"**

**Solusi:**
1. Pastikan email yang digunakan **benar dan sesuai akun Google**
2. Jika baru daftar, tunggu persetujuan Super Admin
3. Jika sudah lama, hubungi Super Admin untuk cek status akun

---

#### **Masalah: Foto panen tidak bisa diupload**

**Solusi:**
1. Pastikan file gambar **format JPG/PNG**
2. Ukuran file **max 5 MB**
3. Coba dengan browser berbeda (Chrome, Firefox, Edge)
4. Bersihkan cache browser (Ctrl+Shift+Delete) & coba lagi

---

#### **Masalah: Stok gudang angka tidak sesuai dengan perhitungan manual**

**Solusi:**
1. Buka menu **"Stok Gudang"** & lihat **riwayat detail** transaksi
2. Verifikasi setiap transaksi: panen +, konversi -, penjualan -
3. Jika ada discrepancy, hubungi Super Admin

---

#### **Masalah: Laporan laba/rugi angkanya tidak cocok**

**Solusi:**
1. Verifikasi **semua biaya produksi sudah tercatat** (Bibit, Pupuk, Pestisida, Lainnya)
2. Verifikasi **semua penjualan sudah tercatat** (langsung atau via katalog)
3. Jika musim terpilih berbeda dari harapan, coba pilih musim yang tepat
4. Hubungi Super Admin jika masih tidak cocok

---

#### **Masalah: Aplikasi lambat / lag**

**Solusi:**
1. Pastikan koneksi internet stabil
2. Refresh halaman (Ctrl+R / Cmd+R)
3. Coba dengan browser berbeda
4. Jika tetap lambat, hubungi developer/admin sistem

---

### 📞 Hubungi Kami

Jika mengalami masalah atau pertanyaan lanjutan:

- **Email Support:** support@sumbertani.ai
- **WhatsApp Super Admin:** [Nomor yang ditampilkan di dashboard]
- **Forum Komunitas Poktan:** [Link grup WhatsApp/Telegram]

---

## Lampiran: Referensi Cepat

### **Shortcut Menu Penting**

| Menu | Petani | Super Admin |
|------|--------|------------|
| Dashboard | ✅ | ✅ |
| Musim Tanam | ✅ | 👁️ |
| Biaya Produksi | ✅ | 👁️ |
| Panen | ✅ | 👁️ |
| Stok Gudang | ✅ | 👁️ |
| Produk Olahan | ✅ | ✅ Kelola |
| Konversi Panen | ✅ | ❌ |
| Pesanan | 👁️ | ✅ Proses |
| Penjualan | ❌ | ✅ |
| Komisi | ✅ Lihat | ✅ Kelola |
| Laporan | ✅ | ✅ Agregat |
| TaniBot | ✅ Pertanian | ✅ Bisnis |
| Verifikasi Akun | ❌ | ✅ |
| Harga Pasar | ❌ | ✅ |
| Berita & Landing | ❌ | ✅ |

### **Daftar Kategori Biaya**

| Kode | Kategori | Warna | Contoh |
|------|----------|-------|--------|
| 1 | 🟢 Bibit | Hijau Tua | Benih jamur, bibit kentang |
| 2 | 🟢 Pupuk | Hijau | Pupuk organik, kompos |
| 3 | 🔴 Pestisida | Merah | Obat hama, fungisida |
| 4 | ⚫ Lainnya | Abu-abu | Sewa alat, tenaga kerja, bensin |

### **Rumus Perhitungan Cepat**

```
Laba/Rugi Musim = Total Penjualan - Total Biaya

Laba/Rugi Produk Olahan = (Omset Penjualan Olahan) - (Biaya Bahan Penolong)
                          (Bahan baku Panen = Rp 0 per Zero Double-Counting)

Laba Agribisnis Terpadu = (Laba Hulu) + (Laba Hilir)

Komisi Platform = 10% × Total Nilai Transaksi Kotor
Penerimaan Petani = 90% × Total Nilai Transaksi Kotor

Capaian Target = (Panen Realisasi / Target Panen) × 100%
```

---

**© 2026 SumberTani Platform. Semua hak dilindungi.**

Panduan ini berlaku efektif mulai 28 Oktober 2026 dan dapat diperbarui sewaktu-waktu.
