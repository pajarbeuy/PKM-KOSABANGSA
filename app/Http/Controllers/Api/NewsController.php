<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\News;
use App\Services\NewsService;
use App\Traits\ApiResponseTrait;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class NewsController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly NewsService $newsService
    ) {}

    /**
     * Public endpoint: Get published news for landing page/mobile app.
     */
    public function publicIndex(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 10);
        $news = $this->newsService->getPublicNews($perPage);

        return $this->successResponse([
            'news' => $news->items(),
            'pagination' => [
                'current_page' => $news->currentPage(),
                'last_page'    => $news->lastPage(),
                'per_page'     => $news->perPage(),
                'total'        => $news->total(),
            ],
            'data' => $news->items(),
            'current_page' => $news->currentPage(),
            'last_page'    => $news->lastPage(),
            'per_page'     => $news->perPage(),
            'total'        => $news->total(),
        ], 'Daftar berita publik berhasil dimuat.');
    }

    /**
     * Public endpoint: Get a published news article by slug.
     */
    public function publicShow(string $slug): JsonResponse
    {
        try {
            $article = $this->newsService->getPublicNewsBySlug($slug);
            return $this->successResponse($article, 'Detail berita berhasil dimuat.');
        } catch (ModelNotFoundException $e) {
            return $this->notFoundResponse('Berita tidak ditemukan atau belum dipublikasikan.');
        }
    }

    /**
     * Admin endpoint: List all news with search & status filters.
     */
    public function index(Request $request): JsonResponse
    {
        $filters = $request->only(['status', 'search']);
        $perPage = (int) $request->input('per_page', 15);

        $news = $this->newsService->getAdminNews($filters, $perPage);

        return $this->successResponse([
            'news' => $news->items(),
            'pagination' => [
                'current_page' => $news->currentPage(),
                'last_page'    => $news->lastPage(),
                'per_page'     => $news->perPage(),
                'total'        => $news->total(),
            ],
            'data' => $news->items(),
            'current_page' => $news->currentPage(),
            'last_page'    => $news->lastPage(),
            'per_page'     => $news->perPage(),
            'total'        => $news->total(),
        ], 'Daftar berita berhasil dimuat.');
    }

    /**
     * Admin endpoint: Create news article.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak membuat berita.');
        }

        $validated = $request->validate([
            'title'        => 'required|string|max:255',
            'slug'         => 'nullable|string|max:255|unique:news,slug',
            'content'      => 'required|string',
            'image'        => 'nullable',
            'status'       => 'nullable|in:draft,published',
            'published_at' => 'nullable|date',
        ], [
            'title.required'   => 'Judul berita wajib diisi.',
            'content.required' => 'Konten berita wajib diisi.',
            'slug.unique'      => 'Slug berita sudah digunakan.',
        ]);

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('news', 'public');
            $validated['image'] = $path;
        }

        $article = $this->newsService->createNews($validated, $user->id);

        return $this->successResponse($article->load('author:id,name'), 'Berita berhasil dibuat.', 201);
    }

    /**
     * Admin endpoint: Show single news article.
     */
    public function show(int $id): JsonResponse
    {
        $article = News::with('author:id,name')->find($id);
        if (!$article) {
            return $this->notFoundResponse('Berita tidak ditemukan.');
        }

        return $this->successResponse($article, 'Detail berita berhasil dimuat.');
    }

    /**
     * Admin endpoint: Update news article.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak memperbarui berita.');
        }

        $article = News::find($id);
        if (!$article) {
            return $this->notFoundResponse('Berita tidak ditemukan.');
        }

        $validated = $request->validate([
            'title'        => 'nullable|string|max:255',
            'slug'         => "nullable|string|max:255|unique:news,slug,{$id}",
            'content'      => 'nullable|string',
            'image'        => 'nullable',
            'status'       => 'nullable|in:draft,published',
            'published_at' => 'nullable|date',
        ]);

        if ($request->hasFile('image')) {
            // Delete old file if stored locally
            if ($article->image && !str_starts_with($article->image, 'http')) {
                Storage::disk('public')->delete($article->image);
            }
            $path = $request->file('image')->store('news', 'public');
            $validated['image'] = $path;
        }

        $updated = $this->newsService->updateNews($article, $validated);

        return $this->successResponse($updated, 'Berita berhasil diperbarui.');
    }

    /**
     * Admin endpoint: Delete news article.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'super_admin') {
            return $this->forbiddenResponse('Hanya Super Admin yang berhak menghapus berita.');
        }

        $article = News::find($id);
        if (!$article) {
            return $this->notFoundResponse('Berita tidak ditemukan.');
        }

        if ($article->image && !str_starts_with($article->image, 'http')) {
            Storage::disk('public')->delete($article->image);
        }

        $this->newsService->deleteNews($article);

        return $this->successResponse(null, 'Berita berhasil dihapus.');
    }
}
