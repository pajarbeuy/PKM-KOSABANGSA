<?php

namespace App\Http\Controllers;

use App\Models\Notification as AppNotification;
use App\Services\NotificationService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly NotificationService $notificationService) {}

    public function index(Request $request)
    {
        $data = $this->notificationService->getUserNotifications($request->user()->id);
        return $this->successResponse($data, 'Notifikasi berhasil diambil.');
    }

    public function markAsRead(Request $request)
    {
        $validated = $request->validate([
            'notification_id' => 'nullable|integer',
        ]);

        $userId = $request->user()->id;

        if (isset($validated['notification_id'])) {
            $found = $this->notificationService->markOneAsRead($validated['notification_id'], $userId);
            if (!$found) {
                return $this->notFoundResponse('Notifikasi tidak ditemukan.');
            }
        } else {
            $this->notificationService->markAllAsRead($userId);
        }

        return $this->successResponse(null, 'Notifikasi berhasil ditandai dibaca.');
    }
}
