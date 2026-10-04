<?php

namespace App\Services;

use App\Models\News;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Str;

class NewsService
{
    /**
     * Get paginated published news for public landing page/mobile app.
     * Selects only required public fields to optimize performance and payload size.
     */
    public function getPublicNews(int $perPage = 10): LengthAwarePaginator
    {
        return News::published()
            ->select([
                'id',
                'title',
                'slug',
                'content',
                'image',
                'status',
                'published_at',
                'created_at',
                'created_by',
            ])
            ->with('author:id,name')
            ->latest('published_at')
            ->paginate($perPage);
    }

    /**
     * Get a single published news by slug for public detail view.
     */
    public function getPublicNewsBySlug(string $slug): News
    {
        return News::published()
            ->where('slug', $slug)
            ->with('author:id,name')
            ->firstOrFail();
    }

    /**
     * Get paginated news for Super Admin CMS.
     */
    public function getAdminNews(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = News::with('author:id,name')->latest('created_at');

        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (!empty($filters['search'])) {
            $search = $filters['search'];
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('content', 'like', "%{$search}%");
            });
        }

        return $query->paginate($perPage);
    }

    /**
     * Create news article.
     */
    public function createNews(array $data, int $userId): News
    {
        $title = $data['title'];
        $slug  = !empty($data['slug']) ? Str::slug($data['slug']) : $this->generateUniqueSlug($title);
        $status = $data['status'] ?? 'draft';

        $publishedAt = null;
        if ($status === 'published') {
            if (!empty($data['published_at'])) {
                $parsed = \Carbon\Carbon::parse($data['published_at']);
                $publishedAt = ($parsed->isFuture() && $parsed->diffInHours(now()) <= 14) ? now() : $parsed;
            } else {
                $publishedAt = now();
            }
        } elseif (!empty($data['published_at'])) {
            $publishedAt = $data['published_at'];
        }

        return News::create([
            'title'        => $title,
            'slug'         => $slug,
            'content'      => $data['content'],
            'image'        => $data['image'] ?? null,
            'status'       => $status,
            'published_at' => $publishedAt,
            'created_by'   => $userId,
        ]);
    }

    /**
     * Update existing news article.
     * Retains existing slug if not explicitly modified, preserving SEO and existing URLs.
     */
    public function updateNews(News $news, array $data): News
    {
        $payload = [];

        if (isset($data['title'])) {
            $payload['title'] = $data['title'];
        }

        // Only modify slug if explicitly passed
        if (!empty($data['slug']) && $data['slug'] !== $news->slug) {
            $payload['slug'] = $this->generateUniqueSlug($data['slug'], $news->id);
        }

        if (isset($data['content'])) {
            $payload['content'] = $data['content'];
        }

        if (array_key_exists('image', $data)) {
            $payload['image'] = $data['image'];
        }

        if (isset($data['status'])) {
            $payload['status'] = $data['status'];
            if ($data['status'] === 'published' && !$news->published_at && empty($data['published_at'])) {
                $payload['published_at'] = now();
            }
        }

        if (isset($data['published_at'])) {
            if (!empty($data['published_at'])) {
                $parsed = \Carbon\Carbon::parse($data['published_at']);
                $payload['published_at'] = ($parsed->isFuture() && $parsed->diffInHours(now()) <= 14) ? now() : $parsed;
            } else {
                $payload['published_at'] = null;
            }
        }

        $news->update($payload);

        return $news->fresh('author:id,name');
    }

    /**
     * Delete news article.
     */
    public function deleteNews(News $news): void
    {
        $news->delete();
    }

    /**
     * Generate unique slug by appending incremental counter if collision occurs.
     */
    public function generateUniqueSlug(string $title, ?int $ignoreId = null): string
    {
        $slug = Str::slug($title);
        $original = $slug;
        $count = 1;

        while (News::where('slug', $slug)->when($ignoreId, fn($q) => $q->where('id', '!=', $ignoreId))->exists()) {
            $slug = "{$original}-{$count}";
            $count++;
        }

        return $slug;
    }
}
