<?php

namespace Database\Seeders;

use App\Models\DashboardMenu;
use App\Models\LandingContent;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create demo users
        User::create([
            'name' => 'Admin Demo',
            'email' => 'admin@simhpsk.com',
            'password' => Hash::make('admin123'),
            'phone' => '081234567890',
            'farm_name' => 'Farm Indonesia Jaya',
            'role' => 'user',
            'status' => 'active',
            'approval' => 'approved',
        ]);

        User::create([
            'name' => 'Super Admin Demo',
            'email' => 'superadmin@simhpsk.com',
            'password' => Hash::make('superadmin123'),
            'phone' => '089876543210',
            'farm_name' => 'SIMHPSK Central',
            'role' => 'super_admin',
            'status' => 'active',
            'approval' => 'approved',
        ]);

        // Create landing page content
        $landingContent = [
            'hero_title' => 'Kelola Panen dan Stok Kentang dengan Mudah',
            'hero_description' => 'Sistem Informasi Manajemen Panen dan Stok Kentang yang membantu Anda mengelola usaha pertanian dengan lebih efisien dan menguntungkan.',
            'hero_cta_1' => 'Daftar Sekarang',
            'hero_cta_2' => 'Login',
            'feature_1_title' => 'Manajemen Stok Real-time',
            'feature_1_desc' => 'Pantau stok gudang Anda secara real-time dengan akurasi tinggi dan laporan otomatis.',
            'feature_2_title' => 'Analisis Panen & Produksi',
            'feature_2_desc' => 'Analisis mendalam tentang performa panen dan produktivitas lahan Anda.',
            'feature_3_title' => 'Laporan Keuangan Otomatis',
            'feature_3_desc' => 'Laporan keuangan lengkap dan analisis untung/rugi secara otomatis setiap hari.',
            'feature_4_title' => 'Manajemen Karyawan',
            'feature_4_desc' => 'Kelola data karyawan dan distribusi tugas dengan mudah dan terstruktur.',
            'feature_5_title' => 'Export PDF/Excel',
            'feature_5_desc' => 'Export semua laporan dalam format PDF atau Excel untuk keperluan bisnis Anda.',
            'feature_6_title' => 'Responsive Design',
            'feature_6_desc' => 'Akses dari desktop, tablet, atau smartphone kapan saja dan di mana saja.',
        ];

        foreach ($landingContent as $section => $content) {
            LandingContent::create([
                'section' => $section,
                'content' => $content,
            ]);
        }

        // Create default settings
        \App\Models\Setting::set('min_stock', 100);
        \App\Models\Setting::set('max_stock', 5000);
        \App\Models\Setting::set('notify_low_stock', 1);
        \App\Models\Setting::set('notify_new_sale', 1);
        \App\Models\Setting::set('notify_cost', 1);

        // Create default dashboard menus
        $menus = [
            ['title' => 'Stok Gudang', 'icon' => 'bi-box-seam', 'color' => '#1A7A4A', 'description' => 'Manajemen stok gudang real-time', 'url' => '/stock', 'sort_order' => 1],
            ['title' => 'Analisis Panen', 'icon' => 'bi-bar-chart', 'color' => '#27AE60', 'description' => 'Analisis data panen dan produksi', 'url' => '/harvests', 'sort_order' => 2],
            ['title' => 'Laporan Keuangan', 'icon' => 'bi-graph-up-arrow', 'color' => '#F5A623', 'description' => 'Laporan keuangan otomatis', 'url' => '/report.profit-loss', 'sort_order' => 3],
            ['title' => 'Penjualan', 'icon' => 'bi-shop', 'color' => '#3498db', 'description' => 'Kelola penjualan dan pembeli', 'url' => '/sales', 'sort_order' => 4],
            ['title' => 'Biaya Produksi', 'icon' => 'bi-cash-coin', 'color' => '#e74c3c', 'description' => 'Catat biaya produksi', 'url' => '/costs', 'sort_order' => 5],
            ['title' => 'Musim Tanam', 'icon' => 'bi-calendar', 'color' => '#9b59b6', 'description' => 'Manajemen musim tanam', 'url' => '/seasons', 'sort_order' => 6],
        ];

        foreach ($menus as $menu) {
            DashboardMenu::create($menu);
        }
    }
}
