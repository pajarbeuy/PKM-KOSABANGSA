<?php

namespace App\Services;

use App\Models\Feedback;

class FeedbackService
{
    /**
     * Create feedback from a user.
     */
    public function createFeedback(int $userId, string $message): Feedback
    {
        return Feedback::create([
            'user_id' => $userId,
            'message' => $message,
            'status'  => 'unread',
        ]);
    }

    /**
     * Get all feedbacks for super admin view (eager loads user).
     */
    public function getAllFeedbacks()
    {
        return Feedback::with('user')->latest()->get();
    }

    /**
     * Mark a feedback as read.
     */
    public function markAsRead(Feedback $feedback): Feedback
    {
        $feedback->update(['status' => 'read']);
        return $feedback;
    }

    /**
     * Delete a feedback.
     */
    public function deleteFeedback(Feedback $feedback): void
    {
        $feedback->delete();
    }
}
