<?php

namespace Database\Factories;

use App\Models\Season;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class SeasonFactory extends Factory
{
    protected $model = Season::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => $this->faker->sentence(3),
            'start_date' => $this->faker->dateTimeBetween('-6 months'),
            'end_date' => $this->faker->dateTimeBetween('now', '+6 months'),
            'status' => $this->faker->randomElement(['active', 'completed', 'cancelled']),
            'target_kg' => $this->faker->numberBetween(500, 5000),
        ];
    }
}
