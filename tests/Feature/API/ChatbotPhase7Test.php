<?php

namespace Tests\Feature\API;

use App\Models\FarmerCommodity;
use App\Models\FarmerGroup;
use App\Models\User;
use App\Services\OpenRouterService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ChatbotPhase7Test extends TestCase
{
    use RefreshDatabase;

    protected User $superAdmin;
    protected User $farmer;
    protected FarmerGroup $poktan;

    protected function setUp(): void
    {
        parent::setUp();

        $this->poktan = FarmerGroup::create([
            'name'   => 'Poktan Maju Makmur',
            'code'   => 'POKTAN-MM',
            'status' => 'active',
        ]);

        $this->superAdmin = User::factory()->create([
            'role' => 'super_admin',
            'name' => 'Pengurus BUMDes',
        ]);

        $this->farmer = User::factory()->create([
            'role' => 'user',
            'name' => 'Pak Tani Santoso',
            'farmer_group_id' => $this->poktan->id,
        ]);

        FarmerCommodity::create([
            'user_id' => $this->farmer->id,
            'name'    => 'Jamur Tiram',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        Config::set('chatbot.openrouter.api_key', '');
    }

    /** @test */
    public function test_farmer_can_chat_via_farmer_chat_endpoint(): void
    {
        Sanctum::actingAs($this->farmer);

        $response = $this->postJson('/api/farmer/chat', [
            'message' => 'Bagaimana cara mencegah hawar daun pada tanaman kentang?',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'role'    => 'farmer',
            ]);

        $reply = $response->json('reply');
        $this->assertNotEmpty($reply);
        $this->assertStringContainsString('Phytophthora', $reply);
    }

    /** @test */
    public function test_farmer_chat_explains_zero_double_counting(): void
    {
        Sanctum::actingAs($this->farmer);

        $response = $this->postJson('/api/farmer/chat', [
            'message' => 'Kenapa modal olahan jamur crispy bahan bakunya Rp 0 dan tidak double counting?',
        ]);

        $response->assertStatus(200);
        $reply = $response->json('reply');
        $this->assertStringContainsString('Zero Double-Counting', $reply);
        $this->assertStringContainsString('modal tanam hulu', $reply);
    }

    /** @test */
    public function test_openrouter_api_is_called_when_key_is_configured(): void
    {
        Config::set('chatbot.openrouter.api_key', 'test-openrouter-key');

        Http::fake([
            'https://openrouter.ai/api/v1/chat/completions' => Http::response([
                'id' => 'gen-123',
                'choices' => [
                    [
                        'message' => [
                            'role' => 'assistant',
                            'content' => 'Jawaban cerdas langsung dari model AI OpenRouter!',
                        ],
                    ],
                ],
            ], 200),
        ]);

        Sanctum::actingAs($this->farmer);

        $response = $this->postJson('/api/farmer/chat', [
            'message' => 'Berapa takaran pupuk untuk 1 hektar kentang?',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'source'  => 'openrouter',
                'reply'   => 'Jawaban cerdas langsung dari model AI OpenRouter!',
            ]);

        Http::assertSent(function ($request) {
            return $request->url() === 'https://openrouter.ai/api/v1/chat/completions'
                && $request->hasHeader('Authorization', 'Bearer test-openrouter-key')
                && str_contains($request['messages'][0]['content'], 'Poktan Maju Makmur');
        });
    }

    /** @test */
    public function test_openrouter_falls_back_gracefully_on_network_failure(): void
    {
        Config::set('chatbot.openrouter.api_key', 'test-openrouter-key');

        Http::fake([
            'https://openrouter.ai/api/v1/chat/completions' => Http::response([
                'error' => 'Rate limit exceeded',
            ], 429),
        ]);

        Sanctum::actingAs($this->superAdmin);

        $response = $this->postJson('/api/super-admin/chat', [
            'message' => 'Bagaimana cara melihat agregat laba rugi seluruh petani?',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'source'  => 'local_fallback',
                'role'    => 'super_admin',
            ]);

        $reply = $response->json('reply');
        $this->assertStringContainsString('Agregat Laba / Rugi Seluruh Petani', $reply);
    }

    /** @test */
    public function test_custom_context_override_is_injected_into_prompt(): void
    {
        $service = new OpenRouterService();
        $prompt = $service->buildSystemPrompt('farmer', $this->farmer, 'Fokuskan hanya pada budidaya jamur tiram putih di musim hujan.');

        $this->assertStringContainsString('Poktan Maju Makmur', $prompt);
        $this->assertStringContainsString('Jamur Tiram', $prompt);
        $this->assertStringContainsString('Fokuskan hanya pada budidaya jamur tiram putih di musim hujan', $prompt);
    }

    /** @test */
    public function test_openrouter_fails_over_to_next_candidate_model_with_same_context(): void
    {
        Config::set('chatbot.openrouter.api_key', 'test-openrouter-key');
        Config::set('chatbot.openrouter.model', 'qwen/qwen-2.5-72b-instruct:free');
        Config::set('chatbot.openrouter.fallback_models', ['meta-llama/llama-3.3-70b-instruct:free']);

        $requestCount = 0;

        Http::fake(function ($request) use (&$requestCount) {
            $requestCount++;
            // Panggilan pertama (native fallback / Qwen) gagal karena rate limit
            if ($requestCount === 1) {
                return Http::response(['error' => 'Qwen 2.5 is rate limited'], 429);
            }

            // Panggilan kedua (sequential fallback ke model berikutnya) berhasil
            return Http::response([
                'id' => 'gen-456',
                'model' => 'meta-llama/llama-3.3-70b-instruct:free',
                'choices' => [
                    [
                        'message' => [
                            'role' => 'assistant',
                            'content' => 'Balasan dari model cadangan LLaMA dengan konteks pertanian yang persis sama!',
                        ],
                    ],
                ],
            ], 200);
        });

        Sanctum::actingAs($this->farmer);

        $response = $this->postJson('/api/farmer/chat', [
            'message' => 'Bagaimana cara mengatasi hama busuk daun?',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'source'  => 'openrouter',
                'model'   => 'meta-llama/llama-3.3-70b-instruct:free',
                'reply'   => 'Balasan dari model cadangan LLaMA dengan konteks pertanian yang persis sama!',
            ]);

        $this->assertGreaterThanOrEqual(2, $requestCount);
    }
}
