<?php

namespace Database\Factories;

use App\Models\Feedback;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class FeedbackFactory extends Factory
{
    protected $model = Feedback::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'rating' => $this->faker->numberBetween(1, 5),
            'message' => $this->faker->paragraph(),
            'category' => $this->faker->randomElement(['general', 'feature_request', 'bug_report', 'improvement']),
        ];
    }
}
