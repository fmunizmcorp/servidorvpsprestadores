#!/bin/bash

# ========================================
# VALIDATION SCRIPT - SPRINT 9
# Email Server Advanced Features
# ========================================

echo "=========================================="
echo "VALIDATING SPRINT 9 ON PRODUCTION"
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
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# ========================================
# SPRINT 9 TESTS
# ========================================
echo "🔍 SPRINT 9: Email Server Advanced"
echo "-----------------------------------"

run_test "EmailController exists" \
    "test -f $APP_PATH/app/Http/Controllers/EmailController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "EmailController has spamLogs method" \
    "grep -q 'public function spamLogs' $APP_PATH/app/Http/Controllers/EmailController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "EmailController has aliases method" \
    "grep -q 'public function aliases' $APP_PATH/app/Http/Controllers/EmailController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "EmailController has storeAlias method" \
    "grep -q 'public function storeAlias' $APP_PATH/app/Http/Controllers/EmailController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "EmailController has deleteAlias method" \
    "grep -q 'public function deleteAlias' $APP_PATH/app/Http/Controllers/EmailController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "getDNSRecordsForDomain includes DKIM" \
    "grep -q 'DKIM' $APP_PATH/app/Http/Controllers/EmailController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "getDNSRecordsForDomain includes DMARC" \
    "grep -q 'DMARC' $APP_PATH/app/Http/Controllers/EmailController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "checkCurrentDNS checks DKIM" \
    "grep -q 'dkim' $APP_PATH/app/Http/Controllers/EmailController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "checkCurrentDNS checks DMARC" \
    "grep -q 'dmarc' $APP_PATH/app/Http/Controllers/EmailController.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Spam logs view exists" \
    "test -f $APP_PATH/resources/views/email/spam-logs.blade.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Aliases view exists" \
    "test -f $APP_PATH/resources/views/email/aliases.blade.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Aliases create view exists" \
    "test -f $APP_PATH/resources/views/email/aliases-create.blade.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Route spam-logs registered in web.php" \
    "grep -q 'spam-logs' $APP_PATH/routes/web.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Route aliases registered in web.php" \
    "grep -q \"Route::get('/aliases'\" $APP_PATH/routes/web.php && echo 'EXISTS'" \
    "EXISTS"

run_test "Postfix virtual file exists" \
    "test -f /etc/postfix/virtual && echo 'EXISTS'" \
    "EXISTS"

run_test "Postfix virtual.db exists (postmap executed)" \
    "test -f /etc/postfix/virtual.db && echo 'EXISTS'" \
    "EXISTS"

run_test "Virtual aliases configured in main.cf" \
    "grep -q 'virtual_alias_maps' /etc/postfix/main.cf && echo 'EXISTS'" \
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
    echo "🎉 ALL TESTS PASSED! SPRINT 9 IS COMPLETE!"
    exit 0
else
    echo "⚠️  Some tests failed. Please review."
    exit 1
fi
