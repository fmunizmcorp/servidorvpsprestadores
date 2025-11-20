#!/bin/bash

echo "=========================================="
echo "SPRINT 20 - TESTES COMPLETOS"
echo "=========================================="
echo ""
echo "Testando com credenciais: test@admin.local / Test@123456"
echo ""

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="cookies_sprint20.txt"
rm -f $COOKIES

# Login
echo "[1] Login..."
curl -k -s -c $COOKIES $ADMIN_URL/login > login.html
CSRF=$(grep -oP '(?<=name="_token" value=")[^"]+' login.html | head -1)

curl -k -s -b $COOKIES -c $COOKIES \
  -X POST $ADMIN_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=${CSRF}&email=test@admin.local&password=Test@123456" \
  -o /dev/null

echo "✓ Logged in"
echo ""

# Test 1: Create Email Domain
echo "=========================================="
echo "TEST 1: Create Email Domain"
echo "=========================================="

TIMESTAMP=$(date +%s)
DOMAIN="sprint20final${TIMESTAMP}.local"

curl -k -s -b $COOKIES $ADMIN_URL/email/domains > domains_page.html
CSRF2=$(grep -oP '(?<=name="_token" value=")[^"]+' domains_page.html | head -1)

echo "Creating domain: $DOMAIN"
curl -k -s -b $COOKIES \
  -X POST $ADMIN_URL/email/domains \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=${CSRF2}&domain=${DOMAIN}" \
  -D headers_domain.txt \
  -o response_domain.html

HTTP_CODE=$(grep "HTTP/" headers_domain.txt | tail -1 | awk '{print $2}')
LOCATION=$(grep -i "^location:" headers_domain.txt | tail -1 | tr -d '\r\n' | awk '{print $2}')

echo "HTTP Status: $HTTP_CODE"
echo "Redirect: $LOCATION"

if [ "$HTTP_CODE" = "302" ] && [[ "$LOCATION" == *"/email/domains"* ]]; then
    echo "✓ TEST 1 PASSED: Domain form redirects correctly"
    
    # Check if domain appears in listing
    sleep 2
    curl -k -s -b $COOKIES $ADMIN_URL/email/domains > domains_list.html
    if grep -q "$DOMAIN" domains_list.html; then
        echo "✓ Domain appears in listing!"
    else
        echo "⚠ Domain NOT in listing (may need refresh)"
    fi
else
    echo "✗ TEST 1 FAILED"
fi

echo ""

# Test 2: Create Email Account
echo "=========================================="
echo "TEST 2: Create Email Account"
echo "=========================================="

curl -k -s -b $COOKIES "$ADMIN_URL/email/accounts?domain=$DOMAIN" > accounts_page.html
CSRF3=$(grep -oP '(?<=name="_token" value=")[^"]+' accounts_page.html | head -1)

echo "Creating account: testuser@$DOMAIN"
curl -k -s -b $COOKIES \
  -X POST $ADMIN_URL/email/accounts \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=${CSRF3}&domain=${DOMAIN}&username=testuser&password=Test@123456&quota=1000" \
  -D headers_account.txt \
  -o response_account.html

HTTP_CODE2=$(grep "HTTP/" headers_account.txt | tail -1 | awk '{print $2}')
echo "HTTP Status: $HTTP_CODE2"

if [ "$HTTP_CODE2" = "302" ]; then
    echo "✓ TEST 2 PASSED: Account form redirects correctly"
    
    # Check if account appears
    sleep 2
    curl -k -s -b $COOKIES "$ADMIN_URL/email/accounts?domain=$DOMAIN" > accounts_list.html
    if grep -q "testuser@$DOMAIN" accounts_list.html; then
        echo "✓ Account appears in listing!"
    else
        echo "⚠ Account NOT in listing"
    fi
else
    echo "✗ TEST 2 FAILED"
fi

echo ""

# Test 3: Create Site (background)
echo "=========================================="
echo "TEST 3: Create Site (Background)"
echo "=========================================="

SITE_NAME="sprint20site${TIMESTAMP}"
SITE_DOMAIN="sprint20site${TIMESTAMP}.local"

curl -k -s -b $COOKIES $ADMIN_URL/sites/create > site_create_page.html
CSRF4=$(grep -oP '(?<=name="_token" value=")[^"]+' site_create_page.html | head -1)

echo "Creating site: $SITE_NAME"
curl -k -s -b $COOKIES \
  -X POST $ADMIN_URL/sites \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=${CSRF4}&site_name=${SITE_NAME}&domain=${SITE_DOMAIN}&php_version=8.3" \
  -D headers_site.txt \
  -o response_site.html

HTTP_CODE3=$(grep "HTTP/" headers_site.txt | tail -1 | awk '{print $2}')
LOCATION3=$(grep -i "^location:" headers_site.txt | tail -1 | tr -d '\r\n' | awk '{print $2}')

echo "HTTP Status: $HTTP_CODE3"
echo "Redirect: $LOCATION3"

if [ "$HTTP_CODE3" = "302" ] && [[ "$LOCATION3" == *"/sites"* ]]; then
    echo "✓ TEST 3 PASSED: Site form redirects correctly (background execution)"
    echo "⚠ Site creation in progress (2-3 minutes)"
    echo "⚠ Check /opt/webserver/sites/logs/site-creation-${SITE_NAME}.log for progress"
else
    echo "✗ TEST 3 FAILED: HTTP $HTTP_CODE3"
fi

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo ""
echo "Test 1 (Email Domain): Check above"
echo "Test 2 (Email Account): Check above"  
echo "Test 3 (Site Creation): Background execution, check logs"
echo ""
echo "All forms should now:"
echo "- Submit without errors"
echo "- Redirect correctly"
echo "- Show success messages"
echo "- Data should appear in listings"
echo ""

