<?php

namespace Database\Factories;

use App\Models\Harvest;
use App\Models\User;
use App\Models\Season;
use Illuminate\Database\Eloquent\Factories\Factory;

class HarvestFactory extends Factory
{
    protected $model = Harvest::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'season_id' => Season::factory(),
            'date' => $this->faker->dateTime(),
            'weight_kg' => $this->faker->numberBetween(100, 1000),
            'notes' => $this->faker->sentence(),
            'location' => $this->faker->word(),
        ];
    }
}
