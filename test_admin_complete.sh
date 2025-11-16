#!/bin/bash

# Comprehensive Laravel Admin Panel Testing Script
# Tests all admin menus with proper session authentication

VPS_IP="72.61.53.222"
VPS_PASS="Jm@D@KDPnw7Q"
BASE_URL="https://${VPS_IP}"
ADMIN_PATH="/admin"
COOKIE_FILE="/tmp/admin_test_cookies.txt"

echo "=========================================="
echo "Laravel Admin Panel - Comprehensive Test"
echo "=========================================="
echo ""
echo "Testing URL: ${BASE_URL}${ADMIN_PATH}"
echo ""

# Clean up old cookies
rm -f "$COOKIE_FILE"

# Function to run command on VPS
run_vps() {
    sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no root@"$VPS_IP" "$1"
}

# Step 1: Clear Laravel logs for fresh testing
echo "Step 1: Clearing Laravel logs on VPS"
echo "----------------------------------------"
run_vps "echo '' > /opt/webserver/admin-panel/storage/logs/laravel.log"
echo "✅ Logs cleared"
echo ""

# Step 2: Get CSRF token from login page
echo "Step 2: Getting CSRF token from login page"
echo "----------------------------------------"
LOGIN_PAGE=$(curl -k -c "$COOKIE_FILE" -s "${BASE_URL}${ADMIN_PATH}/login")
CSRF_TOKEN=$(echo "$LOGIN_PAGE" | grep -oP 'name="_token"\s+value="\K[^"]+' | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ Failed to get CSRF token"
    echo "Login page response (first 500 chars):"
    echo "$LOGIN_PAGE" | head -c 500
    exit 1
fi

echo "✅ CSRF Token obtained: ${CSRF_TOKEN:0:30}..."
echo ""

# Step 3: Perform login
echo "Step 3: Performing login"
echo "----------------------------------------"
LOGIN_RESULT=$(curl -k \
    -b "$COOKIE_FILE" \
    -c "$COOKIE_FILE" \
    -X POST \
    -s \
    -w "\nHTTP_CODE:%{http_code}\nREDIRECT:%{redirect_url}" \
    -d "_token=${CSRF_TOKEN}" \
    -d "email=admin@vps.local" \
    -d "password=Admin2024VPS" \
    "${BASE_URL}${ADMIN_PATH}/login")

HTTP_CODE=$(echo "$LOGIN_RESULT" | grep "HTTP_CODE:" | cut -d: -f2)
REDIRECT=$(echo "$LOGIN_RESULT" | grep "REDIRECT:" | cut -d: -f2-)

echo "HTTP Code: $HTTP_CODE"
if [ -n "$REDIRECT" ]; then
    echo "Redirect to: $REDIRECT"
fi

if [ "$HTTP_CODE" != "302" ] && [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Login failed"
    echo "Response (first 1000 chars):"
    echo "$LOGIN_RESULT" | head -c 1000
    exit 1
fi

echo "✅ Login successful (HTTP $HTTP_CODE)"
echo ""

# Step 4: Test all admin menu endpoints
echo "Step 4: Testing all admin menu endpoints"
echo "=========================================="
echo ""

# Function to test a menu endpoint
test_menu() {
    local menu_name="$1"
    local menu_path="$2"
    local full_url="${BASE_URL}${ADMIN_PATH}${menu_path}"
    
    echo "Testing: $menu_name"
    echo "URL: $full_url"
    
    RESPONSE=$(curl -k \
        -b "$COOKIE_FILE" \
        -s \
        -w "\nHTTP_CODE:%{http_code}" \
        -L \
        "$full_url")
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ $menu_name - HTTP 200 OK"
    elif [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
        echo "⚠️  $menu_name - Redirect ($HTTP_CODE)"
    elif [ "$HTTP_CODE" = "500" ]; then
        echo "❌ $menu_name - ERROR 500!"
        echo ""
        echo "Checking Laravel logs on VPS..."
        run_vps "tail -30 /opt/webserver/admin-panel/storage/logs/laravel.log"
        echo ""
    else
        echo "⚠️  $menu_name - HTTP $HTTP_CODE"
    fi
    
    echo ""
    sleep 1
}

# Test each menu
test_menu "Dashboard" "/dashboard"
test_menu "Sites Management" "/sites"
test_menu "Sites Create" "/sites/create"
test_menu "Email Management" "/email"
test_menu "Email Accounts" "/email/accounts"
test_menu "Email Domains" "/email/domains"
test_menu "Email Queue" "/email/queue"
test_menu "Email Logs" "/email/logs"
test_menu "Email DNS" "/email/dns"
test_menu "Monitoring" "/monitoring"
test_menu "Monitoring Services" "/monitoring/services"
test_menu "Monitoring Processes" "/monitoring/processes"
test_menu "Monitoring Logs" "/monitoring/logs"
test_menu "Security" "/security"
test_menu "Security Firewall" "/security/firewall"
test_menu "Security Fail2Ban" "/security/fail2ban"
test_menu "Security ClamAV" "/security/clamav"
test_menu "Backups" "/backups"
test_menu "Backups List" "/backups/list"
test_menu "Backups Logs" "/backups/logs"
test_menu "Backups Details" "/backups/details"

echo "=========================================="
echo "Testing Complete"
echo "=========================================="
echo ""

# Step 5: Check Laravel logs for any errors
echo "Step 5: Checking Laravel logs for errors"
echo "----------------------------------------"
echo "Last 50 lines of Laravel log:"
echo ""
run_vps "tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log"
echo ""

# Step 6: Check NGINX error logs
echo "Step 6: Checking NGINX error logs"
echo "----------------------------------------"
echo "Last 20 lines of NGINX error log:"
echo ""
run_vps "tail -20 /var/log/nginx/prestadores-error.log"
echo ""

# Step 7: Check PHP-FPM error logs
echo "Step 7: Checking PHP-FPM error logs"
echo "----------------------------------------"
echo "Last 20 lines of PHP-FPM error log (admin-panel pool):"
echo ""
run_vps "tail -20 /var/log/php8.3-fpm-admin-panel.log 2>/dev/null || echo 'Log file not found or empty'"
echo ""

# Clean up
rm -f "$COOKIE_FILE"

echo "=========================================="
echo "✅ TESTING SESSION COMPLETE"
echo "=========================================="
