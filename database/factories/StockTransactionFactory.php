<?php

namespace Database\Factories;

use App\Models\StockTransaction;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class StockTransactionFactory extends Factory
{
    protected $model = StockTransaction::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'type' => $this->faker->randomElement(['in', 'out']),
            'amount' => $this->faker->numberBetween(10, 500),
            'date' => $this->faker->dateTime(),
            'reference' => $this->faker->word(),
            'notes' => $this->faker->sentence(),
        ];
    }
}
