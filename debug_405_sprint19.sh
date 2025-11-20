#!/bin/bash

echo "=== SPRINT 19 - DEBUG HTTP 405 BLOCKER ==="
echo "Timestamp: $(date)"
echo ""

# Test 1: Check if PHP-FPM is receiving requests
echo "[TEST 1] Checking PHP-FPM error logs..."
ssh root@72.61.53.222 "tail -50 /var/log/php8.3-fpm.log 2>/dev/null || echo 'Log not found or empty'"
echo ""

# Test 2: Enable Laravel debug mode temporarily
echo "[TEST 2] Enabling Laravel debug mode..."
ssh root@72.61.53.222 "cd /opt/webserver/admin-panel && sed -i 's/APP_DEBUG=false/APP_DEBUG=true/' .env && cat .env | grep APP_DEBUG"
echo ""

# Test 3: Create simple test route to isolate POST issue
echo "[TEST 3] Creating test POST route..."
ssh root@72.61.53.222 "cat > /opt/webserver/admin-panel/routes/test.php" << 'TESTROUTE'
<?php
use Illuminate\Support\Facades\Route;

Route::post('/test-post', function() {
    return response()->json([
        'status' => 'success',
        'message' => 'POST request received successfully',
        'method' => request()->method(),
        'path' => request()->path(),
        'url' => request()->url()
    ]);
})->name('test.post');

Route::get('/test-post', function() {
    return response()->json([
        'status' => 'info',
        'message' => 'This endpoint requires POST method',
        'use_curl' => 'curl -X POST https://72.61.53.222/admin/test-post'
    ]);
});
TESTROUTE

ssh root@72.61.53.222 "echo \"require __DIR__.'/test.php';\" >> /opt/webserver/admin-panel/routes/web.php"
ssh root@72.61.53.222 "cd /opt/webserver/admin-panel && php artisan config:clear && php artisan route:clear && php artisan cache:clear"
echo ""

# Test 4: Test the simple POST route
echo "[TEST 4] Testing simple POST route without authentication..."
curl -X POST https://72.61.53.222/admin/test-post -k -v 2>&1 | grep -E "(< HTTP|POST|405|200|location)"
echo ""

# Test 5: Check if NGINX is passing POST correctly
echo "[TEST 5] Testing POST with explicit Content-Type..."
curl -X POST https://72.61.53.222/admin/test-post \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "test=data" \
  -k -v 2>&1 | grep -E "(< HTTP|POST|405|200)"
echo ""

# Test 6: Check NGINX access logs for POST requests
echo "[TEST 6] Recent POST requests in NGINX logs..."
ssh root@72.61.53.222 "tail -20 /var/log/nginx/access.log | grep POST || echo 'No POST requests found'"
echo ""

# Test 7: Check if issue is METHOD_NOT_ALLOWED vs route not found
echo "[TEST 7] Testing non-existent route for comparison..."
curl -X POST https://72.61.53.222/admin/nonexistent-route-test -k -I 2>&1 | grep "HTTP"
echo ""

echo "=== DEBUG COMPLETE ==="
