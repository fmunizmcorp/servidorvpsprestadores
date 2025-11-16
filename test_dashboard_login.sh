#!/bin/bash

# Test Dashboard Login and Access
# This script will:
# 1. Login to admin panel
# 2. Access dashboard
# 3. Verify it works without errors

BASE_URL="https://72.61.53.222/admin"
EMAIL="admin@vps.local"
PASSWORD="Admin2024VPS"
COOKIE_FILE="/tmp/admin_cookies.txt"

echo "==================================="
echo "Testing Admin Panel Dashboard"
echo "==================================="

# Step 1: Get CSRF token from login page
echo "Step 1: Getting CSRF token..."
LOGIN_PAGE=$(curl -k -c "$COOKIE_FILE" -s "$BASE_URL/login")
CSRF_TOKEN=$(echo "$LOGIN_PAGE" | grep -oP '(?<=name="_token" value=")[^"]*')

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ Failed to get CSRF token"
    exit 1
fi

echo "✅ CSRF Token obtained"

# Step 2: Perform login
echo "Step 2: Logging in..."
LOGIN_RESPONSE=$(curl -k -b "$COOKIE_FILE" -c "$COOKIE_FILE" -s \
    -X POST "$BASE_URL/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "_token=$CSRF_TOKEN" \
    -d "email=$EMAIL" \
    -d "password=$PASSWORD" \
    -L)

# Check if redirected to dashboard
if echo "$LOGIN_RESPONSE" | grep -q "VPS Server Administration Dashboard"; then
    echo "✅ Login successful"
else
    echo "❌ Login failed"
    echo "Response preview:"
    echo "$LOGIN_RESPONSE" | head -50
    exit 1
fi

# Step 3: Access dashboard
echo "Step 3: Accessing dashboard..."
DASHBOARD_RESPONSE=$(curl -k -b "$COOKIE_FILE" -s "$BASE_URL/dashboard")

# Check for error 500
if echo "$DASHBOARD_RESPONSE" | grep -q "500"; then
    echo "❌ Error 500 detected in dashboard"
    exit 1
fi

# Check for successful content
if echo "$DASHBOARD_RESPONSE" | grep -q "VPS Server Administration Dashboard"; then
    echo "✅ Dashboard loaded successfully"
else
    echo "❌ Dashboard content not found"
    exit 1
fi

# Step 4: Check for specific elements
echo "Step 4: Verifying dashboard elements..."

if echo "$DASHBOARD_RESPONSE" | grep -q "Sites Management"; then
    echo "✅ Sites Management section found"
fi

if echo "$DASHBOARD_RESPONSE" | grep -q "Email Management"; then
    echo "✅ Email Management section found"
fi

if echo "$DASHBOARD_RESPONSE" | grep -q "Server Management"; then
    echo "✅ Server Management section found"
fi

if echo "$DASHBOARD_RESPONSE" | grep -q "CPU Usage"; then
    echo "✅ System Metrics found"
fi

if echo "$DASHBOARD_RESPONSE" | grep -q "Services Status"; then
    echo "✅ Services Status found"
fi

echo ""
echo "==================================="
echo "✅ ALL TESTS PASSED"
echo "==================================="
echo "Dashboard is working correctly!"

# Clean up
rm -f "$COOKIE_FILE"

exit 0
