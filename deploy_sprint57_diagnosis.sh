#!/bin/bash

# ============================================================================
# SPRINT 57 - DIAGNOSTIC DEPLOYMENT SCRIPT
# ============================================================================
# Purpose: Deploy diagnostic tools to identify why POST /sites doesn't
#          reach SitesController
# 
# What this script does:
# 1. Backup current files
# 2. Deploy diagnostic middleware
# 3. Deploy test routes
# 4. Clear caches
# 5. Provide testing instructions
#
# What this script does NOT do:
# - Does NOT modify existing controllers
# - Does NOT change routes that are working
# - Does NOT touch Backups/Email modules (they work!)
# ============================================================================

set -e

SERVER="72.61.53.222"
USER="root"
export SSHPASS="mcorpapp"

echo "=================================================="
echo " SPRINT 57: DEPLOYING DIAGNOSTIC TOOLS"
echo "=================================================="
echo ""
echo "⚠️  This will NOT modify existing working code"
echo "✅ Only adds diagnostic middleware and test routes"
echo ""

# Step 1: Create diagnostic middleware content
echo "📝 Preparing diagnostic middleware..."

cat > /tmp/DiagnosticMiddleware.php << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DiagnosticMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        // Only log POST requests to /sites to avoid log spam
        if ($request->method() === 'POST' && str_contains($request->path(), 'sites')) {
            Log::channel('single')->info('=== SPRINT57 DIAGNOSTIC START ===', [
                'method' => $request->method(),
                'path' => $request->path(),
                'url' => $request->url(),
                'ip' => $request->ip(),
                'timestamp' => now()->toDateTimeString(),
            ]);
            
            Log::channel('single')->info('SPRINT57 DIAG: Auth state', [
                'is_authenticated' => auth()->check(),
                'user_id' => auth()->id(),
                'user_email' => auth()->user()->email ?? 'not_logged_in',
            ]);
            
            Log::channel('single')->info('SPRINT57 DIAG: Session state', [
                'session_id' => session()->getId(),
                'has_token' => session()->has('_token'),
                'session_token' => session()->token(),
            ]);
            
            Log::channel('single')->info('SPRINT57 DIAG: CSRF tokens', [
                'header_token' => $request->header('X-CSRF-TOKEN'),
                'input_token' => $request->input('_token'),
                'tokens_match' => $request->header('X-CSRF-TOKEN') === session()->token() 
                                 || $request->input('_token') === session()->token(),
            ]);
            
            $data = $request->all();
            if (isset($data['password'])) $data['password'] = '[REDACTED]';
            
            Log::channel('single')->info('SPRINT57 DIAG: Request data', [
                'data_keys' => array_keys($data),
                'content_type' => $request->header('Content-Type'),
            ]);
        }
        
        $response = $next($request);
        
        if ($request->method() === 'POST' && str_contains($request->path(), 'sites')) {
            Log::channel('single')->info('SPRINT57 DIAG: Response', [
                'status_code' => $response->getStatusCode(),
                'is_redirect' => $response->isRedirect(),
                'redirect_to' => $response->isRedirect() ? $response->headers->get('Location') : 'not_redirect',
            ]);
            
            Log::channel('single')->info('=== SPRINT57 DIAGNOSTIC END ===');
        }
        
        return $response;
    }
}
EOF

echo "✅ Diagnostic middleware prepared"

# Step 2: Deploy diagnostic middleware
echo "📤 Deploying diagnostic middleware to production..."

sshpass -e scp -o StrictHostKeyChecking=no /tmp/DiagnosticMiddleware.php $USER@$SERVER:/opt/webserver/admin-panel/app/Http/Middleware/DiagnosticMiddleware.php

if [ $? -eq 0 ]; then
    echo "✅ Diagnostic middleware uploaded"
else
    echo "❌ Failed to upload diagnostic middleware"
    exit 1
fi

# Step 3: Register middleware in bootstrap/app.php (Laravel 11)
echo "📝 Registering diagnostic middleware..."

sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel

# Backup bootstrap/app.php
cp bootstrap/app.php bootstrap/app.php.backup.sprint57

