<?php

namespace Tests\Feature\API;

use App\Models\News;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NewsManagementTest extends TestCase
{
    use RefreshDatabase;

    private User $superAdmin;
    private User $farmer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superAdmin = User::factory()->create([
            'role'   => 'super_admin',
            'status' => 'active',
        ]);

        $this->farmer = User::factory()->create([
            'role'   => 'user',
            'status' => 'active',
        ]);
    }

    /** @test */
    public function test_super_admin_can_create_draft_and_published_news(): void
    {
        Sanctum::actingAs($this->superAdmin);

        // 1. Create draft news
        $draftResponse = $this->postJson('/api/super-admin/news', [
            'title'   => 'Promo Diskon Panen Raya',
            'content' => 'Konten promo diskon produk olahan tani.',
            'status'  => 'draft',
        ]);

        $draftResponse->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'title'  => 'Promo Diskon Panen Raya',
                    'slug'   => 'promo-diskon-panen-raya',
                    'status' => 'draft',
                ],
            ]);

        $this->assertDatabaseHas('news', [
            'title'  => 'Promo Diskon Panen Raya',
            'status' => 'draft',
        ]);

        // 2. Create published news
        $publishedResponse = $this->postJson('/api/super-admin/news', [
            'title'   => 'Peluncuran Fitur Baru SumberTani',
            'content' => 'Aplikasi SumberTani resmi merilis fitur pemesanan produk olahan.',
            'status'  => 'published',
        ]);

        $publishedResponse->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'status' => 'published',
                ],
            ]);

        $this->assertNotNull($publishedResponse->json('data.published_at'));
    }

    /** @test */
    public function test_slug_uniqueness_handles_collisions_gracefully(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $res1 = $this->postJson('/api/super-admin/news', [
            'title'   => 'Berita Pertanian Terkini',
            'content' => 'Konten pertama.',
        ]);
        $res1->assertStatus(201);
        $this->assertEquals('berita-pertanian-terkini', $res1->json('data.slug'));

        $res2 = $this->postJson('/api/super-admin/news', [
            'title'   => 'Berita Pertanian Terkini',
            'content' => 'Konten kedua dengan judul yang sama.',
        ]);
        $res2->assertStatus(201);
        $this->assertEquals('berita-pertanian-terkini-1', $res2->json('data.slug'));
    }

    /** @test */
    public function test_updating_news_preserves_existing_slug_unless_explicitly_changed(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $news = News::create([
            'title'        => 'Judul Asli Berita',
            'slug'         => 'judul-asli-berita',
            'content'      => 'Konten awal.',
            'status'       => 'published',
            'published_at' => now(),
            'created_by'   => $this->superAdmin->id,
        ]);

        // Update title without changing slug explicitly
        $updateResponse = $this->putJson("/api/super-admin/news/{$news->id}", [
            'title'   => 'Judul Berita Diperbarui',
            'content' => 'Konten revisi.',
        ]);

        $updateResponse->assertStatus(200);
        $news->refresh();
        $this->assertEquals('Judul Berita Diperbarui', $news->title);
        $this->assertEquals('judul-asli-berita', $news->slug); // Slug preserved
    }

    /** @test */
    public function test_draft_news_is_not_visible_on_public_endpoint(): void
    {
        // 1 Draft, 1 Published
        News::create([
            'title'      => 'Berita Rahasia Draft',
            'slug'       => 'berita-rahasia-draft',
            'content'    => 'Konten belum siap publik.',
            'status'     => 'draft',
            'created_by' => $this->superAdmin->id,
        ]);

        News::create([
            'title'        => 'Berita Publik Terbuka',
            'slug'         => 'berita-publik-terbuka',
            'content'      => 'Konten sudah dipublikasikan.',
            'status'       => 'published',
            'published_at' => now(),
            'created_by'   => $this->superAdmin->id,
        ]);

        $response = $this->getJson('/api/news');
        $response->assertStatus(200);

        $titles = collect($response->json('data.data'))->pluck('title');
        $this->assertTrue($titles->contains('Berita Publik Terbuka'));
        $this->assertFalse($titles->contains('Berita Rahasia Draft'));

        // Direct slug query on draft returns 404
        $draftDetailResponse = $this->getJson('/api/news/berita-rahasia-draft');
        $draftDetailResponse->assertStatus(404);

        // Direct slug query on published returns 200
        $publishedDetailResponse = $this->getJson('/api/news/berita-publik-terbuka');
        $publishedDetailResponse->assertStatus(200);
    }

    /** @test */
    public function test_public_news_is_paginated_and_returns_only_required_fields(): void
    {
        for ($i = 1; $i <= 15; $i++) {
            News::create([
                'title'        => "Berita Publik {$i}",
                'slug'         => "berita-publik-{$i}",
                'content'      => "Isi konten berita {$i}.",
                'status'       => 'published',
                'published_at' => now()->subMinutes(15 - $i),
                'created_by'   => $this->superAdmin->id,
            ]);
        }

        $response = $this->getJson('/api/news?per_page=5');
        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'data' => [
                        '*' => [
                            'id',
                            'title',
                            'slug',
                            'content',
                            'status',
                            'published_at',
                            'author',
                        ],
                    ],
                    'current_page',
                    'per_page',
                    'total',
                ],
            ]);

        $this->assertEquals(5, count($response->json('data.data')));
        $this->assertEquals(15, $response->json('data.total'));
    }

    /** @test */
    public function test_super_admin_can_delete_news(): void
    {
        Sanctum::actingAs($this->superAdmin);

        $news = News::create([
            'title'      => 'Berita Akan Dihapus',
            'slug'       => 'berita-akan-dihapus',
            'content'    => 'Konten.',
            'status'     => 'draft',
            'created_by' => $this->superAdmin->id,
        ]);

        $response = $this->deleteJson("/api/super-admin/news/{$news->id}");
        $response->assertStatus(200);

        $this->assertDatabaseMissing('news', ['id' => $news->id]);
    }

    /** @test */
    public function test_unauthorized_farmer_cannot_manage_news(): void
    {
        Sanctum::actingAs($this->farmer);

        $response = $this->postJson('/api/super-admin/news', [
            'title'   => 'Berita Palsu Petani',
            'content' => 'Konten.',
        ]);

        $response->assertStatus(403);
    }
}
