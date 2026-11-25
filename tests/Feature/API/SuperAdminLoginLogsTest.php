<?php

namespace Tests\Feature\API;

use App\Models\FarmerGroup;
use App\Models\LoginLog;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SuperAdminLoginLogsTest extends TestCase
{
    use RefreshDatabase;

    protected User $superAdmin;
    protected User $farmer;
    protected FarmerGroup $poktan;

    protected function setUp(): void
    {
        parent::setUp();

        $this->poktan = FarmerGroup::create([
            'name'        => 'Poktan Sumber Makmur',
            'code'        => 'PKT-01',
            'status'      => 'active',
            'leader_name' => 'Pak Budi',
            'village'     => 'Sumbersari',
        ]);

        $this->superAdmin = User::factory()->create([
            'role'     => 'super_admin',
            'name'     => 'Super Administrator',
            'status'   => 'active',
            'approval' => 'approved',
        ]);

        $this->farmer = User::factory()->create([
            'role'            => 'user',
            'name'            => 'Petani Poktan',
            'email'           => 'petani@poktan.id',
            'password'        => bcrypt('secret123'),
            'farmer_group_id' => $this->poktan->id,
            'status'          => 'active',
            'approval'        => 'approved',
        ]);
    }

    public function test_login_records_login_log_with_location_and_datetime(): void
    {
        $response = $this->postJson('/api/auth/login', [
            'email'    => 'petani@poktan.id',
            'password' => 'secret123',
            'location' => 'Desa Sumbersari, Jember',
        ]);

        $response->assertStatus(200)->assertJson(['success' => true]);

        $this->assertDatabaseHas('login_logs', [
            'user_id'         => $this->farmer->id,
            'farmer_group_id' => $this->poktan->id,
            'login_method'    => 'password',
            'location'        => 'Desa Sumbersari, Jember',
        ]);
    }

    public function test_super_admin_can_fetch_poktan_login_logs_and_chart_data(): void
    {
        // Poktan logins within 7d
        LoginLog::create([
            'user_id'         => $this->farmer->id,
            'farmer_group_id' => $this->poktan->id,
            'login_method'    => 'password',
            'ip_address'      => '103.10.10.1',
            'location'        => 'Sumbersari, Jember',
            'logged_in_at'    => now(),
        ]);

        LoginLog::create([
            'user_id'         => $this->farmer->id,
            'farmer_group_id' => $this->poktan->id,
            'login_method'    => 'google',
            'ip_address'      => '103.10.10.2',
            'location'        => 'Sumbersari, Jember',
            'logged_in_at'    => now()->subDays(2),
        ]);

        // Older Poktan login outside 7d but inside 30d
        LoginLog::create([
            'user_id'         => $this->farmer->id,
            'farmer_group_id' => $this->poktan->id,
            'login_method'    => 'password',
            'ip_address'      => '103.10.10.3',
            'location'        => 'Malang, Jawa Timur',
            'logged_in_at'    => now()->subDays(15),
        ]);

        // Super admin login should NOT be included in Poktan user login logs
        LoginLog::create([
            'user_id'      => $this->superAdmin->id,
            'login_method' => 'password',
            'ip_address'   => '127.0.0.1',
            'location'     => 'Kantor Pusat',
            'logged_in_at' => now(),
        ]);

        Sanctum::actingAs($this->superAdmin);

        // Check 7d period
        $res7 = $this->getJson('/api/super-admin/login-logs?period=7d');
        $res7->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'data' => [
                    'period',
                    'start_date',
                    'end_date',
                    'total_logins',
                    'unique_users',
                    'daily_counts',
                    'location_summary',
                    'logs',
                ],
            ]);

        $data7 = $res7->json('data');
        $this->assertEquals('7d', $data7['period']);
        $this->assertEquals(2, $data7['total_logins']);
        $this->assertEquals(1, $data7['unique_users']);
        $this->assertCount(7, $data7['daily_counts']);
        $this->assertCount(2, $data7['logs']);
        $this->assertEquals('Sumbersari, Jember', $data7['location_summary'][0]['location']);
        $this->assertEquals(2, $data7['location_summary'][0]['count']);
        $this->assertEquals('Poktan Sumber Makmur', $data7['logs'][0]['farmer_group_name']);

        // Check 30d period includes the 15-day-old login
        $res30 = $this->getJson('/api/super-admin/login-logs?period=30d');
        $res30->assertStatus(200);
        $data30 = $res30->json('data');
        $this->assertEquals(3, $data30['total_logins']);
        $this->assertCount(30, $data30['daily_counts']);
    }

    public function test_farmer_cannot_access_super_admin_login_logs(): void
    {
        Sanctum::actingAs($this->farmer);

        $this->getJson('/api/super-admin/login-logs')->assertStatus(403);
    }
}
