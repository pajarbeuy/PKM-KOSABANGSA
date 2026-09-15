<?php
require __DIR__.'/../vendor/autoload.php';

$app = require_once __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$kernel->bootstrap();

// Get APP_URL from .env
$baseUrl = env('APP_URL', 'http://localhost');
echo "APP_URL: $baseUrl\n";
echo "API Base: $baseUrl/api\n\n";

// Get first user to get a token for testing
try {
    $user = App\Models\User::first();
    if (!$user) {
        echo "ERROR: No user found in database!\n";
        exit(1);
    }
    
    echo "Testing with user: {$user->email}\n";
    
    // Create a sanctum token
    $token = $user->createToken('test-pdf-token')->plainTextToken;
    echo "Token created: " . substr($token, 0, 20) . "...\n\n";
    
    // Test profit-loss PDF endpoint
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "$baseUrl/api/reports/export/profit-loss/pdf");
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer $token",
        "Accept: application/pdf",
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    $error = curl_error($ch);
    curl_close($ch);
    
    echo "=== Profit-Loss PDF Test ===\n";
    echo "HTTP Status: $httpCode\n";
    echo "Content-Type: $contentType\n";
    
    if ($error) {
        echo "cURL Error: $error\n";
    } elseif ($httpCode === 200 && str_contains($contentType, 'pdf')) {
        echo "SUCCESS: PDF received, size = " . strlen($response) . " bytes\n";
    } else {
        echo "FAIL! Response body:\n";
        echo substr($response, 0, 800) . "\n";
    }
    
    // Clean up token
    $user->tokens()->where('name', 'test-pdf-token')->delete();
    echo "\nToken deleted.\n";
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
}
