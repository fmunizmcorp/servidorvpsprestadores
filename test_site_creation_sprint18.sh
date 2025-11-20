#!/bin/bash

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="cookies_sprint18.txt"

echo "=========================================="
echo "TESTE CREATE SITE - SPRINT 18.2"
echo "=========================================="

# Step 1: Login
echo ""
echo "[1] Fazendo login..."
LOGIN_RESPONSE=$(curl -k -s -c "$COOKIES" -b "$COOKIES" \
  -X POST "${ADMIN_URL}/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=admin@prestadores.local&password=AdminSecure123!&_token=$(curl -k -s -b "$COOKIES" -c "$COOKIES" "${ADMIN_URL}/login" | grep -oP 'name="_token" value="\K[^"]+' | head -1)")

echo "Login Response: ${LOGIN_RESPONSE:0:200}"

# Step 2: Get CSRF token from create form
echo ""
echo "[2] Obtendo CSRF token do formulário..."
CSRF_TOKEN=$(curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites/create" | grep -oP 'name="_token" value="\K[^"]+' | head -1)
echo "CSRF Token: $CSRF_TOKEN"

# Step 3: Submit create site form
echo ""
echo "[3] Criando site com dados corretos..."
echo "Dados: site_name=testespringsprint18, domain=testespringsprint18.local, php_version=8.2"

CREATE_RESPONSE=$(curl -k -s -b "$COOKIES" -c "$COOKIES" -w "\n\nHTTP_CODE:%{http_code}\nREDIRECT_URL:%{redirect_url}\n" \
  -X POST "${ADMIN_URL}/sites" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Referer: ${ADMIN_URL}/sites/create" \
  -d "_token=${CSRF_TOKEN}&site_name=testesprint18&domain=testesprint18.local&php_version=8.2&create_database=1")

echo "Create Response:"
echo "$CREATE_RESPONSE"

# Step 4: Verify site in listing
echo ""
echo "[4] Verificando se site aparece na listagem..."
LISTING=$(curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites" | grep -i "testesprint18")

if [ -n "$LISTING" ]; then
    echo "✅ SUCESSO! Site encontrado na listagem!"
    echo "$LISTING"
else
    echo "🔴 FALHOU! Site NÃO encontrado na listagem!"
fi

# Step 5: Check filesystem
echo ""
echo "[5] Verificando filesystem no VPS..."
