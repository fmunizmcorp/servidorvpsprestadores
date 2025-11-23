#!/bin/bash

#############################################################################
# COMPREHENSIVE QA VALIDATION SCRIPT - POST RECOVERY
# Tests both Sites and Email Domains creation with full validation
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ADMIN_URL="https://72.61.53.222/admin"
SERVER_IP="72.61.53.222"
SERVER_USER="root"
SERVER_PASS="Jm@D@KDPnw7Q"

# Test data with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_SITE_NAME="qatest_${TIMESTAMP}"
TEST_SITE_DOMAIN="qatest${TIMESTAMP}.local"
TEST_EMAIL_DOMAIN="qaemail${TIMESTAMP}.local"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Cookie file
COOKIE_FILE="/tmp/qa_cookies_${TIMESTAMP}.txt"

# Function to print test header
print_test_header() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# Function to print test result
print_test_result() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ $1 -eq 0 ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}✅ PASSED:${NC} $2"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}❌ FAILED:${NC} $2"
        echo -e "${YELLOW}   Details:${NC} $3"
    fi
}

# Function to execute SSH command
ssh_exec() {
    sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$1" 2>&1
}

print_test_header "STEP 0: PRE-VALIDATION - CLEAR ALL CACHES"
echo "Clearing Laravel caches to ensure fresh state..."
ssh_exec "cd /opt/webserver/admin-panel && php artisan optimize:clear"
echo -e "${GREEN}✓ All caches cleared${NC}"

print_test_header "STEP 1: AUTHENTICATE TO ADMIN PANEL"
echo "Logging in to admin panel..."

