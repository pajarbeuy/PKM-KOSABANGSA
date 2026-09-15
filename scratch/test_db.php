<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== USERS ===\n";
print_r(DB::table('users')->get()->toArray());

echo "=== SEASONS ===\n";
print_r(DB::table('seasons')->get()->toArray());

