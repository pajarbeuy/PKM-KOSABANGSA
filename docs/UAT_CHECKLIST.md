# Checklist UAT (User Acceptance Testing) End-to-End

**Proyek:** SumberTani berbasis AI  
**Dokumen:** `docs/UAT_CHECKLIST.md`  
**Status:** Verification Baseline & Future QA Guide  
**Terakhir Diperbarui:** 21 September 2026  

---

## 🎯 Panduan & Lingkungan UAT

- **URL Web/API:** `http://localhost:8000` (atau port web server lokal Laravel).
- **Aplikasi Klien:** Flutter Web/Desktop / Android Emulator.
- **Akun Pengujian:**
  - Akun Petani: `admin@simhpsk.com` (Role: Petani / Farm Admin).
  - Akun Super Admin: `superadmin@simhpsk.com` (Role: Super Admin).

---

## 📋 Skenario Pengujian Fungsional

### Skenario 1 — Verifikasi Kategori Biaya Produksi (BUG-001)
| Langkah Pengujian | Hasil yang Diharapkan | Status |
|---|---|---|
| 1. Buka menu **Biaya Produksi** sebagai Petani | Tampil 4 kategori resmi: Bibit, Pupuk, Pestisida, Lainnya | [x] PASSED |
| 2. Tambah biaya baru dengan kategori "Bibit" (Rp50.000) | Entri tersimpan, progres bar bertambah sesuai porsi | [x] PASSED |
| 3. Tambah biaya baru dengan kategori "Lainnya" (Rp20.000) | Entri tersimpan di kategori Lainnya, tidak ada error | [x] PASSED |
| 4. Periksa ringkasan grafik kategori biaya | Tidak muncul artifak kategori 'equipment' atau 'transport' | [x] PASSED |

---

### Skenario 2 — Transisi Status Otomatis Musim Tanam (BUG-002)
| Langkah Pengujian | Hasil yang Diharapkan | Status |
|---|---|---|
| 1. Buat musim tanam baru dengan rentang tanggal hari ini | Status otomatis berbadge hijau: `Aktif` | [x] PASSED |
| 2. Buat musim tanam dengan rentang tanggal bulan lalu | Status otomatis berbadge abu-abu: `Selesai` | [x] PASSED |
| 3. Buat musim tanam dengan tanggal mulai minggu depan | Status otomatis berbadge kuning: `Belum Dimulai` | [x] PASSED |
| 4. Ubah status musim menjadi `cancelled` | Badge merah: `Dibatalkan`. Tidak ditimpa oleh tanggal | [x] PASSED |
| 5. Buka Dashboard utama | Target panen hanya menampilkan musim aktif non-cancelled | [x] PASSED |

---

### Skenario 3 — Mutasi Stok Saat Edit Penjualan (BUG-003)
| Langkah Pengujian | Hasil yang Diharapkan | Status |
|---|---|---|
| 1. Catat panen sebesar 2.000 kg | Saldo stok gudang menjadi 2.000 kg | [x] PASSED |
| 2. Catat penjualan sebesar 200 kg | Saldo stok gudang menjadi 1.800 kg (tercatat transaksi keluar 200 kg) | [x] PASSED |
| 3. Edit transaksi penjualan: ubah bobot dari 200 kg menjadi 300 kg | Stok berkurang 100 kg lagi → Saldo menjadi 1.700 kg | [x] PASSED |
| 4. Edit transaksi penjualan: ubah bobot dari 300 kg menjadi 150 kg | Stok bertambah kembali 150 kg → Saldo menjadi 1.850 kg | [x] PASSED |
| 5. Cek tabel Riwayat Transaksi Stok | Seluruh penyesuaian delta tercatat akurat dan konsisten | [x] PASSED |

---

### Skenario 4 — Integritas Generalisasi "Kentang → Hasil Tani" (P2-A)
| Langkah Pengujian | Hasil yang Diharapkan | Status |
|---|---|---|
| 1. Buka form Tambah Panen | Tidak ada field input dummy 'Komoditas' berisikan 'Kentang' | [x] PASSED |
| 2. Buka tabel Riwayat Pencatatan Panen | Tidak ada badge hardcoded 'Kentang' | [x] PASSED |
| 3. Buka Landing Page Publik | Fallback judul & fitur menggunakan istilah hasil pertanian umum | [x] PASSED |
| 4. Buka unduhan PDF Laba Rugi & Target | Dokumen bersih dari residual penyebutan sistem kentang | [x] PASSED |

---

### Skenario 5 — Tampilan Grafik Dashboard & Realisasi Target Panen
| Langkah Pengujian | Hasil yang Diharapkan | Status |
|---|---|---|
| 1. Buka Dashboard, hover pada titik bulan Agustus (Panen 2.000 kg, Jual 0 kg) | Tooltip menampilkan murni `Panen: 2.000 kg` dan `Penjualan: 0 kg` tanpa persen semu | [x] PASSED |
| 2. Buka layar Musim Tanam | Kolom `TOTAL PANEN` menampilkan `2.000 kg` (bukan 0 kg) | [x] PASSED |
| 3. Buka layar Target Panen | Realisasi menampilkan `2.000 kg`, progress bar terisi 100%, teks persentase menunjukkan pencapaian nyata (1.000%) | [x] PASSED |

---

### Skenario 6 — Fitur Baru PKM (SumberTani berbasis AI)
| Langkah Pengujian | Hasil yang Diharapkan | Status |
|---|---|---|
| 1. Login Petani: Akses menu Produk Olahan | Petani dapat menambah & mengedit produk olahan miliknya sendiri dengan proteksi stok | [x] PASSED |
| 2. Akses Landing Page Publik `#katalog` | Tampil kartu produk olahan petani aktif, produk stok 0 bertanda badge "Stok Habis" | [x] PASSED |
| 3. Klik "Pesan via WhatsApp" di Katalog | Mengarah ke link WhatsApp Super Admin dengan pesan pemesanan terformat, stok TIDAK berkurang saat klik | [x] PASSED |
| 4. Login Super Admin: Catat Penjualan Pesanan | Super Admin mencatat penjualan terpusat, stok produk olahan petani berkurang secara atomik | [x] PASSED |
| 5. Login Super Admin: Buka Laba/Rugi Agregat | Menampilkan total agregat omset, biaya produksi, dan laba/rugi bersih seluruh petani sesuai formula | [x] PASSED |
| 6. Login Super Admin: Akses TaniBot AI | Chatbot operasional merespons pertanyaan panduan pemasaran, stok petani, dan manajemen platform | [x] PASSED |
| 7. Login Petani: Periksa sidebar & bottom nav | Menu Produk Olahan tampil; menu Penjualan & Chatbot dialihkan/terpusat pada Super Admin | [x] PASSED |
