#!/bin/bash

# ========================================
# VALIDATION SCRIPT - SPRINT 8
# Dashboard Historical Graphs + Email Alerts
# ========================================

echo "=========================================="
echo "VALIDATING SPRINT 8 ON PRODUCTION"
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
# SPRINT 8 TESTS
# ========================================
echo "🔍 SPRINT 8: Dashboard Enhancements"
echo "------------------------------------"

run_test "MetricsHistory model exists" \
    "test -f $APP_PATH/app/Models/MetricsHistory.php && echo 'EXISTS'" \
    "EXISTS"

run_test "metrics_history table created" \
    "cd $APP_PATH && php artisan tinker --execute=\"echo \App\Models\MetricsHistory::count();\"" \
    "[0-9]"

run_test "CollectMetrics command exists" \
    "test -f $APP_PATH/app/Console/Commands/CollectMetrics.php && echo 'EXISTS'" \
    "EXISTS"

run_test "CollectMetrics command registered" \
    "cd $APP_PATH && php artisan list | grep 'metrics:collect' && echo 'EXISTS'" \
    "EXISTS"

run_test "HighUsageAlert mail class exists" \
    "test -f $APP_PATH/app/Mail/HighUsageAlert.php && echo 'EXISTS'" \
    "EXISTS"

run_test "High-usage-alert email view exists" \
    "test -f $APP_PATH/resources/views/emails/high-usage-alert.blade.php && echo 'EXISTS'" \
    "EXISTS"

run_test "DashboardController has apiHistoricalMetrics method" \
    "grep -q 'public function apiHistoricalMetrics' $APP_PATH/app/Http/Controllers/DashboardController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Dashboard view has Chart.js" \
    "grep -q 'chart.js' $APP_PATH/resources/views/dashboard.blade.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Dashboard view has cpuChart canvas" \
    "grep -q 'id=\"cpuChart\"' $APP_PATH/resources/views/dashboard.blade.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Dashboard view has time range selector" \
    "grep -q 'id=\"timeRange\"' $APP_PATH/resources/views/dashboard.blade.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Route dashboard.apiHistoricalMetrics registered" \
    "grep -q 'dashboard.apiHistoricalMetrics' $APP_PATH/routes/web.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Cron job for metrics collection exists" \
    "crontab -l | grep 'metrics:collect' && echo 'EXISTS'" \
    "EXISTS"

run_test "At least one metric record collected" \
    "cd $APP_PATH && php artisan tinker --execute=\"echo \App\Models\MetricsHistory::count() > 0 ? 'YES' : 'NO';\"" \
    "YES"

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
    echo "🎉 ALL TESTS PASSED! SPRINT 8 IS COMPLETE!"
    exit 0
else
    echo "⚠️  Some tests failed. Please review."
    exit 1
fi
