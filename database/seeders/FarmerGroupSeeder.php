<?php

namespace Database\Seeders;

use App\Models\FarmerGroup;
use Illuminate\Database\Seeder;

class FarmerGroupSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $groups = [
            [
                'name'        => 'Poktan 1 - Tani Makmur',
                'code'        => 'POKTAN-01',
                'village'     => 'Desa Sukamaju',
                'leader_name' => 'Bapak Slamet Raharjo',
                'description' => 'Kelompok Tani binaan spesialisasi komoditas palawija dan tanaman pangan.',
                'status'      => 'active',
            ],
            [
                'name'        => 'Poktan 2 - Subur Abadi',
                'code'        => 'POKTAN-02',
                'village'     => 'Desa Karanganyar',
                'leader_name' => 'Bapak Joko Waluyo',
                'description' => 'Kelompok Tani dengan fokus hortikultura buah-buahan dan sayuran segar.',
                'status'      => 'active',
            ],
            [
                'name'        => 'Poktan 3 - Harapan Maju',
                'code'        => 'POKTAN-03',
                'village'     => 'Desa Wanasari',
                'leader_name' => 'Ibu Sri Wahyuni',
                'description' => 'Kelompok Tani penggerak budidaya jamur tiram dan pengolahan kripik jamur.',
                'status'      => 'active',
            ],
            [
                'name'        => 'Poktan 4 - Berkah Tani',
                'code'        => 'POKTAN-04',
                'village'     => 'Desa Margaluyu',
                'leader_name' => 'Bapak Asep Saepudin',
                'description' => 'Kelompok Tani sentra umbi-umbian, talas, dan singkong unggul lokal.',
                'status'      => 'active',
            ],
            [
                'name'        => 'Poktan 5 - Karya Tani',
                'code'        => 'POKTAN-05',
                'village'     => 'Desa Pasirhuni',
                'leader_name' => 'Bapak Dedi Kusnadi',
                'description' => 'Kelompok Tani pengembang pisang ambon dan diversifikasi olahan sale pisang.',
                'status'      => 'active',
            ],
            [
                'name'        => 'Poktan 6 - Sinar Harapan',
                'code'        => 'POKTAN-06',
                'village'     => 'Desa Cibodas',
                'leader_name' => 'Bapak Ujang Supriatna',
                'description' => 'Kelompok Tani dataran tinggi dengan fokus kentang dan cabai merah keriting.',
                'status'      => 'active',
            ],
            [
                'name'        => 'Poktan 7 - Mandiri Sejahtera',
                'code'        => 'POKTAN-07',
                'village'     => 'Desa Bojongloa',
                'leader_name' => 'Bapak Hendra Gunawan',
                'description' => 'Kelompok Tani berorientasi pupuk organik mandiri dan pertanian berkelanjutan.',
                'status'      => 'active',
            ],
            [
                'name'        => 'Poktan 8 - Tunas Mekar',
                'code'        => 'POKTAN-08',
                'village'     => 'Desa Sukamulya',
                'leader_name' => 'Ibu Siti Aminah',
                'description' => 'Kelompok Tani pembibitan komoditas unggul dan tanaman herbal rempah.',
                'status'      => 'active',
            ],
            [
                'name'        => 'Poktan 9 - Gemah Ripah',
                'code'        => 'POKTAN-09',
                'village'     => 'Desa Tanjungsari',
                'leader_name' => 'Bapak Agus Setiawan',
                'description' => 'Kelompok Tani sentra jagung manis dan pakan silase ternak berkualitas.',
                'status'      => 'active',
            ],
            [
                'name'        => 'Poktan 10 - Tani Bersatu',
                'code'        => 'POKTAN-10',
                'village'     => 'Desa Mekarwangi',
                'leader_name' => 'Bapak Cecep Hidayat',
                'description' => 'Kelompok Tani terpadu integrasi tanaman pangan dan produk olahan kripik.',
                'status'      => 'active',
            ],
        ];

        foreach ($groups as $group) {
            FarmerGroup::updateOrCreate(
                ['code' => $group['code']],
                $group
            );
        }
    }
}
