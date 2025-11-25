<?php

/**
 * DIAGNOSTIC TEST ROUTES - Sprint 57
 * 
 * Purpose: Add minimal test routes to identify where POST /sites is blocked
 * 
 * Installation:
 * Add these routes to routes/web.php BEFORE the auth middleware group:
 */

// TEST 1: Simple route with NO middleware
// This tests if Laravel routing works at all
Route::get('/test-route-simple', function() {
    return response()->json([
        'status' => 'success',
        'message' => 'Laravel routing works!',
        'timestamp' => now()->toDateTimeString(),
    ]);
});

// TEST 2: POST route with NO middleware
// This tests if POST requests reach Laravel
Route::post('/test-post-simple', function() {
    return response()->json([
        'status' => 'success',
        'message' => 'POST routing works!',
        'data_received' => request()->all(),
        'timestamp' => now()->toDateTimeString(),
    ]);
});

// TEST 3: POST route with CSRF middleware only
// This tests if CSRF validation is the problem
Route::post('/test-post-csrf', function() {
    return response()->json([
        'status' => 'success',
        'message' => 'POST with CSRF works!',
        'csrf_token' => csrf_token(),
        'session_token' => session()->token(),
        'data_received' => request()->all(),
        'timestamp' => now()->toDateTimeString(),
    ]);
})->middleware('web');

// TEST 4: POST route with auth middleware
// This tests if authentication middleware is blocking
Route::post('/test-post-auth', function() {
    return response()->json([
        'status' => 'success',
        'message' => 'POST with auth works!',
        'user' => auth()->user()->email ?? 'not_logged_in',
        'authenticated' => auth()->check(),
        'data_received' => request()->all(),
        'timestamp' => now()->toDateTimeString(),
    ]);
})->middleware(['web', 'auth']);

// TEST 5: POST to /sites prefix with minimal controller
// This mimics the actual /sites route structure
Route::prefix('sites')->middleware(['web', 'auth'])->group(function () {
    Route::post('/test-store', function(Request $request) {
        \Log::info('TEST ROUTE: /sites/test-store reached!', [
            'method' => $request->method(),
            'data' => $request->all(),
            'user' => auth()->user()->email ?? 'not_logged_in',
        ]);
        
        return response()->json([
            'status' => 'success',
            'message' => 'Test store route works!',
            'data_received' => $request->all(),
            'user' => auth()->user()->email ?? 'not_logged_in',
        ]);
    });
});

/**
 * HOW TO TEST:
 * 
 * 1. Add routes above to routes/web.php
 * 2. Clear route cache: php artisan route:clear
 * 3. Test each route in order:
 * 
 * TEST 1 (should always work):
 *   curl https://72.61.53.222/admin/test-route-simple
 *   Expected: {"status":"success",...}
 * 
 * TEST 2 (tests POST without CSRF):
 *   curl -X POST https://72.61.53.222/admin/test-post-simple -d "test=value"
 *   Expected: {"status":"success",...}
 *   If fails: POST routing broken in NGINX/Laravel
 * 
 * TEST 3 (tests POST with CSRF):
 *   First get CSRF token:
 *     curl -c cookies.txt https://72.61.53.222/admin/login
 *   Then POST with token:
 *     curl -b cookies.txt -c cookies.txt -X POST \
 *       https://72.61.53.222/admin/test-post-csrf \
 *       -d "_token=TOKEN_FROM_PAGE&test=value"
 *   Expected: {"status":"success",...}
 *   If fails: CSRF validation rejecting requests
 * 
 * TEST 4 (tests with authentication):
 *   Login first:
 *     curl -c cookies.txt -b cookies.txt -X POST \
 *       https://72.61.53.222/admin/login \
 *       -d "_token=TOKEN&email=admin@vps.local&password=mcorpapp"
 *   Then test authenticated POST:
 *     curl -b cookies.txt -c cookies.txt -X POST \
 *       https://72.61.53.222/admin/test-post-auth \
 *       -d "_token=TOKEN&test=value"
 *   Expected: {"status":"success","user":"admin@vps.local",...}
 *   If fails: Auth middleware rejecting requests
 * 
 * TEST 5 (tests /sites prefix):
 *   curl -b cookies.txt -c cookies.txt -X POST \
 *     https://72.61.53.222/admin/sites/test-store \
 *     -d "_token=TOKEN&test=value"
 *   Expected: {"status":"success",...}
 *   AND check logs: tail -f storage/logs/laravel.log | grep "TEST ROUTE"
 *   If fails: Problem specific to /sites routes
 * 
 * INTERPRETATION:
 * - TEST 1 fails: Basic routing broken (NGINX/Laravel config issue)
 * - TEST 2 fails: POST routing broken (NGINX config issue)
 * - TEST 3 fails: CSRF validation issue
 * - TEST 4 fails: Authentication middleware issue
 * - TEST 5 fails: Something specific to /sites routes
 * - All pass but actual POST /sites fails: Issue in SitesController@store
 */

?>
