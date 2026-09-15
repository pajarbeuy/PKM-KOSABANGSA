<?php

namespace Database\Factories;

use App\Models\ProductionCost;
use App\Models\User;
use App\Models\Season;
use Illuminate\Database\Eloquent\Factories\Factory;

class ProductionCostFactory extends Factory
{
    protected $model = ProductionCost::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'season_id' => Season::factory(),
            'category' => $this->faker->randomElement(['bibit', 'pupuk', 'pestisida', 'lainnya']),
            'amount' => $this->faker->numberBetween(50000, 1000000),
            'date' => $this->faker->dateTime(),
            'description' => $this->faker->sentence(),
        ];
    }
}
