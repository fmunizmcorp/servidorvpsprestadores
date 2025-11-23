<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * DIAGNOSTIC MIDDLEWARE - Sprint 57
 * 
 * Purpose: Log every request that passes through the middleware stack
 * This will help identify where POST /sites requests are being blocked
 * 
 * Installation:
 * 1. Copy to: app/Http/Middleware/DiagnosticMiddleware.php
 * 2. Register in bootstrap/app.php or app/Http/Kernel.php
 * 3. Add to 'web' middleware group FIRST (before any other middleware)
 * 4. Test POST /sites and check logs
 * 
 * Expected behavior if working:
 * - Log entry for POST /sites appears
 * - Log shows session data
 * - Log shows CSRF token
 * - Controller log appears after this
 * 
 * If broken:
 * - No log entry = Request not reaching Laravel
 * - Log but no controller execution = Middleware blocking request
 * - Log shows missing token = CSRF issue
 * - Log shows no auth = Authentication issue
 */
class DiagnosticMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        // Log EVERY request (GET, POST, PUT, DELETE, etc)
        Log::channel('single')->info('=== DIAGNOSTIC MIDDLEWARE START ===', [
            'method' => $request->method(),
            'path' => $request->path(),
            'url' => $request->url(),
            'ip' => $request->ip(),
            'timestamp' => now()->toDateTimeString(),
        ]);
        
        // Log authentication state
        Log::channel('single')->info('DIAGNOSTIC: Auth state', [
            'is_authenticated' => auth()->check(),
            'user_id' => auth()->id(),
            'user_email' => auth()->user()->email ?? 'not_logged_in',
        ]);
        
        // Log session data
        Log::channel('single')->info('DIAGNOSTIC: Session state', [
            'session_id' => session()->getId(),
            'has_token' => session()->has('_token'),
            'token' => session()->token(),
        ]);
        
        // Log CSRF token from request
        Log::channel('single')->info('DIAGNOSTIC: CSRF from request', [
            'header_token' => $request->header('X-CSRF-TOKEN'),
            'input_token' => $request->input('_token'),
            'meta_token' => $request->header('X-XSRF-TOKEN'),
        ]);
        
        // Log request data (be careful with passwords!)
        $data = $request->all();
        if (isset($data['password'])) {
            $data['password'] = '[REDACTED]';
        }
        Log::channel('single')->info('DIAGNOSTIC: Request data', [
            'data' => $data,
            'content_type' => $request->header('Content-Type'),
        ]);
        
        // Pass request to next middleware
        $response = $next($request);
        
        // Log response
        Log::channel('single')->info('DIAGNOSTIC: Response', [
            'status_code' => $response->getStatusCode(),
            'redirect_to' => $response->isRedirect() ? $response->headers->get('Location') : 'not_redirect',
        ]);
        
        Log::channel('single')->info('=== DIAGNOSTIC MIDDLEWARE END ===');
        
        return $response;
    }
}
