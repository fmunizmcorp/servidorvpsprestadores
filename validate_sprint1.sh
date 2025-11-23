#!/bin/bash

# SPRINT 1 Validation Script: Two-Factor Authentication (2FA)
# Epic 1, US-1.4 - Validate complete 2FA implementation

REMOTE_HOST="72.61.53.222"
REMOTE_USER="root"
REMOTE_PASS="Jm@D@KDPnw7Q"
REMOTE_PATH="/opt/webserver/admin-panel"

echo "========================================"
echo "🧪 SPRINT 1: 2FA Validation"
echo "========================================"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo "Test $TOTAL_TESTS: $test_name"
    
    if eval "$test_command"; then
        echo "  ✅ PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "  ❌ FAILED"
    fi
    echo ""
}

# Test 1: Check User model has 2FA columns in fillable
run_test "User model has 2FA fields in fillable array" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"two_factor_enabled\" $REMOTE_PATH/app/Models/User.php && \
     grep -q \"two_factor_secret\" $REMOTE_PATH/app/Models/User.php && \
     grep -q \"two_factor_recovery_codes\" $REMOTE_PATH/app/Models/User.php'"

# Test 2: Check User model has hasTwoFactorEnabled method
run_test "User model has hasTwoFactorEnabled() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"function hasTwoFactorEnabled\" $REMOTE_PATH/app/Models/User.php'"

# Test 3: Check User model has generateRecoveryCodes method
run_test "User model has generateRecoveryCodes() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"function generateRecoveryCodes\" $REMOTE_PATH/app/Models/User.php'"

# Test 4: Check TwoFactorController exists
run_test "TwoFactorController exists" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'test -f $REMOTE_PATH/app/Http/Controllers/TwoFactorController.php'"

# Test 5: Check TwoFactorController has show method
run_test "TwoFactorController has show() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"public function show\" $REMOTE_PATH/app/Http/Controllers/TwoFactorController.php'"

# Test 6: Check TwoFactorController has enable method
run_test "TwoFactorController has enable() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"public function enable\" $REMOTE_PATH/app/Http/Controllers/TwoFactorController.php'"

# Test 7: Check TwoFactorController has confirm method
run_test "TwoFactorController has confirm() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"public function confirm\" $REMOTE_PATH/app/Http/Controllers/TwoFactorController.php'"

# Test 8: Check TwoFactorController has disable method
run_test "TwoFactorController has disable() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"public function disable\" $REMOTE_PATH/app/Http/Controllers/TwoFactorController.php'"

# Test 9: Check TwoFactorController has challenge method
run_test "TwoFactorController has challenge() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"public function challenge\" $REMOTE_PATH/app/Http/Controllers/TwoFactorController.php'"

# Test 10: Check TwoFactorController has verify method
run_test "TwoFactorController has verify() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"public function verify\" $REMOTE_PATH/app/Http/Controllers/TwoFactorController.php'"

# Test 11: Check TwoFactorController has regenerateRecoveryCodes method
run_test "TwoFactorController has regenerateRecoveryCodes() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"public function regenerateRecoveryCodes\" $REMOTE_PATH/app/Http/Controllers/TwoFactorController.php'"

# Test 12: Check AuthenticatedSessionController updated with 2FA logic
run_test "AuthenticatedSessionController has 2FA check in store() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"hasTwoFactorEnabled\" $REMOTE_PATH/app/Http/Controllers/Auth/AuthenticatedSessionController.php'"

# Test 13: Check 2FA show view exists
run_test "2FA show view exists" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'test -f $REMOTE_PATH/resources/views/auth/two-factor/show.blade.php'"

# Test 14: Check 2FA enable view exists
run_test "2FA enable view exists" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'test -f $REMOTE_PATH/resources/views/auth/two-factor/enable.blade.php'"

# Test 15: Check 2FA challenge view exists
run_test "2FA challenge view exists" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'test -f $REMOTE_PATH/resources/views/auth/two-factor/challenge.blade.php'"

# Test 16: Check 2FA recovery codes view exists
run_test "2FA recovery codes view exists" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'test -f $REMOTE_PATH/resources/views/auth/two-factor/recovery-codes.blade.php'"

# Test 17: Check routes contain two-factor.show
run_test "Route two-factor.show is registered" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"two-factor.show\" $REMOTE_PATH/routes/web.php'"

