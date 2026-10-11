<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ChatbotDataQueryService;
use App\Services\OpenRouterService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatbotController extends Controller
{
    use ApiResponseTrait;

    protected OpenRouterService $openRouterService;
    protected ChatbotDataQueryService $dataQueryService;

    public function __construct(
        OpenRouterService $openRouterService,
        ChatbotDataQueryService $dataQueryService
    ) {
        $this->openRouterService = $openRouterService;
        $this->dataQueryService  = $dataQueryService;
    }

    /**
     * Knowledge Base Khusus Petani (Agronomi, Budidaya, Hama, Modal Hulu).
     */
    private array $farmerKnowledgeBase = [
        [
            'keywords' => ['hawar daun', 'phytophthora', 'busuk daun', 'hama', 'penyakit', 'ulat', 'fusarium', 'layu'],
            'reply'    => "🌱 **Panduan Agronomi & Pengendalian Hama:**\n\n• **Hawar Daun (Phytophthora infestans):** Lakukan sanitasi lahan dan atur jarak tanam agar kelembapan terjaga. Jika terserang, gunakan fungisida kontak berbahan aktif mankozeb secara teratur, atau fungisida sistemik berbahan simoksanil/dimetomorf jika serangan meluas.\n• **Pestisida Ramah Lingkungan:** Semprotkan pestisida nabati (ekstrak daun nimba/bawang putih) pada fase awal pencegahan.\n• **Peringatan Aman:** Selalu baca label resmi kemasan pestisida dan konsultasikan dengan penyuluh pertanian setempat sebelum aplikasi kimia dosis tinggi.",
        ],
        [
            'keywords' => ['pupuk', 'poc', 'pemupukan', 'kompos', 'urea', 'npk', 'pupuk organik cair'],
            'reply'    => "🌿 **Panduan Pemupukan & Efisiensi Modal Kebun:**\n\n• **Pemupukan Dasar:** Berikan pupuk kandang matang/kompos (10-20 ton/ha) dan pupuk anorganik dasar (SP-36/NPK) saat olah tanah.\n• **Pupuk Organik Cair (POC):** Fermentasi urin sapi/kambing atau limbah hijauan dengan EM4 selama 14-21 hari. Encerkan dengan perbandingan 1:10 untuk menekan biaya pupuk sintetis hingga 30%.\n• **Aplikasi:** Semprotkan POC pada pagi hari (pukul 07.00-09.00) saat stomata daun terbuka optimal.",
        ],
        [
            'keywords' => ['jamur tiram', 'baglog', 'kumbung', 'trichoderma', 'sterilisasi'],
            'reply'    => "🍄 **Panduan Budidaya Jamur Tiram:**\n\n• **Sterilisasi Media (Baglog):** Panaskan baglog pada suhu 95-100°C selama 7-8 jam tanpa henti untuk membunuh spora jamur kompetitor liar.\n• **Pencegahan Kontaminasi Jamur Hijau (Trichoderma):** Semprotkan alkohol 70% pada tangan dan alat inokulasi, serta jaga sirkulasi udara dan kelembapan kumbung di kisaran 80-90%.\n• **Pascapanen:** Cabut jamur hingga ke pangkal akar agar media siap untuk penumbuhan flush berikutnya.",
        ],
        [
            'keywords' => ['zero double counting', 'double counting', 'modal olahan', 'konversi', 'bebas biaya ganda'],
            'reply'    => "🍳 **Prinsip Bebas Biaya Ganda (Zero Double-Counting):**\n\n1. Jika Anda mengolah hasil panen kebun sendiri menjadi produk olahan (keripik kentang/jamur crispy), bahan mentah dicatat bernilai kas **Rp 0** pada modal olahan.\n2. Biaya bibit, pupuk, dan perawatan sudah tercatat di pos **modal tanam hulu** (kebun), sehingga tidak boleh dihitung dua kali.\n3. Anda hanya perlu mencatat biaya bahan penolong tambahan (minyak goreng, tepung, bumbu, kemasan standing pouch, gas elpiji).\n4. Hasilnya: Laba Hulu (Kebun) dan Laba Hilir (Olahan) tercatat transparan dan akurat!",
        ],
        [
            'keywords' => ['hak bersih', 'bagi hasil', '97%', 'penjualan olahan', 'pendapatan petani'],
            'reply'    => "🤝 **Hak Bagi Hasil Penjualan Produk Petani:**\n\n• Pada setiap transaksi produk olahan yang berhasil diselesaikan melalui platform SumberTani, petani menerima **97.00% pendapatan bersih**.\n• Potongan komisi platform sebesar **3.00%** dialokasikan secara transparan untuk biaya operasional platform dan kas desa (BUMDes).",
        ],
    ];

    /**
     * Knowledge Base Khusus Super Admin / BUMDes (Bisnis, Katalog, Pesanan, Rantai Pasok).
     */
    private array $superAdminKnowledgeBase = [
        [
            'keywords' => ['harga', 'analisis harga', 'harga acuan', 'harga pasar', 'pasar komoditas', 'harga komoditas', 'tren harga'],
            'reply'    => "📊 **Analisis Harga Acuan Pasar Komoditas BUMDes:**\n\n1. **Fungsi Acuan Harga di BUMDes:**\n   • Menu **Harga Acuan Pasar** digunakan sebagai patokan harga serapan panen dari petani mitra agar terlindung dari tengkulak.\n   • Menjadi dasar penetapan Harga Pokok Penjualan (HPP) untuk lini produk olahan desa (keripik kentang, jamur crispy, sambal, bubuk kopi).\n\n2. **Pola Analisis Margin & Fluktuasi:**\n   • *Spread Margin:* Selisih antara harga acuan hulu petani vs harga jual hilir menjadi margin operasional kas desa/BUMDes.\n   • *Buffer Volatilitas:* Siapkan batas toleransi fluktuasi harga ±5-10% untuk menjaga stabilitas kas pembelian BUMDes.\n\n3. **Strategi Penyerapan & Stabilisasi Pasokan:**\n   • Saat panen raya (harga turun), BUMDes aktif menyerap panen untuk diolah menjadi produk bernilai tambah tahan lama.\n   • Saat pasokan berkurang (harga naik), lepas stok olahan secara bertahap guna mempertahankan kestabilan pasokan pasar mitra.\n\n*Catatan: Anda dapat melihat dan memperbarui data riil seluruh komoditas melalui menu **Harga Acuan Pasar** pada sidebar admin.*",
        ],
        [
            'keywords' => ['penetrasi', 'branding', 'penetrasi pasar', 'strategi penetrasi', 'strategi penetrasi pasar', 'merek', 'kemasan'],
            'reply'    => "🚀 **Strategi Penetrasi Pasar & Branding Produk Olahan BUMDes:**\n\n1. **Identitas & Kemasan Menarik (Packaging & Legalitas):**\n   • Gunakan kemasan standing pouch bersegel dengan label informasi nilai gizi, masa kedaluwarsa, dan izin edar (P-IRT / Sertifikasi Halal).\n   • Tonjolkan cerita keaslian desa (*storytelling*) bahwa produk diolah langsung dari komoditas segar petani lokal binaan BUMDes.\n\n2. **Optimalisasi Etalase Digital (Katalog SumberTani):**\n   • Pastikan foto produk beresolusi tinggi dengan deskripsi keunggulan produk di menu **Pemasaran & Katalog**.\n   • Aktifkan promo bundling atau diskon peluncuran untuk menarik pembeli pertama.\n\n3. **Penetapan Harga & Saluran Distribusi:**\n   • Terapkan harga penetrasi kompetitif pada tahap awal guna mendorong adopsi pasar dan pembelian berulang (*repeat order*).\n   • Manfaatkan jejaring kemitraan: toko oleh-oleh lokal, koperasi karyawan, gerai BUMDes, dan event pameran UMKM.",
        ],
        [
            'keywords' => ['pemasaran', 'katalog', 'produk olahan', 'etalase', 'marketing'],
            'reply'    => "📦 **Tata Kelola Pemasaran & Katalog Produk Olahan:**\n\n1. Buka menu **Manajemen Pemasaran** pada dashboard Super Admin.\n2. Anda dapat melihat seluruh produk olahan petani binaan beserta harga, stok, dan pemiliknya.\n3. Gunakan toggle status untuk mengaktifkan produk agar tayang di Katalog Publik (`/katalog`).\n4. Produk yang berstatus `active` atau `out_of_stock` dapat dilihat masyarakat dan dipesan via kontak WhatsApp resmi Super Admin.",
        ],
        [
            'keywords' => ['laba', 'rugi', 'profit', 'laba rugi', 'laba rugi agregat', 'agregat laba rugi', 'agregat'],
            'reply'    => "📈 **Agregat Laba / Rugi Seluruh Petani:**\n\n• **Formula Baku:** Total Pendapatan Penjualan Bersih Petani - Total Biaya Produksi Kebun & Olahan.\n• Super Admin dapat memantau ringkasan performa finansial gabungan seluruh mitra binaan pada menu **Laba / Rugi Agregat**.\n• Data menyajikan perbandingan detail per petani, omzet kotor, efisiensi modal, dan net profit/loss yang dapat difilter per periode waktu.",
        ],
        [
            'keywords' => ['pesanan', 'order', 'whatsapp', 'sla', 'konfirmasi pesanan'],
            'reply'    => "🛒 **Standar Operasional Prosedur (SOP) Pesanan Katalog:**\n\n1. Calon pembeli mengirimkan pesanan dari katalog web ke WhatsApp admin dengan kode pesanan unik (contoh: `ORD-...`).\n2. Admin melakukan konfirmasi ketersediaan stok dan ongkir, lalu ubah status pesanan menjadi `confirmed`.\n3. Setelah pembayaran diverifikasi, admin menyelesaikan pesanan (`completed`) yang secara otomatis memotong stok gudang dan mencatat penjualan.",
        ],
        [
            'keywords' => ['komisi', '3%', 'pades', 'kas bumdes', 'pendapatan platform'],
            'reply'    => "💼 **Skema Keuangan & Komisi Platform 3%:**\n\n• Tarif komisi baku platform adalah **3.00%** per transaksi selesai.\n• Sebesar **97.00%** merupakan hak bersih petani pemilik produk.\n• Dana komisi 3% ini digunakan secara akuntabel untuk pemeliharaan sistem digital, operasional promosi BUMDes, dan Pendapatan Asli Desa (PADes).",
        ],
        [
            'keywords' => ['serapan panen', 'panen raya', 'rantai pasok', 'gudang', 'susut'],
            'reply'    => "🏬 **Tata Kelola Rantai Pasok & Serapan Komoditas Desa:**\n\n• **Stabilisasi Harga:** Saat panen raya, BUMDes bertindak sebagai penyerap komoditas 10 Kelompok Tani binaan untuk melindungi petani dari anjloknya harga lokal.\n• **Rotasi Stok (FIFO):** Gunakan prinsip First-In First-Out pada gudang simpan untuk meminimalkan susut bobot komoditas segar.\n• **Kemitraan Offtaker:** Hubungkan stok panen stabil desa dengan industri makanan dan pasar ritel melalui kontrak pasokan rutin.",
        ],
        [
            'keywords' => ['kelola pengguna', 'tambah petani', 'poktan', 'impersonasi', 'akun'],
            'reply'    => "👥 **Manajemen Akun Petani & 10 Poktan Binaan:**\n\n1. Buka menu **Kelola Pengguna** di Super Admin untuk melihat seluruh akun petani.\n2. Anda dapat menambah akun baru, menugaskan ke salah satu dari 10 Poktan, atau menyetujui pendaftaran petani baru.\n3. Fitur **Impersonasi** memungkinkan Super Admin mendampingi petani secara langsung dari sudut pandang akun petani.",
        ],
    ];

    /**
     * Knowledge Base Bersama (Salam & Info Platform).
     */
    private array $commonKnowledgeBase = [
        [
            'keywords' => ['halo', 'hai', 'hello', 'hi', 'bantuan', 'menu'],
            'reply'    => "Halo! 👋 Saya **TaniBot AI**, asisten cerdas platform SumberTani berbasis AI (PKM-Kosabangsa).\n\nSilakan ajukan pertanyaan seputar budidaya tanaman, penanganan hama, hitung biaya modal, atau tata kelola agribisnis BUMDes desa!",
        ],
        [
            'keywords' => ['sumbertani', 'tentang', 'platform', 'aplikasi'],
            'reply'    => "🌱 **Tentang SumberTani berbasis AI:**\n\nSumberTani berbasis AI (PKM-Kosabangsa) adalah platform terpadu hilirisasi dan digitalisasi agribisnis pedesaan yang menghubungkan Petani, 10 Kelompok Tani (Poktan), dan BUMDes.\n\nFokus Utama:\n1. Digitalisasi rantai pasok dan serapan komoditas desa.\n2. Peningkatan nilai tambah komoditas segar menjadi produk olahan bernilai tinggi.\n3. Transparansi analisis laba/rugi terpadu (Hulu Kebun + Hilir Olahan).\n4. Asisten AI cerdas untuk efisiensi usaha tani desa! 🌟",
        ],
    ];

    /**
     * Endpoint Chat Eksklusif Petani (Agricultural Assistant).
     */
    public function farmerChat(Request $request): JsonResponse
    {
        $user = $request->user();

        // Pemeriksaan otorisasi eksplisit backend
        if (!$user || !in_array($user->role, ['user', 'farmer'], true)) {
            return response()->json([
                'success' => false,
                'message' => 'Forbidden - Endpoint ini khusus untuk Petani terdaftar.',
            ], 403);
        }

        $validated = $this->validateChatPayload($request);

        return $this->processChat(
            $validated['message'],
            'farmer',
            $user,
            $validated['history'],
            null // Pengguna biasa DILARANG menyuntikkan customContext
        );
    }

    /**
     * Endpoint Chat Eksklusif Super Admin / BUMDes (Business & Platform Assistant).
     */
    public function superAdminChat(Request $request): JsonResponse
    {
        $user = $request->user();

        // Pemeriksaan otorisasi eksplisit backend
        if (!$user || $user->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Forbidden - Endpoint ini khusus untuk Super Admin / BUMDes.',
            ], 403);
        }

        $validated = $this->validateChatPayload($request);

        return $this->processChat(
            $validated['message'],
            'super_admin',
            $user,
            $validated['history'],
            $validated['context'] // Diizinkan hanya untuk Super Admin
        );
    }



    /**
     * Validasi dan sanitasi payload request chat.
     */
    protected function validateChatPayload(Request $request): array
    {
        $validated = $request->validate([
            'message'           => ['required', 'string', 'min:1', 'max:2000'],
            'history'           => ['nullable', 'array', 'max:15'],
            'history.*.role'    => ['required_with:history', 'string', 'in:user,assistant'],
            'history.*.content' => ['required_with:history', 'string', 'max:10000'],
            'context'           => ['nullable', 'string', 'max:500'],
        ]);

        $cleanHistory = [];
        $currentMessage = trim($validated['message']);

        if (!empty($validated['history']) && is_array($validated['history'])) {
            foreach ($validated['history'] as $item) {
                if (!isset($item['role'], $item['content'])) {
                    continue;
                }
                $r = (string) $item['role'];
                $c = trim((string) $item['content']);

                if (!in_array($r, ['user', 'assistant'], true) || $c === '') {
                    continue;
                }

                $cleanHistory[] = [
                    'role'    => $r,
                    'content' => mb_substr($c, 0, 1500),
                ];
            }

            // Batasi riwayat ke 8 percakapan terakhir
            if (count($cleanHistory) > 8) {
                $cleanHistory = array_slice($cleanHistory, -8);
            }
        }

        return [
            'message' => $currentMessage,
            'history' => $cleanHistory,
            'context' => $validated['context'] ?? null,
        ];
    }

    /**
     * Eksekusi alur chat dengan prioritas OpenRouter AI, dengan fallback ke knowledge base lokal.
     */
    private function processChat(
        string $message,
        string $roleContext,
        $user,
        array $history,
        ?string $customContext
    ): JsonResponse {
        // 1. Ekstraksi data aktual dari database dengan tenant isolation
        $factualResult = $this->dataQueryService->queryFactualData($user, $message, $roleContext);
        $factualDataSummary = $factualResult['has_data'] ? $factualResult['summary'] : null;

        // 2. Coba OpenRouter API terlebih dahulu jika API Key tersedia
        if ($this->openRouterService->isAvailable()) {
            $aiReply = $this->openRouterService->generateReply(
                $message,
                $roleContext,
                $user,
                $history,
                $customContext,
                $factualDataSummary
            );

            if (!empty($aiReply)) {
                return response()->json([
                    'success' => true,
                    'reply'   => $aiReply,
                    'message' => $aiReply,
                    'source'  => 'openrouter',
                    'model'   => $this->openRouterService->getLastUsedModel() ?? config('chatbot.openrouter.model'),
                    'role'    => $roleContext,
                ]);
            }
        }

        // 3. Fallback cerdas ke knowledge base lokal jika OpenRouter offline / gagal
        $fallbackReply = $this->findLocalReply(
            strtolower($message),
            $roleContext,
            $factualDataSummary
        );

        return response()->json([
            'success' => true,
            'reply'   => $fallbackReply,
            'message' => $fallbackReply,
            'source'  => 'local_fallback',
            'role'    => $roleContext,
        ]);
    }

    /**
     * Cari respon terbaik dari knowledge base lokal berbasis kecocokan peran dan kata kunci terisolasi.
     */
    private function findLocalReply(string $message, string $role, ?string $factualSummary = null): string
    {
        $isCodingRequest = (bool) preg_match('/\b(python|script|kode|coding|koding|programming|program)\b/i', $message);
        $codeDisclaimer = "💡 *Catatan:* Sebagai asisten **TaniBot**, saya berfokus pada analisis agribisnis dan operasional BUMDes (tidak memproses pembuatan script kode pemrograman). Berikut analisis bisnis terkait topik Anda:\n\n";

        // 1. Dapatkan knowledge base khusus peran
        $roleKb = ($role === 'farmer')
            ? $this->farmerKnowledgeBase
            : (($role === 'super_admin') ? $this->superAdminKnowledgeBase : []);

        // Jika ada data faktual aktual dari database yang cocok dengan pertanyaan, utamakan fakta!
        if (!empty($factualSummary)) {
            $factualSection = "📊 **Ringkasan Data Resmi SumberTani:**\n\n{$factualSummary}\n\n*Catatan: Anda dapat melihat rincian selengkapnya melalui menu terkait pada dashboard aplikasi.*";

            // Jika pengguna juga meminta analisis/panduan yang cocok dengan KB, gabungkan secara cerdas
            foreach ($roleKb as $item) {
                foreach ($item['keywords'] as $keyword) {
                    if ($this->matchesKeyword($message, $keyword)) {
                        $combined = "{$factualSection}\n\n---\n\n{$item['reply']}";
                        return $isCodingRequest ? ($codeDisclaimer . $combined) : $combined;
                    }
                }
            }

            return $isCodingRequest ? ($codeDisclaimer . $factualSection) : $factualSection;
        }

        // 2. Cek knowledge base khusus peran jika tidak ada data faktual mentah
        foreach ($roleKb as $item) {
            foreach ($item['keywords'] as $keyword) {
                if ($this->matchesKeyword($message, $keyword)) {
                    return $isCodingRequest ? ($codeDisclaimer . $item['reply']) : $item['reply'];
                }
            }
        }

        // 3. Cek knowledge base umum (salam / tentang)
        foreach ($this->commonKnowledgeBase as $item) {
            foreach ($item['keywords'] as $keyword) {
                if ($this->matchesKeyword($message, $keyword)) {
                    return $item['reply'];
                }
            }
        }

        // 4. Jika pengguna meminta kode pemrograman murni di luar cakupan agribisnis
        if ($isCodingRequest) {
            return "💡 **Pemberitahuan Cakupan TaniBot:**\n\n" .
                "Mohon maaf, sebagai asisten cerdas **TaniBot**, fokus utama saya adalah pendampingan **agribisnis, budidaya pertanian, stok hasil panen, dan operasional BUMDes desa**.\n\n" .
                "Saya tidak dirancang untuk membuat script kode pemrograman atau menangani tugas teknis IT di luar sektor pertanian/BUMDes.\n\n" .
                "Silakan ajukan pertanyaan seputar:\n" .
                "• Analisis harga pasar komoditas & serapan panen\n" .
                "• Strategi pemasaran & etalase katalog produk olahan\n" .
                "• Tata kelola pesanan katalog WhatsApp & komisi platform 3%\n" .
                "• Monitoring stok gudang desa & evaluasi laba/rugi agregat";
        }

        // 5. Respons klarifikasi jika tidak ada intent yang cocok dengan keyakinan tinggi
        if ($role === 'farmer') {
            return "Halo Petani Mitra! 🌾 Saya **TaniBot Pertanian** siap membantu Anda seputar:\n" .
                "• Rekomendasi budidaya & siklus musim tanam\n" .
                "• Pengendalian hama & penyakit tanaman\n" .
                "• Pembuatan pupuk organik cair (POC) & kompos hemat modal\n" .
                "• Penghitungan modal kebun hulu & prinsip bebas biaya ganda olahan\n" .
                "• Informasi hak bersih penjualan 97% petani\n\n" .
                "Silakan jelaskan komoditas atau kendala yang sedang Anda hadapi agar saya dapat memberikan panduan yang tepat!";
        }

        return "Halo Pengurus BUMDes! 💼 Saya **TaniBot Bisnis** siap membantu Anda seputar:\n" .
            "• Strategi pemasaran & etalase katalog produk olahan\n" .
            "• Alur pemrosesan pesanan katalog via WhatsApp & SLA\n" .
            "• Pemantauan stok gudang desa & mitigasi susut panen\n" .
            "• Analisis margin usaha & tata kelola komisi platform 3%\n" .
            "• Evaluasi serapan panen 10 Kelompok Tani binaan desa\n\n" .
            "Silakan ketik topik bisnis atau operasional yang ingin Anda diskusikan!";
    }

    /**
     * Pengecekan kata kunci aman berbasis batas kata (word boundary) untuk mencegah false positives.
     */
    private function matchesKeyword(string $message, string $keyword): bool
    {
        $kw = trim(strtolower($keyword));
        $pattern = '/\b' . preg_quote($kw, '/') . '\b/i';
        return (bool) preg_match($pattern, $message);
    }
}