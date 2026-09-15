<?php
$baseUrl = 'http://127.0.0.1:8000';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/login');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_HEADER, 1);
$response = curl_exec($ch);
$header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$header = substr($response, 0, $header_size);
$body = substr($response, $header_size);
preg_match_all('/^Set-Cookie:\s*([^;]*)/mi', $header, $matches);
$cookies = array();
foreach($matches[1] as $item) {
    parse_str($item, $cookie);
    $cookies = array_merge($cookies, $cookie);
}
$token = '';
if(preg_match('/name="_token"\s+value="([^"]+)"/', $body, $m)) {
    $token = $m[1];
}
$cookieStr = '';
foreach($cookies as $k => $v) { $cookieStr .= "$k=$v; "; }

$ch2 = curl_init();
curl_setopt($ch2, CURLOPT_URL, $baseUrl . '/login');
curl_setopt($ch2, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch2, CURLOPT_HEADER, 1);
curl_setopt($ch2, CURLOPT_POST, 1);
curl_setopt($ch2, CURLOPT_POSTFIELDS, http_build_query([
    '_token' => $token,
    'email' => 'admin@simhpsk.com',
    'password' => 'password',
]));
curl_setopt($ch2, CURLOPT_COOKIE, $cookieStr);
$response2 = curl_exec($ch2);
$header_size2 = curl_getinfo($ch2, CURLINFO_HEADER_SIZE);
$header2 = substr($response2, 0, $header_size2);
echo "Response 2 Headers:\n" . $header2 . "\n";
