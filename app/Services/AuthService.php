<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    /**
     * Create a new user account.
     */
    public function createUser(array $data, string $role = 'user'): User
    {
        return User::create([
            'farm_name'       => $data['farm_name'],
            'name'            => $data['name'],
            'email'           => $data['email'],
            'phone'           => $data['phone'],
            'farmer_group_id' => $data['farmer_group_id'] ?? null,
            'password'        => Hash::make($data['password']),
            'role'            => $role,
            'status'          => 'active',
            'approval'        => 'approved',
        ]);
    }

    /**
     * Attempt to find and authenticate a user by credentials.
     * Returns the user if valid, null otherwise.
     */
    public function attemptLogin(string $email, string $password): ?User
    {
        $user = User::with('farmerGroup')->where('email', $email)->first();

        if (!$user || !Hash::check($password, $user->password)) {
            return null;
        }

        return $user;
    }

    /**
     * Create a Sanctum API token for the user.
     */
    public function createToken(User $user, string $name = 'api-token'): string
    {
        return $user->createToken($name)->plainTextToken;
    }

    /**
     * Format a user for API response.
     */
    public function formatUser(User $user): array
    {
        $user->loadMissing('farmerGroup');

        return [
            'id'              => $user->id,
            'name'            => $user->name,
            'email'           => $user->email,
            'farm_name'       => $user->farm_name,
            'phone'           => $user->phone,
            'farmer_group_id' => $user->farmer_group_id,
            'farmer_group'    => $user->farmerGroup ? [
                'id'          => $user->farmerGroup->id,
                'name'        => $user->farmerGroup->name,
                'code'        => $user->farmerGroup->code,
            ] : null,
            'role'            => $user->role,
            'status'          => $user->status,
            'approval'        => $user->approval,
        ];
    }
}
