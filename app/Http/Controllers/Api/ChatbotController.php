<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatbotController extends Controller
{
    use ApiResponseTrait;

    // Knowledge base asisten operasional Super Admin SumberTani berbasis AI
    private array $responses = [
        // Pemasaran & Katalog
        [
            'keywords' => ['pemasaran', 'katalog', 'produk olahan', 'jual olahan', 'olahan', 'marketing'],
            'reply' => "📦 Manajemen Pemasaran & Katalog Produk Olahan:\n\n1. Buka menu 'Manajemen Pemasaran' pada dashboard Super Admin.\n2. Anda dapat melihat seluruh produk olahan yang didaftarkan petani beserta pemilik, harga, dan sisa stok.\n3. Anda dapat mengaktifkan/menonaktifkan (toggle status) produk untuk tampil di Katalog Publik.\n4. Calon pembeli dapat melihat produk yang berstatus 'active' atau 'out_of_stock' pada katalog web dan memesan langsung melalui kontak WhatsApp Super Admin! 🛒"
        ],

        // Penjualan Terpusat
        [
            'keywords' => ['penjualan', 'catat penjualan', 'transaksi', 'proses pesanan', 'order', 'pesanan'],
            'reply' => "💰 Panduan Penjualan Terpusat Super Admin:\n\n1. Seluruh pencatatan penjualan dipusatkan di Super Admin.\n2. Buka menu 'Penjualan' → Tekan 'Catat Penjualan'.\n3. Pilih Jenis Penjualan:\n   - Hasil Panen: pilih petani pemilik, masukkan berat (kg), harga, dan pembeli.\n   - Produk Olahan: pilih produk olahan, masukkan jumlah unit, harga, dan pembeli.\n4. Stok akan otomatis berkurang secara atomik pada inventori petani yang bersangkutan! ✅"
        ],

        // Agregat Laba / Rugi
        [
            'keywords' => ['laba', 'rugi', 'profit', 'laporan', 'keuangan', 'agregat', 'pendapatan', 'biaya'],
            'reply' => "📈 Agregat Laba / Rugi Seluruh Petani:\n\n- Formula perhitungan baku: Total Pendapatan Petani - Total Biaya Produksi.\n- Super Admin dapat memantau ringkasan finansial gabungan seluruh mitra tani binaan.\n- Buka menu 'Laba / Rugi Agregat' untuk melihat rincian per petani, pendapatan kotor, pengeluaran, dan net profit/loss.\n- Data dapat difilter berdasarkan rentang tanggal tertentu! 📊"
        ],

        // Kelola Pengguna & Petani
        [
            'keywords' => ['petani', 'user', 'pengguna', 'kelola user', 'tambah petani', 'akun', 'impersonasi'],
            'reply' => "👥 Manajemen Akun Petani & Pengguna:\n\n1. Buka menu 'Kelola Pengguna' di Super Admin.\n2. Anda dapat menambah akun petani baru, mengaktifkan/menonaktifkan akun, atau mereset kata sandi.\n3. Fitur Impersonasi memungkinkan Super Admin masuk ke sudut pandang akun petani untuk membantu pendampingan operasional secara langsung. 🔒"
        ],

        // Stok & Gudang
        [
            'keywords' => ['stok', 'gudang', 'persediaan', 'sisa stok', 'out of stock'],
            'reply' => "🏬 Monitoring Stok & Persediaan:\n\n- Stok Komoditas Mentah: bersumber dari catatan panen dan transaksi stok gudang petani.\n- Stok Produk Olahan: bersumber langsung dari data produk olahan petani (single source of truth).\n- Ketika stok produk olahan mencapai 0, sistem secara otomatis mengubah status menjadi 'out_of_stock'.\n- Stok bertambah kembali saat petani melakukan restock melalui aplikasi! 📦"
        ],

        // WhatsApp Order & Integrasi
        [
            'keywords' => ['whatsapp', 'wa', 'nomor wa', 'pesan wa', 'checkout'],
            'reply' => "💬 Mekanisme Pesanan via WhatsApp:\n\n- Tombol pesan di katalog publik secara dinamis mengarah ke nomor WhatsApp Super Admin (berdasarkan User.phone akun super_admin).\n- WhatsApp berfungsi sebagai media komunikasi/order intent langsung, bukan sistem integrasi backend otomatis.\n- Stok tidak akan berkurang saat link WhatsApp diklik. Stok baru berkurang setelah Super Admin memproses dan mencatat penjualan di sistem! 📲"
        ],

        // Salam & Bantuan Operasional
        [
            'keywords' => ['halo', 'hai', 'hello', 'hi', 'bantuan', 'menu', 'panduan'],
            'reply' => "Halo! 👋 Saya TaniBot AI, asisten operasional Super Admin untuk SumberTani berbasis AI.\n\nSaya siap membantu Anda mengelola ekosistem pertanian terintegrasi. Topik yang dapat Anda tanyakan:\n\n• Manajemen Pemasaran & Katalog Produk Olahan\n• Pencatatan Penjualan Terpusat (Panen & Olahan)\n• Laporan Agregat Laba / Rugi Seluruh Petani\n• Pengelolaan Data Akun Petani\n• Alur Pemesanan via WhatsApp Super Admin 🌾"
        ],

        // Tentang Platform SumberTani berbasis AI
        [
            'keywords' => ['sumbertani', 'simhpsk', 'tentang', 'aplikasi', 'platform', 'ai'],
            'reply' => "🌱 Tentang SumberTani berbasis AI:\n\nSumberTani berbasis AI (PKM-Kosabangsa) adalah platform terpadu hilirisasi dan digitalisasi pertanian.\n\nPeran Utama Super Admin:\n1. Memasarkan produk olahan petani ke pasar yang lebih luas.\n2. Menangani pemesanan dan pencatatan transaksi penjualan secara terpusat.\n3. Memantau kesehatan finansial seluruh petani melalui agregat laba/rugi.\n4. Mendukung produktivitas dan kesejahteraan komunitas tani lokal! 🌟"
        ],

        // Terima kasih
        [
            'keywords' => ['terima kasih', 'makasih', 'thanks', 'terimakasih', 'sip', 'mantap'],
            'reply' => "Sama-sama! 😊 Senang bisa membantu operasional Super Admin SumberTani berbasis AI. Sukses selalu untuk pertanian Indonesia! 🌾"
        ],
    ];

    public function chat(Request $request): JsonResponse
    {
        $request->validate([
            'message' => 'required|string|max:1000',
        ]);

        $userMessage = strtolower(trim($request->input('message')));
        $reply = $this->findReply($userMessage);

        return response()->json([
            'success' => true,
            'reply'   => $reply,
            'message' => $reply, // For flexible client consumption
        ]);
    }

    private function findReply(string $message): string
    {
        foreach ($this->responses as $item) {
            foreach ($item['keywords'] as $keyword) {
                if (str_contains($message, $keyword)) {
                    return $item['reply'];
                }
            }
        }

        return "Mohon maaf, saya belum memahami pertanyaan tersebut. 🤔\n\nSebagai asisten operasional Super Admin SumberTani berbasis AI, Anda dapat menanyakan tentang:\n• Manajemen pemasaran & katalog\n• Pencatatan penjualan (panen/olahan)\n• Agregat laba rugi seluruh petani\n• Kelola akun petani\n• Konfigurasi pesanan WhatsApp\n\nKetik 'halo' untuk melihat ringkasan panduan! 🌾";
    }
}