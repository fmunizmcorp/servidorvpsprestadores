#!/bin/bash

echo "=========================================="
echo "TESTING FORMS WITH CORRECT FIELDS"
echo "=========================================="
echo ""

# Login
curl -k -s -c cookies_form.txt https://72.61.53.222/admin/login > login.html
CSRF=$(grep -oP '(?<=<input type="hidden" name="_token" value=")[^"]+' login.html | head -1)
curl -k -s -b cookies_form.txt -c cookies_form.txt \
  -X POST https://72.61.53.222/admin/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=${CSRF}&email=admin@example.com&password=admin123" \
  -o /dev/null
echo "✓ Logged in"
echo ""

# PROBLEM 2: Create Site Form (CORRECTED)
echo "=========================================="
echo "PROBLEM 2: Create Site Form (Corrected)"
echo "=========================================="

curl -k -s -b cookies_form.txt https://72.61.53.222/admin/sites/create -o create_site.html
CSRF2=$(grep -oP '(?<=<input type="hidden" name="_token" value=")[^"]+' create_site.html | head -1)

TIMESTAMP=$(date +%s)
curl -k -s -b cookies_form.txt \
  -X POST https://72.61.53.222/admin/sites \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=${CSRF2}&site_name=testsite${TIMESTAMP}&domain=testsite${TIMESTAMP}.local&php_version=8.3" \
  -D headers_site.txt \
  -o response_site.html

HTTP_CODE=$(grep "HTTP/" headers_site.txt | tail -1 | awk '{print $2}')
LOCATION=$(grep -i "^location:" headers_site.txt | tail -1 | tr -d '\r\n' | awk '{print $2}')

echo "HTTP Status: $HTTP_CODE"
echo "Redirect: $LOCATION"

if [ "$HTTP_CODE" = "302" ]; then
    if [[ "$LOCATION" == *"?%2Fsites%2Fcreate="* ]]; then
        echo "✗ FAILED - Malformed redirect URL"
    elif [[ "$LOCATION" == *"/admin/sites"* ]] && [[ "$LOCATION" != *"create"* ]]; then
        echo "✓ FIXED - Redirects to sites list"
    elif [[ "$LOCATION" == *"create"* ]]; then
        echo "⚠ Redirects back to create (validation error)"
        grep -o "error.*</div>" response_site.html | head -5
    else
        echo "⚠ Unexpected redirect: $LOCATION"
    fi
fi

echo ""

# PROBLEM 3: Email Domains (Check if domains page has a form)
echo "=========================================="
echo "PROBLEM 3: Email Domains Form"
echo "=========================================="

curl -k -s -b cookies_form.txt https://72.61.53.222/admin/email/domains -o domains_page.html

if grep -q "Add Domain\|Create Domain\|New Domain" domains_page.html; then
    echo "✓ Domains page loads"
    
    # Try to submit
    CSRF3=$(grep -oP '(?<=<input type="hidden" name="_token" value=")[^"]+' domains_page.html | head -1)
    
    if [ -n "$CSRF3" ]; then
        curl -k -s -b cookies_form.txt \
          -X POST https://72.61.53.222/admin/email/domains \
          -H "Content-Type: application/x-www-form-urlencoded" \
          -d "_token=${CSRF3}&domain=test${TIMESTAMP}.example.com" \
          -D headers_domain.txt \
          -o response_domain.html
        
        HTTP_CODE3=$(grep "HTTP/" headers_domain.txt | tail -1 | awk '{print $2}')
        LOCATION3=$(grep -i "^location:" headers_domain.txt | tail -1 | tr -d '\r\n' | awk '{print $2}')
        
        echo "HTTP Status: $HTTP_CODE3"
        echo "Redirect: $LOCATION3"
        
        if [ "$HTTP_CODE3" = "302" ]; then
            if [[ "$LOCATION3" == *"?%2Femail%2Fdomains="* ]]; then
                echo "✗ FAILED - Malformed redirect URL"
            elif [[ "$LOCATION3" == *"/email/domains"* ]]; then
                echo "✓ FIXED - Redirects to domains list"
            else
                echo "⚠ Unexpected redirect"
            fi
        fi
    fi
else
    echo "⚠ Domains page structure different than expected"
fi

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo ""

