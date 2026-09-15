<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ChatbotController extends Controller
{
    // Daftar jawaban manual berdasarkan kata kunci (keyword)
    private array $responses = [
        // Cara mencatat panen
        ['keywords' => ['catat panen', 'pencatatan panen', 'input panen', 'rekam panen', 'tambah panen'],
         'reply' => "🌾 Cara Mencatat Panen:\n\n1. Buka menu Pencatatan Panen di sidebar\n2. Tekan tombol Catat Panen (hijau)\n3. Isi formulir: pilih Musim Tanam, masukkan Tanggal, Berat (kg), dan Keterangan\n4. Tekan Simpan\n\nData panen Anda akan langsung tercatat dan terlihat di daftar! ✅"],

        // Musim tanam
        ['keywords' => ['musim tanam', 'tambah musim', 'buat musim', 'musim baru', 'periode tanam'],
         'reply' => "🌱 Cara Mengatur Musim Tanam:\n\n1. Buka menu Musim Tanam di sidebar\n2. Tekan tombol Tambah Musim Tanam\n3. Isi nama musim, tanggal mulai, dan target panen (opsional)\n4. Tekan Simpan\n\nMusim tanam yang aktif akan otomatis muncul sebagai pilihan saat mencatat panen! 📅"],

        // Stok gudang
        ['keywords' => ['stok', 'gudang', 'stok masuk', 'stok keluar', 'tambah stok', 'pantau stok', 'barang masuk', 'barang keluar'],
         'reply' => "📦 Cara Menggunakan Stok Gudang:\n\n- Stok Masuk: Buka menu Stok → Tekan Stok Masuk → Isi jumlah dan keterangan\n- Stok Keluar: Buka menu Stok → Tekan Stok Keluar → Isi jumlah dan tujuan\n- Saldo stok dihitung otomatis secara real-time\n\nAnda bisa memantau total stok saat ini dari halaman Stok Gudang! 📊"],

        // Penjualan
        ['keywords' => ['penjualan', 'catat jual', 'tambah penjualan', 'transaksi', 'jual kentang', 'pembeli', 'catat transaksi'],
         'reply' => "💰 Cara Mencatat Penjualan:\n\n1. Buka menu Penjualan di sidebar\n2. Tekan tombol Tambah Penjualan\n3. Isi data: Pembeli, Jumlah (kg), Harga per kg, Tanggal\n4. Status bisa diatur menjadi Lunas atau Belum Lunas\n5. Tekan Simpan\n\nTotal penjualan akan otomatis terhitung! 🛒"],

        // Laporan
        ['keywords' => ['laporan', 'untung', 'rugi', 'laba', 'laporan keuangan', 'keuntungan', 'profit', 'target', 'realisasi'],
         'reply' => "📈 Cara Melihat Laporan:\n\n- Laporan Untung/Rugi: Buka menu Laporan → pilih tab Laba Rugi\n- Target vs Realisasi: Buka menu Laporan → pilih tab Target vs Realisasi\n- Anda bisa filter berdasarkan Musim Tanam\n- Tersedia opsi Export ke PDF atau Excel\n\nGunakan laporan ini untuk keputusan pertanian yang lebih cerdas! 📊"],

        // Biaya produksi
        ['keywords' => ['biaya', 'pengeluaran', 'catat biaya', 'tambah biaya', 'biaya produksi', 'ongkos'],
         'reply' => "💸 Cara Mencatat Biaya Produksi:\n\n1. Buka menu Biaya Produksi di sidebar\n2. Tekan tombol Tambah Biaya\n3. Pilih Kategori (Pupuk, Pestisida, Tenaga Kerja, dll)\n4. Masukkan nominal dan keterangan\n5. Tekan Simpan\n\nBiaya ini akan otomatis terhitung dalam laporan untung/rugi Anda! 💡"],

        // Profil dan pengaturan
        ['keywords' => ['profil', 'pengaturan', 'setting', 'ubah nama', 'ubah password', 'ganti password', 'akun', 'edit profil'],
         'reply' => "⚙️ Cara Mengubah Profil/Pengaturan:\n\n- Edit Profil: Buka menu Profil → tekan tombol Edit → ubah nama atau email\n- Ganti Password: Buka menu Pengaturan → pilih Ubah Password\n- Notifikasi: Buka Pengaturan → atur preferensi notifikasi\n\nAkun Anda aman dan data Anda terenkripsi! 🔒"],

        // Salam
        ['keywords' => ['halo', 'hai', 'hello', 'hi', 'hei', 'selamat'],
         'reply' => "Halo! 👋 Saya KAI, asisten digital SIMHPSK.\n\nSaya siap membantu Anda mengelola aplikasi pertanian kentang. Apa yang ingin Anda tanyakan?\n\n💡 Contoh pertanyaan:\n- Bagaimana cara mencatat panen?\n- Cara melihat laporan untung rugi?\n- Cara menambah musim tanam baru?"],

        // Tentang aplikasi
        ['keywords' => ['simhpsk', 'aplikasi', 'tentang', 'fitur', 'apa ini', 'apa itu', 'apk'],
         'reply' => "📱 Tentang SIMHPSK:\n\nSIMHPSK adalah Sistem Informasi Manajemen Hasil Panen dan Stok Kentang yang dirancang khusus untuk petani kentang Indonesia.\n\nFitur Utama:\n🌱 Musim Tanam\n🚜 Pencatatan Panen\n📦 Stok Gudang\n💰 Penjualan\n📊 Biaya Produksi\n📈 Laporan Keuangan\n\nSemua fitur GRATIS dan data Anda aman! 🔒"],

        // Terima kasih
        ['keywords' => ['terima kasih', 'makasih', 'thanks', 'terimakasih', 'mantap', 'bagus'],
         'reply' => "Sama-sama! 😊 Senang bisa membantu Anda.\n\nJika ada pertanyaan lain seputar aplikasi SIMHPSK atau budidaya kentang, jangan sungkan untuk bertanya ya! 🌾"],
    ];

    public function chat(Request $request)
    {
        $request->validate([
            'message' => 'required|string',
        ]);

        $userMessage = strtolower(trim($request->message));
        $reply = $this->findReply($userMessage);

        return response()->json(['reply' => $reply]);
    }

    private function findReply(string $message): string
    {
        // Cari jawaban berdasarkan keyword
        foreach ($this->responses as $item) {
            foreach ($item['keywords'] as $keyword) {
                if (str_contains($message, $keyword)) {
                    return $item['reply'];
                }
            }
        }

        // Jawaban default jika tidak ada keyword yang cocok
        return "Maaf, saya belum paham pertanyaan Anda. 🤔\n\nCoba tanyakan salah satu dari ini:\n\n• Cara mencatat panen\n• Cara menambah musim tanam\n• Cara memantau stok gudang\n• Cara mencatat penjualan\n• Cara melihat laporan\n• Cara mencatat biaya produksi\n\nAtau ketik halo untuk melihat panduan umum! 🌾";
    }
}