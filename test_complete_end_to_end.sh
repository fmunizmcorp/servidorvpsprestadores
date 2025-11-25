#!/bin/bash

###############################################################################
# END-TO-END TEST - CRIAÇÃO DE SITE E EMAIL DOMAIN
# Testa com autenticação real e submissão de formulários
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ADMIN_URL="https://72.61.53.222/admin"
COOKIE_FILE="/tmp/e2e_test_cookies_$(date +%s).txt"
TIMESTAMP=$(date +%s)

TEST_SITE="e2e_site_$TIMESTAMP"
TEST_DOMAIN="e2e-site-$TIMESTAMP.local"
TEST_EMAIL_DOMAIN="e2e-email-$TIMESTAMP.local"

PASSED=0
FAILED=0

test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASSED:${NC} $2"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ FAILED:${NC} $2"
        echo -e "${YELLOW}   $3${NC}"
        FAILED=$((FAILED + 1))
    fi
}

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  END-TO-END TEST - Admin Panel VPS                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# ==================================================
# TEST 1: LOGIN
# ==================================================
echo -e "${BLUE}[TEST 1] Autenticação no admin panel...${NC}"

# Get login page and CSRF token
LOGIN_PAGE=$(curl -s -k -c "$COOKIE_FILE" "$ADMIN_URL/login")
CSRF_TOKEN=$(echo "$LOGIN_PAGE" | grep -oP '(?<=name="_token" value=")[^"]+' | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    test_result 1 "Obter CSRF token da página de login" "Token não encontrado"
    exit 1
fi

test_result 0 "Obter CSRF token da página de login" "Token: ${CSRF_TOKEN:0:20}..."

# Login
LOGIN_RESPONSE=$(curl -s -k -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
    -X POST "$ADMIN_URL/login" \
    -H "Referer: $ADMIN_URL/login" \
    -H "Origin: https://72.61.53.222" \
    -d "_token=$CSRF_TOKEN" \
    -d "email=admin@localhost" \
    -d "password=Admin@2025!" \
    -L -w "\n%{http_code}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -1)

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "302" ]; then
    test_result 0 "Login no admin panel" "HTTP $HTTP_CODE"
else
    test_result 1 "Login no admin panel" "HTTP $HTTP_CODE - Autenticação falhou"
    exit 1
fi

# ==================================================
# TEST 2: CRIAR SITE
# ==================================================
echo ""
echo -e "${BLUE}[TEST 2] Criando novo site...${NC}"

# Get create site page
CREATE_SITE_PAGE=$(curl -s -k -b "$COOKIE_FILE" "$ADMIN_URL/sites/create")
CSRF_SITE=$(echo "$CREATE_SITE_PAGE" | grep -oP '(?<=name="_token" value=")[^"]+' | head -1)

if [ -z "$CSRF_SITE" ]; then
    test_result 1 "Obter CSRF token de sites/create" "Token não encontrado"
else
    test_result 0 "Obter CSRF token de sites/create" "Token obtido"
fi

# Submit site creation form
SITE_CREATE_RESPONSE=$(curl -s -k -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
    -X POST "$ADMIN_URL/sites" \
    -H "Referer: $ADMIN_URL/sites/create" \
    -H "Origin: https://72.61.53.222" \
    -d "_token=$CSRF_SITE" \
    -d "site_name=$TEST_SITE" \
    -d "domain=$TEST_DOMAIN" \
    -d "php_version=8.3" \
    -d "create_database=1" \
    -L -w "\n%{http_code}")

HTTP_SITE=$(echo "$SITE_CREATE_RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$SITE_CREATE_RESPONSE" | sed '$d')

if [ "$HTTP_SITE" == "200" ] || [ "$HTTP_SITE" == "302" ]; then
    test_result 0 "Submeter formulário de criação de site" "HTTP $HTTP_SITE"
else
    test_result 1 "Submeter formulário de criação de site" "HTTP $HTTP_SITE"
    echo "$RESPONSE_BODY" > /tmp/site_create_error.html
fi

# Wait for creation
echo "   Aguardando criação do site (5 segundos)..."
sleep 5

# Verify site in database
SITE_IN_DB=$(sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"SELECT site_name FROM sites WHERE site_name='$TEST_SITE'\" -sN" 2>/dev/null)

if [ "$SITE_IN_DB" == "$TEST_SITE" ]; then
    test_result 0 "Site persistido no banco de dados" "Site '$TEST_SITE' encontrado"
else
    test_result 1 "Site persistido no banco de dados" "Site '$TEST_SITE' NÃO encontrado"
fi

# Verify directory
SITE_DIR=$(sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "[ -d /opt/webserver/sites/$TEST_SITE ] && echo 'yes' || echo 'no'" 2>/dev/null)

if [ "$SITE_DIR" == "yes" ]; then
    test_result 0 "Diretório do site criado" "/opt/webserver/sites/$TEST_SITE existe"
else
    test_result 1 "Diretório do site criado" "Diretório NÃO encontrado"
fi

# ==================================================
# TEST 3: CRIAR EMAIL DOMAIN
# ==================================================
echo ""
echo -e "${BLUE}[TEST 3] Criando novo email domain...${NC}"

# Get email domains page
EMAIL_PAGE=$(curl -s -k -b "$COOKIE_FILE" "$ADMIN_URL/email/domains")
CSRF_EMAIL=$(echo "$EMAIL_PAGE" | grep -oP '(?<=name="_token" value=")[^"]+' | head -1)

if [ -z "$CSRF_EMAIL" ]; then
    test_result 1 "Obter CSRF token de email/domains" "Token não encontrado"
else
    test_result 0 "Obter CSRF token de email/domains" "Token obtido"
fi

# Submit email domain creation
EMAIL_CREATE_RESPONSE=$(curl -s -k -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
    -X POST "$ADMIN_URL/email/domains" \
    -H "Referer: $ADMIN_URL/email/domains" \
    -H "Origin: https://72.61.53.222" \
    -d "_token=$CSRF_EMAIL" \
    -d "domain=$TEST_EMAIL_DOMAIN" \
    -L -w "\n%{http_code}")

HTTP_EMAIL=$(echo "$EMAIL_CREATE_RESPONSE" | tail -1)

if [ "$HTTP_EMAIL" == "200" ] || [ "$HTTP_EMAIL" == "302" ]; then
    test_result 0 "Submeter formulário de criação de email domain" "HTTP $HTTP_EMAIL"
else
    test_result 1 "Submeter formulário de criação de email domain" "HTTP $HTTP_EMAIL"
fi

# Wait for creation
echo "   Aguardando criação do domain (3 segundos)..."
sleep 3

# Verify domain in database
DOMAIN_IN_DB=$(sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "mysql -u root -pJm@D@KDPnw7Q admin_panel -e \"SELECT domain FROM email_domains WHERE domain='$TEST_EMAIL_DOMAIN'\" -sN" 2>/dev/null)

if [ "$DOMAIN_IN_DB" == "$TEST_EMAIL_DOMAIN" ]; then
    test_result 0 "Email domain persistido no banco de dados" "Domain '$TEST_EMAIL_DOMAIN' encontrado"
else
    test_result 1 "Email domain persistido no banco de dados" "Domain '$TEST_EMAIL_DOMAIN' NÃO encontrado"
fi

# ==================================================
# SUMMARY
# ==================================================
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  RESULTADO FINAL                                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Total de Testes: $((PASSED + FAILED))"
echo -e "${GREEN}Passados:${NC} $PASSED"
echo -e "${RED}Falhados:${NC} $FAILED"
echo ""

# Cleanup
rm -f "$COOKIE_FILE"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✅ TODOS OS TESTES PASSARAM!             ║${NC}"
    echo -e "${GREEN}║     Sistema 100% Funcional - Problema RESOLVIDO   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    PERCENT=$((PASSED * 100 / (PASSED + FAILED)))
    echo -e "${YELLOW}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   Taxa de Sucesso: $PERCENT%                          ║${NC}"
    echo -e "${YELLOW}║   Alguns testes falharam - revisar logs acima     ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
