#!/bin/bash

# ========================================
# VALIDATION SCRIPT - SPRINTS 6 & 7
# Email: complete validation via SSH
# ========================================

echo "=========================================="
echo "VALIDATING SPRINTS 6 & 7 ON PRODUCTION"
echo "=========================================="
echo ""

HOST="72.61.53.222"
PASS="Jm@D@KDPnw7Q"
APP_PATH="/opt/webserver/admin-panel"

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Helper function to run test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    echo -n "[$TEST_COUNT] Testing: $test_name ... "
    
    result=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST "$command" 2>&1)
    
    if echo "$result" | grep -q "$expected"; then
        echo "✅ PASS"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo "❌ FAIL"
        echo "    Expected: $expected"
        echo "    Got: $result"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# ========================================
# SPRINT 6 TESTS: LogsController
# ========================================
echo "🔍 SPRINT 6: Logs Management"
echo "----------------------------"

run_test "LogsController exists" \
    "test -f $APP_PATH/app/Http/Controllers/LogsController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "LogsController::index() method exists" \
    "grep -q 'public function index' $APP_PATH/app/Http/Controllers/LogsController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "LogsController::clear() method exists" \
    "grep -q 'public function clear' $APP_PATH/app/Http/Controllers/LogsController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "LogsController::download() method exists" \
    "grep -q 'public function download' $APP_PATH/app/Http/Controllers/LogsController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Logs index view exists" \
    "test -f $APP_PATH/resources/views/logs/index.blade.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Route logs.index registered" \
    "grep -q \"Route::get('/', \[LogsController::class, 'index'\])\" $APP_PATH/routes/web.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Route logs.clear registered" \
    "grep -q \"Route::post('/clear/{type}', \[LogsController::class, 'clear'\])\" $APP_PATH/routes/web.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Route logs.download registered" \
    "grep -q \"Route::get('/download/{type}', \[LogsController::class, 'download'\])\" $APP_PATH/routes/web.php && echo 'EXISTS'" \
    "EXISTS"

echo ""

# ========================================
# SPRINT 7 TESTS: ServicesController
# ========================================
echo "🔍 SPRINT 7: Services Management"
echo "--------------------------------"

run_test "ServicesController exists" \
    "test -f $APP_PATH/app/Http/Controllers/ServicesController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "ServicesController::stop() method exists" \
    "grep -q 'public function stop' $APP_PATH/app/Http/Controllers/ServicesController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "ServicesController::start() method exists" \
    "grep -q 'public function start' $APP_PATH/app/Http/Controllers/ServicesController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "ServicesController::restart() method exists" \
    "grep -q 'public function restart' $APP_PATH/app/Http/Controllers/ServicesController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Services index view exists" \
    "test -f $APP_PATH/resources/views/services/index.blade.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Route services.stop registered" \
    "grep -q \"Route::post('/stop/{service}', \[ServicesController::class, 'stop'\])\" $APP_PATH/routes/web.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Route services.start registered" \
    "grep -q \"Route::post('/start/{service}', \[ServicesController::class, 'start'\])\" $APP_PATH/routes/web.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Route services.restart registered" \
    "grep -q \"Route::post('/restart/{service}', \[ServicesController::class, 'restart'\])\" $APP_PATH/routes/web.php && echo 'EXISTS'" \
    "EXISTS"

echo ""

# ========================================
# SUMMARY
# ========================================
echo "=========================================="
echo "VALIDATION SUMMARY"
echo "=========================================="
echo "Total Tests: $TEST_COUNT"
echo "Passed:      $PASS_COUNT ✅"
echo "Failed:      $FAIL_COUNT ❌"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED! SPRINTS 6 & 7 ARE COMPLETE!"
    exit 0
else
    echo "⚠️  Some tests failed. Please review."
    exit 1
fi
