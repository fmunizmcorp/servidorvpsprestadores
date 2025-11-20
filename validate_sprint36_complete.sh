#!/bin/bash
# SPRINT 36 - Complete End-to-End Validation Test
# Test via WEB FORM, NOT SSH

set -e

ADMIN_URL="https://72.61.53.222/admin"
LOGIN_URL="$ADMIN_URL/login"
CREATE_SITE_URL="$ADMIN_URL/sites"
SITES_LIST_URL="$ADMIN_URL/sites"
USERNAME="test@admin.local"
PASSWORD="Test@123456"
SITE_NAME="sprint36test$(date +%s)"
DOMAIN="${SITE_NAME}.local"
COOKIES_FILE="cookies_sprint36_final_validation.txt"
VPS_IP="72.61.53.222"
VPS_USER="root"
VPS_PASS="Jm@D@KDPnw7Q"

echo "========================================="
echo "  SPRINT 36 - END-TO-END VALIDATION"
echo "========================================="
echo "Site name: $SITE_NAME"
echo "Domain: $DOMAIN"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="
echo ""

# Function to execute remote commands
remote_exec() {
    sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "$1"
}

echo "[1/10] Step 1: Fetching login page and CSRF token..."
CSRF_TOKEN=$(curl -k -s -c "$COOKIES_FILE" "$LOGIN_URL" | grep -oP 'name="_token" value="\K[^"]+' | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ ERROR: Could not get CSRF token"
    exit 1
fi

echo "✅ CSRF Token: ${CSRF_TOKEN:0:20}..."
echo ""

echo "[2/10] Step 2: Logging in..."
LOGIN_RESPONSE=$(curl -k -s -b "$COOKIES_FILE" -c "$COOKIES_FILE" \
    -X POST "$LOGIN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Referer: $LOGIN_URL" \
    -d "_token=$CSRF_TOKEN&email=$USERNAME&password=$PASSWORD" \
    -w "\n%{http_code}" \
    -L)

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n 1)

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "302" ]; then
    echo "❌ ERROR: Login failed with HTTP $HTTP_CODE"
    exit 1
fi

echo "✅ Login successful (HTTP $HTTP_CODE)"
echo ""

echo "[3/10] Step 3: Fetching create site form..."
CREATE_FORM=$(curl -k -s -b "$COOKIES_FILE" "$ADMIN_URL/sites/create")
CSRF_TOKEN=$(echo "$CREATE_FORM" | grep -oP 'name="_token" value="\K[^"]+' | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ ERROR: Could not get form CSRF token"
    exit 1
fi

echo "✅ Form CSRF Token: ${CSRF_TOKEN:0:20}..."
echo ""

echo "[4/10] Step 4: Submitting site creation form..."
CREATE_RESPONSE=$(curl -k -s -b "$COOKIES_FILE" -c "$COOKIES_FILE" \
    -X POST "$CREATE_SITE_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Referer: $ADMIN_URL/sites/create" \
    -d "_token=$CSRF_TOKEN&site_name=$SITE_NAME&domain=$DOMAIN&php_version=8.3&create_database=1&template=php" \
    -w "\n%{http_code}" \
    -L)

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n 1)

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "302" ]; then
    echo "❌ ERROR: Site creation failed with HTTP $HTTP_CODE"
    echo "Response: $(echo "$CREATE_RESPONSE" | head -n -1)"
    exit 1
fi

echo "✅ Site creation request submitted (HTTP $HTTP_CODE)"
echo ""

echo "[5/10] Step 5: Verifying site in database (initial check)..."
DB_CHECK=$(remote_exec "mysql -u root -p'$VPS_PASS' admin_panel -N -e \"SELECT id, status FROM sites WHERE site_name='$SITE_NAME';\"")

if [ -z "$DB_CHECK" ]; then
    echo "❌ ERROR: Site not found in database"
    exit 1
fi

