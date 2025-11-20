#!/bin/bash

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="cookies_sprint19.txt"
rm -f "$COOKIES"

echo "=========================================="
echo "TESTE SPRINT 19 - USUÁRIO DO RELATÓRIO"
echo "=========================================="
echo "Credenciais: test@admin.local / Test@123456"
echo ""

# Step 1: Get login page
echo "[1] Obtendo página de login..."
curl -k -s -c "$COOKIES" "${ADMIN_URL}/login" > /tmp/login_page.html
TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/login_page.html | head -1)
echo "CSRF Token: ${TOKEN:0:20}..."

# Step 2: Login
echo ""
echo "[2] Fazendo login..."
curl -k -s -c "$COOKIES" -b "$COOKIES" -L \
  -X POST "${ADMIN_URL}/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "_token=${TOKEN}" \
  --data-urlencode "email=test@admin.local" \
  --data-urlencode "password=Test@123456" \
  > /tmp/dashboard.html

if grep -q "Dashboard\|Sites\|Email" /tmp/dashboard.html; then
    echo "✅ Login bem-sucedido!"
else
    echo "🔴 Login falhou!"
    echo "Resposta:"
    head -30 /tmp/dashboard.html
    exit 1
fi

# Step 3: Test email accounts page (Problema #1)
echo ""
echo "[3] Testando /admin/email/accounts (Problema #1)..."
RESPONSE=$(curl -k -s -b "$COOKIES" -w "\nHTTP:%{http_code}\n" "${ADMIN_URL}/email/accounts")
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP:" | cut -d: -f2)

if [ "$HTTP_CODE" == "500" ]; then
    echo "🔴 FALHOU! Ainda retorna HTTP 500"
    echo "$RESPONSE" | tail -20
elif [ "$HTTP_CODE" == "200" ]; then
    echo "✅ PASSOU! HTTP 200 - Página carregou"
else
    echo "⚠️ HTTP $HTTP_CODE"
fi

# Step 4: Test create site form (Problema #2)
echo ""
echo "[4] Testando formulário Create Site (Problema #2)..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites/create" > /tmp/create_site_form.html
SITE_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/create_site_form.html | head -1)

SITE_RESPONSE=$(curl -k -s -b "$COOKIES" -L -w "\nFINAL_URL:%{url_effective}\nHTTP:%{http_code}\n" \
  -X POST "${ADMIN_URL}/sites" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Referer: ${ADMIN_URL}/sites/create" \
  --data-urlencode "_token=${SITE_TOKEN}" \
  --data-urlencode "site_name=sprint19test" \
  --data-urlencode "domain=sprint19test.local" \
  --data-urlencode "php_version=8.3" \
  --data-urlencode "create_database=1")

FINAL_URL=$(echo "$SITE_RESPONSE" | grep "FINAL_URL:" | cut -d: -f2-)

if echo "$FINAL_URL" | grep -q "?%2Fsites%2Fcreate="; then
    echo "🔴 FALHOU! URL malformada: $FINAL_URL"
elif echo "$FINAL_URL" | grep -q "/sites"; then
    echo "✅ PASSOU! Redirecionou corretamente para: $FINAL_URL"
else
    echo "⚠️ URL inesperada: $FINAL_URL"
fi

# Step 5: Test create email domain (Problema #3)
echo ""
echo "[5] Testando formulário Create Email Domain (Problema #3)..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/email/domains" > /tmp/create_domain_form.html
DOMAIN_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/create_domain_form.html | head -1)

DOMAIN_RESPONSE=$(curl -k -s -b "$COOKIES" -L -w "\nFINAL_URL:%{url_effective}\nHTTP:%{http_code}\n" \
  -X POST "${ADMIN_URL}/email/domains" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Referer: ${ADMIN_URL}/email/domains" \
  --data-urlencode "_token=${DOMAIN_TOKEN}" \
  --data-urlencode "domain=sprint19test.local")

FINAL_URL_DOMAIN=$(echo "$DOMAIN_RESPONSE" | grep "FINAL_URL:" | cut -d: -f2-)

if echo "$FINAL_URL_DOMAIN" | grep -q "?%2Femail%2Fdomains="; then
    echo "🔴 FALHOU! URL malformada: $FINAL_URL_DOMAIN"
elif echo "$FINAL_URL_DOMAIN" | grep -q "/email/domains"; then
    echo "✅ PASSOU! Redirecionou corretamente para: $FINAL_URL_DOMAIN"
else
    echo "⚠️ URL inesperada: $FINAL_URL_DOMAIN"
fi

echo ""
echo "=========================================="
echo "FIM DOS TESTES"
echo "=========================================="
