#!/bin/bash

echo "=== Testing Real Login with correct credentials ==="
echo ""

# Get login page
curl -k -s -c cookies_real.txt https://72.61.53.222/admin/login > login_real.html

CSRF=$(grep -oP '(?<=name="_token" value=")[^"]+' login_real.html | head -1)

# Try the credentials from Sprint 18 report: admin@example.com / admin123
echo "Attempting login with admin@example.com..."
curl -k -s -L -b cookies_real.txt -c cookies_real.txt \
  -X POST https://72.61.53.222/admin/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=$CSRF&email=admin@example.com&password=admin123" \
  -D headers_admin.txt \
  -o response_admin.html

HTTP_CODE=$(grep "HTTP/" headers_admin.txt | tail -1 | awk '{print $2}')
LOCATION=$(grep -i "^location:" headers_admin.txt | tail -1 | tr -d '\r' | awk '{print $2}')

echo "HTTP Status: $HTTP_CODE"
echo "Redirect: $LOCATION"

if [[ "$LOCATION" == *"/admin/dashboard"* ]]; then
    echo "✓ Login SUCCESSFUL! Redirected to dashboard"
    echo ""
    echo "Now testing protected routes..."
    
    # Test 1: Email accounts
    echo ""
    echo "[TEST 1] /admin/email/accounts..."
    curl -k -s -b cookies_real.txt \
      https://72.61.53.222/admin/email/accounts \
      -D headers_email.txt -o response_email.html
    
    EMAIL_CODE=$(grep "HTTP/" headers_email.txt | tail -1 | awk '{print $2}')
    echo "HTTP Status: $EMAIL_CODE"
    
    if [ "$EMAIL_CODE" = "200" ]; then
        # Check for the array error
        if grep -q "htmlspecialchars(): Argument #1" response_email.html; then
            echo "✗ Array-to-string error still present"
        else
            echo "✓ Email accounts page working!"
        fi
    elif [ "$EMAIL_CODE" = "500" ]; then
        echo "✗ HTTP 500 error (check logs)"
    else
        echo "Unexpected status: $EMAIL_CODE"
    fi
    
else
    echo "⚠ Login failed or redirected elsewhere"
fi

