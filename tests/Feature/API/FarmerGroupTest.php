<?php

namespace Tests\Feature\API;

use App\Models\FarmerGroup;
use App\Models\User;
use Database\Seeders\FarmerGroupSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FarmerGroupTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(FarmerGroupSeeder::class);
    }

    public function test_can_list_all_10_active_farmer_groups(): void
    {
        $response = $this->getJson('/api/farmer-groups');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonCount(10, 'data');

        $response->assertJsonFragment([
            'code' => 'POKTAN-01',
            'name' => 'Poktan 1 - Tani Makmur',
        ]);
        $response->assertJsonFragment([
            'code' => 'POKTAN-10',
            'name' => 'Poktan 10 - Tani Bersatu',
        ]);
    }

    public function test_farmer_registration_succeeds_with_valid_poktan(): void
    {
        $poktan = FarmerGroup::where('code', 'POKTAN-03')->first();

        $payload = [
            'name'                  => 'Petani Jamur Sukabumi',
            'email'                 => 'petanijamur@example.com',
            'phone'                 => '081298765432',
            'farm_name'             => 'Kebun Jamur Sejahtera',
            'farmer_group_id'       => $poktan->id,
            'password'              => 'password123',
            'password_confirmation' => 'password123',
        ];

        $response = $this->postJson('/api/auth/register', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'email'           => 'petanijamur@example.com',
                    'farmer_group_id' => $poktan->id,
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email'           => 'petanijamur@example.com',
            'farmer_group_id' => $poktan->id,
            'role'            => 'user',
        ]);
    }

    public function test_farmer_registration_fails_if_poktan_is_missing_or_invalid(): void
    {
        // 1. Missing Poktan
        $payloadMissing = [
            'name'                  => 'Petani Tanpa Poktan',
            'email'                 => 'tanpapoktan@example.com',
            'phone'                 => '081200000000',
            'farm_name'             => 'Kebun Mandiri',
            'password'              => 'password123',
            'password_confirmation' => 'password123',
        ];

        $response = $this->postJson('/api/auth/register', $payloadMissing);
        $response->assertStatus(422);

        // 2. Invalid Poktan ID
        $payloadInvalid = array_merge($payloadMissing, [
            'email'           => 'invalidpoktan@example.com',
            'farmer_group_id' => 99999, // non-existent
        ]);

        $responseInvalid = $this->postJson('/api/auth/register', $payloadInvalid);
        $responseInvalid->assertStatus(422);
    }

    public function test_super_admin_can_view_farmer_groups_with_member_counts(): void
    {
        $superAdmin = User::factory()->create([
            'role'   => 'super_admin',
            'status' => 'active',
        ]);

        $poktan = FarmerGroup::first();

        // Create 2 members for this poktan
        User::factory()->count(2)->create([
            'role'            => 'user',
            'farmer_group_id' => $poktan->id,
        ]);

        $response = $this->actingAs($superAdmin)->getJson('/api/super-admin/farmer-groups');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'name',
                        'code',
                        'status',
                        'members_count',
                    ],
                ],
            ]);

        $firstItem = collect($response->json('data'))->firstWhere('id', $poktan->id);
        $this->assertEquals(2, $firstItem['members_count']);
    }

    public function test_super_admin_can_view_poktan_detail_with_members(): void
    {
        $superAdmin = User::factory()->create([
            'role'   => 'super_admin',
            'status' => 'active',
        ]);

        $poktan = FarmerGroup::first();

        $member = User::factory()->create([
            'name'            => 'Budi Petani Anggota',
            'role'            => 'user',
            'farmer_group_id' => $poktan->id,
        ]);

        $response = $this->actingAs($superAdmin)->getJson("/api/super-admin/farmer-groups/{$poktan->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'id'   => $poktan->id,
                    'code' => $poktan->code,
                    'members' => [
                        [
                            'id'   => $member->id,
                            'name' => 'Budi Petani Anggota',
                        ],
                    ],
                ],
            ]);
    }

    public function test_super_admin_can_reassign_farmer_to_another_poktan(): void
    {
        $superAdmin = User::factory()->create([
            'role'   => 'super_admin',
            'status' => 'active',
        ]);

        $poktan1 = FarmerGroup::find(1);
        $poktan2 = FarmerGroup::find(2);

        $farmer = User::factory()->create([
            'role'            => 'user',
            'farmer_group_id' => $poktan1->id,
        ]);

        $response = $this->actingAs($superAdmin)->postJson("/api/super-admin/users/{$farmer->id}/assign-poktan", [
            'farmer_group_id' => $poktan2->id,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'user_id'         => $farmer->id,
                    'farmer_group_id' => $poktan2->id,
                    'farmer_group'    => [
                        'id'   => $poktan2->id,
                        'name' => $poktan2->name,
                    ],
                ],
            ]);

        $this->assertEquals($poktan2->id, $farmer->fresh()->farmer_group_id);
    }

    public function test_regular_farmer_cannot_access_super_admin_poktan_routes(): void
    {
        $farmer = User::factory()->create([
            'role'   => 'user',
            'status' => 'active',
        ]);

        // Attempt to create poktan
        $response = $this->actingAs($farmer)->postJson('/api/super-admin/farmer-groups', [
            'name' => 'Poktan Ilegal',
            'code' => 'POKTAN-ILEGAL',
        ]);
        $response->assertStatus(403);

        // Attempt to reassign poktan
        $responseAssign = $this->actingAs($farmer)->postJson("/api/super-admin/users/{$farmer->id}/assign-poktan", [
            'farmer_group_id' => 1,
        ]);
        $responseAssign->assertStatus(403);
    }
}
