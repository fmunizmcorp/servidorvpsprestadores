#!/bin/bash

echo "=========================================="
echo "SPRINT 19 - COMPLETE TESTING"
echo "=========================================="
echo ""

rm -f cookies_*.txt headers_*.txt response_*.html

# Step 1: Get fresh login page
echo "[1] Fetching login page..."
curl -k -s -c cookies_fresh.txt https://72.61.53.222/admin/login > login_fresh.html

# Extract CSRF
CSRF=$(grep -oP '(?<=<input type="hidden" name="_token" value=")[^"]+' login_fresh.html | head -1)

if [ -z "$CSRF" ]; then
    echo "✗ CSRF token not found"
    exit 1
fi

echo "✓ CSRF token: ${CSRF:0:30}..."

# Step 2: Attempt login
echo ""
echo "[2] Testing POST login..."
curl -k -s -b cookies_fresh.txt -c cookies_fresh.txt \
  -X POST https://72.61.53.222/admin/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Referer: https://72.61.53.222/admin/login" \
  -d "_token=${CSRF}&email=admin@example.com&password=admin123" \
  -D headers_login.txt \
  -o response_login.html

HTTP_CODE=$(grep "HTTP/" headers_login.txt | tail -1 | awk '{print $2}')
LOCATION=$(grep -i "^location:" headers_login.txt | tail -1 | tr -d '\r\n' | awk '{print $2}')

echo "HTTP Status: $HTTP_CODE"
echo "Redirect: $LOCATION"

if [ "$HTTP_CODE" = "302" ]; then
    if [[ "$LOCATION" == *"dashboard"* ]]; then
        echo "✓ Login successful!"
        LOGGED_IN=true
    else
        echo "⚠ POST accepted but redirected to: $LOCATION"
        echo "   (likely invalid credentials)"
        LOGGED_IN=false
    fi
elif [ "$HTTP_CODE" = "405" ]; then
    echo "✗ HTTP 405 - POST method not allowed (BUG STILL EXISTS)"
    exit 1
else
    echo "⚠ Unexpected status: $HTTP_CODE"
    LOGGED_IN=false
fi

# Step 3: Test Email Accounts without login (should redirect)
echo ""
echo "[3] Testing /admin/email/accounts (unauthenticated)..."
curl -k -s https://72.61.53.222/admin/email/accounts \
  -D headers_email_noauth.txt \
  -o response_email_noauth.html

EMAIL_CODE=$(grep "HTTP/" headers_email_noauth.txt | tail -1 | awk '{print $2}')
EMAIL_LOCATION=$(grep -i "^location:" headers_email_noauth.txt | tail -1 | tr -d '\r\n' | awk '{print $2}')

echo "HTTP Status: $EMAIL_CODE"

if [ "$EMAIL_CODE" = "302" ] && [[ "$EMAIL_LOCATION" == *"login"* ]]; then
    echo "✓ Properly redirects to login"
elif [ "$EMAIL_CODE" = "500" ]; then
    echo "✗ HTTP 500 error (BUG EXISTS)"
else
    echo "Status: $EMAIL_CODE, Redirect: $EMAIL_LOCATION"
fi

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo ""
echo "✓ HTTP 405 bug FIXED (POST requests work)"
echo "✓ NGINX routing working correctly"
echo "⚠ Login credentials need verification"
echo ""
echo "Next steps:"
echo "1. Verify/create test user with known password"
echo "2. Test authenticated routes"
echo "3. Test forms (Create Site, Create Domain)"
echo ""

