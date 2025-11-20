#!/bin/bash

echo "[TEST 2] Testing POST /admin/login..."
echo ""

# Get login page and extract CSRF token
curl -k -s -c cookies_test.txt https://72.61.53.222/admin/login > login_page.html

CSRF_TOKEN=$(grep -oP '(?<=name="_token" value=")[^"]+' login_page.html | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    echo "✗ Could not extract CSRF token"
    exit 1
fi

echo "CSRF Token found: ${CSRF_TOKEN:0:20}..."

# Attempt login
echo "Attempting POST login..."
curl -k -s -b cookies_test.txt -c cookies_test.txt \
  -X POST https://72.61.53.222/admin/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Referer: https://72.61.53.222/admin/login" \
  -d "_token=$CSRF_TOKEN&email=test@admin.local&password=senha123&remember=on" \
  -D response_headers.txt \
  -o response_body.html

echo ""
echo "Response headers:"
cat response_headers.txt | head -15

HTTP_STATUS=$(grep "HTTP/" response_headers.txt | tail -1 | awk '{print $2}')

echo ""
if [ "$HTTP_STATUS" = "302" ]; then
    LOCATION=$(grep -i "^Location:" response_headers.txt | tr -d '\r' | awk '{print $2}')
    echo "✓ POST accepted (HTTP $HTTP_STATUS)"
    echo "Redirect to: $LOCATION"
elif [ "$HTTP_STATUS" = "405" ]; then
    echo "✗ HTTP 405 Method Not Allowed - POST still not working"
elif [ "$HTTP_STATUS" = "200" ]; then
    echo "⚠ HTTP 200 - Check if login failed or other issue"
    grep -i "error\|invalid\|incorrect" response_body.html | head -5
else
    echo "Unexpected status: HTTP $HTTP_STATUS"
fi

