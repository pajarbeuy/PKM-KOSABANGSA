<?php
require __DIR__.'/../vendor/autoload.php';

$app = require_once __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$kernel->bootstrap();

try {
    $pdf = Barryvdh\DomPDF\Facade\Pdf::loadHtml('<h1>Test PDF</h1><p>Berfungsi dengan baik!</p>');
    $output = $pdf->output();
    echo "SUCCESS: PDF generated, size = " . strlen($output) . " bytes\n";
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
}
