<?php

namespace Database\Factories;

use App\Models\ProcessedProduct;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ProcessedProductFactory extends Factory
{
    protected $model = ProcessedProduct::class;

    public function definition(): array
    {
        $stock = $this->faker->numberBetween(0, 100);
        return [
            'owner_id' => User::factory(),
            'name' => $this->faker->words(2, true),
            'price' => $this->faker->numberBetween(10000, 100000),
            'stock' => $stock,
            'description' => $this->faker->paragraph(),
            'photo' => null,
            'status' => $stock > 0 ? 'active' : 'out_of_stock',
        ];
    }

    public function outOfStock(): static
    {
        return $this->state(fn (array $attributes) => [
            'stock' => 0,
            'status' => 'out_of_stock',
        ]);
    }

    public function active(int $stock = 20): static
    {
        return $this->state(fn (array $attributes) => [
            'stock' => $stock,
            'status' => 'active',
        ]);
    }

    public function inactive(int $stock = 10): static
    {
        return $this->state(fn (array $attributes) => [
            'stock' => $stock,
            'status' => 'inactive',
        ]);
    }
}
