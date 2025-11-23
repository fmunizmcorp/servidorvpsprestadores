#!/bin/bash
SSH_HOST="root@72.61.53.222"
SSH_PASS="Jm@D@KDPnw7Q"

echo "=========================================="
echo "🧪 SPRINT 3 VALIDATION TESTS"
echo "=========================================="

PASS=0
FAIL=0

# Test 1
echo "TEST 1: EmailController::editAccount() exists"
RES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "grep -c 'public function editAccount' /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php || echo 0")
if [ "$RES" -ge "1" ]; then echo "  ✅ PASS"; ((PASS++)); else echo "  ❌ FAIL"; ((FAIL++)); fi

# Test 2
echo "TEST 2: EmailController::updateAccount() exists"
RES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "grep -c 'public function updateAccount' /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php || echo 0")
if [ "$RES" -ge "1" ]; then echo "  ✅ PASS"; ((PASS++)); else echo "  ❌ FAIL"; ((FAIL++)); fi

# Test 3
echo "TEST 3: accounts-edit.blade.php exists"
RES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "test -f /opt/webserver/admin-panel/resources/views/email/accounts-edit.blade.php && echo 1 || echo 0")
if [ "$RES" = "1" ]; then echo "  ✅ PASS"; ((PASS++)); else echo "  ❌ FAIL"; ((FAIL++)); fi

# Test 4
echo "TEST 4: Route GET /accounts/{id}/edit exists"
RES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "grep -c \"Route::get('/accounts/{id}/edit'\" /opt/webserver/admin-panel/routes/web.php || echo 0")
if [ "$RES" -ge "1" ]; then echo "  ✅ PASS"; ((PASS++)); else echo "  ❌ FAIL"; ((FAIL++)); fi

# Test 5
echo "TEST 5: Route PUT /accounts/{id} exists"
RES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "grep -c \"Route::put('/accounts/{id}'\" /opt/webserver/admin-panel/routes/web.php || echo 0")
if [ "$RES" -ge "1" ]; then echo "  ✅ PASS"; ((PASS++)); else echo "  ❌ FAIL"; ((FAIL++)); fi

# Test 6
echo "TEST 6: accounts.blade.php has Edit button"
RES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "grep -c 'email.accounts.edit' /opt/webserver/admin-panel/resources/views/email/accounts.blade.php || echo 0")
if [ "$RES" -ge "1" ]; then echo "  ✅ PASS"; ((PASS++)); else echo "  ❌ FAIL"; ((FAIL++)); fi

# Test 7
echo "TEST 7: PHP syntax valid"
RES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "php -l /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php 2>&1 | grep -c 'No syntax errors' || echo 0")
if [ "$RES" -ge "1" ]; then echo "  ✅ PASS"; ((PASS++)); else echo "  ❌ FAIL"; ((FAIL++)); fi

# Test 8
echo "TEST 8: Routes registered"
RES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "cd /opt/webserver/admin-panel && php artisan route:list | grep -c 'email.accounts.edit' || echo 0")
if [ "$RES" -ge "1" ]; then echo "  ✅ PASS"; ((PASS++)); else echo "  ❌ FAIL"; ((FAIL++)); fi

echo "=========================================="
echo "📊 RESULTS: ✅ $PASS | ❌ $FAIL | 📈 $((PASS*100/(PASS+FAIL)))%"
echo "=========================================="
if [ "$FAIL" -eq 0 ]; then echo "🎉 ALL TESTS PASSED!"; exit 0; else exit 1; fi
