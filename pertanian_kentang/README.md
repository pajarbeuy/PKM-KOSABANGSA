# SIMHPSK - Sistem Informasi Manajemen Panen dan Stok Kentang

Aplikasi web lengkap untuk mengelola usaha pertanian kentang dengan fitur manajemen panen, stok gudang, penjualan, dan laporan keuangan.

## Fitur Utama

### 🌾 Produksi
- **Manajemen Musim Tanam**: Buat dan kelola musim tanam dengan status (Aktif, Selesai, Dibatalkan)
- **Pencatatan Panen**: Catat hasil panen dengan foto, catatan, dan tracking otomatis

### 📦 Gudang
- **Manajemen Stok Real-time**: Monitor stok gudang dengan akurasi tinggi
- **Transaksi Stok**: Log semua transaksi masuk/keluar dengan balance tracking
- **Alert Otomatis**: Notifikasi jika stok di bawah minimum atau melebihi kapasitas

### 💰 Keuangan
- **Penjualan**: Catat semua transaksi penjualan dengan status pembayaran
- **Biaya Produksi**: Kelola biaya (bibit, pupuk, pestisida, lainnya) per musim
- **Laporan Untung/Rugi**: Analisis keuangan otomatis dengan export PDF/Excel
- **Target vs Realisasi**: Bandingkan target dengan realisasi panen per musim

### 👥 Super Admin
- **Manajemen User**: CRUD user dengan role dan approval system
- **Landing Page Editor**: Edit konten landing page langsung dari dashboard
- **Tambah Menu Dashboard**: Customisasi menu dashboard dengan ikon dan warna

