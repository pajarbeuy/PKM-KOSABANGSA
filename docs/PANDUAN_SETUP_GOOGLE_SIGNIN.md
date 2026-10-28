# Panduan Setup & Konfigurasi Google Sign-In — SumberTani

Dokumen ini menjelaskan langkah-langkah konfigurasi Google OAuth 2.0 untuk backend Laravel REST API dan aplikasi Flutter (Android & Web) pada sistem **SumberTani berbasis AI**.

---

## 1. Arsitektur Autentikasi

```
+----------------+          +-------------------------+          +-----------------------+
|  Flutter App   |  (1)     |  Google OAuth Service   |          |    Laravel Backend    |
| (Mobile / Web) | -------> |    (Google Sign-In)     |          |   (Sanctum API Auth)  |
+----------------+          +-------------------------+          +-----------------------+
        |                                |                                   |
        |  (2) id_token                  |                                   |
        +--------------------------------+                                   |
        |                                                                    |
        |  (3) POST /api/auth/google { "id_token": "..." }                  |
        +------------------------------------------------------------------> |
        |                                                                    |
        |                                  (4) Verifikasi tokeninfo ke Google|
        |                                      tokeninfo?id_token=...        |
        |                                  <-------------------------------> |
        |                                                                    |
        |                                  (5) Match / Auto-create User      |
        |                                      + simpan UserOauthIdentity    |
        |                                      + create Sanctum token        |
        |                                                                    |
        |  (6) Response 200 { success: true, data: { token, user } }         |
        | <------------------------------------------------------------------+
        |
        v
Simpan Bearer Token di SharedPreferences
Masuk ke Dashboard Poktan
```

---

## 2. Langkah Setup di Google Cloud Console

1. Buka [Google Cloud Console](https://console.cloud.google.com/).
2. Buat project baru atau pilih project yang sudah ada (contoh: `sumbertani-app`).
3. Buka menu **APIs & Services** > **OAuth consent screen**:
   - Pilih User Type: **External**
   - Isi **App name**: `SumberTani`
   - Isi **User support email** dan **Developer contact information**.
   - Tambahkan scope: `.../auth/userinfo.email` dan `.../auth/userinfo.profile`.
   - Simpan dan lanjutkan.
4. Buka menu **APIs & Services** > **Credentials**:

### A. Buat Web Client ID (Wajib untuk verifikasi backend & web)
- Klik **Create Credentials** > **OAuth client ID**.
- Application type: **Web application**.
- Name: `SumberTani Web Client`.
- Klik **Create**.
- Salin **Client ID** (contoh format: `XXXXXXXXXXXX-YYYYYYYYYYYY.apps.googleusercontent.com`).

### B. Buat Android Client ID (Untuk aplikasi Android)
- Klik **Create Credentials** > **OAuth client ID**.
- Application type: **Android**.
- Name: `SumberTani Android Client`.
- Package name: periksa file `mobile_app/android/app/build.gradle.kts` (default: `com.example.mobile_app` atau namespace resmi).
- Dapatkan SHA-1 certificate fingerprint dari debug keystore lokal dengan perintah:
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```
- Tempelkan nilai **SHA-1** ke kolom fingerprint di Google Cloud Console.
- Klik **Create**.

---

## 3. Konfigurasi Backend Laravel

Tambahkan Client ID yang diperoleh ke file `.env` di backend:

```env
# Google OAuth (Google Sign-In)
GOOGLE_CLIENT_ID=XXXXXXXXXXXX-YYYYYYYYYYYY.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=XXXXXXXXXXXX-ZZZZZZZZZZZZ.apps.googleusercontent.com
```

Jalankan migration database saat database MySQL aktif:
```bash
php artisan migrate
```

Tabel baru yang dibuat:
- `user_oauth_identities`: Menyimpan relasi `provider` ('google'), `provider_user_id` (Google `sub`), email, nama, dan avatar yang terhubung ke tabel `users`.

---

## 4. Konfigurasi Flutter Mobile App

Package `google_sign_in` telah ditambahkan di [pubspec.yaml](file:///d:/laragon/www/PKM/mobile_app/pubspec.yaml).

### Android
Pastikan SHA-1 fingerprint dari keystore rilis/debug telah terdaftar di Google Cloud Console. Tidak wajib menambahkan `google-services.json` jika hanya menggunakan Google Sign-In standar tanpa Firebase.

### Web (Flutter Web)
Aplikasi membaca Client ID secara dinamis via `--dart-define=GOOGLE_CLIENT_ID=...`. Tidak perlu mengubah atau meng-hardcode tag `<meta>` di `web/index.html`.

Jalankan di Chrome dengan perintah:
```bash
flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=913573270503-vpd62vl8a38p8jmug5i50fbjc6h515o1.apps.googleusercontent.com
```

Atau saat build web untuk produksi:
```bash
flutter build web --release --dart-define=GOOGLE_CLIENT_ID=913573270503-vpd62vl8a38p8jmug5i50fbjc6h515o1.apps.googleusercontent.com
```

---

## 5. Spesifikasi API Endpoint

### Endpoint: `POST /api/auth/google`

**Rate Limiting**: `throttle:auth` (6 percobaan / menit).

#### Request Headers:
```http
Content-Type: application/json
Accept: application/json
```

#### Request Body:
```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij..."
}
```

#### Response Sukses (200 OK):
```json
{
  "success": true,
  "message": "Login berhasil.",
  "data": {
    "token": "1|abcdef123456...",
    "token_type": "Bearer",
    "is_new_account": false,
    "user": {
      "id": 15,
      "email": "petani@gmail.com",
      "name": "Budi Santoso",
      "role": "poktan",
      "status": "active",
      "approval_status": "approved",
      "farm_name": "Kebun Petani",
      "phone": null,
      "farmer_group_id": null
    }
  }
}
```

#### Kasus Error Respons:
- **422 Unprocessable Content**: Field `id_token` tidak diisi atau kurang dari 10 karakter.
- **401 Unauthorized**: ID token tidak valid, telah kedaluwarsa, atau Client ID tidak cocok.
- **403 Forbidden**: Akun pengguna berstatus `inactive` atau status persetujuan `rejected`/`pending`.

---

## 6. Kebijakan Bisnis & Keamanan

1. **Auto-Link Email Sama**: Jika email akun Google sudah terdaftar sebelumnya melalui register form biasa, sistem langsung mengaitkan identitas Google tersebut ke akun lokal yang ada tanpa membuat duplikat user.
2. **Akun Baru Otomatis**: Jika pengguna baru masuk via Google, akun Poktan langsung dibuat dengan status `active` dan persetujuan `approved` (mengikuti standar registrasi).
3. **Penyimpanan Password Aman**: Akun baru via Google diberi password acak terenkripsi (64 karakter acak), sehingga login password biasa dicegah kecuali pengguna melakukan reset password.
4. **Verifikasi Server-Side**: Token ID diverifikasi langsung di backend ke server Google (`https://oauth2.googleapis.com/tokeninfo`), sehingga token palsu atau manipulasi sisi client langsung ditolak.
5. **Pencabutan Token (Revocation)**: Saat logout di aplikasi Flutter, token Sanctum di database backend dihapus dan sesi Google Sign-In di perangkat ditutup (`GoogleSignIn().signOut()`).
