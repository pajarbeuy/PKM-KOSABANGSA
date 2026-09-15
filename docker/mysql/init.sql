-- ============================================================
-- docker/mysql/init.sql
-- Inisialisasi database (dijalankan sekali saat container pertama kali dibuat)
-- ============================================================

CREATE DATABASE IF NOT EXISTS `pertanian_kentang`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Pastikan user memiliki akses penuh ke database
GRANT ALL PRIVILEGES ON `pertanian_kentang`.* TO '${DB_USERNAME}'@'%';
FLUSH PRIVILEGES;