### 🎨 Desain
- **Bootstrap 5.3**: UI modern dan responsive
- **Bootstrap Icons**: 1000+ icon untuk berbagai kebutuhan
- **Chart.js**: Visualisasi data panen dan keuangan
- **Custom Styling**: Warna hijau pertanian (#1A7A4A) dengan aksen kuning (#F5A623)

## Teknologi Stack

- **Backend**: Laravel 11
- **Frontend**: Bootstrap 5.3 + Blade Templating
- **Database**: MySQL
- **Charts**: Chart.js
- **Icons**: Bootstrap Icons
- **PHP**: 8.2+

## Setup & Instalasi

### Prerequisites
- PHP 8.2+
- Composer
- MySQL 5.7+
- Node.js & NPM (opsional untuk asset compilation)

### Langkah-langkah Instalasi

1. **Clone Repository**
```bash
cd /path/to/pertanian_kentang
```

2. **Copy Environment File**
```bash
cp .env.example .env
```

3. **Generate App Key**
```bash
php artisan key:generate
```

4. **Setup Database**
- Buat database baru: `CREATE DATABASE simhpsk;`
- Update `.env` dengan credential database Anda:
```
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=simhpsk
DB_USERNAME=root
DB_PASSWORD=
```

5. **Run Migrations**
```bash
php artisan migrate
```

6. **Seed Database (Demo Data)**
```bash
php artisan db:seed
```

7. **Start Server**
```bash
php artisan serve
```

Server akan berjalan di: `http://localhost:8000`

## Demo Credentials

**Admin User:**
- Email: `admin@simhpsk.com`
- Password: `admin123`

**Super Admin User:**
- Email: `superadmin@simhpsk.com`
- Password: `superadmin123`

## Struktur Database

### Tabel Utama
- `users` - Data pengguna dengan role (admin/super_admin)
- `seasons` - Data musim tanam
- `harvests` - Pencatatan panen
- `stock_transactions` - Log transaksi stok
- `sales` - Data penjualan
- `production_costs` - Data biaya produksi
- `settings` - Konfigurasi sistem
- `notifications` - Notifikasi pengguna
- `dashboard_menus` - Menu dashboard yang dapat dikustomisasi
- `landing_contents` - Konten landing page

## Struktur Folder

```
├── app/
│   ├── Models/          → Database models
│   └── Http/
│       ├── Controllers/ → Business logic
│       └── Middleware/  → Middleware custom
├── database/
│   ├── migrations/      → Database schema
│   └── seeders/         → Demo data
├── resources/
│   ├── views/           → Blade templates
│   │   ├── layouts/     → Master layouts
│   │   ├── components/  → Reusable components
│   │   ├── pages/       → Page templates
│   │   └── super-admin/ → Super admin pages
│   └── css/
│       └── app.css      → Custom styling
├── routes/
│   └── web.php          → Web routes
└── config/              → Configuration files
```

## Fitur & Menu

### Admin Dashboard
- **Dashboard**: Overview statistik dan charts
- **Produksi**: Musim Tanam, Pencatatan Panen
- **Gudang**: Manajemen Stok & Transaksi
- **Keuangan**: Penjualan, Biaya Produksi
- **Laporan**: Untung/Rugi, Target vs Realisasi
- **Pengaturan**: Profile, Password, Gudang, Notifikasi

### Super Admin Dashboard
- **Dashboard**: Statistik user
- **Manajemen User**: CRUD user + approval system
- **Edit Landing Page**: Customize hero & fitur section
- **Tambah Menu Dashboard**: Customisasi menu dengan icon & warna
- **View Only Mode**: Akses semua menu admin sebagai read-only

## Warna & Styling

```css
--color-primary: #1A7A4A     /* Hijau Pertanian */
--color-accent: #F5A623      /* Kuning Alert */
--color-success: #27AE60     /* Hijau Sukses */
--color-danger: #E74C3C      /* Merah Bahaya */
--radius-input: 8px          /* Border radius input */
--radius-card: 12px          /* Border radius card */
```

## API Endpoints

### Authentication
- `GET /` - Landing page
- `POST /login` - User login
- `POST /register` - User registration
- `POST /logout` - User logout

### Admin Routes (Protected)
- `GET /dashboard` - Dashboard
- `GET|POST /seasons` - Musim tanam
- `GET|POST /harvests` - Panen
- `GET|POST /stock` - Stok gudang
- `GET|POST /sales` - Penjualan
- `GET|POST /costs` - Biaya produksi
- `GET /reports/profit-loss` - Laporan untung/rugi
- `GET /reports/target-vs-actual` - Target vs realisasi
- `GET|POST /settings` - Pengaturan

### Super Admin Routes (Protected)
- `GET /super-admin` - Super admin dashboard
- `GET|POST|PUT|DELETE /super-admin/users` - Manajemen user
- `GET|POST /super-admin/landing-editor` - Edit landing
- `GET|POST|PUT|DELETE /super-admin/menus` - Manajemen menu

## Security

- ✅ CSRF Protection di semua form
- ✅ Password hashing dengan bcrypt
- ✅ Authentication middleware
- ✅ Authorization gates & policies
- ✅ Input validation
- ✅ SQL injection prevention (Eloquent ORM)

## Troubleshooting

### Database connection error
```
Pastikan MySQL running dan .env database config sudah benar
php artisan config:clear
```

### Missing migrations
```
php artisan migrate --fresh
php artisan db:seed
```

### Storage permission error
```
chmod -R 775 storage/
chmod -R 775 bootstrap/cache/
```

## Support

Untuk pertanyaan atau issue, silahkan hubungi tim development.

## License

SIMHPSK © 2024. All rights reserved.

Laravel is accessible, powerful, and provides tools required for large, robust applications.

## Learning Laravel

Laravel has the most extensive and thorough [documentation](https://laravel.com/docs) and video tutorial library of all modern web application frameworks, making it a breeze to get started with the framework.

In addition, [Laracasts](https://laracasts.com) contains thousands of video tutorials on a range of topics including Laravel, modern PHP, unit testing, and JavaScript. Boost your skills by digging into our comprehensive video library.

You can also watch bite-sized lessons with real-world projects on [Laravel Learn](https://laravel.com/learn), where you will be guided through building a Laravel application from scratch while learning PHP fundamentals.

## Agentic Development

Laravel's predictable structure and conventions make it ideal for AI coding agents like Claude Code, Cursor, and GitHub Copilot. Install [Laravel Boost](https://laravel.com/docs/ai) to supercharge your AI workflow:

```bash
composer require laravel/boost --dev

php artisan boost:install
```

Boost provides your agent 15+ tools and skills that help agents build Laravel applications while following best practices.

## Contributing

Thank you for considering contributing to the Laravel framework! The contribution guide can be found in the [Laravel documentation](https://laravel.com/docs/contributions).

## Code of Conduct

In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
