<?php

namespace App\Http\Controllers;

use App\Models\Feedback;
use App\Services\FeedbackService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class FeedbackController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly FeedbackService $feedbackService) {}

    public function store(Request $request)
    {
        $validated = $request->validate([
            'message' => 'required|string|max:1000',
        ]);

        $feedback = $this->feedbackService->createFeedback($request->user()->id, $validated['message']);

        return $this->successResponse($feedback, 'Ulasan/Feedback berhasil dikirim! Terima kasih.', 201);
    }

    public function indexSuperAdmin()
    {
        return $this->successResponse(
            $this->feedbackService->getAllFeedbacks(),
            'Daftar ulasan berhasil diambil.'
        );
    }

    public function markAsRead(Feedback $feedback)
    {
        $updated = $this->feedbackService->markAsRead($feedback);
        return $this->successResponse($updated, 'Ulasan ditandai sudah dibaca.');
    }

    public function destroy(Feedback $feedback)
    {
        $this->feedbackService->deleteFeedback($feedback);
        return $this->successResponse(null, 'Ulasan berhasil dihapus.');
    }
}
