<?php

namespace Database\Factories;

use App\Models\Sale;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class SaleFactory extends Factory
{
    protected $model = Sale::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'date' => $this->faker->dateTime(),
            'buyer_name' => $this->faker->company(),
            'quantity_kg' => $this->faker->numberBetween(10, 500),
            'price_per_kg' => $this->faker->numberBetween(3000, 8000),
            'total_price' => $this->faker->numberBetween(50000, 5000000),
            'payment_status' => $this->faker->randomElement(['paid', 'pending', 'cancelled']),
            'notes' => $this->faker->sentence(),
        ];
    }
}
