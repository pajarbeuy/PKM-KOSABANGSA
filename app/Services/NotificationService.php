<?php

namespace App\Services;

use App\Models\Notification as AppNotification;

class NotificationService
{
    /**
     * Get all notifications for a user, formatted for API response.
     */
    public function getUserNotifications(int $userId): array
    {
        $notifications = AppNotification::where('user_id', $userId)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($n) => [
                'id'         => $n->id,
                'type'       => $n->type,
                'title'      => $n->title,
                'message'    => $n->message,
                'is_read'    => (bool) $n->is_read,
                'created_at' => $n->created_at?->toIso8601String(),
            ]);

        return [
            'items'        => $notifications->values()->toArray(),
            'unread_count' => $notifications->where('is_read', false)->count(),
        ];
    }

    /**
     * Mark a single notification as read.
     */
    public function markOneAsRead(int $notificationId, int $userId): bool
    {
        $notification = AppNotification::where('id', $notificationId)
            ->where('user_id', $userId)
            ->first();

        if (!$notification) {
            return false;
        }

        $notification->markAsRead();
        return true;
    }

    /**
     * Mark all unread notifications for a user as read.
     */
    public function markAllAsRead(int $userId): void
    {
        AppNotification::where('user_id', $userId)
            ->where('is_read', false)
            ->update(['is_read' => true]);
    }
}
