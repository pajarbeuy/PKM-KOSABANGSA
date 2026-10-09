<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        if (!Auth::check()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized - No token provided',
            ], 401);
        }

        $userRole = Auth::user()->role;
        $allowedRoles = [];
        foreach ($roles as $r) {
            foreach (explode(',', $r) as $sub) {
                $trimmed = trim($sub);
                if ($trimmed !== '') {
                    $allowedRoles[] = $trimmed;
                }
            }
        }

        if (!in_array($userRole, $allowedRoles, true)) {
            return response()->json([
                'success' => false,
                'message' => 'Forbidden - Requires ' . implode(' or ', $allowedRoles) . ' role',
            ], 403);
        }

        return $next($request);
    }
}
