<?php

if (!function_exists('formatRupiah')) {
    /**
     * Format angka ke format Rupiah
     */
    function formatRupiah($value)
    {
        return 'Rp ' . number_format($value, 0, ',', '.');
    }
}

if (!function_exists('formatNumber')) {
    /**
     * Format angka dengan separator
     */
    function formatNumber($value, $decimal = 2)
    {
        return number_format($value, $decimal, ',', '.');
    }
}

if (!function_exists('getStatusBadge')) {
    /**
     * Get bootstrap badge class untuk status
     */
    function getStatusBadge($status)
    {
        return match($status) {
            'active', 'approved', 'paid', 'verified' => 'success',
            'pending' => 'warning',
            'rejected', 'cancelled', 'unpaid' => 'danger',
            'inactive' => 'secondary',
            default => 'info',
        };
    }
}

if (!function_exists('getStatusLabel')) {
    /**
     * Get label untuk status
     */
    function getStatusLabel($status)
    {
        return match($status) {
            'active' => 'Aktif',
            'inactive' => 'Tidak Aktif',
            'approved' => 'Disetujui',
            'pending' => 'Menunggu',
            'rejected' => 'Ditolak',
            'paid' => 'Lunas',
            'unpaid' => 'Belum Lunas',
            'verified' => 'Terverifikasi',
            'recorded' => 'Tercatat',
            'cancelled' => 'Dibatalkan',
            default => ucfirst($status),
        };
    }
}

if (!function_exists('notifyUser')) {
    /**
     * Send notification to user
     */
    function notifyUser($userId, $type, $title, $message)
    {
        \App\Models\Notification::create([
            'user_id' => $userId,
            'type' => $type,
            'title' => $title,
            'message' => $message,
        ]);
    }
}

if (!function_exists('getCurrentSetting')) {
    /**
     * Get setting value
     */
    function getCurrentSetting($key, $default = null)
    {
        return \App\Models\Setting::get($key, $default);
    }
}
