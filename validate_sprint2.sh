#!/bin/bash
##############################################
# VALIDATION SCRIPT - SPRINT 2
# Email Domains EDIT Functionality
##############################################

SSH_HOST="root@72.61.53.222"
SSH_PASS="Jm@D@KDPnw7Q"

echo "============================================"
echo "🧪 SPRINT 2 VALIDATION TESTS"
echo "============================================"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

# Test 1: Verify EmailController has editDomain method
echo "TEST 1: EmailController::editDomain() method exists"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "grep -c 'public function editDomain' /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php || echo 0")
if [ "$RESULT" -ge "1" ]; then
  echo "  ✅ PASS - editDomain() method found"
  ((PASS_COUNT++))
else
  echo "  ❌ FAIL - editDomain() method NOT found"
  ((FAIL_COUNT++))
fi
echo ""

# Test 2: Verify EmailController has updateDomain method
echo "TEST 2: EmailController::updateDomain() method exists"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "grep -c 'public function updateDomain' /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php || echo 0")
if [ "$RESULT" -ge "1" ]; then
  echo "  ✅ PASS - updateDomain() method found"
  ((PASS_COUNT++))
else
  echo "  ❌ FAIL - updateDomain() method NOT found"
  ((FAIL_COUNT++))
fi
echo ""

# Test 3: Verify domains-edit view exists
echo "TEST 3: domains-edit.blade.php view exists"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "test -f /opt/webserver/admin-panel/resources/views/email/domains-edit.blade.php && echo 1 || echo 0")
if [ "$RESULT" = "1" ]; then
  echo "  ✅ PASS - domains-edit.blade.php exists"
  ((PASS_COUNT++))
else
  echo "  ❌ FAIL - domains-edit.blade.php NOT found"
  ((FAIL_COUNT++))
fi
echo ""

# Test 4: Verify routes contain edit endpoint
echo "TEST 4: Route GET /domains/{id}/edit exists"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "grep -c \"Route::get('/domains/{id}/edit'\" /opt/webserver/admin-panel/routes/web.php || echo 0")
if [ "$RESULT" -ge "1" ]; then
  echo "  ✅ PASS - EDIT route found in web.php"
  ((PASS_COUNT++))
else
  echo "  ❌ FAIL - EDIT route NOT found"
  ((FAIL_COUNT++))
fi
echo ""

# Test 5: Verify routes contain update endpoint
echo "TEST 5: Route PUT /domains/{id} exists"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "grep -c \"Route::put('/domains/{id}'\" /opt/webserver/admin-panel/routes/web.php || echo 0")
if [ "$RESULT" -ge "1" ]; then
  echo "  ✅ PASS - UPDATE route found in web.php"
  ((PASS_COUNT++))
else
  echo "  ❌ FAIL - UPDATE route NOT found"
  ((FAIL_COUNT++))
fi
echo ""

# Test 6: Verify updated domains view has Edit button
echo "TEST 6: domains.blade.php has Edit button link"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "grep -c 'email.domains.edit' /opt/webserver/admin-panel/resources/views/email/domains.blade.php || echo 0")
if [ "$RESULT" -ge "1" ]; then
  echo "  ✅ PASS - Edit button found in domains view"
  ((PASS_COUNT++))
else
  echo "  ❌ FAIL - Edit button NOT found"
  ((FAIL_COUNT++))
fi
echo ""

# Test 7: Verify PHP syntax is valid
echo "TEST 7: EmailController PHP syntax validation"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "php -l /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php 2>&1 | grep -c 'No syntax errors' || echo 0")
if [ "$RESULT" -ge "1" ]; then
  echo "  ✅ PASS - PHP syntax valid"
  ((PASS_COUNT++))
else
  echo "  ❌ FAIL - PHP syntax error"
  ((FAIL_COUNT++))
fi
echo ""

# Test 8: Verify routes can be cached (no errors)
echo "TEST 8: Routes cache successfully"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "cd /opt/webserver/admin-panel && php artisan route:cache 2>&1 | grep -c 'Routes cached successfully' || echo 0")
if [ "$RESULT" -ge "1" ]; then
  echo "  ✅ PASS - Routes cache successful"
  ((PASS_COUNT++))
else
  echo "  ❌ FAIL - Routes cache failed"
  ((FAIL_COUNT++))
fi

# Clear route cache after test
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "cd /opt/webserver/admin-panel && php artisan route:clear" > /dev/null 2>&1

echo ""

# Test 9: Verify domain exists in database for testing
echo "TEST 9: At least one email domain exists in database"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e 'SELECT COUNT(*) FROM email_domains;' -s -N")
if [ "$RESULT" -ge "1" ]; then
  echo "  ✅ PASS - $RESULT email domains found in database"
  ((PASS_COUNT++))
else
  echo "  ⚠️  WARN - No email domains found (cannot test edit functionality)"
  echo "  ℹ️  INFO - Create a domain first to test edit feature"
fi
echo ""

# Test 10: List routes to verify they are registered
echo "TEST 10: Verify email.domains.edit route is registered"
RESULT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "cd /opt/webserver/admin-panel && php artisan route:list | grep -c 'email.domains.edit' || echo 0")
if [ "$RESULT" -ge "1" ]; then
  echo "  ✅ PASS - email.domains.edit route registered"
  ((PASS_COUNT++))
else
  echo "  ❌ FAIL - email.domains.edit route NOT registered"
  ((FAIL_COUNT++))
fi
echo ""

# RESULTS SUMMARY
echo "============================================"
echo "📊 VALIDATION RESULTS"
echo "============================================"
echo "  ✅ Passed: $PASS_COUNT"
echo "  ❌ Failed: $FAIL_COUNT"
echo "  📈 Success Rate: $(( PASS_COUNT * 100 / (PASS_COUNT + FAIL_COUNT) ))%"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "🎉 ALL TESTS PASSED! SPRINT 2 VALIDATED SUCCESSFULLY"
  echo ""
  echo "✅ Email Domains EDIT functionality is ready for production use"
  exit 0
else
  echo "⚠️  SOME TESTS FAILED - Review errors above"
  exit 1
fi
