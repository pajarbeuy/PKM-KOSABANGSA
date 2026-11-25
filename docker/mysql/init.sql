-- ============================================================
-- docker/mysql/init.sql
-- Inisialisasi database (dijalankan sekali saat container pertama kali dibuat)
-- ============================================================

CREATE DATABASE IF NOT EXISTS `sumbertani`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
