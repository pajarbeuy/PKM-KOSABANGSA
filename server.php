<?php

/**
 * Laravel - A PHP Framework For Web Artisans
 * Custom server.php router with CORS support for Flutter Web & API clients.
 */

$publicPath = getcwd();

$uri = urldecode(
    parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? ''
);

// Handle CORS preflight directly
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    $requestHeaders = $_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'] ?? '*';
    header("Access-Control-Allow-Headers: $requestHeaders");
    header('Access-Control-Max-Age: 86400');
    http_response_code(200);
    exit;
}

// If the request is for a storage file or image asset, serve it directly with CORS headers
if ($uri !== '/' && file_exists($publicPath.$uri)) {
    if (str_starts_with($uri, '/storage/') || preg_match('/\.(png|jpe?g|gif|webp|svg|ico)$/i', $uri)) {
        $filePath = $publicPath.$uri;
        if (is_file($filePath)) {
            $mime = mime_content_type($filePath) ?: 'application/octet-stream';
            header('Access-Control-Allow-Origin: *');
            header('Access-Control-Allow-Methods: GET, OPTIONS');
            header('Access-Control-Allow-Headers: *');
            header("Content-Type: $mime");
            header("Content-Length: " . filesize($filePath));
            header('Cache-Control: public, max-age=86400');
            readfile($filePath);
            exit;
        }
    }
    return false;
}

$formattedDateTime = date('D M j H:i:s Y');
$requestMethod = $_SERVER['REQUEST_METHOD'];
$remoteAddress = $_SERVER['REMOTE_ADDR'].':'.$_SERVER['REMOTE_PORT'];

file_put_contents('php://stdout', "[$formattedDateTime] $remoteAddress [$requestMethod] URI: $uri\n");

require_once $publicPath.'/index.php';
