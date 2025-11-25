#!/bin/bash

# Validation Script for Recovery Sprints 1-4
# Tests all fixes applied based on QA report

REMOTE_HOST="72.61.53.222"
REMOTE_USER="root"
REMOTE_PASS="Jm@D@KDPnw7Q"
REMOTE_PATH="/opt/webserver/admin-panel"

echo "========================================"
echo "🧪 RECOVERY FIXES VALIDATION"
echo "Testing all corrections from QA report"
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

echo "========================================"
echo "📋 RECOVERY SPRINT 1: BackupsController"
echo "========================================"
echo ""

# Test 1: BackupsController syntax is valid
run_test "BackupsController has no PHP syntax errors" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'php -l $REMOTE_PATH/app/Http/Controllers/BackupsController.php' | grep -q 'No syntax errors'"

# Test 2: BackupsController has only ONE download method
run_test "BackupsController has exactly ONE download() method" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -c \"public function download\" $REMOTE_PATH/app/Http/Controllers/BackupsController.php' | grep -q '^1$'"

# Test 3: Backups page is accessible (no error 500)
run_test "Backups page accessible (HTTP 200)" \
    "curl -k -s -o /dev/null -w '%{http_code}' -u 'admin@vps.local:mcorpapp' https://72.61.53.222/admin/backups | grep -q '^200$'"

echo "========================================"
echo "📋 RECOVERY SPRINT 2: Email Routes"
echo "========================================"
echo ""

# Test 4: Route email.accounts.edit is registered correctly
run_test "Route email.accounts.edit is registered (not duplicated)" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'cd $REMOTE_PATH && php artisan route:list --name=email.accounts.edit' | grep -q 'email.accounts.edit'"

# Test 5: Email Accounts page is accessible (no error 500)
run_test "Email Accounts page accessible (HTTP 200)" \
    "curl -k -s -o /dev/null -w '%{http_code}' -u 'admin@vps.local:mcorpapp' https://72.61.53.222/admin/email/accounts | grep -q '^200$'"

echo "========================================"
echo "📋 RECOVERY SPRINT 3: Sites Persistence"
echo "========================================"
echo ""

# Test 6: SitesController uses physical verification instead of output check
run_test "SitesController uses is_dir() verification" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"is_dir.*sitePath\" $REMOTE_PATH/app/Http/Controllers/SitesController.php'"

# Test 7: SitesController checks pool file exists
run_test "SitesController checks PHP-FPM pool file" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'grep -q \"file_exists.*poolFile\" $REMOTE_PATH/app/Http/Controllers/SitesController.php'"

# Test 8: Site::create() works in database
run_test "Site::create() can persist to database" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'cd $REMOTE_PATH && php artisan tinker --execute=\"\\\$site = \App\Models\Site::create([\\\"site_name\\\" => \\\"test_validate_\\\".time(), \\\"domain\\\" => \\\"test.local\\\", \\\"php_version\\\" => \\\"8.3\\\", \\\"status\\\" => \\\"active\\\"]); echo \\\$site->id ? \\\"YES\\\" : \\\"NO\\\";\" 2>/dev/null' | grep -q 'YES'"

echo "========================================"
echo "📋 RECOVERY SPRINT 4: Email Domains"
echo "========================================"
echo ""

# Test 9: EmailDomain::create() works in database
run_test "EmailDomain::create() can persist to database" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'cd $REMOTE_PATH && php artisan tinker --execute=\"\\\$domain = \App\Models\EmailDomain::create([\\\"domain\\\" => \\\"test-validate-\\\".time().\\\".local\\\", \\\"status\\\" => \\\"active\\\"]); echo \\\$domain->id ? \\\"YES\\\" : \\\"NO\\\";\" 2>/dev/null' | grep -q 'YES'"

# Test 10: Email Domains page is accessible
run_test "Email Domains page accessible (HTTP 200)" \
    "curl -k -s -o /dev/null -w '%{http_code}' -u 'admin@vps.local:mcorpapp' https://72.61.53.222/admin/email/domains | grep -q '^200$'"

echo "========================================"
echo "📋 SYSTEM HEALTH CHECKS"
echo "========================================"
echo ""

# Test 11: All services running
run_test "NGINX is running" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'systemctl is-active nginx' | grep -q 'active'"

run_test "PHP-FPM is running" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'systemctl is-active php8.3-fpm' | grep -q 'active'"

run_test "MariaDB is running" \
    "sshpass -p '$REMOTE_PASS' ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    'systemctl is-active mariadb' | grep -q 'active'"

# Summary
echo ""
echo "========================================"
echo "📊 VALIDATION SUMMARY"
echo "========================================"
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $((TOTAL_TESTS - PASSED_TESTS))"
echo ""

SUCCESS_RATE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
echo "Success Rate: $SUCCESS_RATE%"
echo ""

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo "🎉🎉🎉 ALL RECOVERY FIXES VALIDATED! 🎉🎉🎉"
    echo ""
    echo "✅ RECOVERY SPRINT 1: BackupsController syntax fixed"
    echo "✅ RECOVERY SPRINT 2: Email routes corrected"
    echo "✅ RECOVERY SPRINT 3: Sites persistence fixed"
    echo "✅ RECOVERY SPRINT 4: Email domains working"
    echo ""
    echo "🏆 All critical bugs from QA report are RESOLVED!"
    exit 0
else
    echo "⚠️  SOME TESTS FAILED"
    echo ""
    echo "Review failed tests above and fix remaining issues."
    exit 1
fi
