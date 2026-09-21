# Git Workflow & CI/CD Rules

## 1. Tujuan

Repository ini menggunakan Git sebagai version control yang terstruktur.

Git tidak hanya digunakan untuk melakukan `push`, tetapi untuk:

* memisahkan pekerjaan berdasarkan fitur/perbaikan
* menjaga branch `main` tetap stabil
* memudahkan rollback
* memudahkan review perubahan
* menjalankan automated testing melalui CI/CD
* menandai versi aplikasi menggunakan Git tag

AI Agent WAJIB mengikuti workflow ini ketika melakukan perubahan pada repository.

---

## 2. Branch Utama

Branch utama:

```text
main
```

`main` harus selalu merepresentasikan kondisi aplikasi yang relatif stabil.

AI Agent TIDAK BOLEH langsung melakukan perubahan fitur ke `main`, kecuali perubahan tersebut secara eksplisit diminta oleh user.

Semua pekerjaan baru harus dilakukan melalui branch terpisah.

---

## 3. Branch Naming Convention

Gunakan prefix berikut:

### Feature

Untuk fitur baru:

```text
feature/<nama-fitur>
```

Contoh:

```text
feature/processed-products
feature/customer-order
feature/marketing-management
```

### Bug Fix

Untuk memperbaiki bug:

```text
fix/<nama-bug>
```

Contoh:

```text
fix/product-image-cors
fix/dashboard-season
fix/stock-calculation
```

### Refactor

Untuk perubahan struktur kode tanpa perubahan behavior utama:

```text
refactor/<nama-refactor>
```

Contoh:

```text
refactor/api-service
refactor/sale-service
```

### Documentation

Untuk perubahan dokumentasi:

```text
docs/<nama-dokumentasi>
```

Contoh:

```text
docs/git-workflow
docs/api-documentation
```

Gunakan nama branch yang singkat, jelas, dan menggunakan kebab-case.

---

## 4. Workflow Sebelum Memulai Perubahan

Sebelum mengubah kode:

1. Periksa branch saat ini.

```bash
git branch --show-current
```

2. Pastikan working tree bersih.

```bash
git status
```

3. Update `main` jika diperlukan.

```bash
git checkout main
git pull origin main
```

4. Buat branch baru dari `main`.

Contoh:

```bash
git checkout -b feature/processed-products
```

Jangan membuat branch fitur berdasarkan branch fitur lama kecuali user secara eksplisit meminta hal tersebut.

---

## 5. Satu Branch untuk Satu Tujuan

Satu branch harus memiliki satu tujuan utama.

Contoh yang benar:

```text
feature/processed-products
```

berisi perubahan untuk fitur produk olahan.

Jangan mencampurkan:

```text
feature/processed-products
```

dengan:

* refactor authentication
* perubahan dashboard
* perbaikan chatbot
* perubahan unrelated UI

Jika ditemukan perubahan lain yang tidak berhubungan, jangan otomatis memasukkannya ke branch tersebut.

---

## 6. Commit Convention

Gunakan Conventional Commits.

Format:

```text
<type>: <description>
```

Type yang digunakan:

```text
feat
fix
refactor
test
docs
chore
perf
```

Contoh:

```text
feat: add processed product management
fix: prevent negative processed product stock
refactor: split product API service
test: add processed product service tests
docs: document git workflow
chore: update dependencies
```

Gunakan commit yang kecil dan memiliki tujuan jelas.

Hindari commit seperti:

```text
update
fix
changes
final
final fix
final fix 2
final banget
```

Commit message harus menjelaskan perubahan yang dilakukan.

---

## 7. Jangan Membuat Commit Palsu

AI Agent tidak boleh membuat commit hanya untuk terlihat memiliki progress.

Commit hanya dilakukan ketika terdapat perubahan nyata dan masuk akal untuk disimpan sebagai satu unit perubahan.

---

## 8. Testing Sebelum Commit

Sebelum membuat commit, AI Agent harus menjalankan test yang relevan dengan perubahan.

Backend Laravel minimal:

```bash
php artisan test
```

Flutter minimal:

```bash
flutter analyze
```

Jika project memiliki test Flutter yang relevan:

```bash
flutter test
```

Jika perubahan menyentuh API, database, authentication, authorization, stock, order, atau business logic, test backend yang relevan WAJIB dijalankan.

Jika perubahan menyentuh UI Flutter, `flutter analyze` WAJIB dijalankan.

Jika test gagal:

* jangan mengabaikan failure
* jangan menghapus test hanya agar CI hijau
* identifikasi penyebab failure
* perbaiki implementasi atau test sesuai penyebab sebenarnya

---

## 9. Jangan Mengubah Test Hanya Agar Lulus

AI Agent tidak boleh memodifikasi atau menghapus test hanya untuk membuat:

```text
PASS
```

kecuali behavior aplikasi memang sengaja berubah dan test tersebut memang harus diperbarui berdasarkan requirement baru.

Perubahan test harus mengikuti perubahan requirement, bukan sebaliknya.

---

## 10. Pull Request

Setelah implementasi selesai dan test lokal berhasil:

```bash
git push -u origin <branch-name>
```

Kemudian buat Pull Request:

```text
feature/processed-products
        ↓
      main
```

Pull Request harus menjelaskan:

* tujuan perubahan
* masalah yang diselesaikan
* file/komponen utama yang berubah
* test yang dijalankan
* hasil test
* potensi breaking changes
* database migration jika ada

AI Agent tidak boleh menganggap branch sudah boleh di-merge hanya karena kode berhasil dibuat.

---

## 11. CI Pipeline

Setiap Pull Request menuju `main` harus menjalankan automated checks.