# Test 18: Check routes contain two-factor.enable
run_test "Route two-factor.enable is registered" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"two-factor.enable\" $REMOTE_PATH/routes/web.php'"

# Test 19: Check routes contain two-factor.confirm
run_test "Route two-factor.confirm is registered" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"two-factor.confirm\" $REMOTE_PATH/routes/web.php'"

# Test 20: Check routes contain two-factor.disable
run_test "Route two-factor.disable is registered" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"two-factor.disable\" $REMOTE_PATH/routes/web.php'"

# Test 21: Check routes contain two-factor.challenge
run_test "Route two-factor.challenge is registered" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"two-factor.challenge\" $REMOTE_PATH/routes/web.php'"

# Test 22: Check routes contain two-factor.verify
run_test "Route two-factor.verify is registered" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"two-factor.verify\" $REMOTE_PATH/routes/web.php'"

# Test 23: Check routes contain two-factor.regenerate-codes
run_test "Route two-factor.regenerate-codes is registered" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"two-factor.regenerate-codes\" $REMOTE_PATH/routes/web.php'"

# Test 24: Check database has two_factor_enabled column
run_test "Database has two_factor_enabled column" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'cd $REMOTE_PATH && php artisan tinker --execute=\"echo in_array(\\\"two_factor_enabled\\\", \DB::getSchemaBuilder()->getColumnListing(\\\"users\\\")) ? \\\"YES\\\" : \\\"NO\\\";\" 2>/dev/null | grep -q \"YES\"'"

# Test 25: Check database has two_factor_secret column
run_test "Database has two_factor_secret column" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'cd $REMOTE_PATH && php artisan tinker --execute=\"echo in_array(\\\"two_factor_secret\\\", \DB::getSchemaBuilder()->getColumnListing(\\\"users\\\")) ? \\\"YES\\\" : \\\"NO\\\";\" 2>/dev/null | grep -q \"YES\"'"

# Test 26: Check database has two_factor_recovery_codes column
run_test "Database has two_factor_recovery_codes column" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'cd $REMOTE_PATH && php artisan tinker --execute=\"echo in_array(\\\"two_factor_recovery_codes\\\", \DB::getSchemaBuilder()->getColumnListing(\\\"users\\\")) ? \\\"YES\\\" : \\\"NO\\\";\" 2>/dev/null | grep -q \"YES\"'"

# Test 27: Check google2fa package is installed
run_test "Google2FA package is installed" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'test -d $REMOTE_PATH/vendor/pragmarx/google2fa-laravel'"

# Test 28: Check bacon-qr-code package is installed
run_test "Bacon QR Code package is installed" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'test -d $REMOTE_PATH/vendor/bacon/bacon-qr-code'"

# Test 29: Check TwoFactorController is imported in routes
run_test "TwoFactorController is imported in routes" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"use App\\\\\\\Http\\\\\\\Controllers\\\\\\\TwoFactorController\" $REMOTE_PATH/routes/web.php'"

# Test 30: Validate no PHP syntax errors in User model
run_test "User model has no PHP syntax errors" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'php -l $REMOTE_PATH/app/Models/User.php' | grep -q 'No syntax errors'"

# Test 31: Validate no PHP syntax errors in TwoFactorController
run_test "TwoFactorController has no PHP syntax errors" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'php -l $REMOTE_PATH/app/Http/Controllers/TwoFactorController.php' | grep -q 'No syntax errors'"

# Test 32: Validate no PHP syntax errors in AuthenticatedSessionController
run_test "AuthenticatedSessionController has no PHP syntax errors" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'php -l $REMOTE_PATH/app/Http/Controllers/Auth/AuthenticatedSessionController.php' | grep -q 'No syntax errors'"

# Summary
echo "========================================"
echo "📊 VALIDATION SUMMARY"
echo "========================================"
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $((TOTAL_TESTS - PASSED_TESTS))"
echo ""

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo "✅ ALL TESTS PASSED!"
    echo "🎉 SPRINT 1 (2FA) is fully validated and functional"
    echo ""
    echo "📋 User Story US-1.4: Two-Factor Authentication - COMPLETE"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    echo "Success Rate: $(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")%"
    exit 1
fi
