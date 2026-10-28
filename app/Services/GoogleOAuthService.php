<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * GoogleOAuthService
 *
 * Verifies a Google ID Token by calling the Google tokeninfo endpoint.
 * This approach requires no additional PHP library while still performing
 * server-side verification — the signature, expiry, issuer, and audience
 * are all validated by Google's servers.
 *
 * ⚠️  The Google ID token is verified HERE at the backend only.
 *      The Flutter client NEVER makes access decisions based on the raw token.
 *
 * Returned payload example (subset of claims):
 *   sub           — stable unique Google user ID (never changes)
 *   email         — Google account email
 *   email_verified — boolean (always true for @gmail.com)
 *   name          — display name
 *   aud           — must match our configured client ID
 *   iss           — must be 'accounts.google.com' or 'https://accounts.google.com'
 *   exp           — Unix timestamp of expiry (validated by Google)
 */
class GoogleOAuthService
{
    private const TOKENINFO_URL = 'https://oauth2.googleapis.com/tokeninfo';
    private const VALID_ISSUERS  = ['accounts.google.com', 'https://accounts.google.com'];

    /**
     * Verify the given Google Token (ID Token or Access Token) and return the verified claims.
     *
     * @param  string $token    The raw Google ID token or Access token from the Flutter client.
     * @return array            Verified claims (sub, email, email_verified, name, …)
     *
     * @throws \RuntimeException  When the token is invalid, expired, or audience
     *                            does not match the configured client ID.
     */
    public function verify(string $token): array
    {
        // A JWT ID Token consists of 3 segments separated by dots (header.payload.sig)
        $isJwt = substr_count($token, '.') === 2;

        if ($isJwt) {
            return $this->verifyIdToken($token);
        }

        return $this->verifyAccessToken($token);
    }

    private function verifyIdToken(string $idToken): array
    {
        $response = Http::timeout(10)->get(self::TOKENINFO_URL, [
            'id_token' => $idToken,
        ]);

        if ($response->failed()) {
            Log::warning('GoogleOAuthService: tokeninfo id_token call failed', [
                'status' => $response->status(),
            ]);
            throw new \RuntimeException('ID token tidak valid atau sudah kedaluwarsa.');
        }

        $claims = $response->json();

        $this->assertAudience($claims['aud'] ?? '');
        $this->assertIssuer($claims['iss'] ?? '');

        if (!($claims['email_verified'] ?? false)) {
            throw new \RuntimeException('Akun Google belum diverifikasi.');
        }

        if (empty($claims['sub'])) {
            throw new \RuntimeException('Token Google tidak mengandung identitas pengguna.');
        }

        return $claims;
    }

    private function verifyAccessToken(string $accessToken): array
    {
        $response = Http::timeout(10)->get(self::TOKENINFO_URL, [
            'access_token' => $accessToken,
        ]);

        if ($response->failed()) {
            Log::warning('GoogleOAuthService: tokeninfo access_token call failed', [
                'status' => $response->status(),
            ]);
            throw new \RuntimeException('Token Google tidak valid atau sudah kedaluwarsa.');
        }

        $tokenInfo = $response->json();

        $aud = $tokenInfo['aud'] ?? $tokenInfo['azp'] ?? '';
        $this->assertAudience($aud);

        if (!empty($tokenInfo['email_verified']) && $tokenInfo['email_verified'] !== true && $tokenInfo['email_verified'] !== 'true') {
            throw new \RuntimeException('Akun Google belum diverifikasi.');
        }

        if (empty($tokenInfo['sub'])) {
            throw new \RuntimeException('Token Google tidak mengandung identitas pengguna.');
        }

        $claims = [
            'sub'            => $tokenInfo['sub'],
            'email'          => $tokenInfo['email'] ?? null,
            'email_verified' => true,
            'name'           => null,
            'picture'        => null,
        ];

        try {
            $userinfoResponse = Http::timeout(10)
                ->withToken($accessToken)
                ->get('https://www.googleapis.com/oauth2/v3/userinfo');

            if ($userinfoResponse->successful()) {
                $userinfo = $userinfoResponse->json();
                $claims['name']    = $userinfo['name'] ?? null;
                $claims['picture'] = $userinfo['picture'] ?? null;
                if (!empty($userinfo['email'])) {
                    $claims['email'] = $userinfo['email'];
                }
            }
        } catch (\Throwable $e) {
            Log::warning('GoogleOAuthService: userinfo fetch failed, using tokeninfo data', [
                'error' => $e->getMessage(),
            ]);
        }

        return $claims;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────────────────────────────────

    private function assertAudience(string $aud): void
    {
        $allowedClientIds = $this->getAllowedClientIds();

        if (empty($allowedClientIds)) {
            // Guard: if no client ID is configured, always reject
            throw new \RuntimeException('Konfigurasi Google Client ID belum diatur.');
        }

        // The 'aud' field may be a comma-separated list for multiple clients
        $audienceList = array_map('trim', explode(',', $aud));

        foreach ($allowedClientIds as $clientId) {
            if (in_array($clientId, $audienceList, true)) {
                return; // Matched
            }
        }

        Log::warning('GoogleOAuthService: audience mismatch', [
            'aud'     => $aud,
            'allowed' => $allowedClientIds,
        ]);

        throw new \RuntimeException('Token Google tidak ditujukan untuk aplikasi ini.');
    }

    private function assertIssuer(string $iss): void
    {
        if (!in_array($iss, self::VALID_ISSUERS, true)) {
            throw new \RuntimeException('Token Google berasal dari sumber yang tidak dipercaya.');
        }
    }

    /**
     * Collect all configured OAuth client IDs.
     * Supports Web Client ID and Android Client ID separately.
     */
    private function getAllowedClientIds(): array
    {
        $ids = [];

        $web     = config('services.google.client_id');
        $android = config('services.google.android_client_id');

        if (!empty($web))     $ids[] = $web;
        if (!empty($android)) $ids[] = $android;

        return array_values(array_unique(array_filter($ids)));
    }
}
