#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="72.61.53.222"
SERVER_USER="root"
SERVER_PASS="Jm@D@KDPnw7Q"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_SITE="qadb_${TIMESTAMP}"
TEST_DOMAIN="qaemail_db_${TIMESTAMP}.local"

ssh_exec() {
    sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$1" 2>&1
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SIMPLE DATABASE PERSISTENCE TEST${NC}"
echo -e "${BLUE}========================================${NC}"

echo ""
echo "Test 1: Sites table - Create and verify"
ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"INSERT INTO sites (site_name, domain, php_version, status, created_at, updated_at) VALUES ('$TEST_SITE', '$TEST_SITE.local', '8.3', 'active', NOW(), NOW())\""

VERIFY=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"SELECT site_name FROM sites WHERE site_name='$TEST_SITE'\" -sN")

if [ "$VERIFY" == "$TEST_SITE" ]; then
    echo -e "${GREEN}✅ PASSED: Site persisted to database${NC}"
else
    echo -e "${RED}❌ FAILED: Site NOT found in database${NC}"
    exit 1
fi

echo ""
echo "Test 2: Email Domains table - Create and verify"
ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"INSERT INTO email_domains (domain, status, created_at, updated_at) VALUES ('$TEST_DOMAIN', 'active', NOW(), NOW())\""

VERIFY2=$(ssh_exec "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"SELECT domain FROM email_domains WHERE domain='$TEST_DOMAIN'\" -sN")

if [ "$VERIFY2" == "$TEST_DOMAIN" ]; then
    echo -e "${GREEN}✅ PASSED: Email domain persisted to database${NC}"
else
    echo -e "${RED}❌ FAILED: Email domain NOT found in database${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ ALL DATABASE TESTS PASSED  100%   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Both Sites and Email Domains tables are working correctly!${NC}"
echo -e "${GREEN}Database persistence confirmed.${NC}"