# Get CSRF token from login page (using -k to ignore self-signed certificate)
LOGIN_PAGE=$(curl -s -k -c "$COOKIE_FILE" "$ADMIN_URL/login")
CSRF_TOKEN=$(echo "$LOGIN_PAGE" | grep -oP '(?<=name="_token" value=")[^"]+' | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    echo -e "${RED}ERROR: Could not extract CSRF token from login page${NC}"
    exit 1
fi

echo "CSRF Token: $CSRF_TOKEN"

# Login (using -k to ignore self-signed certificate)
LOGIN_RESPONSE=$(curl -s -k -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
    -X POST "$ADMIN_URL/login" \
    -H "Referer: $ADMIN_URL/login" \
    -H "Origin: https://72.61.53.222" \
    -d "_token=$CSRF_TOKEN" \
    -d "email=admin@localhost" \
    -d "password=Admin@2025!" \
    -L -w "\n%{http_code}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -1)
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Authentication successful${NC}"
else
    echo -e "${RED}✗ Authentication failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

###############################################################################
# TEST SUITE 1: SITES CREATION
###############################################################################

print_test_header "TEST SUITE 1: SITES CREATION"

echo "1.1 Getting baseline site count..."
BASELINE_COUNT=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e 'SELECT COUNT(*) FROM sites' -sN")
echo "Baseline sites count: $BASELINE_COUNT"

echo ""
echo "1.2 Getting CSRF token from create site form..."
CREATE_SITE_PAGE=$(curl -s -k -b "$COOKIE_FILE" "$ADMIN_URL/sites/create")
CSRF_TOKEN_SITE=$(echo "$CREATE_SITE_PAGE" | grep -oP '(?<=name="_token" value=")[^"]+' | head -1)

if [ -z "$CSRF_TOKEN_SITE" ]; then
    print_test_result 1 "Extract CSRF token from sites/create form" "No CSRF token found in page"
    exit 1
fi

echo "CSRF Token for site creation: $CSRF_TOKEN_SITE"
print_test_result 0 "Extract CSRF token from sites/create form" ""

echo ""
echo "1.3 Submitting site creation form..."
SITE_CREATE_RESPONSE=$(curl -s -k -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
    -X POST "$ADMIN_URL/sites" \
    -H "Referer: $ADMIN_URL/sites/create" \
    -H "X-CSRF-TOKEN: $CSRF_TOKEN_SITE" \
    -d "_token=$CSRF_TOKEN_SITE" \
    -d "site_name=$TEST_SITE_NAME" \
    -d "domain=$TEST_SITE_DOMAIN" \
    -d "php_version=8.3" \
    -d "create_database=1" \
    -L -w "\n%{http_code}")

HTTP_CODE_SITE=$(echo "$SITE_CREATE_RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$SITE_CREATE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE_SITE" == "200" ]; then
    print_test_result 0 "Site creation HTTP response (200)" ""
elif [ "$HTTP_CODE_SITE" == "405" ]; then
    print_test_result 1 "Site creation HTTP response" "ERROR 405 Method Not Allowed - Route issue detected"
    echo "$RESPONSE_BODY" > /tmp/site_405_error.html
    echo "Full response saved to /tmp/site_405_error.html"
    exit 1
else
    print_test_result 1 "Site creation HTTP response" "Unexpected HTTP code: $HTTP_CODE_SITE"
    echo "$RESPONSE_BODY" > /tmp/site_error.html
    exit 1
fi

echo ""
echo "1.4 Waiting for site creation to complete (3 seconds)..."
sleep 3

echo ""
echo "1.5 Validating site was created..."

# Check database
SITE_IN_DB=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"SELECT site_name FROM sites WHERE site_name='$TEST_SITE_NAME'\" -sN")
if [ "$SITE_IN_DB" == "$TEST_SITE_NAME" ]; then
    print_test_result 0 "Site persisted to database" "Site '$TEST_SITE_NAME' found in database"
else
    print_test_result 1 "Site persisted to database" "Site '$TEST_SITE_NAME' NOT found in database"
fi

# Check directory
SITE_DIR_EXISTS=$(ssh_exec "[ -d /opt/webserver/sites/$TEST_SITE_NAME ] && echo 'yes' || echo 'no'")
if [ "$SITE_DIR_EXISTS" == "yes" ]; then
    print_test_result 0 "Site directory created" "Directory /opt/webserver/sites/$TEST_SITE_NAME exists"
else
    print_test_result 1 "Site directory created" "Directory /opt/webserver/sites/$TEST_SITE_NAME NOT found"
fi

# Check PHP-FPM pool
POOL_EXISTS=$(ssh_exec "[ -f /etc/php/8.3/fpm/pool.d/$TEST_SITE_NAME.conf ] && echo 'yes' || echo 'no'")
if [ "$POOL_EXISTS" == "yes" ]; then
    print_test_result 0 "PHP-FPM pool created" "Pool /etc/php/8.3/fpm/pool.d/$TEST_SITE_NAME.conf exists"
else
    print_test_result 1 "PHP-FPM pool created" "Pool /etc/php/8.3/fpm/pool.d/$TEST_SITE_NAME.conf NOT found"
fi

# Check sites listing
NEW_COUNT=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e 'SELECT COUNT(*) FROM sites' -sN")
if [ "$NEW_COUNT" -gt "$BASELINE_COUNT" ]; then
    print_test_result 0 "Sites count increased" "Count went from $BASELINE_COUNT to $NEW_COUNT"
else
    print_test_result 1 "Sites count increased" "Count remained at $BASELINE_COUNT"
fi

###############################################################################
# TEST SUITE 2: EMAIL DOMAINS CREATION
###############################################################################

print_test_header "TEST SUITE 2: EMAIL DOMAINS CREATION"

echo "2.1 Getting baseline email domains count..."
BASELINE_DOMAINS=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e 'SELECT COUNT(*) FROM email_domains' -sN")
echo "Baseline email domains count: $BASELINE_DOMAINS"

echo ""
echo "2.2 Getting domains page and CSRF token..."
DOMAINS_PAGE=$(curl -s -k -b "$COOKIE_FILE" "$ADMIN_URL/email/domains")
CSRF_TOKEN_EMAIL=$(echo "$DOMAINS_PAGE" | grep -oP '(?<=name="_token" value=")[^"]+' | head -1)

if [ -z "$CSRF_TOKEN_EMAIL" ]; then
    print_test_result 1 "Extract CSRF token from email/domains page" "No CSRF token found"
    exit 1
fi

echo "CSRF Token for email domain creation: $CSRF_TOKEN_EMAIL"
print_test_result 0 "Extract CSRF token from email/domains page" ""

echo ""
echo "2.3 Submitting email domain creation..."
EMAIL_CREATE_RESPONSE=$(curl -s -k -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
    -X POST "$ADMIN_URL/email/domains" \
    -H "Referer: $ADMIN_URL/email/domains" \
    -H "X-CSRF-TOKEN: $CSRF_TOKEN_EMAIL" \
    -d "_token=$CSRF_TOKEN_EMAIL" \
    -d "domain=$TEST_EMAIL_DOMAIN" \
    -L -w "\n%{http_code}")

HTTP_CODE_EMAIL=$(echo "$EMAIL_CREATE_RESPONSE" | tail -1)
RESPONSE_BODY_EMAIL=$(echo "$EMAIL_CREATE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE_EMAIL" == "200" ]; then
    print_test_result 0 "Email domain creation HTTP response (200)" ""
elif [ "$HTTP_CODE_EMAIL" == "405" ]; then
    print_test_result 1 "Email domain creation HTTP response" "ERROR 405 Method Not Allowed"
    echo "$RESPONSE_BODY_EMAIL" > /tmp/email_405_error.html
    exit 1
else
    print_test_result 1 "Email domain creation HTTP response" "Unexpected HTTP code: $HTTP_CODE_EMAIL"
    echo "$RESPONSE_BODY_EMAIL" > /tmp/email_error.html
fi

echo ""
echo "2.4 Waiting for domain creation to complete (2 seconds)..."
sleep 2

echo ""
echo "2.5 Validating email domain was created..."

# Check database
DOMAIN_IN_DB=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"SELECT domain FROM email_domains WHERE domain='$TEST_EMAIL_DOMAIN'\" -sN")
if [ "$DOMAIN_IN_DB" == "$TEST_EMAIL_DOMAIN" ]; then
    print_test_result 0 "Email domain persisted to database" "Domain '$TEST_EMAIL_DOMAIN' found in database"
else
    print_test_result 1 "Email domain persisted to database" "Domain '$TEST_EMAIL_DOMAIN' NOT found in database"
fi

# Check email domains count
NEW_DOMAINS_COUNT=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e 'SELECT COUNT(*) FROM email_domains' -sN")
if [ "$NEW_DOMAINS_COUNT" -gt "$BASELINE_DOMAINS" ]; then
    print_test_result 0 "Email domains count increased" "Count went from $BASELINE_DOMAINS to $NEW_DOMAINS_COUNT"
else
    print_test_result 1 "Email domains count increased" "Count remained at $BASELINE_DOMAINS"
fi

###############################################################################
# FINAL SUMMARY
###############################################################################

print_test_header "FINAL TEST SUMMARY"

echo ""
echo -e "${BLUE}Total Tests:${NC}  $TOTAL_TESTS"
echo -e "${GREEN}Passed:${NC}       $PASSED_TESTS"
echo -e "${RED}Failed:${NC}       $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL TESTS PASSED - 100% SUCCESS  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Both Sites and Email Domains creation are working correctly!${NC}"
    exit 0
else
    PASS_PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║     ❌ SOME TESTS FAILED ($PASS_PERCENTAGE%)        ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Please review the failed tests above for details.${NC}"
    exit 1
fi
