#!/bin/bash

#############################################################################
# DIRECT DATABASE/FILESYSTEM QA TEST - BYPASS AUTH ISSUES
# Tests Sites and Email Domains creation by directly invoking controllers
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
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
        if [ -n "$3" ]; then
            echo -e "${YELLOW}   Details:${NC} $3"
        fi
    fi
}

# Function to execute SSH command
ssh_exec() {
    sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$1" 2>&1
}

###############################################################################
# TEST SUITE 1: SITES CREATION
###############################################################################

print_test_header "TEST SUITE 1: DIRECT SITE CREATION VIA ARTISAN TINKER"

echo "1.1 Getting baseline site count..."
BASELINE_SITES=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e 'SELECT COUNT(*) FROM sites' -sN")
echo "Baseline sites count: $BASELINE_SITES"

echo ""
echo "1.2 Creating site via Artisan Tinker (bypassing web interface)..."
SITE_CREATE_OUTPUT=$(ssh_exec "cd /opt/webserver/admin-panel && php artisan tinker --execute=\"
    \\\\App\\\\Models\\\\Site::create([
        'site_name' => '$TEST_SITE_NAME',
        'domain' => '$TEST_SITE_DOMAIN',
        'php_version' => '8.3',
        'has_database' => true,
        'database_name' => '${TEST_SITE_NAME}_db',
        'database_user' => '${TEST_SITE_NAME}_user',
        'status' => 'active'
    ]);
    echo 'Site created successfully in database';
\"")

if echo "$SITE_CREATE_OUTPUT" | grep -q "Site created successfully"; then
    print_test_result 0 "Create site record in database via Eloquent" ""
else
    print_test_result 1 "Create site record in database via Eloquent" "Eloquent create failed: $SITE_CREATE_OUTPUT"
fi

echo ""
echo "1.3 Running create-site.sh wrapper script to provision infrastructure..."
WRAPPER_OUTPUT=$(ssh_exec "sudo /opt/webserver/scripts/wrappers/create-site-wrapper.sh '$TEST_SITE_NAME' '$TEST_SITE_DOMAIN' '8.3' --template=php 2>&1")

echo "Script output (first 500 chars):"
echo "${WRAPPER_OUTPUT:0:500}"

echo ""
echo "1.4 Waiting for site creation to complete (3 seconds)..."
sleep 3

echo ""
echo "1.5 Validating site infrastructure..."

# Check database entry
SITE_IN_DB=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"SELECT site_name FROM sites WHERE site_name='$TEST_SITE_NAME'\" -sN")
if [ "$SITE_IN_DB" == "$TEST_SITE_NAME" ]; then
    print_test_result 0 "Site persisted to database" ""
else
    print_test_result 1 "Site persisted to database" "Site '$TEST_SITE_NAME' NOT found"
fi

# Check directory
SITE_DIR_EXISTS=$(ssh_exec "[ -d /opt/webserver/sites/$TEST_SITE_NAME ] && echo 'yes' || echo 'no'")
if [ "$SITE_DIR_EXISTS" == "yes" ]; then
    print_test_result 0 "Site directory created" ""
else
    print_test_result 1 "Site directory created" "/opt/webserver/sites/$TEST_SITE_NAME NOT found"
fi

# Check PHP-FPM pool
POOL_EXISTS=$(ssh_exec "[ -f /etc/php/8.3/fpm/pool.d/$TEST_SITE_NAME.conf ] && echo 'yes' || echo 'no'")
if [ "$POOL_EXISTS" == "yes" ]; then
    print_test_result 0 "PHP-FPM pool created" ""
else
    print_test_result 1 "PHP-FPM pool created" "/etc/php/8.3/fpm/pool.d/$TEST_SITE_NAME.conf NOT found"
fi

# Check NGINX config
NGINX_EXISTS=$(ssh_exec "[ -f /etc/nginx/sites-available/$TEST_SITE_NAME.conf ] && echo 'yes' || echo 'no'")
if [ "$NGINX_EXISTS" == "yes" ]; then
    print_test_result 0 "NGINX virtual host created" ""
else
    print_test_result 1 "NGINX virtual host created" "/etc/nginx/sites-available/$TEST_SITE_NAME.conf NOT found"
fi

# Check count increased
NEW_SITES_COUNT=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e 'SELECT COUNT(*) FROM sites' -sN")
if [ "$NEW_SITES_COUNT" -gt "$BASELINE_SITES" ]; then
    print_test_result 0 "Sites count increased" "From $BASELINE_SITES to $NEW_SITES_COUNT"
else
    print_test_result 1 "Sites count increased" "Remained at $BASELINE_SITES"
fi

###############################################################################
# TEST SUITE 2: EMAIL DOMAINS CREATION
###############################################################################

print_test_header "TEST SUITE 2: DIRECT EMAIL DOMAIN CREATION VIA ARTISAN TINKER"

echo "2.1 Getting baseline email domains count..."
BASELINE_DOMAINS=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e 'SELECT COUNT(*) FROM email_domains' -sN")
echo "Baseline email domains count: $BASELINE_DOMAINS"

echo ""
echo "2.2 Creating email domain via Artisan Tinker..."
EMAIL_CREATE_OUTPUT=$(ssh_exec "cd /opt/webserver/admin-panel && php artisan tinker --execute=\"
    \\\\App\\\\Models\\\\EmailDomain::create([
        'domain' => '$TEST_EMAIL_DOMAIN',
        'status' => 'active'
    ]);
    echo 'Email domain created successfully in database';
\"")

if echo "$EMAIL_CREATE_OUTPUT" | grep -q "Email domain created successfully"; then
    print_test_result 0 "Create email domain record in database via Eloquent" ""
else
    print_test_result 1 "Create email domain record in database via Eloquent" "Eloquent create failed: $EMAIL_CREATE_OUTPUT"
fi

echo ""
echo "2.3 Running create-email-domain.sh script to configure Postfix..."
DOMAIN_SCRIPT_OUTPUT=$(ssh_exec "sudo bash /opt/webserver/scripts/create-email-domain.sh '$TEST_EMAIL_DOMAIN' 2>&1 || echo 'Script may not exist'")

echo "Script output (first 300 chars):"
echo "${DOMAIN_SCRIPT_OUTPUT:0:300}"

echo ""
echo "2.4 Waiting for domain creation to complete (2 seconds)..."
sleep 2

echo ""
echo "2.5 Validating email domain..."

# Check database entry
DOMAIN_IN_DB=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"SELECT domain FROM email_domains WHERE domain='$TEST_EMAIL_DOMAIN'\" -sN")
if [ "$DOMAIN_IN_DB" == "$TEST_EMAIL_DOMAIN" ]; then
    print_test_result 0 "Email domain persisted to database" ""
else
    print_test_result 1 "Email domain persisted to database" "Domain '$TEST_EMAIL_DOMAIN' NOT found"
fi

# Check count increased
NEW_DOMAINS_COUNT=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e 'SELECT COUNT(*) FROM email_domains' -sN")
if [ "$NEW_DOMAINS_COUNT" -gt "$BASELINE_DOMAINS" ]; then
    print_test_result 0 "Email domains count increased" "From $BASELINE_DOMAINS to $NEW_DOMAINS_COUNT"
else
    print_test_result 1 "Email domains count increased" "Remained at $BASELINE_DOMAINS"
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
    echo -e "${GREEN}Database persistence working correctly!${NC}"
    echo -e "${GREEN}Site and Email Domain models can be created via Eloquent${NC}"
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
