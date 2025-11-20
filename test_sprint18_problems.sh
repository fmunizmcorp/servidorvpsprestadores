#!/bin/bash

echo "=========================================="
echo "TESTING SPRINT 18 PROBLEMS"
echo "=========================================="
echo ""

rm -f cookies_*.txt headers_*.txt response_*.html

# Login first
echo "[SETUP] Logging in..."
curl -k -s -c cookies_auth.txt https://72.61.53.222/admin/login > login.html
CSRF=$(grep -oP '(?<=<input type="hidden" name="_token" value=")[^"]+' login.html | head -1)

curl -k -s -b cookies_auth.txt -c cookies_auth.txt \
  -X POST https://72.61.53.222/admin/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=${CSRF}&email=admin@example.com&password=admin123" \
  -o /dev/null

echo "✓ Logged in"
echo ""

# PROBLEM 1: HTTP 500 on /admin/email/accounts
echo "=========================================="
echo "PROBLEM 1: Email Accounts Page (HTTP 500)"
echo "=========================================="
curl -k -s -b cookies_auth.txt \
  https://72.61.53.222/admin/email/accounts \
  -D headers_problem1.txt \
  -o response_problem1.html

HTTP_CODE=$(grep "HTTP/" headers_problem1.txt | tail -1 | awk '{print $2}')
echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    if grep -q "htmlspecialchars(): Argument #1" response_problem1.html; then
        echo "✗ FAILED - Array-to-string error still present"
        grep -A5 "htmlspecialchars" response_problem1.html | head -10
    elif grep -q "Email Accounts" response_problem1.html; then
        echo "✓ FIXED - Page loads successfully"
    else
        echo "⚠ Page loads but content unexpected"
    fi
elif [ "$HTTP_CODE" = "500" ]; then
    echo "✗ FAILED - HTTP 500 error"
    grep -o "<title>[^<]*</title>" response_problem1.html
else
    echo "Unexpected status: $HTTP_CODE"
fi

echo ""

# PROBLEM 2: Create Site form doesn't save
echo "=========================================="
echo "PROBLEM 2: Create Site Form"
echo "=========================================="

# Get create site page
curl -k -s -b cookies_auth.txt \
  https://72.61.53.222/admin/sites/create \
  -o create_site_page.html

CSRF2=$(grep -oP '(?<=<input type="hidden" name="_token" value=")[^"]+' create_site_page.html | head -1)

if [ -z "$CSRF2" ]; then
    echo "✗ Could not access create site page"
else
    # Submit form
    curl -k -s -b cookies_auth.txt \
      -X POST https://72.61.53.222/admin/sites \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "_token=${CSRF2}&domain=test-site-$(date +%s).example.com&user=testuser&password=testpass123" \
      -D headers_problem2.txt \
      -o response_problem2.html
    
    HTTP_CODE2=$(grep "HTTP/" headers_problem2.txt | tail -1 | awk '{print $2}')
    LOCATION2=$(grep -i "^location:" headers_problem2.txt | tail -1 | tr -d '\r\n' | awk '{print $2}')
    
    echo "HTTP Status: $HTTP_CODE2"
    echo "Redirect: $LOCATION2"
    
    if [ "$HTTP_CODE2" = "302" ]; then
        if [[ "$LOCATION2" == *"?%2Fsites%2Fcreate="* ]]; then
            echo "✗ FAILED - Redirects to malformed URL with ?%2Fsites%2Fcreate="
        elif [[ "$LOCATION2" == *"/sites"* ]] && [[ "$LOCATION2" != *"create"* ]]; then
            echo "✓ FIXED - Redirects to sites list"
        else
            echo "⚠ Redirects to: $LOCATION2"
        fi
    else
        echo "Unexpected status: $HTTP_CODE2"
    fi
fi

echo ""

# PROBLEM 3: Create Email Domain form redirect issue
echo "=========================================="
echo "PROBLEM 3: Create Email Domain Form"
echo "=========================================="

# Get create domain page
curl -k -s -b cookies_auth.txt \
  https://72.61.53.222/admin/email/domains/create \
  -o create_domain_page.html

CSRF3=$(grep -oP '(?<=<input type="hidden" name="_token" value=")[^"]+' create_domain_page.html | head -1)

if [ -z "$CSRF3" ]; then
    echo "✗ Could not access create domain page"
else
    # Submit form
    curl -k -s -b cookies_auth.txt \
      -X POST https://72.61.53.222/admin/email/domains \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "_token=${CSRF3}&domain=test-$(date +%s).example.com" \
      -D headers_problem3.txt \
      -o response_problem3.html
    
    HTTP_CODE3=$(grep "HTTP/" headers_problem3.txt | tail -1 | awk '{print $2}')
    LOCATION3=$(grep -i "^location:" headers_problem3.txt | tail -1 | tr -d '\r\n' | awk '{print $2}')
    
    echo "HTTP Status: $HTTP_CODE3"
    echo "Redirect: $LOCATION3"
    
    if [ "$HTTP_CODE3" = "302" ]; then
        if [[ "$LOCATION3" == *"?%2Femail%2Fdomains="* ]]; then
            echo "✗ FAILED - Redirects to malformed URL with ?%2Femail%2Fdomains="
        elif [[ "$LOCATION3" == *"/email/domains"* ]] && [[ "$LOCATION3" != *"create"* ]]; then
            echo "✓ FIXED - Redirects to domains list"
        else
            echo "⚠ Redirects to: $LOCATION3"
        fi
    else
        echo "Unexpected status: $HTTP_CODE3"
    fi
fi

echo ""
echo "=========================================="
echo "FINAL SUMMARY"
echo "=========================================="
echo ""