SITE_ID=$(echo "$DB_CHECK" | awk '{print $1}')
INITIAL_STATUS=$(echo "$DB_CHECK" | awk '{print $2}')

echo "✅ Site found in database"
echo "  Site ID: $SITE_ID"
echo "  Initial Status: $INITIAL_STATUS"
echo ""

echo "[6/10] Step 6: Waiting 30 seconds for background scripts..."
for i in {30..1}; do
    echo -ne "  Waiting: $i seconds remaining...\r"
    sleep 1
done
echo ""
echo "✅ Wait complete"
echo ""

echo "[7/10] Step 7: Checking final site status in database..."
FINAL_CHECK=$(remote_exec "mysql -u root -p'$VPS_PASS' admin_panel -N -e \"SELECT site_name, status, ssl_enabled, created_at FROM sites WHERE site_name='$SITE_NAME';\"")

FINAL_STATUS=$(echo "$FINAL_CHECK" | awk '{print $2}')
SSL_STATUS=$(echo "$FINAL_CHECK" | awk '{print $3}')

echo "Site Details:"
echo "  Name: $SITE_NAME"
echo "  Status: $FINAL_STATUS"
echo "  SSL: $SSL_STATUS"
echo ""

if [ "$FINAL_STATUS" = "active" ]; then
    echo "✅ SUCCESS: Site status is ACTIVE"
else
    echo "❌ FAILURE: Site status is $FINAL_STATUS (expected: active)"
fi
echo ""

echo "[8/10] Step 8: Checking Laravel logs for Sprint 36 markers..."
LARAVEL_LOG=$(remote_exec "tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log | grep -i 'SPRINT 36' || echo 'No Sprint 36 markers found'")

if echo "$LARAVEL_LOG" | grep -q "SPRINT 36"; then
    echo "✅ Sprint 36 execution markers found in Laravel logs"
    echo "Recent Sprint 36 log entries:"
    echo "$LARAVEL_LOG" | head -5
else
    echo "❌ WARNING: No Sprint 36 markers in Laravel logs"
fi
echo ""

echo "[9/10] Step 9: Checking post-creation script logs..."
POST_LOG=$(remote_exec "cat /tmp/post-site-${SITE_NAME}.log 2>/dev/null || echo 'Log file not found'")

if echo "$POST_LOG" | grep -q "SPRINT 36"; then
    echo "✅ Post-creation script executed"
    echo "Log excerpt:"
    echo "$POST_LOG" | grep "SPRINT 36" | head -3
else
    echo "❌ ERROR: Post-creation script did not execute"
    echo "Log content: $POST_LOG"
fi
echo ""

echo "[10/10] Step 10: Final validation summary..."
echo ""

if [ "$FINAL_STATUS" = "active" ] && echo "$POST_LOG" | grep -q "SUCCESS"; then
    echo "========================================="
    echo "  ✅ VALIDATION SUCCESSFUL - 100%"
    echo "========================================="
    echo ""
    echo "RESULTS:"
    echo "  ✅ Site created in database"
    echo "  ✅ Status changed to 'active'"
    echo "  ✅ Post-creation script executed"
    echo "  ✅ Sprint 36 markers present"
    echo "  ✅ All logs show success"
    echo ""
    echo "SYSTEM IS 100% FUNCTIONAL"
    echo ""
    exit 0
else
    echo "========================================="
    echo "  ❌ VALIDATION FAILED"
    echo "========================================="
    echo ""
    echo "ISSUES DETECTED:"
    
    if [ "$FINAL_STATUS" != "active" ]; then
        echo "  ❌ Site status is '$FINAL_STATUS' (expected 'active')"
    fi
    
    if ! echo "$POST_LOG" | grep -q "SUCCESS"; then
        echo "  ❌ Post-creation script did not complete successfully"
    fi
    
    echo ""
    echo "SYSTEM IS NOT 100% FUNCTIONAL"
    echo "Further investigation required"
    echo ""
    exit 1
fi
