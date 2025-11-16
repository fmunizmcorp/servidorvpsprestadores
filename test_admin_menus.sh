#!/bin/bash

# Test script for comprehensive admin panel menu testing
# Tests all menus with proper authentication session

BASE_URL="https://72.61.53.222"
ADMIN_PATH="/admin"
COOKIE_FILE="/tmp/admin_cookies.txt"
LOG_FILE="/opt/webserver/admin-panel/storage/logs/laravel.log"

echo "=========================================="
echo "Laravel Admin Panel - Comprehensive Testing"
echo "=========================================="
echo ""

# Clean up old cookies
rm -f "$COOKIE_FILE"

echo "Step 1: Get CSRF token from login page"
echo "----------------------------------------"
CSRF_TOKEN=$(curl -k -c "$COOKIE_FILE" -s "$BASE_URL$ADMIN_PATH/login" | grep -oP '(?<=name="_token" value=")[^"]+' | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ Failed to get CSRF token"
    exit 1
fi

echo "✅ CSRF Token obtained: ${CSRF_TOKEN:0:20}..."
echo ""

echo "Step 2: Perform login"
echo "----------------------------------------"
LOGIN_RESPONSE=$(curl -k -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
    -X POST \
    -s \
    -w "\nHTTP_CODE:%{http_code}" \
    -d "_token=$CSRF_TOKEN" \
    -d "email=admin@vps.local" \
    -d "password=Admin2024VPS" \
    -L \
    "$BASE_URL$ADMIN_PATH/login")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
echo "Login HTTP Code: $HTTP_CODE"

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Login failed with code: $HTTP_CODE"
    echo "$LOGIN_RESPONSE"
    exit 1
fi

echo "✅ Login successful"
echo ""

# Function to test a menu endpoint
test_menu() {
    local menu_name="$1"
    local menu_path="$2"
    
    echo "Testing: $menu_name"
    echo "URL: $BASE_URL$ADMIN_PATH$menu_path"
    
    RESPONSE=$(curl -k -b "$COOKIE_FILE" \
        -s \
        -w "\nHTTP_CODE:%{http_code}\nREDIRECT_URL:%{redirect_url}" \
        -L \
        "$BASE_URL$ADMIN_PATH$menu_path")
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
    REDIRECT_URL=$(echo "$RESPONSE" | grep "REDIRECT_URL:" | cut -d: -f2-)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ $menu_name - HTTP 200 OK"
    elif [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
        echo "⚠️  $menu_name - Redirect ($HTTP_CODE) to: $REDIRECT_URL"
    elif [ "$HTTP_CODE" = "500" ]; then
        echo "❌ $menu_name - ERROR 500!"
        echo "Last 20 lines of Laravel log:"
        tail -20 "$LOG_FILE"
    else
        echo "⚠️  $menu_name - HTTP $HTTP_CODE"
    fi
    
    echo ""
}

echo "Step 3: Testing all admin menus"
echo "=========================================="
echo ""

# Test each menu
test_menu "Dashboard" "/dashboard"
test_menu "Sites Management" "/sites"
test_menu "Email Management" "/email"
test_menu "Monitoring" "/monitoring"
test_menu "Security" "/security"
test_menu "Backups" "/backups"

echo "=========================================="
echo "Testing Complete"
echo "=========================================="
echo ""

# Check for any errors in the log
echo "Checking Laravel logs for errors..."
if grep -q "ERROR" "$LOG_FILE" 2>/dev/null; then
    echo "⚠️  Errors found in Laravel log:"
    grep "ERROR" "$LOG_FILE" | tail -10
else
    echo "✅ No errors found in Laravel log"
fi

# Clean up
rm -f "$COOKIE_FILE"

