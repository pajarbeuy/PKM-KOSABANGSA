<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Feedback;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FeedbackTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'user']);
    }

    /** @test */
    public function user_can_submit_feedback()
    {
        $response = $this->actingAs($this->user)
            ->post('/feedback', [
                'rating' => 5,
                'message' => 'Great application! Very helpful for farm management.',
                'category' => 'general',
            ]);

        $this->assertDatabaseHas('feedback', [
            'user_id' => $this->user->id,
            'rating' => 5,
            'category' => 'general',
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');
    }

    /** @test */
    public function feedback_requires_valid_rating()
    {
        $response = $this->actingAs($this->user)
            ->post('/feedback', [
                'rating' => 10,
                'message' => 'Test message',
                'category' => 'general',
            ]);

        $response->assertSessionHasErrors('rating');
    }

    /** @test */
    public function feedback_requires_message()
    {
        $response = $this->actingAs($this->user)
            ->post('/feedback', [
                'rating' => 5,
                'message' => '',
                'category' => 'general',
            ]);

        $response->assertSessionHasErrors('message');
    }

    /** @test */
    public function unauthenticated_user_cannot_submit_feedback()
    {
        $response = $this->post('/feedback', [
            'rating' => 5,
            'message' => 'Test',
            'category' => 'general',
        ]);

        $response->assertRedirect('/login');
    }

    /** @test */
    public function feedback_is_associated_with_user()
    {
        $feedback = Feedback::create([
            'user_id' => $this->user->id,
            'rating' => 4,
            'message' => 'Good application',
            'category' => 'feature_request',
        ]);

        $this->assertEquals($this->user->id, $feedback->user_id);
        $this->assertTrue($feedback->user->is($this->user));
    }
}