Minimal pipeline:

```text
Pull Request
     │
     ├── Backend dependency check
     ├── Laravel tests
     ├── Flutter analyze
     └── Flutter tests
             │
             ▼
        CI PASS / FAIL
```

Jika CI gagal, perubahan belum dianggap siap untuk merge.

CI harus menjadi pemeriksaan otomatis, bukan pengganti testing lokal.

---

## 12. Merge ke Main

Branch hanya boleh di-merge setelah:

1. perubahan selesai
2. test lokal relevan berhasil
3. CI berhasil
4. tidak ada unresolved conflict
5. perubahan sesuai requirement

Setelah merge:

```text
feature/*
       ↓
      main
```

Branch fitur yang sudah selesai dapat dihapus.

---

## 13. Versioning

Project menggunakan Semantic Versioning:

```text
MAJOR.MINOR.PATCH
```

Format:

```text
v1.0.0
```

### PATCH

Untuk bug fix atau perubahan kecil yang tidak menambah fitur baru.

Contoh:

```text
v1.0.1
```

### MINOR

Untuk penambahan fitur baru yang tetap backward compatible.

Contoh:

```text
v1.1.0
```

### MAJOR

Untuk perubahan besar yang menyebabkan breaking changes.

Contoh:

```text
v2.0.0
```

Jangan membuat tag versi untuk setiap commit.

Tag digunakan untuk menandai release/version yang dianggap stabil.

---

## 14. Release Workflow

Contoh:

```text
feature/processed-products
          │
          ▼
       Pull Request
          │
          ▼
       CI Testing
          │
          ▼
        main
          │
          ▼
      Release
          │
          ▼
        v1.1.0
```

Tag dibuat setelah versi tersebut dianggap stabil.

Contoh:

```bash
git checkout main
git pull origin main

git tag -a v1.1.0 -m "Release v1.1.0"
git push origin v1.1.0
```

---

## 15. AI Agent Tidak Boleh Mengubah Release Secara Sembarangan

AI Agent tidak boleh:

* membuat tag release tanpa instruksi user
* menghapus tag
* mengubah tag yang sudah dipublish
* force push ke `main`
* force push ke branch orang lain
* melakukan `git reset --hard` yang dapat menghapus pekerjaan user
* melakukan `git push --force` tanpa instruksi eksplisit

Jika terdapat kondisi yang berpotensi menghapus atau menimpa pekerjaan user, berhenti dan jelaskan kondisi tersebut.

---

## 16. Database Migration

Jika perubahan membutuhkan database migration:

1. migration harus dibuat dalam branch fitur
2. migration harus diuji
3. migration harus dicatat dalam Pull Request
4. jangan mengubah migration lama yang sudah digunakan pada environment production tanpa alasan yang sangat kuat

Prefer membuat migration baru daripada mengedit migration lama yang sudah pernah dijalankan.

---

## 17. CI/CD dan Deployment

CI dan CD harus dipisahkan secara konsep.

### CI

CI bertugas memastikan kode dapat:

```text
Build
Test
Analyze
Validate
```

### CD

CD bertugas melakukan deployment setelah kondisi yang ditentukan terpenuhi.

Untuk tahap awal project:

```text
Pull Request
    ↓
CI
    ↓
Merge main
    ↓
Release Tag
    ↓
CD / Deployment
```

Deployment production tidak boleh otomatis hanya karena developer melakukan push ke sembarang branch.

Production deployment harus menggunakan kondisi/release yang jelas.

---

## 18. Prinsip Utama untuk AI Agent

Urutan prioritas:

```text
Requirement
    ↓
Branch
    ↓
Implementation
    ↓
Local Test
    ↓
Commit
    ↓
Push
    ↓
Pull Request
    ↓
CI
    ↓
Merge
    ↓
Release Tag
    ↓
CD
```

AI Agent harus menjaga pemisahan antara:

```text
development
testing
merge
release
deployment
```

Jangan melewati tahapan hanya karena perubahan terlihat sederhana.

---

## 19. Expected Behavior AI Agent

Ketika user mengatakan:

> "Buat fitur X"

AI Agent harus memahami bahwa pekerjaan tersebut merupakan perubahan terisolasi.

Contoh:

```text
User:
"Buat fitur customer order."

AI Agent:

1. cek git status
2. update branch main
3. buat feature/customer-order
4. implementasi
5. test
6. review perubahan
7. commit
8. push branch
9. laporkan hasil dan status CI/PR
```

Ketika user mengatakan:

> "Fix bug foto produk."

AI Agent menggunakan:

```text
fix/product-image-cors
```

bukan langsung mengubah `main`.

---

## 20. Prinsip Keamanan Git

AI Agent harus menganggap command berikut sebagai operasi berisiko tinggi:

```bash
git reset --hard
git clean -fd
git push --force
git branch -D
git tag -d
```

Jangan menjalankan command tersebut tanpa alasan yang jelas dan tanpa memastikan tidak ada pekerjaan user yang akan hilang.

---

## 21. Definition of Done

Sebuah perubahan dianggap selesai apabila:

* [ ] requirement terpenuhi
* [ ] branch khusus digunakan
* [ ] kode telah direview
* [ ] test relevan berhasil
* [ ] tidak ada error analyzer
* [ ] commit memiliki message yang jelas
* [ ] branch sudah dipush
* [ ] Pull Request dibuat jika workflow repository menggunakannya
* [ ] CI berhasil
* [ ] migration terdokumentasi jika ada
* [ ] release tag dibuat jika perubahan masuk release
* [ ] deployment dilakukan sesuai release policy

AI Agent harus melaporkan status setiap tahap secara ringkas dan jujur.