# Check if Laravel 11 structure (uses ->withMiddleware())
if grep -q "withMiddleware" bootstrap/app.php; then
    echo "Detected Laravel 11 structure"
    
    # Add diagnostic middleware to web group
    # This is tricky - need to modify the closure
    cat > bootstrap/app.php.new << 'APPEOF'
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // SPRINT 57: Add diagnostic middleware to web group
        $middleware->web(append: [
            \App\Http\Middleware\DiagnosticMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
APPEOF
    
    mv bootstrap/app.php.new bootstrap/app.php
    echo "✅ Diagnostic middleware registered in Laravel 11 format"
else
    echo "⚠️  Laravel 10 or earlier detected - middleware registration may need manual intervention"
fi

# Set permissions
chown www-data:www-data bootstrap/app.php
chown www-data:www-data app/Http/Middleware/DiagnosticMiddleware.php
chmod 644 bootstrap/app.php app/Http/Middleware/DiagnosticMiddleware.php

ENDSSH

if [ $? -eq 0 ]; then
    echo "✅ Middleware registered successfully"
else
    echo "❌ Middleware registration failed"
    exit 1
fi

# Step 4: Add test routes
echo "📝 Adding diagnostic test routes..."

sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel/routes

# Backup routes/web.php
cp web.php web.php.backup.sprint57

# Add test routes at the TOP of the file (before other routes)
cat > web.php.new << 'ROUTESEOF'
<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\SitesController;
use App\Http\Controllers\EmailController;
use App\Http\Controllers\BackupsController;
use App\Http\Controllers\SecurityController;
use App\Http\Controllers\MonitoringController;
use App\Http\Controllers\DnsController;
use App\Http\Controllers\UsersController;
use App\Http\Controllers\SettingsController;
use App\Http\Controllers\LogsController;
use App\Http\Controllers\ServicesController;
use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;

/*
|--------------------------------------------------------------------------
| SPRINT 57: DIAGNOSTIC TEST ROUTES
|--------------------------------------------------------------------------
| These routes help identify where POST /sites is being blocked
| Remove these routes after diagnosis is complete
*/

// TEST 1: Simple GET (no middleware)
Route::get('/sprint57-test-1-simple', function() {
    return response()->json([
        'test' => 'TEST 1',
        'status' => 'success',
        'message' => 'Basic routing works',
        'timestamp' => now()->toDateTimeString(),
    ]);
});

// TEST 2: Simple POST (no middleware, no CSRF)
Route::post('/sprint57-test-2-post', function() {
    return response()->json([
        'test' => 'TEST 2',
        'status' => 'success',
        'message' => 'POST routing works (no CSRF)',
        'data' => request()->all(),
    ]);
})->withoutMiddleware([\App\Http\Middleware\VerifyCsrfToken::class]);

// TEST 3: POST with CSRF (web middleware)
Route::post('/sprint57-test-3-csrf', function() {
    return response()->json([
        'test' => 'TEST 3',
        'status' => 'success',
        'message' => 'POST with CSRF works',
        'session_token' => session()->token(),
        'request_token' => request()->input('_token'),
        'tokens_match' => request()->input('_token') === session()->token(),
    ]);
})->middleware('web');

// TEST 4: POST with authentication
Route::post('/sprint57-test-4-auth', function() {
    return response()->json([
        'test' => 'TEST 4',
        'status' => 'success',
        'message' => 'POST with auth works',
        'user' => auth()->user()->email ?? 'not_logged_in',
        'authenticated' => auth()->check(),
    ]);
})->middleware(['web', 'auth']);

// TEST 5: POST to /sites prefix (mimics actual route)
Route::prefix('sites')->middleware(['web', 'auth'])->group(function () {
    Route::post('/sprint57-test-5-sites-prefix', function(Request $request) {
        \Log::info('SPRINT57 TEST 5: Route reached!', [
            'user' => auth()->user()->email ?? 'not_logged_in',
            'data_keys' => array_keys($request->all()),
        ]);
        
        return response()->json([
            'test' => 'TEST 5',
            'status' => 'success',
            'message' => '/sites prefix with auth works',
            'user' => auth()->user()->email ?? 'not_logged_in',
        ]);
    });
});

/*
|--------------------------------------------------------------------------
| END SPRINT 57 DIAGNOSTIC ROUTES
|--------------------------------------------------------------------------
*/

ROUTESEOF

# Append the rest of the original routes
tail -n +17 web.php.backup.sprint57 >> web.php.new

# Replace routes file
mv web.php.new web.php
chown www-data:www-data web.php
chmod 644 web.php

echo "✅ Test routes added"

ENDSSH

if [ $? -eq 0 ]; then
    echo "✅ Test routes deployed"
else
    echo "❌ Test routes deployment failed"
    exit 1
fi

# Step 5: Clear all Laravel caches
echo "🗑️  Clearing Laravel caches..."

sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel

php artisan route:clear
php artisan config:clear
php artisan view:clear
php artisan cache:clear
php artisan clear-compiled

echo "✅ All caches cleared"
ENDSSH

# Step 6: Verify deployment
echo "🔍 Verifying deployment..."

sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
echo "Checking diagnostic middleware..."
if [ -f "/opt/webserver/admin-panel/app/Http/Middleware/DiagnosticMiddleware.php" ]; then
    echo "✅ DiagnosticMiddleware.php exists"
else
    echo "❌ DiagnosticMiddleware.php NOT found"
fi

echo "Checking test routes..."
if grep -q "sprint57-test" /opt/webserver/admin-panel/routes/web.php; then
    echo "✅ Test routes present in web.php"
else
    echo "❌ Test routes NOT found in web.php"
fi

echo "Checking Laravel routes..."
cd /opt/webserver/admin-panel
php artisan route:list | grep -E "(sprint57|POST.*sites)"
ENDSSH

echo ""
echo "=================================================="
echo " ✅ DIAGNOSTIC TOOLS DEPLOYED"
echo "=================================================="
echo ""
echo "📋 HOW TO RUN DIAGNOSTICS:"
echo ""
echo "1. Test basic routing (should always work):"
echo "   curl https://72.61.53.222/admin/sprint57-test-1-simple"
echo ""
echo "2. Test POST without CSRF (tests POST routing):"
echo "   curl -X POST https://72.61.53.222/admin/sprint57-test-2-post -d 'test=value'"
echo ""
echo "3. Test POST with CSRF (requires login first):"
echo "   # Get session cookie:"
echo "   curl -c /tmp/cookies.txt https://72.61.53.222/admin/login"
echo "   # Login:"
echo "   curl -b /tmp/cookies.txt -c /tmp/cookies.txt -X POST https://72.61.53.222/admin/login \\"
echo "     -d '_token=GET_FROM_PAGE&email=admin@vps.local&password=mcorpapp'"
echo "   # Test CSRF:"
echo "   curl -b /tmp/cookies.txt -X POST https://72.61.53.222/admin/sprint57-test-3-csrf \\"
echo "     -d '_token=GET_FROM_SESSION&test=value'"
echo ""
echo "4. Test with authentication:"
echo "   curl -b /tmp/cookies.txt -X POST https://72.61.53.222/admin/sprint57-test-4-auth \\"
echo "     -d '_token=TOKEN&test=value'"
echo ""
echo "5. Test /sites prefix specifically:"
echo "   curl -b /tmp/cookies.txt -X POST https://72.61.53.222/admin/sites/sprint57-test-5-sites-prefix \\"
echo "     -d '_token=TOKEN&test=value'"
echo ""
echo "6. Check Laravel logs for diagnostic output:"
echo "   ssh root@72.61.53.222 'tail -100 /opt/webserver/admin-panel/storage/logs/laravel.log | grep SPRINT57'"
echo ""
echo "7. Try actual site creation and watch logs:"
echo "   ssh root@72.61.53.222 'tail -f /opt/webserver/admin-panel/storage/logs/laravel.log'"
echo "   (Then create site via web interface)"
echo ""
echo "=================================================="
echo ""
echo "📝 INTERPRETATION:"
echo "  - Test 1 fails: NGINX/Laravel routing broken"
echo "  - Test 2 fails: POST routing broken"
echo "  - Test 3 fails: CSRF validation issue ← MOST LIKELY"
echo "  - Test 4 fails: Authentication middleware issue"
echo "  - Test 5 fails: Problem specific to /sites routes"
echo "  - All pass but actual creation fails: Controller issue"
echo ""
echo "After running tests, analyze logs and implement surgical fix"
echo ""
echo "=================================================="
