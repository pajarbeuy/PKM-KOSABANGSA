# 🚀 Panduan Deployment: Docker Hub Workflow & Domain sumbersarihub.web.id

**Konsep Alur (Paling Cepat & Ringan untuk VPS):**
1. **Lokal (PC Anda):**
   - Build Flutter APK (dengan API `https://sumbersarihub.web.id/api`)
   - Taruh APK di folder `public/download/sumbertani.apk`
   - Build Docker Image Backend (`docker build`)
   - Push Image ke Docker Hub (`docker push`)
2. **VPS Server:**
   - Tidak perlu git pull / clone full repo
   - Cukup buat 1 folder berisi `docker-compose.yml` dan `.env.production`
   - Tarik image dari Docker Hub (`docker compose pull`)
   - Jalankan (`docker compose up -d`)
3. **Domain & SSL:**
   - Hubungkan domain dari **Sumopod** ke **Cloudflare** untuk mendapatkan **SSL HTTPS Gratis Otomatis**.

---

## 📌 DAFTAR ISI
1. [Bagian 1: Setting Domain (Sumopod + Cloudflare)](#bagian-1-setting-domain-sumopod--cloudflare)
2. [Bagian 2: Persiapan di PC Lokal (Build & Push Docker Hub)](#bagian-2-persiapan-di-pc-lokal-build--push-docker-hub)
3. [Bagian 3: Setup & Menjalankan di VPS (Docker Pull)](#bagian-3-setup--menjalankan-di-vps-docker-pull)
4. [Bagian 4: Verifikasi & Test Download APK](#bagian-4-verifikasi--test-download-apk)
5. [Bagian 5: Alur Update di Masa Depan (Jika ada perubahan kode)](#bagian-5-alur-update-di-masa-depan)

---

## Bagian 1: Setting Domain (Sumopod + Cloudflare)

> [!TIP]
> **Mengapa pakai Cloudflare?**  
> Sumopod adalah registrar tempat Anda membeli domain. Jika memakai Cloudflare, Anda tidak perlu repot install sertifikat SSL (Certbot) di VPS, tidak perlu takut sertifikat kadaluarsa, dan website langsung mendapatkan HTTPS resmi secara otomatis.

### Langkah 1.1: Daftar & Tambahkan Domain di Cloudflare
1. Buka [dash.cloudflare.com](https://dash.cloudflare.com) (login atau daftar gratis).
2. Klik **"Add a domain"** atau **"Add Site"**.
3. Masukkan: `sumbersarihub.web.id`, pilih paket **Free ($0)**.
4. Cloudflare akan menampilkan 2 buah **Nameserver**, contohnya:
   - `alec.ns.cloudflare.com`
   - `amy.ns.cloudflare.com`
   *(Catat 2 alamat nameserver ini)*.

### Langkah 1.2: Ubah Nameserver di Panel Sumopod
1. Login ke panel akun **Sumopod** Anda.
2. Buka menu **Domain Management / Kelola Domain** -> pilih domain `sumbersarihub.web.id`.
3. Cari menu **Nameserver (NS)**.
4. Ubah dari *"Default Sumopod Nameservers"* menjadi *"Custom Nameservers"*.
5. Masukkan 2 nameserver dari Cloudflare tadi:
   - Nameserver 1: `alec.ns.cloudflare.com`
   - Nameserver 2: `amy.ns.cloudflare.com`
6. Klik **Simpan / Update Nameserver**.  
   *(Proses propagasi biasanya butuh 5–30 menit)*.

### Langkah 1.3: Atur DNS Record di Cloudflare
Kembali ke dashboard Cloudflare -> pilih domain `sumbersarihub.web.id` -> menu **DNS** -> **Records**:
Tambahkan 2 baris berikut:

| Type | Name | IPv4 address | Proxy status | TTL |
|---|---|---|---|---|
| **A** | `@` | `[IP_PUBLIC_VPS_ANDA]` | **Proxied (Awan Oranye)** | Auto |
| **A** | `www` | `[IP_PUBLIC_VPS_ANDA]` | **Proxied (Awan Oranye)** | Auto |

Terakhir, buka menu **SSL/TLS** di Cloudflare -> pilih mode enkripsi: **Full** (atau **Flexible**).

---

## Bagian 2: Persiapan di PC Lokal (Build & Push Docker Hub)

Pastikan Docker Desktop sudah aktif di PC/Laptop Anda dan Anda sudah login ke Docker Hub (`docker login`).

### Langkah 2.1: Build Flutter APK
Di terminal PowerShell laptop:
```powershell
cd d:\laragon\www\PKM\mobile_app

# 1. Build APK release
flutter build apk --release `
  --dart-define=BASE_URL=https://sumbersarihub.web.id/api `
  --dart-define=GOOGLE_CLIENT_ID=913573270503-vpd62vl8a38p8jmug5i50fbjc6h515o1.apps.googleusercontent.com

# 2. Salin APK hasil build ke folder download publik Laravel
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "..\public\download\sumbertani.apk" -Force
```

### Langkah 2.2: Build Docker Image Backend
Pindah ke root folder project PKM:
```powershell
cd d:\laragon\www\PKM

# Ganti 'USERNAME_DOCKERHUB' dengan username akun Docker Hub Anda
# Contoh: ifan/sumbertani-app:latest
docker build -t USERNAME_DOCKERHUB/sumbertani-app:latest .
```

### Langkah 2.3: Push Image ke Docker Hub
```powershell
docker push USERNAME_DOCKERHUB/sumbertani-app:latest
```
Tunggu hingga proses upload selesai (100%).

---

## Bagian 3: Setup & Menjalankan di VPS (Docker Pull)

Sekarang login ke VPS Anda via SSH (misal via PuTTY atau terminal):
```bash
ssh root@IP_PUBLIC_VPS_ANDA
```

### Langkah 3.1: Buat Folder Kerja di VPS
```bash
mkdir -p ~/sumbertani
cd ~/sumbertani
```

### Langkah 3.2: Buat File `docker-compose.yml` di VPS
Ketik:
```bash
nano docker-compose.yml
```
Salin dan tempel isi berikut (pastikan mengganti `USERNAME_DOCKERHUB`):

```yaml
version: '3.8'

services:

  # ── 1. Laravel App (PHP-FPM + Nginx) ─────────────────────────
  app:
    image: ${APP_IMAGE:-USERNAME_DOCKERHUB/sumbertani-app:latest}
    container_name: sumbertani_app
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - APP_ENV=production
      - APP_DEBUG=false
    env_file:
      - .env.production
    volumes:
      - app_storage:/var/www/html/storage/app
      - app_logs:/var/www/html/storage/logs
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    networks:
      - sumbertani_net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # ── 2. MySQL Database ────────────────────────────────────────
  db:
    image: mysql:8.0
    container_name: sumbertani_db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: ${DB_DATABASE:-sumbertani}
      MYSQL_USER: ${DB_USERNAME:-sumbertani_user}
      MYSQL_PASSWORD: ${DB_PASSWORD:-ganti_password_db_ini}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD:-ganti_password_root_ini}
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - sumbertani_net
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${DB_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # ── 3. Redis Cache ───────────────────────────────────────────
  cache:
    image: redis:7-alpine
    container_name: sumbertani_cache
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD:-ganti_password_redis_ini} --maxmemory 128mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    networks:
      - sumbertani_net

volumes:
  db_data:
  redis_data:
  app_storage:
  app_logs:

networks:
  sumbertani_net:
    driver: bridge
```
Simpan (`Ctrl + O`, `Enter`, lalu `Ctrl + X`).

---

### Langkah 3.3: Buat File `.env.production` di VPS
Ketik:
```bash
nano .env.production
```
Salin dan tempel konfigurasi ini:

```ini
APP_NAME="SumberTani AI"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://sumbersarihub.web.id
APP_TIMEZONE=Asia/Jakarta

# Docker Image Tag
APP_IMAGE=USERNAME_DOCKERHUB/sumbertani-app:latest

APP_LOCALE=id
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=id_ID

APP_MAINTENANCE_DRIVER=file

CORS_ALLOWED_ORIGINS="https://sumbersarihub.web.id,http://localhost:5000"
CORS_SUPPORTS_CREDENTIALS=true
SANCTUM_EXPIRATION=10080

BCRYPT_ROUNDS=12

LOG_CHANNEL=stack
LOG_STACK=daily
LOG_DAILY_DAYS=14
LOG_LEVEL=error

# ── Database ───────────────────────────────────────────────
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=sumbertani
DB_USERNAME=sumbertani_user
DB_PASSWORD=BuatPasswordDatabaseKuat123!
DB_ROOT_PASSWORD=BuatPasswordRootKuat123!

# ── Redis ──────────────────────────────────────────────────
SESSION_DRIVER=redis
CACHE_STORE=redis
QUEUE_CONNECTION=redis
REDIS_CLIENT=phpredis
REDIS_HOST=cache
REDIS_PASSWORD=BuatPasswordRedisKuat123!
REDIS_PORT=6379

FILESYSTEM_DISK=public

# ── Google OAuth ───────────────────────────────────────────
GOOGLE_CLIENT_ID=913573270503-vpd62vl8a38p8jmug5i50fbjc6h515o1.apps.googleusercontent.com

# ── OpenRouter AI ──────────────────────────────────────────
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxx
OPENROUTER_MODEL=qwen/qwen3.8-27b:free
```
Simpan (`Ctrl + O`, `Enter`, lalu `Ctrl + X`).

---

### Langkah 3.4: Jalankan Container!
Di VPS dalam folder `~/sumbertani`:
```bash
# 1. Tarik image dari Docker Hub
docker compose pull

# 2. Jalankan container di background
docker compose up -d

# 3. Cek status
docker compose ps
```

Container akan otomatis:
- Menunggu database MySQL siap.
- Menjalankan migrasi database Laravel (`php artisan migrate --force`).
- Men-generate `APP_KEY` jika kosong.
- Meng-cache config, route, dan view.
- Membuat symlink storage.

Untuk melihat log startup:
```bash
docker compose logs -f app
```

---

## Bagian 4: Verifikasi & Test Download APK

1. **Buka di Browser:**  
   Kunjungi `https://sumbersarihub.web.id`
   - Pastikan gembok hijau HTTPS aktif (dari Cloudflare).
   - Tampilan landing page muncul.
2. **Uji Tombol Download:**  
   - Klik tombol **"Unduh APK"** di Navbar atau **"Unduh Aplikasi Android (.apk)"** di banner utama.
   - File `sumbertani.apk` akan langsung terdownload.
3. **Uji di HP Android:**  
   - Install APK tersebut di HP Android.
   - Buka aplikasi dan login (koneksi API otomatis terhubung ke `https://sumbersarihub.web.id/api`).

---

## Bagian 5: Alur Update di Masa Depan

Jika nanti ada perubahan fitur/kode di laptop lokal Anda:

1. Di laptop:
   ```powershell
   # Jika ada update mobile app:
   flutter build apk --release ...
   Copy-Item "...\app-release.apk" "..\public\download\sumbertani.apk" -Force

   # Build & push image baru:
   docker build -t USERNAME_DOCKERHUB/sumbertani-app:latest .
   docker push USERNAME_DOCKERHUB/sumbertani-app:latest
   ```

2. Di VPS (cukup 2 perintah sederhana):
   ```bash
   cd ~/sumbertani
   docker compose pull
   docker compose up -d
   ```
Server VPS Anda akan otomatis berganti ke versi terbaru tanpa downtime lama!
