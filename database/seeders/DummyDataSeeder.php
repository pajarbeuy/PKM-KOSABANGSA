<?php

namespace Database\Seeders;

use App\Models\Commission;
use App\Models\DashboardMenu;
use App\Models\FarmerCommodity;
use App\Models\FarmerGroup;
use App\Models\Feedback;
use App\Models\Harvest;
use App\Models\LandingContent;
use App\Models\LoginLog;
use App\Models\MarketPrice;
use App\Models\News;
use App\Models\Notification;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\ProcessedProduct;
use App\Models\ProcessedProductDiscount;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\Season;
use App\Models\Setting;
use App\Models\StockTransaction;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DummyDataSeeder extends Seeder
{
    /**
     * Jalankan seeder data dummy komprehensif untuk project PKM / SumberTani.
     */
    public function run(): void
    {
        $this->command?->info('🌱 Menjalankan DummyDataSeeder...');

        // 1. Pastikan 10 Kelompok Tani (Poktan) resmi terisi
        $this->call(FarmerGroupSeeder::class);
        $poktans = FarmerGroup::all()->keyBy('code');

        // 2. Default Platform Settings
        Setting::set('min_stock', 50);
        Setting::set('max_stock', 5000);
        Setting::set('notify_low_stock', 1);
        Setting::set('notify_new_sale', 1);
        Setting::set('notify_cost', 1);

        // 3. User Accounts (Super Admin, Petani Aktif, Petani Pending, Petani Rejected)
        $superAdmin = User::updateOrCreate(
            ['email' => 'superadmin@simhpsk.com'],
            [
                'name'              => 'Super Admin Pusat',
                'password'          => Hash::make('superadmin123'),
                'phone'             => '085138003594',
                'farm_name'         => 'Kantor Pusat SIMHPSK',
                'farmer_group_id'   => null,
                'role'              => 'super_admin',
                'status'            => 'active',
                'approval'          => 'approved',
                'email_verified_at' => now(),
            ]
        );

        // Petani 1: Pak Slamet (Komoditas Utama: Padi Ciherang & Jagung Hibrida)
        $farmerSlamet = User::updateOrCreate(
            ['email' => 'admin@simhpsk.com'],
            [
                'name'              => 'Pak Slamet Raharjo',
                'password'          => Hash::make('admin123'),
                'phone'             => '081234567890',
                'farm_name'         => 'Kebun Berkah Tani Makmur',
                'farmer_group_id'   => $poktans['POKTAN-01']?->id ?? 1,
                'role'              => 'user',
                'status'            => 'active',
                'approval'          => 'approved',
                'email_verified_at' => now(),
            ]
        );

        // Petani 2: Budi Santoso (Komoditas Utama: Cabai Rawit & Bawang Merah)
        $farmerBudi = User::updateOrCreate(
            ['email' => 'budi@simhpsk.com'],
            [
                'name'              => 'Budi Santoso',
                'password'          => Hash::make('budi123'),
                'phone'             => '081298765431',
                'farm_name'         => 'Tani Sayur Sri Rejeki',
                'farmer_group_id'   => $poktans['POKTAN-02']?->id ?? 2,
                'role'              => 'user',
                'status'            => 'active',
                'approval'          => 'approved',
                'email_verified_at' => now(),
            ]
        );

        // Petani 3: Ibu Siti Rahmawati (Komoditas: Jamur Tiram & Tomat)
        $farmerSiti = User::updateOrCreate(
            ['email' => 'siti@simhpsk.com'],
            [
                'name'              => 'Siti Rahmawati',
                'password'          => Hash::make('siti123'),
                'phone'             => '081377889900',
                'farm_name'         => 'Rumah Jamur & Horti Harapan',
                'farmer_group_id'   => $poktans['POKTAN-03']?->id ?? 3,
                'role'              => 'user',
                'status'            => 'active',
                'approval'          => 'approved',
                'email_verified_at' => now(),
            ]
        );

        // Petani 4: Joko Supriyanto (Komoditas: Kedelai & Jahe Merah)
        $farmerJoko = User::updateOrCreate(
            ['email' => 'joko@simhpsk.com'],
            [
                'name'              => 'Joko Supriyanto',
                'password'          => Hash::make('joko123'),
                'phone'             => '081566778899',
                'farm_name'         => 'Agro Palawija Karya Bersama',
                'farmer_group_id'   => $poktans['POKTAN-04']?->id ?? 4,
                'role'              => 'user',
                'status'            => 'active',
                'approval'          => 'approved',
                'email_verified_at' => now(),
            ]
        );

        // Petani 5: I Wayan Subekti (Komoditas: Beras Merah Organik)
        $farmerWayan = User::updateOrCreate(
            ['email' => 'wayan@simhpsk.com'],
            [
                'name'              => 'I Wayan Subekti',
                'password'          => Hash::make('wayan123'),
                'phone'             => '081822334455',
                'farm_name'         => 'Kebun Subak Sari Sumber Pangan',
                'farmer_group_id'   => $poktans['POKTAN-05']?->id ?? 5,
                'role'              => 'user',
                'status'            => 'active',
                'approval'          => 'approved',
                'email_verified_at' => now(),
            ]
        );

        // Petani Pending 1 (Untuk simulasi verifikasi Super Admin)
        $farmerPending1 = User::updateOrCreate(
            ['email' => 'ahmad.pending@simhpsk.com'],
            [
                'name'              => 'Ahmad Dahlan (Menunggu Verifikasi)',
                'password'          => Hash::make('petani123'),
                'phone'             => '081255443322',
                'farm_name'         => 'Kebun Sayur Hijau Mandiri',
                'farmer_group_id'   => $poktans['POKTAN-06']?->id ?? 6,
                'role'              => 'user',
                'status'            => 'active',
                'approval'          => 'pending',
                'email_verified_at' => now(),
            ]
        );

        // Petani Pending 2 (Untuk simulasi verifikasi Super Admin)
        $farmerPending2 = User::updateOrCreate(
            ['email' => 'dewi.pending@simhpsk.com'],
            [
                'name'              => 'Dewi Lestari (Menunggu Verifikasi)',
                'password'          => Hash::make('petani123'),
                'phone'             => '081988776655',
                'farm_name'         => 'Organik Berkah Nusantara',
                'farmer_group_id'   => $poktans['POKTAN-07']?->id ?? 7,
                'role'              => 'user',
                'status'            => 'active',
                'approval'          => 'pending',
                'email_verified_at' => now(),
            ]
        );

        // Petani Ditolak (Untuk simulasi riwayat penolakan akun tidak valid)
        $farmerRejected = User::updateOrCreate(
            ['email' => 'rudi.rejected@simhpsk.com'],
            [
                'name'              => 'Rudi Hermawan (Ditolak)',
                'password'          => Hash::make('petani123'),
                'phone'             => '089911223344',
                'farm_name'         => 'Lahan Tani Fiktif',
                'farmer_group_id'   => $poktans['POKTAN-08']?->id ?? 8,
                'role'              => 'user',
                'status'            => 'inactive',
                'approval'          => 'rejected',
                'email_verified_at' => now(),
            ]
        );

        $this->command?->info('  ✓ 8 Akun pengguna berhasil disiapkan (1 Super Admin, 5 Petani Aktif, 2 Pending, 1 Rejected)');

        // 4. Komoditas Tani (Farmer Commodities)
        $commoditiesData = [
            // Pak Slamet
            [
                'user_id'     => $farmerSlamet->id,
                'name'        => 'Padi Ciherang',
                'code'        => 'KMD-SLM-PADI',
                'unit'        => 'kg',
                'description' => 'Varietas padi sawah unggul dengan tekstur nasi pulen dan wangi alami.',
                'status'      => 'active',
            ],
            [
                'user_id'     => $farmerSlamet->id,
                'name'        => 'Jagung Hibrida Bisi-18',
                'code'        => 'KMD-SLM-JAGUNG',
                'unit'        => 'kg',
                'description' => 'Jagung hibrida produktivitas tinggi, bulir rapat dan padat nutrisi.',
                'status'      => 'active',
            ],

            // Budi Santoso
            [
                'user_id'     => $farmerBudi->id,
                'name'        => 'Cabai Rawit Merah',
                'code'        => 'KMD-BDI-RAWIT',
                'unit'        => 'kg',
                'description' => 'Cabai rawit merah pedas segar dipanen langsung dari kebun hortikultura.',
                'status'      => 'active',
            ],
            [
                'user_id'     => $farmerBudi->id,
                'name'        => 'Bawang Merah Brebes',
                'code'        => 'KMD-BDI-BAWANG',
                'unit'        => 'kg',
                'description' => 'Bawang merah umbi padat, aroma wangi kuat khas varietas Brebes.',
                'status'      => 'active',
            ],
            [
                'user_id'     => $farmerBudi->id,
                'name'        => 'Cabai Merah Keriting',
                'code'        => 'KMD-BDI-KERITING',
                'unit'        => 'kg',
                'description' => 'Cabai merah keriting berkualitas untuk aneka bumbu olahan dan konsumsi segar.',
                'status'      => 'active',
            ],

            // Siti Rahmawati
            [
                'user_id'     => $farmerSiti->id,
                'name'        => 'Jamur Tiram Putih',
                'code'        => 'KMD-STI-JAMUR',
                'unit'        => 'kg',
                'description' => 'Jamur tiram putih budidaya baglog ramah lingkungan, bersih dan kenyal.',
                'status'      => 'active',
            ],
            [
                'user_id'     => $farmerSiti->id,
                'name'        => 'Tomat Servo',
                'code'        => 'KMD-STI-TOMAT',
                'unit'        => 'kg',
                'description' => 'Tomat sayur berdaging tebal, tahan simpan dan kaya vitamin C.',
                'status'      => 'active',
            ],

            // Joko Supriyanto
            [
                'user_id'     => $farmerJoko->id,
                'name'        => 'Kedelai Anjasmoro',
                'code'        => 'KMD-JKO-KEDELAI',
                'unit'        => 'kg',
                'description' => 'Kedelai lokal biji besar, sangat cocok untuk bahan tempe dan tahu bermutu.',
                'status'      => 'active',
            ],
            [
                'user_id'     => $farmerJoko->id,
                'name'        => 'Jahe Merah Rimpang',
                'code'        => 'KMD-JKO-JAHE',
                'unit'        => 'kg',
                'description' => 'Jahe merah rimpang pedas berkhasiat herbal tinggi untuk minuman tradisional.',
                'status'      => 'active',
            ],

            // I Wayan Subekti
            [
                'user_id'     => $farmerWayan->id,
                'name'        => 'Beras Merah Organik',
                'code'        => 'KMD-WYN-BMERAH',
                'unit'        => 'kg',
                'description' => 'Padi beras merah budidaya organik sistem subak, kaya serat dan antioksidan.',
                'status'      => 'active',
            ],
        ];

        $commodities = [];
        foreach ($commoditiesData as $cData) {
            $commodities[$cData['code']] = FarmerCommodity::updateOrCreate(
                ['user_id' => $cData['user_id'], 'code' => $cData['code']],
                $cData
            );
        }

        $this->command?->info('  ✓ 10 Komoditas petani berhasil disiapkan');

        // 5. Master Harga Pasar (Market Prices) - Historis & Efektif
        $marketPricesSpec = [
            // Padi Ciherang
            ['code' => 'KMD-SLM-PADI', 'date' => '2026-06-01', 'price' => 6500, 'source' => 'Pasar Induk Cipinang'],
            ['code' => 'KMD-SLM-PADI', 'date' => '2026-09-01', 'price' => 6800, 'source' => 'Pasar Induk Cipinang'],
            ['code' => 'KMD-SLM-PADI', 'date' => '2026-11-01', 'price' => 7100, 'source' => 'PIHPS Nasional'],

            // Jagung Hibrida
            ['code' => 'KMD-SLM-JAGUNG', 'date' => '2026-06-01', 'price' => 5200, 'source' => 'Bappebti'],
            ['code' => 'KMD-SLM-JAGUNG', 'date' => '2026-09-15', 'price' => 5600, 'source' => 'Pasar Induk Kramat Jati'],

            // Cabai Rawit Merah
            ['code' => 'KMD-BDI-RAWIT', 'date' => '2026-07-01', 'price' => 42000, 'source' => 'PIHPS Nasional'],
            ['code' => 'KMD-BDI-RAWIT', 'date' => '2026-09-01', 'price' => 45000, 'source' => 'Pasar Induk Kramat Jati'],
            ['code' => 'KMD-BDI-RAWIT', 'date' => '2026-11-01', 'price' => 48000, 'source' => 'PIHPS Nasional'],

            // Bawang Merah Brebes
            ['code' => 'KMD-BDI-BAWANG', 'date' => '2026-08-01', 'price' => 30000, 'source' => 'Pasar Induk Brebes'],
            ['code' => 'KMD-BDI-BAWANG', 'date' => '2026-10-01', 'price' => 33000, 'source' => 'Pasar Induk Kramat Jati'],

            // Cabai Merah Keriting
            ['code' => 'KMD-BDI-KERITING', 'date' => '2026-08-15', 'price' => 36000, 'source' => 'PIHPS Nasional'],
            ['code' => 'KMD-BDI-KERITING', 'date' => '2026-10-15', 'price' => 39000, 'source' => 'PIHPS Nasional'],

            // Jamur Tiram Putih
            ['code' => 'KMD-STI-JAMUR', 'date' => '2026-07-01', 'price' => 17000, 'source' => 'Dinas Ketahanan Pangan'],
            ['code' => 'KMD-STI-JAMUR', 'date' => '2026-10-01', 'price' => 19000, 'source' => 'Dinas Ketahanan Pangan'],

            // Tomat Servo
            ['code' => 'KMD-STI-TOMAT', 'date' => '2026-08-01', 'price' => 11000, 'source' => 'Pasar Tradisional'],
            ['code' => 'KMD-STI-TOMAT', 'date' => '2026-10-01', 'price' => 12500, 'source' => 'Pasar Tradisional'],

            // Kedelai Anjasmoro
            ['code' => 'KMD-JKO-KEDELAI', 'date' => '2026-06-15', 'price' => 11000, 'source' => 'Koperasi Tahu Tempe'],
            ['code' => 'KMD-JKO-KEDELAI', 'date' => '2026-09-15', 'price' => 12000, 'source' => 'Bappebti'],

            // Jahe Merah
            ['code' => 'KMD-JKO-JAHE', 'date' => '2026-07-01', 'price' => 26000, 'source' => 'Pasar Rempah'],
            ['code' => 'KMD-JKO-JAHE', 'date' => '2026-10-01', 'price' => 29000, 'source' => 'Pasar Rempah'],

            // Beras Merah Organik
            ['code' => 'KMD-WYN-BMERAH', 'date' => '2026-06-01', 'price' => 14000, 'source' => 'Koperasi Subak'],
            ['code' => 'KMD-WYN-BMERAH', 'date' => '2026-10-01', 'price' => 15500, 'source' => 'Pasar Organik'],
        ];

        $marketPrices = [];
        foreach ($marketPricesSpec as $pSpec) {
            $cmd = $commodities[$pSpec['code']] ?? null;
            if (!$cmd) continue;

            $marketPrices[$pSpec['code'] . '_' . $pSpec['date']] = MarketPrice::updateOrCreate(
                [
                    'commodity_id'   => $cmd->id,
                    'effective_date' => $pSpec['date'],
                ],
                [
                    'price'      => $pSpec['price'],
                    'unit'       => 'kg',
                    'source'     => $pSpec['source'],
                    'notes'      => 'Update harga referensi pasar komoditas.',
                    'created_by' => $superAdmin->id,
                ]
            );
        }

        $this->command?->info('  ✓ 20 Rekor harga pasar komoditas historis & efektif disiapkan');

        // 6. Musim Tanam (Seasons)
        $seasonsData = [
            // Pak Slamet: Padi (Musim Kemarau 2026 - selesai) & Padi (Musim Hujan 2026/2027 - aktif)
            'slamet_padi_s1' => [
                'user_id'      => $farmerSlamet->id,
                'commodity_id' => $commodities['KMD-SLM-PADI']->id,
                'name'         => 'Musim Tanam Gadu Padi 2026',
                'start_date'   => '2026-05-10',
                'end_date'     => '2026-09-15',
                'status'       => 'completed',
                'target_kg'    => 5000,
            ],
            'slamet_padi_s2' => [
                'user_id'      => $farmerSlamet->id,
                'commodity_id' => $commodities['KMD-SLM-PADI']->id,
                'name'         => 'Musim Tanam Rendeng Padi 2026/2027',
                'start_date'   => '2026-10-01',
                'end_date'     => '2027-02-15',
                'status'       => 'active',
                'target_kg'    => 5500,
            ],
            // Pak Slamet: Jagung
            'slamet_jagung_s1' => [
                'user_id'      => $farmerSlamet->id,
                'commodity_id' => $commodities['KMD-SLM-JAGUNG']->id,
                'name'         => 'Musim Jagung Pipil Q3 2026',
                'start_date'   => '2026-06-01',
                'end_date'     => '2026-09-30',
                'status'       => 'completed',
                'target_kg'    => 3500,
            ],

            // Budi Santoso: Cabai Rawit & Bawang Merah
            'budi_rawit_s1' => [
                'user_id'      => $farmerBudi->id,
                'commodity_id' => $commodities['KMD-BDI-RAWIT']->id,
                'name'         => 'Siklus Cabai Rawit Intensif 2026',
                'start_date'   => '2026-06-15',
                'end_date'     => '2026-10-20',
                'status'       => 'completed',
                'target_kg'    => 800,
            ],
            'budi_bawang_s1' => [
                'user_id'      => $farmerBudi->id,
                'commodity_id' => $commodities['KMD-BDI-BAWANG']->id,
                'name'         => 'Musim Bawang Brebes Musim Kemarau',
                'start_date'   => '2026-07-20',
                'end_date'     => '2026-10-10',
                'status'       => 'completed',
                'target_kg'    => 1200,
            ],

            // Siti Rahmawati: Jamur Tiram (Siklus 1 completed, Siklus 2 active)
            'siti_jamur_s1' => [
                'user_id'      => $farmerSiti->id,
                'commodity_id' => $commodities['KMD-STI-JAMUR']->id,
                'name'         => 'Siklus Budidaya Jamur Baglog Gelombang 1',
                'start_date'   => '2026-06-01',
                'end_date'     => '2026-08-31',
                'status'       => 'completed',
                'target_kg'    => 600,
            ],
            'siti_jamur_s2' => [
                'user_id'      => $farmerSiti->id,
                'commodity_id' => $commodities['KMD-STI-JAMUR']->id,
                'name'         => 'Siklus Budidaya Jamur Baglog Gelombang 2',
                'start_date'   => '2026-09-01',
                'end_date'     => '2026-11-30',
                'status'       => 'active',
                'target_kg'    => 750,
            ],

            // Joko Supriyanto: Kedelai Anjasmoro
            'joko_kedelai_s1' => [
                'user_id'      => $farmerJoko->id,
                'commodity_id' => $commodities['KMD-JKO-KEDELAI']->id,
                'name'         => 'Musim Kedelai Palawija 2026',
                'start_date'   => '2026-06-10',
                'end_date'     => '2026-09-25',
                'status'       => 'completed',
                'target_kg'    => 2000,
            ],

            // I Wayan: Beras Merah
            'wayan_berasmerah_s1' => [
                'user_id'      => $farmerWayan->id,
                'commodity_id' => $commodities['KMD-WYN-BMERAH']->id,
                'name'         => 'Musim Padi Merah Organik Subak Q3',
                'start_date'   => '2026-05-20',
                'end_date'     => '2026-09-30',
                'status'       => 'completed',
                'target_kg'    => 3000,
            ],
        ];

        $seasons = [];
        foreach ($seasonsData as $key => $sData) {
            $seasons[$key] = Season::updateOrCreate(
                [
                    'user_id'      => $sData['user_id'],
                    'commodity_id' => $sData['commodity_id'],
                    'name'         => $sData['name'],
                ],
                $sData
            );
        }

        $this->command?->info('  ✓ 9 Musim tanam (aktif & selesai) disiapkan');

        // 7. Biaya Produksi Pertanian (Production Costs - cost_type: 'farm')
        $farmCosts = [
            // Slamet - Padi S1
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_padi_s1'], 'cat' => 'seed', 'item' => 'Benih Padi Ciherang Unggul 50kg', 'amount' => 600000, 'date' => '2026-05-15', 'qty' => 50, 'unit' => 'kg', 'price' => 12000],
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_padi_s1'], 'cat' => 'fertilizer', 'item' => 'Pupuk Organik & NPK Phonska 250kg', 'amount' => 1500000, 'date' => '2026-06-05', 'qty' => 250, 'unit' => 'kg', 'price' => 6000],
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_padi_s1'], 'cat' => 'pesticide', 'item' => 'Pestisida Nabati & Insektisida', 'amount' => 450000, 'date' => '2026-07-01', 'qty' => 3, 'unit' => 'botol', 'price' => 150000],
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_padi_s1'], 'cat' => 'other', 'item' => 'Sewa Hand Traktor & Tenaga Olah Tanah', 'amount' => 1800000, 'date' => '2026-05-12', 'qty' => 1, 'unit' => 'paket', 'price' => 1800000],
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_padi_s1'], 'cat' => 'other', 'item' => 'Upah Tenaga Kerja Panen & Angkut', 'amount' => 1600000, 'date' => '2026-09-10', 'qty' => 4, 'unit' => 'orang/hari', 'price' => 400000],

            // Slamet - Padi S2 (Musim Berjalan)
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_padi_s2'], 'cat' => 'seed', 'item' => 'Benih Padi Ciherang Bersertifikasi 60kg', 'amount' => 720000, 'date' => '2026-10-05', 'qty' => 60, 'unit' => 'kg', 'price' => 12000],
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_padi_s2'], 'cat' => 'fertilizer', 'item' => 'Pupuk Urea & Kompos Fermentasi', 'amount' => 1200000, 'date' => '2026-10-25', 'qty' => 200, 'unit' => 'kg', 'price' => 6000],

            // Slamet - Jagung
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_jagung_s1'], 'cat' => 'seed', 'item' => 'Benih Jagung Hibrida Bisi-18 20kg', 'amount' => 900000, 'date' => '2026-06-03', 'qty' => 20, 'unit' => 'kg', 'price' => 45000],
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_jagung_s1'], 'cat' => 'fertilizer', 'item' => 'Pupuk SP-36 & ZA Jagung', 'amount' => 850000, 'date' => '2026-06-25', 'qty' => 150, 'unit' => 'kg', 'price' => 5666],
            ['user' => $farmerSlamet, 'season' => $seasons['slamet_jagung_s1'], 'cat' => 'other', 'item' => 'Upah Perawatan & Panen Jagung', 'amount' => 1100000, 'date' => '2026-09-20', 'qty' => 1, 'unit' => 'borongan', 'price' => 1100000],

            // Budi - Cabai Rawit S1
            ['user' => $farmerBudi, 'season' => $seasons['budi_rawit_s1'], 'cat' => 'seed', 'item' => 'Bibit Cabai Rawit Semai Polybag 1500 pohon', 'amount' => 750000, 'date' => '2026-06-20', 'qty' => 1500, 'unit' => 'batang', 'price' => 500],
            ['user' => $farmerBudi, 'season' => $seasons['budi_rawit_s1'], 'cat' => 'fertilizer', 'item' => 'Pupuk Hayati Cair & NPK Mutiara', 'amount' => 950000, 'date' => '2026-07-15', 'qty' => 1, 'unit' => 'paket', 'price' => 950000],
            ['user' => $farmerBudi, 'season' => $seasons['budi_rawit_s1'], 'cat' => 'pesticide', 'item' => 'Fungisida & Perekat Daun', 'amount' => 500000, 'date' => '2026-08-01', 'qty' => 4, 'unit' => 'botol', 'price' => 125000],
            ['user' => $farmerBudi, 'season' => $seasons['budi_rawit_s1'], 'cat' => 'other', 'item' => 'Mulsa Plastik Hitam Perak & Ajir Bambu', 'amount' => 800000, 'date' => '2026-06-18', 'qty' => 2, 'unit' => 'roll', 'price' => 400000],

            // Budi - Bawang Merah S1
            ['user' => $farmerBudi, 'season' => $seasons['budi_bawang_s1'], 'cat' => 'seed', 'item' => 'Umbi Bibit Bawang Merah Brebes 100kg', 'amount' => 3200000, 'date' => '2026-07-22', 'qty' => 100, 'unit' => 'kg', 'price' => 32000],
            ['user' => $farmerBudi, 'season' => $seasons['budi_bawang_s1'], 'cat' => 'fertilizer', 'item' => 'Pupuk Kalsium & Kalium Bawang', 'amount' => 750000, 'date' => '2026-08-10', 'qty' => 50, 'unit' => 'kg', 'price' => 15000],
            ['user' => $farmerBudi, 'season' => $seasons['budi_bawang_s1'], 'cat' => 'other', 'item' => 'Irigasi Pompa Air & BBM', 'amount' => 600000, 'date' => '2026-08-25', 'qty' => 1, 'unit' => 'paket', 'price' => 600000],

            // Siti - Jamur Tiram S1
            ['user' => $farmerSiti, 'season' => $seasons['siti_jamur_s1'], 'cat' => 'seed', 'item' => 'Baglog Jamur Siap Tumbuh 1.200 pcs', 'amount' => 2400000, 'date' => '2026-06-02', 'qty' => 1200, 'unit' => 'baglog', 'price' => 2000],
            ['user' => $farmerSiti, 'season' => $seasons['siti_jamur_s1'], 'cat' => 'other', 'item' => 'Perawatan Kumbung, Sterilisasi & Kabut Air', 'amount' => 450000, 'date' => '2026-07-05', 'qty' => 1, 'unit' => 'paket', 'price' => 450000],

            // Joko - Kedelai S1
            ['user' => $farmerJoko, 'season' => $seasons['joko_kedelai_s1'], 'cat' => 'seed', 'item' => 'Benih Kedelai Anjasmoro Berkualitas 40kg', 'amount' => 640000, 'date' => '2026-06-12', 'qty' => 40, 'unit' => 'kg', 'price' => 16000],
            ['user' => $farmerJoko, 'season' => $seasons['joko_kedelai_s1'], 'cat' => 'fertilizer', 'item' => 'Inokulan Rhizobium & Pupuk Organik', 'amount' => 500000, 'date' => '2026-06-25', 'qty' => 1, 'unit' => 'paket', 'price' => 500000],

            // Wayan - Beras Merah S1
            ['user' => $farmerWayan, 'season' => $seasons['wayan_berasmerah_s1'], 'cat' => 'seed', 'item' => 'Benih Padi Merah Organik 40kg', 'amount' => 560000, 'date' => '2026-05-22', 'qty' => 40, 'unit' => 'kg', 'price' => 14000],
            ['user' => $farmerWayan, 'season' => $seasons['wayan_berasmerah_s1'], 'cat' => 'fertilizer', 'item' => 'Pupuk Kompos Subak & Mikroorganisme', 'amount' => 900000, 'date' => '2026-06-15', 'qty' => 1, 'unit' => 'paket', 'price' => 900000],
        ];

        foreach ($farmCosts as $cost) {
            ProductionCost::updateOrCreate(
                [
                    'user_id'   => $cost['user']->id,
                    'season_id' => $cost['season']->id,
                    'item_name' => $cost['item'],
                ],
                [
                    'cost_type'      => 'farm',
                    'date'           => $cost['date'],
                    'category'       => $cost['cat'],
                    'quantity'       => $cost['qty'],
                    'unit'           => $cost['unit'],
                    'price_per_unit' => $cost['price'],
                    'amount'         => $cost['amount'],
                    'notes'          => 'Pencatatan biaya operasional budidaya tanaman.',
                ]
            );
        }

        $this->command?->info('  ✓ 20 Biaya produksi pertanian (bibit, pupuk, pestisida, operasional) disiapkan');

        // 8. Pencatatan Panen (Harvests)
        $harvestsData = [
            'slamet_padi_h1' => [
                'user'                        => $farmerSlamet,
                'season'                      => $seasons['slamet_padi_s1'],
                'commodity'                   => $commodities['KMD-SLM-PADI'],
                'date'                        => '2026-09-12',
                'weight_kg'                   => 4850,
                'quantity'                    => 4850,
                'unit'                        => 'kg',
                'status'                      => 'verified',
                'market_price_snapshot'       => 6800.00,
                'market_price_effective_date' => '2026-09-01',
                'market_price_id'             => $marketPrices['KMD-SLM-PADI_2026-09-01']->id ?? null,
                'notes'                       => 'Panen raya padi Ciherang musim gadu. Kualitas butir bernas dan kadar air 14%.',
            ],
            'slamet_jagung_h1' => [
                'user'                        => $farmerSlamet,
                'season'                      => $seasons['slamet_jagung_s1'],
                'commodity'                   => $commodities['KMD-SLM-JAGUNG'],
                'date'                        => '2026-09-25',
                'weight_kg'                   => 3400,
                'quantity'                    => 3400,
                'unit'                        => 'kg',
                'status'                      => 'verified',
                'market_price_snapshot'       => 5600.00,
                'market_price_effective_date' => '2026-09-15',
                'market_price_id'             => $marketPrices['KMD-SLM-JAGUNG_2026-09-15']->id ?? null,
                'notes'                       => 'Panen jagung pipil kering panen. Kondisi tongkol besar seragam.',
            ],
            'budi_rawit_h1' => [
                'user'                        => $farmerBudi,
                'season'                      => $seasons['budi_rawit_s1'],
                'commodity'                   => $commodities['KMD-BDI-RAWIT'],
                'date'                        => '2026-09-18',
                'weight_kg'                   => 420,
                'quantity'                    => 420,
                'unit'                        => 'kg',
                'status'                      => 'verified',
                'market_price_snapshot'       => 45000.00,
                'market_price_effective_date' => '2026-09-01',
                'market_price_id'             => $marketPrices['KMD-BDI-RAWIT_2026-09-01']->id ?? null,
                'notes'                       => 'Panen petikan ke-3 cabai rawit merah kualitas Grade A.',
            ],
            'budi_rawit_h2' => [
                'user'                        => $farmerBudi,
                'season'                      => $seasons['budi_rawit_s1'],
                'commodity'                   => $commodities['KMD-BDI-RAWIT'],
                'date'                        => '2026-10-15',
                'weight_kg'                   => 360,
                'quantity'                    => 360,
                'unit'                        => 'kg',
                'status'                      => 'verified',
                'market_price_snapshot'       => 45000.00,
                'market_price_effective_date' => '2026-09-01',
                'market_price_id'             => $marketPrices['KMD-BDI-RAWIT_2026-09-01']->id ?? null,
                'notes'                       => 'Panen petikan ke-5 cabai rawit merah petik matang pohon.',
            ],
            'budi_bawang_h1' => [
                'user'                        => $farmerBudi,
                'season'                      => $seasons['budi_bawang_s1'],
                'commodity'                   => $commodities['KMD-BDI-BAWANG'],
                'date'                        => '2026-10-08',
                'weight_kg'                   => 1150,
                'quantity'                    => 1150,
                'unit'                        => 'kg',
                'status'                      => 'verified',
                'market_price_snapshot'       => 33000.00,
                'market_price_effective_date' => '2026-10-01',
                'market_price_id'             => $marketPrices['KMD-BDI-BAWANG_2026-10-01']->id ?? null,
                'notes'                       => 'Panen umbi bawang merah Brebes daun kering siap jual & olah goreng.',
            ],
            'siti_jamur_h1' => [
                'user'                        => $farmerSiti,
                'season'                      => $seasons['siti_jamur_s1'],
                'commodity'                   => $commodities['KMD-STI-JAMUR'],
                'date'                        => '2026-08-20',
                'weight_kg'                   => 580,
                'quantity'                    => 580,
                'unit'                        => 'kg',
                'status'                      => 'verified',
                'market_price_snapshot'       => 17000.00,
                'market_price_effective_date' => '2026-07-01',
                'market_price_id'             => $marketPrices['KMD-STI-JAMUR_2026-07-01']->id ?? null,
                'notes'                       => 'Hasil petik jamur tiram putih kumbung 1, payung lebar dan segar.',
            ],
            'siti_jamur_h2' => [
                'user'                        => $farmerSiti,
                'season'                      => $seasons['siti_jamur_s2'],
                'commodity'                   => $commodities['KMD-STI-JAMUR'],
                'date'                        => '2026-10-18',
                'weight_kg'                   => 320,
                'quantity'                    => 320,
                'unit'                        => 'kg',
                'status'                      => 'recorded',
                'market_price_snapshot'       => 19000.00,
                'market_price_effective_date' => '2026-10-01',
                'market_price_id'             => $marketPrices['KMD-STI-JAMUR_2026-10-01']->id ?? null,
                'notes'                       => 'Hasil petik gelombang 2, sebagian dialokasikan untuk jamur crispy.',
            ],
            'joko_kedelai_h1' => [
                'user'                        => $farmerJoko,
                'season'                      => $seasons['joko_kedelai_s1'],
                'commodity'                   => $commodities['KMD-JKO-KEDELAI'],
                'date'                        => '2026-09-22',
                'weight_kg'                   => 1920,
                'quantity'                    => 1920,
                'unit'                        => 'kg',
                'status'                      => 'verified',
                'market_price_snapshot'       => 12000.00,
                'market_price_effective_date' => '2026-09-15',
                'market_price_id'             => $marketPrices['KMD-JKO-KEDELAI_2026-09-15']->id ?? null,
                'notes'                       => 'Panen kedelai polong tua kuning kering, biji kuning mengkilap.',
            ],
            'wayan_berasmerah_h1' => [
                'user'                        => $farmerWayan,
                'season'                      => $seasons['wayan_berasmerah_s1'],
                'commodity'                   => $commodities['KMD-WYN-BMERAH'],
                'date'                        => '2026-09-28',
                'weight_kg'                   => 2850,
                'quantity'                    => 2850,
                'unit'                        => 'kg',
                'status'                      => 'verified',
                'market_price_snapshot'       => 14000.00,
                'market_price_effective_date' => '2026-06-01',
                'market_price_id'             => $marketPrices['KMD-WYN-BMERAH_2026-06-01']->id ?? null,
                'notes'                       => 'Panen padi merah organik varietas lokal Tabanan.',
            ],
        ];

        $harvests = [];
        foreach ($harvestsData as $key => $hData) {
            $harvests[$key] = Harvest::updateOrCreate(
                [
                    'user_id'   => $hData['user']->id,
                    'season_id' => $hData['season']->id,
                    'date'      => $hData['date'],
                ],
                [
                    'commodity_id'                => $hData['commodity']->id,
                    'weight_kg'                   => $hData['weight_kg'],
                    'quantity'                    => $hData['quantity'],
                    'unit'                        => $hData['unit'],
                    'status'                      => $hData['status'],
                    'market_price_snapshot'       => $hData['market_price_snapshot'],
                    'market_price_effective_date' => $hData['market_price_effective_date'],
                    'market_price_id'             => $hData['market_price_id'],
                    'notes'                       => $hData['notes'],
                ]
            );
        }

        // Catat mutasi stok panen mentah masuk gudang untuk masing-masing catatan panen
        foreach ($harvests as $hKey => $hModel) {
            StockTransaction::updateOrCreate(
                [
                    'user_id'              => $hModel->user_id,
                    'processed_product_id' => null,
                    'reference'            => 'HARV-' . $hModel->id,
                ],
                [
                    'type'          => 'in',
                    'amount'        => $hModel->weight_kg,
                    'unit'          => 'kg',
                    'notes'         => 'Penerimaan hasil panen masuk gudang komoditas.',
                    'balance_after' => $hModel->weight_kg,
                    'date'          => $hModel->date,
                ]
            );
        }

        $this->command?->info('  ✓ 9 Catatan panen riil dengan snapshot harga pasar historis disiapkan');

        // 9. Produk Olahan Hasil Hilirisasi Tani (Processed Products)
        $processedProductsData = [
            'beras_ciherang_5kg' => [
                'owner'               => $farmerSlamet,
                'harvest'             => $harvests['slamet_padi_h1'],
                'name'                => 'Beras Premium Ciherang 5kg',
                'price'               => 75000.00,
                'stock'               => 70,
                'raw_material_weight' => 5.50,
                'unit'                => 'sak',
                'description'         => 'Beras putih pulen alami tanpa pemutih dan tanpa pengawet. Kemasan praktis 5 kg higienis.',
                'status'              => 'active',
            ],
            'jagung_pipil_10kg' => [
                'owner'               => $farmerSlamet,
                'harvest'             => $harvests['slamet_jagung_h1'],
                'name'                => 'Jagung Pipil Kering Pakan & Pangan 10kg',
                'price'               => 68000.00,
                'stock'               => 45,
                'raw_material_weight' => 10.20,
                'unit'                => 'karung',
                'description'         => 'Jagung pipil kering kadar air rendah <14%, bersih dari kotoran dan serangga.',
                'status'              => 'active',
            ],
            'boncabe_rawit' => [
                'owner'               => $farmerBudi,
                'harvest'             => $harvests['budi_rawit_h1'],
                'name'                => 'Boncabe Rawit Super Pedas 100g',
                'price'               => 18000.00,
                'stock'               => 120,
                'raw_material_weight' => 0.35,
                'unit'                => 'botol',
                'description'         => 'Bubuk cabai rawit merah asli kering tanpa pewarna kimia, pedas nendang cocok untuk aneka camilan.',
                'status'              => 'active',
            ],
            'sambal_bawang_botol' => [
                'owner'               => $farmerBudi,
                'harvest'             => $harvests['budi_bawang_h1'],
                'name'                => 'Sambal Bawang Uleg Istimewa 150g',
                'price'               => 24000.00,
                'stock'               => 85,
                'raw_material_weight' => 0.20,
                'unit'                => 'botol',
                'description'         => 'Sambal bawang merah Brebes segar dimasak dengan minyak kelapa harum dan rempah pilihan.',
                'status'              => 'active',
            ],
            'bawang_goreng_brebes' => [
                'owner'               => $farmerBudi,
                'harvest'             => $harvests['budi_bawang_h1'],
                'name'                => 'Bawang Goreng Brebes Crispy 200g',
                'price'               => 35000.00,
                'stock'               => 95,
                'raw_material_weight' => 0.85,
                'unit'                => 'toples',
                'description'         => 'Bawang merah Brebes goreng renyah tanpa campuran tepung berlebih, gurih dan harum tahan lama.',
                'status'              => 'active',
            ],
            'jamur_crispy_ori' => [
                'owner'               => $farmerSiti,
                'harvest'             => $harvests['siti_jamur_h1'],
                'name'                => 'Jamur Crispy Gurih Original 150g',
                'price'               => 17500.00,
                'stock'               => 140,
                'raw_material_weight' => 0.40,
                'unit'                => 'pouch',
                'description'         => 'Keripik jamur tiram renyah dengan bumbu bawang gurih original. Camilan sehat berprotein tinggi.',
                'status'              => 'active',
            ],
            'jamur_crispy_balado' => [
                'owner'               => $farmerSiti,
                'harvest'             => $harvests['siti_jamur_h1'],
                'name'                => 'Jamur Crispy Pedas Balado 150g',
                'price'               => 18500.00,
                'stock'               => 110,
                'raw_material_weight' => 0.40,
                'unit'                => 'pouch',
                'description'         => 'Keripik jamur tiram dibalut bumbu balado pedas manis gurih nagih.',
                'status'              => 'active',
            ],
            'keripik_tempe_anjasmoro' => [
                'owner'               => $farmerJoko,
                'harvest'             => $harvests['joko_kedelai_h1'],
                'name'                => 'Keripik Tempe Kedelai Anjasmoro 250g',
                'price'               => 20000.00,
                'stock'               => 75,
                'raw_material_weight' => 0.35,
                'unit'                => 'pack',
                'description'         => 'Keripik tempe tipis gurih renyah dibuat dari kedelai lokal Anjasmoro non-GMO.',
                'status'              => 'active',
            ],
            'susu_kedelai_liter' => [
                'owner'               => $farmerJoko,
                'harvest'             => $harvests['joko_kedelai_h1'],
                'name'                => 'Susu Kedelai Murni Tanpa Pengawet 1L',
                'price'               => 15000.00,
                'stock'               => 30,
                'raw_material_weight' => 0.45,
                'unit'                => 'botol',
                'description'         => 'Sari kedelai kental manis alami kaya kalsium dan isoflavon, diproduksi higienis setiap hari.',
                'status'              => 'active',
            ],
            'beras_merah_vakum' => [
                'owner'               => $farmerWayan,
                'harvest'             => $harvests['wayan_berasmerah_h1'],
                'name'                => 'Beras Merah Organik Vakum 1kg',
                'price'               => 22000.00,
                'stock'               => 60,
                'raw_material_weight' => 1.10,
                'unit'                => 'pack',
                'description'         => 'Beras merah organik kemasan kedap udara (vakum) menjaga keawetan nutrisi dan bebas kutu.',
                'status'              => 'active',
            ],
        ];

        $products = [];
        foreach ($processedProductsData as $key => $pData) {
            $products[$key] = ProcessedProduct::updateOrCreate(
                [
                    'owner_id' => $pData['owner']->id,
                    'name'     => $pData['name'],
                ],
                [
                    'harvest_id'             => $pData['harvest']?->id,
                    'price'                  => $pData['price'],
                    'stock'                  => $pData['stock'],
                    'raw_material_weight_kg' => $pData['raw_material_weight'],
                    'unit'                   => $pData['unit'],
                    'description'            => $pData['description'],
                    'status'                 => $pData['status'],
                ]
            );
        }

        $this->command?->info('  ✓ 10 Produk olahan hilirisasi pertanian (beras, sambal, keripik, susu kedelai) disiapkan');

        // 10. Biaya Tambahan Pengolahan Produk (Production Costs - cost_type: 'processing')
        $processingCosts = [
            ['owner' => $farmerSlamet, 'product' => $products['beras_ciherang_5kg'], 'cat' => 'packaging', 'item' => 'Kantong Karung Beras Sablon 5kg (100 pcs)', 'amount' => 250000, 'date' => '2026-09-15', 'qty' => 100, 'unit' => 'pcs', 'price' => 2500],
            ['owner' => $farmerSlamet, 'product' => $products['beras_ciherang_5kg'], 'cat' => 'labor', 'item' => 'Upah Penggilingan & Pengemasan Beras', 'amount' => 300000, 'date' => '2026-09-16', 'qty' => 1, 'unit' => 'batch', 'price' => 300000],

            ['owner' => $farmerBudi, 'product' => $products['boncabe_rawit'], 'cat' => 'packaging', 'item' => 'Botol Bumbu Plastik & Segel Induksi 100g', 'amount' => 180000, 'date' => '2026-09-22', 'qty' => 150, 'unit' => 'botol', 'price' => 1200],
            ['owner' => $farmerBudi, 'product' => $products['boncabe_rawit'], 'cat' => 'labor', 'item' => 'Proses Pengeringan Oven & Penggilingan Halus', 'amount' => 150000, 'date' => '2026-09-23', 'qty' => 1, 'unit' => 'batch', 'price' => 150000],

            ['owner' => $farmerBudi, 'product' => $products['bawang_goreng_brebes'], 'cat' => 'raw_material_addon', 'item' => 'Minyak Goreng Sawit SunCo 10 Liter', 'amount' => 185000, 'date' => '2026-10-10', 'qty' => 10, 'unit' => 'liter', 'price' => 18500],
            ['owner' => $farmerBudi, 'product' => $products['bawang_goreng_brebes'], 'cat' => 'packaging', 'item' => 'Toples Tabung Pet 800ml & Stiker Label', 'amount' => 220000, 'date' => '2026-10-10', 'qty' => 100, 'unit' => 'toples', 'price' => 2200],

            ['owner' => $farmerSiti, 'product' => $products['jamur_crispy_ori'], 'cat' => 'raw_material_addon', 'item' => 'Tepung Beras, Maizena & Bumbu Gurih', 'amount' => 140000, 'date' => '2026-08-25', 'qty' => 1, 'unit' => 'paket', 'price' => 140000],
            ['owner' => $farmerSiti, 'product' => $products['jamur_crispy_ori'], 'cat' => 'packaging', 'item' => 'Standing Pouch Metalize Ziplock 150g', 'amount' => 195000, 'date' => '2026-08-25', 'qty' => 150, 'unit' => 'pouch', 'price' => 1300],

            ['owner' => $farmerJoko, 'product' => $products['keripik_tempe_anjasmoro'], 'cat' => 'packaging', 'item' => 'Plastik Kemasan Tebal & Desain Label', 'amount' => 120000, 'date' => '2026-09-30', 'qty' => 80, 'unit' => 'pack', 'price' => 1500],
            ['owner' => $farmerWayan, 'product' => $products['beras_merah_vakum'], 'cat' => 'packaging', 'item' => 'Plastik Vakum Khusus Beras 1kg (100 pcs)', 'amount' => 160000, 'date' => '2026-10-02', 'qty' => 100, 'unit' => 'pcs', 'price' => 1600],
        ];

        foreach ($processingCosts as $pCost) {
            ProductionCost::updateOrCreate(
                [
                    'user_id'              => $pCost['owner']->id,
                    'processed_product_id' => $pCost['product']->id,
                    'item_name'            => $pCost['item'],
                ],
                [
                    'cost_type'      => 'processing',
                    'date'           => $pCost['date'],
                    'category'       => $pCost['cat'],
                    'quantity'       => $pCost['qty'],
                    'unit'           => $pCost['unit'],
                    'price_per_unit' => $pCost['price'],
                    'amount'         => $pCost['amount'],
                    'notes'          => 'Biaya incremental pengolahan produk hilirisasi (anti double-counting).',
                ]
            );
        }

        $this->command?->info('  ✓ 10 Rincian biaya pengolahan produk olahan disiapkan');

        // 11. Diskon Promo Produk Olahan (Processed Product Discounts)
        $discountsData = [
            [
                'product'    => $products['boncabe_rawit'],
                'percentage' => 15.00,
                'start_date' => now()->subDays(5)->toDateString(),
                'end_date'   => now()->addDays(20)->toDateString(),
            ],
            [
                'product'    => $products['jamur_crispy_ori'],
                'percentage' => 10.00,
                'start_date' => now()->subDays(3)->toDateString(),
                'end_date'   => now()->addDays(15)->toDateString(),
            ],
            [
                'product'    => $products['bawang_goreng_brebes'],
                'percentage' => 12.50,
                'start_date' => now()->subDays(7)->toDateString(),
                'end_date'   => now()->addDays(10)->toDateString(),
            ],
        ];

        foreach ($discountsData as $disc) {
            ProcessedProductDiscount::updateOrCreate(
                [
                    'processed_product_id' => $disc['product']->id,
                    'start_date'           => $disc['start_date'],
                ],
                [
                    'discount_percentage' => $disc['percentage'],
                    'end_date'            => $disc['end_date'],
                    'created_by'          => $superAdmin->id,
                ]
            );
        }

        $this->command?->info('  ✓ 3 Diskon promo aktif produk olahan disiapkan');

        // 12. Transaksi Mutasi Stok (Stock Transactions)
        foreach ($products as $prodKey => $prod) {
            // Stok Masuk Awal (Batch Olahan)
            StockTransaction::updateOrCreate(
                [
                    'user_id'              => $prod->owner_id,
                    'processed_product_id' => $prod->id,
                    'type'                 => 'in',
                    'notes'                => 'Pencatatan batch produksi awal masuk gudang.',
                ],
                [
                    'amount'        => $prod->stock + 20, // misal awalnya diproduksi +20 sebelum ada penjualan
                    'unit'          => $prod->unit,
                    'reference'     => 'PROD-' . strtoupper(Str::slug($prod->name)),
                    'balance_after' => $prod->stock + 20,
                    'date'          => now()->subDays(25)->toDateString(),
                ]
            );

            // Mutasi Keluar Sebagian (Terjual di Toko Mitra / Offline)
            StockTransaction::updateOrCreate(
                [
                    'user_id'              => $prod->owner_id,
                    'processed_product_id' => $prod->id,
                    'type'                 => 'out',
                    'notes'                => 'Pengiriman penjualan perdana pesanan offline.',
                ],
                [
                    'amount'        => 20,
                    'unit'          => $prod->unit,
                    'reference'     => 'OUT-SAMPLE-' . $prod->id,
                    'balance_after' => $prod->stock,
                    'date'          => now()->subDays(10)->toDateString(),
                ]
            );
        }

        $this->command?->info('  ✓ 20 Rekor mutasi keluar-masuk stok gudang disiapkan');

        // 13. Transaksi Penjualan (Sales) - Bahan Baku Mentah & Produk Olahan
        $salesData = [
            // A. Penjualan Hasil Panen Mentah (product_type = 'harvest')
            'sale_padi_gabah' => [
                'user'            => $farmerSlamet,
                'season'          => $seasons['slamet_padi_s1'],
                'commodity'       => $commodities['KMD-SLM-PADI'],
                'product_type'    => 'harvest',
                'product'         => null,
                'created_by'      => $farmerSlamet->id,
                'date'            => '2026-09-18',
                'buyer_name'      => 'Koperasi Unit Desa Tani Makmur',
                'buyer_phone'     => '081344556677',
                'buyer_address'   => 'Jl. Raya Pertanian No. 12, Sukamaju',
                'weight_kg'       => 3500,
                'price_per_kg'    => 6900.00,
                'total'           => 3500 * 6900.00,
                'payment_status'  => 'paid',
                'notes'           => 'Penjualan gabah kering panen langsung ke KUD setelah penimbangan serentak.',
            ],
            'sale_jagung_mentah' => [
                'user'            => $farmerSlamet,
                'season'          => $seasons['slamet_jagung_s1'],
                'commodity'       => $commodities['KMD-SLM-JAGUNG'],
                'product_type'    => 'harvest',
                'product'         => null,
                'created_by'      => $farmerSlamet->id,
                'date'            => '2026-10-02',
                'buyer_name'      => 'Pengepul Jagung Pakan Pak Joko',
                'buyer_phone'     => '081266778811',
                'buyer_address'   => 'Kecamatan Tani Sejahtera',
                'weight_kg'       => 2500,
                'price_per_kg'    => 5700.00,
                'total'           => 2500 * 5700.00,
                'payment_status'  => 'paid',
                'notes'           => 'Penjualan jagung pipil curah kering panen.',
            ],
            'sale_cabai_mentah' => [
                'user'            => $farmerBudi,
                'season'          => $seasons['budi_rawit_s1'],
                'commodity'       => $commodities['KMD-BDI-RAWIT'],
                'product_type'    => 'harvest',
                'product'         => null,
                'created_by'      => $farmerBudi->id,
                'date'            => '2026-09-20',
                'buyer_name'      => 'Pedagang Sayur Pasar Induk Kramat Jati',
                'buyer_phone'     => '081388991122',
                'buyer_address'   => 'Lapak B-15 Pasar Induk Kramat Jati Jakarta',
                'weight_kg'       => 300,
                'price_per_kg'    => 46000.00,
                'total'           => 300 * 46000.00,
                'payment_status'  => 'paid',
                'notes'           => 'Cabai rawit segar petik pagi diantar ke pasar induk.',
            ],
            'sale_bawang_mentah' => [
                'user'            => $farmerBudi,
                'season'          => $seasons['budi_bawang_s1'],
                'commodity'       => $commodities['KMD-BDI-BAWANG'],
                'product_type'    => 'harvest',
                'product'         => null,
                'created_by'      => $farmerBudi->id,
                'date'            => '2026-10-12',
                'buyer_name'      => 'Grosir Bawang Merah Brebes Mas Doni',
                'buyer_phone'     => '085711224455',
                'buyer_address'   => 'Pasar Klampok Brebes',
                'weight_kg'       => 800,
                'price_per_kg'    => 33500.00,
                'total'           => 800 * 33500.00,
                'payment_status'  => 'paid',
                'notes'           => 'Bawang merah askip super siap kirim antarkota.',
            ],

            // B. Penjualan Produk Olahan (product_type = 'processed')
            'sale_beras_kemasan' => [
                'user'            => $farmerSlamet,
                'season'          => null,
                'commodity'       => null,
                'product_type'    => 'processed',
                'product'         => $products['beras_ciherang_5kg'],
                'created_by'      => $superAdmin->id,
                'date'            => '2026-10-15',
                'buyer_name'      => 'Toko Kelontong Berkah Mandiri',
                'buyer_phone'     => '081233445566',
                'buyer_address'   => 'Jl. Pahlawan No. 44, Semarang',
                'weight_kg'       => 20, // 20 sak
                'price_per_kg'    => 75000.00,
                'total'           => 20 * 75000.00,
                'payment_status'  => 'paid',
                'notes'           => 'Pesanan beras kemasan 5kg untuk display rak sembako.',
            ],
            'sale_boncabe_reseller' => [
                'user'            => $farmerBudi,
                'season'          => null,
                'commodity'       => null,
                'product_type'    => 'processed',
                'product'         => $products['boncabe_rawit'],
                'created_by'      => $superAdmin->id,
                'date'            => '2026-10-22',
                'buyer_name'      => 'Reseller Kuliner Pedas Bandung',
                'buyer_phone'     => '081399887711',
                'buyer_address'   => 'Jl. Buah Batu No. 101, Bandung',
                'weight_kg'       => 40, // 40 botol
                'price_per_kg'    => 18000.00,
                'total'           => 40 * 18000.00,
                'payment_status'  => 'paid',
                'notes'           => 'Order boncabe botolan untuk bahan bumbu seblak & makaroni.',
            ],
            'sale_jamur_crispy' => [
                'user'            => $farmerSiti,
                'season'          => null,
                'commodity'       => null,
                'product_type'    => 'processed',
                'product'         => $products['jamur_crispy_ori'],
                'created_by'      => $superAdmin->id,
                'date'            => '2026-09-28',
                'buyer_name'      => 'Toko Oleh-Oleh Khas Daerah Bu Nining',
                'buyer_phone'     => '081744556622',
                'buyer_address'   => 'Jl. Malioboro No. 58, Yogyakarta',
                'weight_kg'       => 50, // 50 pouch
                'price_per_kg'    => 17500.00,
                'total'           => 50 * 17500.00,
                'payment_status'  => 'paid',
                'notes'           => 'Pesanan jamur crispy original untuk gerai oleh-oleh.',
            ],
            'sale_bawang_goreng' => [
                'user'            => $farmerBudi,
                'season'          => null,
                'commodity'       => null,
                'product_type'    => 'processed',
                'product'         => $products['bawang_goreng_brebes'],
                'created_by'      => $superAdmin->id,
                'date'            => '2026-10-28',
                'buyer_name'      => 'Restoran Soto Kudus Barokah',
                'buyer_phone'     => '081299001144',
                'buyer_address'   => 'Jl. Fatmawati No. 25, Jakarta Selatan',
                'weight_kg'       => 30, // 30 toples
                'price_per_kg'    => 35000.00,
                'total'           => 30 * 35000.00,
                'payment_status'  => 'paid',
                'notes'           => 'Supply bawang goreng renyah toplesan untuk kuah soto.',
            ],
        ];

        $sales = [];
        foreach ($salesData as $key => $sData) {
            $sales[$key] = Sale::updateOrCreate(
                [
                    'user_id'    => $sData['user']->id,
                    'buyer_name' => $sData['buyer_name'],
                    'date'       => $sData['date'],
                ],
                [
                    'season_id'            => $sData['season']?->id,
                    'commodity_id'         => $sData['commodity']?->id,
                    'product_type'         => $sData['product_type'],
                    'processed_product_id' => $sData['product']?->id,
                    'created_by'           => $sData['created_by'],
                    'buyer_phone'          => $sData['buyer_phone'],
                    'buyer_address'        => $sData['buyer_address'],
                    'weight_kg'            => $sData['weight_kg'],
                    'price_per_kg'         => $sData['price_per_kg'],
                    'total'                => $sData['total'],
                    'payment_status'       => $sData['payment_status'],
                    'notes'                => $sData['notes'],
                ]
            );
        }

        // Catat pengeluaran stok panen mentah untuk penjualan komoditas mentah
        foreach ($sales as $sKey => $sModel) {
            if ($sModel->product_type === 'harvest') {
                StockTransaction::updateOrCreate(
                    [
                        'user_id'              => $sModel->user_id,
                        'processed_product_id' => null,
                        'reference'            => 'SALE-RAW-' . $sModel->id,
                    ],
                    [
                        'type'          => 'out',
                        'amount'        => $sModel->weight_kg,
                        'unit'          => 'kg',
                        'notes'         => 'Pengeluaran hasil panen untuk penjualan langsung ke pembeli.',
                        'balance_after' => 0,
                        'date'          => $sModel->date,
                    ]
                );
            }
        }

        // Rekalkulasi balance_after secara kronologis untuk tiap petani
        foreach ([$farmerSlamet, $farmerBudi, $farmerSiti, $farmerJoko, $farmerWayan] as $f) {
            $running = 0.0;
            $txs = StockTransaction::where('user_id', $f->id)
                ->whereNull('processed_product_id')
                ->orderBy('date')
                ->orderBy('id')
                ->get();
            foreach ($txs as $tx) {
                if ($tx->type === 'in') {
                    $running += (float) $tx->amount;
                } else {
                    $running -= (float) $tx->amount;
                }
                $tx->update(['balance_after' => $running]);
            }
        }

        $this->command?->info('  ✓ 8 Transaksi penjualan riil (mentah & produk olahan) disiapkan');

        // 14. Komisi Platform (Commissions)
        // Diberlakukan untuk penjualan produk olahan terpusat
        $commissionSales = [
            'sale_beras_kemasan',
            'sale_boncabe_reseller',
            'sale_jamur_crispy',
            'sale_bawang_goreng',
        ];

        foreach ($commissionSales as $sKey) {
            $sale = $sales[$sKey] ?? null;
            if (!$sale) continue;

            $rate = Commission::DEFAULT_RATE ?? 10.00;
            $baseAmount = (float) $sale->total;
            $commAmount = round(($baseAmount * $rate) / 100, 2);
            $netAmount  = $baseAmount - $commAmount;

            Commission::updateOrCreate(
                ['sale_id' => $sale->id],
                [
                    'order_id'          => null,
                    'user_id'           => $sale->user_id,
                    'rate'              => $rate,
                    'base_amount'       => $baseAmount,
                    'commission_amount' => $commAmount,
                    'net_farmer_amount' => $netAmount,
                    'status'            => 'settled',
                    'notes'             => 'Alokasi komisi platform/koperasi otomatis sesuai ketentuan 10%.',
                ]
            );
        }

        $this->command?->info('  ✓ 4 Rekor komisi transaksi platform disiapkan');

        // 15. Pesanan Katalog Publik (Orders & Order Items)
        $publicOrdersData = [
            [
                'code'    => 'ORD-20261101-001',
                'name'    => 'Anisa Maharani',
                'phone'   => '081288992211',
                'address' => 'Jl. Tebet Barat Raya No. 18, Jakarta Selatan',
                'status'  => 'completed',
                'notes'   => 'Tolong dipacking kardus tebal ya.',
                'items'   => [
                    ['product' => $products['beras_ciherang_5kg'], 'qty' => 2, 'price' => 75000],
                    ['product' => $products['bawang_goreng_brebes'], 'qty' => 2, 'price' => 35000],
                ],
            ],
            [
                'code'    => 'ORD-20261103-002',
                'name'    => 'Hendra Gunawan',
                'phone'   => '085611223344',
                'address' => 'Komplek Dago Asri Blok C-12, Bandung',
                'status'  => 'completed',
                'notes'   => 'Kirim via kurir ekspres.',
                'items'   => [
                    ['product' => $products['boncabe_rawit'], 'qty' => 4, 'price' => 18000],
                    ['product' => $products['jamur_crispy_ori'], 'qty' => 5, 'price' => 17500],
                ],
            ],
            [
                'code'    => 'ORD-20261105-003',
                'name'    => 'Ibu Maya Santika',
                'phone'   => '081977665544',
                'address' => 'Jl. Rungkut Madya No. 45, Surabaya',
                'status'  => 'processing',
                'notes'   => 'Pesanan untuk hampers kantor.',
                'items'   => [
                    ['product' => $products['beras_merah_vakum'], 'qty' => 5, 'price' => 22000],
                    ['product' => $products['sambal_bawang_botol'], 'qty' => 3, 'price' => 24000],
                ],
            ],
            [
                'code'    => 'ORD-20261108-004',
                'name'    => 'Bambang Trihatmono',
                'phone'   => '081322114455',
                'address' => 'Jl. Gejayan No. 22, Sleman, D.I. Yogyakarta',
                'status'  => 'confirmed',
                'notes'   => 'Sudah transfer bukti via WhatsApp.',
                'items'   => [
                    ['product' => $products['jamur_crispy_balado'], 'qty' => 3, 'price' => 18500],
                    ['product' => $products['keripik_tempe_anjasmoro'], 'qty' => 2, 'price' => 20000],
                ],
            ],
            [
                'code'    => 'ORD-20261109-005',
                'name'    => 'Rian Pratama',
                'phone'   => '087855443322',
                'address' => 'Jl. Pemuda No. 89, Semarang',
                'status'  => 'pending',
                'notes'   => 'Menunggu konfirmasi ketersediaan stok.',
                'items'   => [
                    ['product' => $products['susu_kedelai_liter'], 'qty' => 2, 'price' => 15000],
                    ['product' => $products['boncabe_rawit'], 'qty' => 2, 'price' => 18000],
                ],
            ],
        ];

        foreach ($publicOrdersData as $oData) {
            $totalAmount = 0;
            foreach ($oData['items'] as $item) {
                $totalAmount += $item['qty'] * $item['price'];
            }

            $order = Order::updateOrCreate(
                ['order_code' => $oData['code']],
                [
                    'customer_name'    => $oData['name'],
                    'customer_phone'   => $oData['phone'],
                    'customer_address' => $oData['address'],
                    'status'           => $oData['status'],
                    'total_amount'     => $totalAmount,
                    'notes'            => $oData['notes'],
                ]
            );

            // Re-create order items
            $order->items()->delete();
            foreach ($oData['items'] as $item) {
                OrderItem::create([
                    'order_id'             => $order->id,
                    'processed_product_id' => $item['product']->id,
                    'quantity'             => $item['qty'],
                    'price_snapshot'       => $item['price'],
                    'subtotal'             => $item['qty'] * $item['price'],
                ]);
            }
        }

        $this->command?->info('  ✓ 5 Pesanan katalog web publik dengan aneka status & rincian produk disiapkan');

        // 16. Berita & Artikel Edukasi Pertanian (News)
        $articles = [
            [
                'title'   => 'Pemberdayaan Rantai Pasok Digital untuk Kelompok Tani Mandiri',
                'slug'    => 'pemberdayaan-rantai-pasok-digital-kelompok-tani-mandiri',
                'content' => '<p>Platform digital SumberTani memfasilitasi transparansi tata niaga produk tani dari tingkat petani langsung ke pasar nasional. Dengan integrasi data harga pasar harian, kelompok tani dapat memantau estimasi pendapatan secara akurat sebelum melepas hasil panen ke tengkulak.</p><p>Hasil evaluasi kuartal ini membuktikan kenaikan rata-rata margin keuntungan bersih petani mitra sebesar 22,4% melalui program hilirisasi produk olahan bermutu.</p>',
                'status'  => 'published',
                'date'    => now()->subDays(4),
            ],
            [
                'title'   => 'Strategi Pengolahan Jamur Tiram Menjadi Camilan Bernilai Tinggi',
                'slug'    => 'strategi-pengolahan-jamur-tiram-camilan-bernilai-tinggi',
                'content' => '<p>Jamur tiram segar memiliki umur simpan yang sangat pendek (1–2 hari). Dengan teknologi penggorengan higienis dan penirisan minyak sentrifugal, kelompok tani binaan berhasil mentransformasikan panen berlimpah menjadi Keripik Jamur Crispy dengan daya tahan hingga 6 bulan.</p><p>Nilai jual produk olahan meningkat lebih dari 200% dibandingkan dengan penjualan jamur basah mentah.</p>',
                'status'  => 'published',
                'date'    => now()->subDays(6),
            ],
            [
                'title'   => 'Kiat Pengendalian Hama Ramah Lingkungan untuk Hortikultura Cabai',
                'slug'    => 'kiat-pengendalian-hama-ramah-lingkungan-cabai',
                'content' => '<p>Penggunaan pestisida nabati berbahan dasar daun mimba, serai wangi, dan tembakau terbukti efektif menekan serangan kutu kebul dan thrips pada tanaman cabai rawit tanpa meninggalkan residu kimia berbahaya.</p><p>Simak tips praktis pembuatan ekstrak nabati murah dan ramah lingkungan dalam ulasan lengkap berikut.</p>',
                'status'  => 'published',
                'date'    => now()->subDays(10),
            ],
            [
                'title'   => 'Peluang Pasar Beras Organik dan Beras Khusus di Pasar Modern',
                'slug'    => 'peluang-pasar-beras-organik-pasar-modern',
                'content' => '<p>Meningkatnya kesadaran masyarakat perkotaan akan pola hidup sehat membuka peluang luar biasa bagi varietas beras merah dan beras organik bersertifikat. Kelompok tani kini dapat memasarkan langsung produk kemasan vakum melalui katalog digital platform SumberTani.</p>',
                'status'  => 'published',
                'date'    => now()->subDays(14),
            ],
        ];

        foreach ($articles as $art) {
            News::updateOrCreate(
                ['slug' => $art['slug']],
                [
                    'title'        => $art['title'],
                    'content'      => $art['content'],
                    'image'        => null,
                    'status'       => $art['status'],
                    'published_at' => $art['date'],
                    'created_by'   => $superAdmin->id,
                ]
            );
        }

        $this->command?->info('  ✓ 4 Artikel berita pertanian & hilirisasi edukatif disiapkan');

        // 17. Feedback / Testimoni Petani
        $feedbacksData = [
            [
                'user'    => $farmerSlamet,
                'message' => 'Sistem pencatatan panen digital ini sangat membantu kami di Poktan Tani Makmur dalam menghitung biaya olah tanah dan pupuk secara transparan.',
                'status'  => 'read',
            ],
            [
                'user'    => $farmerBudi,
                'message' => 'Fitur snapshot harga pasar sangat bermanfaat. Sekarang kami tahu kapan waktu terbaik menjual cabai rawit dan mengolahnya menjadi boncabe.',
                'status'  => 'read',
            ],
            [
                'user'    => $farmerSiti,
                'message' => 'Alhamdulillah produk jamur crispy kami laris dipesan lewat katalog publik. Pembagian komisi transparan dan pencairannya tertib.',
                'status'  => 'unread',
            ],
            [
                'user'    => $farmerJoko,
                'message' => 'Mohon tambahkan fitur pengingat jadwal pemupukan lanjutan pada aplikasi mobile agar lebih praktis di lapangan.',
                'status'  => 'unread',
            ],
        ];

        foreach ($feedbacksData as $fb) {
            Feedback::updateOrCreate(
                [
                    'user_id' => $fb['user']->id,
                    'message' => $fb['message'],
                ],
                [
                    'status' => $fb['status'],
                ]
            );
        }

        $this->command?->info('  ✓ 4 Feedback petani untuk perbaikan berkelanjutan disiapkan');

        // 18. Notifikasi Pengguna (Notifications)
        $notificationsData = [
            [
                'user'    => $farmerSlamet,
                'type'    => 'penjualan',
                'title'   => 'Penjualan Beras Kemasan Terkonfirmasi',
                'message' => 'Pesanan 20 sak Beras Premium Ciherang 5kg telah berhasil dicatat dan pembayaran lunas.',
                'is_read' => true,
            ],
            [
                'user'    => $farmerBudi,
                'type'    => 'harga_pasar',
                'title'   => 'Update Harga Pasar Cabai Rawit',
                'message' => 'Harga pasar referensi Cabai Rawit Merah hari ini berada di level Rp 48.000/kg di PIHPS Nasional.',
                'is_read' => false,
            ],
            [
                'user'    => $farmerSiti,
                'type'    => 'stok_rendah',
                'title'   => 'Stok Jamur Crispy Menipis',
                'message' => 'Stok produk Jamur Crispy Gurih Original tersisa 140 pouch. Segera lakukan penjadwalan batch olahan baru.',
                'is_read' => false,
            ],
            [
                'user'    => $superAdmin,
                'type'    => 'pendaftaran_petani',
                'title'   => 'Akun Petani Baru Menunggu Persetujuan',
                'message' => 'Petani baru Ahmad Dahlan (Kebun Sayur Hijau Mandiri) dan Dewi Lestari sedang menunggu verifikasi akun.',
                'is_read' => false,
            ],
        ];

        foreach ($notificationsData as $notif) {
            Notification::updateOrCreate(
                [
                    'user_id' => $notif['user']->id,
                    'title'   => $notif['title'],
                ],
                [
                    'type'       => $notif['type'],
                    'message'    => $notif['message'],
                    'is_read'    => $notif['is_read'],
                    'created_at' => now()->subHours(rand(1, 48)),
                ]
            );
        }

        $this->command?->info('  ✓ 4 Notifikasi sistem penting disiapkan');

        // 15. Sample Log Login User Poktan (untuk chart aktivitas login)
        if (LoginLog::count() === 0) {
            $sampleLogins = [
                [$farmerSlamet, 'password', 'Desa Sumbersari, Jember', 0, 8, 15],
                [$farmerBudi,   'google',   'Desa Sukorejo, Malang',   0, 9, 40],
                [$farmerSiti,   'password', 'Desa Sumberjambe, Jember',1, 7, 20],
                [$farmerSlamet, 'password', 'Desa Sumbersari, Jember', 2, 14, 5],
                [$farmerBudi,   'google',   'Desa Sukorejo, Malang',   3, 10, 12],
                [$farmerSiti,   'password', 'Desa Sumberjambe, Jember',4, 16, 45],
                [$farmerSlamet, 'password', 'Desa Sumbersari, Jember', 6, 8, 50],
                [$farmerBudi,   'password', 'Desa Sukorejo, Malang',   10, 11, 30],
                [$farmerSiti,   'google',   'Desa Sumberjambe, Jember',14, 15, 10],
            ];

            foreach ($sampleLogins as [$u, $method, $loc, $daysAgo, $hour, $minute]) {
                if (!$u) continue;
                LoginLog::create([
                    'user_id'         => $u->id,
                    'farmer_group_id' => $u->farmer_group_id,
                    'login_method'    => $method,
                    'ip_address'      => '103.10.10.' . rand(10, 99),
                    'location'        => $loc,
                    'user_agent'      => 'Sumbersarihub Mobile App',
                    'logged_in_at'    => now()->subDays($daysAgo)->setTime($hour, $minute, 0),
                ]);
            }

            $this->command?->info('  ✓ 9 Log login user Poktan disiapkan');
        }

        $this->command?->info('🎉 DummyDataSeeder selesai dieksekusi dengan sukses!');
    }
}
