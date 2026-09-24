<?php

namespace Tests\Feature\API;

use App\Models\FarmerCommodity;
use App\Models\FarmerGroup;
use App\Models\User;
use Database\Seeders\FarmerGroupSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FarmerCommodityTest extends TestCase
{
    use RefreshDatabase;

    private User $farmerA;
    private User $farmerB;
    private User $superAdmin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(FarmerGroupSeeder::class);
        $poktan = FarmerGroup::first();

        $this->farmerA = User::factory()->create([
            'role'            => 'user',
            'status'          => 'active',
            'farmer_group_id' => $poktan->id,
            'farm_name'       => 'Kebun Petani A',
        ]);

        $this->farmerB = User::factory()->create([
            'role'            => 'user',
            'status'          => 'active',
            'farmer_group_id' => $poktan->id,
            'farm_name'       => 'Kebun Petani B',
        ]);

        $this->superAdmin = User::factory()->create([
            'role'   => 'super_admin',
            'status' => 'active',
        ]);
    }

    public function test_farmer_a_can_create_multiple_commodities(): void
    {
        $commodities = [
            ['name' => 'Jeruk', 'unit' => 'kg', 'description' => 'Jeruk Manis'],
            ['name' => 'Mangga', 'unit' => 'kg', 'description' => 'Mangga Harum Manis'],
            ['name' => 'Pisang', 'unit' => 'ikat', 'description' => 'Pisang Cavendish'],
        ];

        foreach ($commodities as $payload) {
            $response = $this->actingAs($this->farmerA)->postJson('/api/commodities', $payload);
            $response->assertStatus(201)
                ->assertJson([
                    'success' => true,
                    'data'    => [
                        'user_id' => $this->farmerA->id,
                        'name'    => $payload['name'],
                        'unit'    => $payload['unit'],
                    ],
                ]);
        }

        $this->assertCount(3, $this->farmerA->commodities);
    }

    public function test_farmer_b_can_create_same_commodity_name_without_conflict(): void
    {
        // Farmer A creates Jeruk
        FarmerCommodity::create([
            'user_id' => $this->farmerA->id,
            'name'    => 'Jeruk',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        // Farmer B also creates Jeruk & Padi (acceptance test from implementation plan)
        $responseJeruk = $this->actingAs($this->farmerB)->postJson('/api/commodities', [
            'name' => 'Jeruk',
            'unit' => 'kg',
        ]);
        $responseJeruk->assertStatus(201);

        $responsePadi = $this->actingAs($this->farmerB)->postJson('/api/commodities', [
            'name' => 'Padi',
            'unit' => 'kuintal',
        ]);
        $responsePadi->assertStatus(201);

        $this->assertEquals(1, FarmerCommodity::where('user_id', $this->farmerA->id)->where('name', 'Jeruk')->count());
        $this->assertEquals(1, FarmerCommodity::where('user_id', $this->farmerB->id)->where('name', 'Jeruk')->count());
    }

    public function test_farmer_cannot_create_duplicate_commodity_name_for_themselves(): void
    {
        FarmerCommodity::create([
            'user_id' => $this->farmerA->id,
            'name'    => 'Talas Bogor',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        $response = $this->actingAs($this->farmerA)->postJson('/api/commodities', [
            'name' => 'talas bogor', // case-insensitive check
            'unit' => 'kg',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }

    public function test_farmer_only_sees_their_own_commodities(): void
    {
        FarmerCommodity::create([
            'user_id' => $this->farmerA->id,
            'name'    => 'Kentang Granola',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        FarmerCommodity::create([
            'user_id' => $this->farmerB->id,
            'name'    => 'Wortel Brastagi',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        $response = $this->actingAs($this->farmerA)->getJson('/api/commodities');

        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals('Kentang Granola', $data[0]['name']);
    }

    public function test_farmer_cannot_view_update_or_delete_other_farmers_commodity(): void
    {
        $commodityB = FarmerCommodity::create([
            'user_id' => $this->farmerB->id,
            'name'    => 'Kubis',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        // Attempt view
        $responseView = $this->actingAs($this->farmerA)->getJson("/api/commodities/{$commodityB->id}");
        $responseView->assertStatus(404);

        // Attempt update
        $responseUpdate = $this->actingAs($this->farmerA)->putJson("/api/commodities/{$commodityB->id}", [
            'name' => 'Kubis Bajakan',
        ]);
        $responseUpdate->assertStatus(404);

        // Attempt delete
        $responseDelete = $this->actingAs($this->farmerA)->deleteJson("/api/commodities/{$commodityB->id}");
        $responseDelete->assertStatus(404);
    }

    public function test_farmer_can_update_their_own_commodity(): void
    {
        $commodity = FarmerCommodity::create([
            'user_id' => $this->farmerA->id,
            'name'    => 'Cabai Rawit',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        $response = $this->actingAs($this->farmerA)->putJson("/api/commodities/{$commodity->id}", [
            'name'        => 'Cabai Rawit Merah',
            'unit'        => 'kg',
            'description' => 'Varietas pedas tahan hama',
            'status'      => 'active',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'id'          => $commodity->id,
                    'name'        => 'Cabai Rawit Merah',
                    'description' => 'Varietas pedas tahan hama',
                ],
            ]);

        $this->assertEquals('Cabai Rawit Merah', $commodity->fresh()->name);
    }

    public function test_farmer_can_delete_their_own_commodity(): void
    {
        $commodity = FarmerCommodity::create([
            'user_id' => $this->farmerA->id,
            'name'    => 'Bawang Merah',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        $response = $this->actingAs($this->farmerA)->deleteJson("/api/commodities/{$commodity->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Komoditas hasil tani berhasil dihapus.',
            ]);

        $this->assertSoftDeleted('farmer_commodities', [
            'id' => $commodity->id,
        ]);
    }

    public function test_super_admin_can_view_all_farmer_commodities(): void
    {
        FarmerCommodity::create([
            'user_id' => $this->farmerA->id,
            'name'    => 'Kentang',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        FarmerCommodity::create([
            'user_id' => $this->farmerB->id,
            'name'    => 'Jagung Manis',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        $response = $this->actingAs($this->superAdmin)->getJson('/api/super-admin/commodities');

        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertCount(2, $data);
        $this->assertArrayHasKey('farmer', $data[0]);
    }

    public function test_super_admin_can_update_farmer_commodity(): void
    {
        $commodity = FarmerCommodity::create([
            'user_id' => $this->farmerA->id,
            'name'    => 'Kopi Robusta',
            'unit'    => 'kg',
            'status'  => 'active',
        ]);

        $response = $this->actingAs($this->superAdmin)->putJson("/api/super-admin/commodities/{$commodity->id}", [
            'name'   => 'Kopi Arabika Premium',
            'status' => 'active',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Komoditas petani berhasil disesuaikan oleh Super Admin.',
            ]);

        $this->assertEquals('Kopi Arabika Premium', $commodity->fresh()->name);
    }
}
