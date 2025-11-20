#!/bin/bash

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="test_cookies.txt"
rm -f "$COOKIES"

echo "==================================================================="
echo "TESTE COMPLETO - CRIAÇÃO DE SITE SPRINT 18.2"
echo "==================================================================="

# Step 1: Get login page
echo -e "\n[1] Obtendo página de login..."
curl -k -s -c "$COOKIES" -b "$COOKIES" "${ADMIN_URL}/login" > /tmp/login_page.html
LOGIN_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/login_page.html | head -1)
echo "CSRF Token obtido: ${LOGIN_TOKEN:0:20}..."

# Step 2: Login POST
echo -e "\n[2] Fazendo login (admin@vps.local / AdminTest123)..."
curl -k -s -c "$COOKIES" -b "$COOKIES" \
  -X POST "${ADMIN_URL}/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: text/html" \
  -H "Referer: ${ADMIN_URL}/login" \
  --data-urlencode "_token=${LOGIN_TOKEN}" \
  --data-urlencode "email=admin@vps.local" \
  --data-urlencode "password=AdminTest123" \
  -L > /tmp/after_login.html

# Check if redirected to dashboard
if grep -q "Dashboard\|Sites\|Monitoring" /tmp/after_login.html; then
    echo "✅ Login bem-sucedido!"
else
    echo "🔴 Login falhou. Resposta:"
    head -20 /tmp/after_login.html
    exit 1
fi

# Step 3: Get create form
echo -e "\n[3] Acessando formulário de criação de site..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites/create" > /tmp/create_form.html
CREATE_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/create_form.html | head -1)
echo "Create CSRF Token: ${CREATE_TOKEN:0:20}..."

# Verify form fields
if grep -q 'name="site_name"' /tmp/create_form.html; then
    echo "✅ Formulário contém campo 'site_name' (correto!)"
else
    echo "🔴 Formulário NÃO contém campo 'site_name'"
fi

if grep -q 'name="php_version"' /tmp/create_form.html; then
    echo "✅ Formulário contém campo 'php_version' (correto!)"
fi

# Step 4: Submit create site form
echo -e "\n[4] Submetendo formulário..."
echo "Dados: site_name=testefinal1832, domain=testefinal1832.local, php_version=8.3"

curl -k -s -b "$COOKIES" -c "$COOKIES" \
  -X POST "${ADMIN_URL}/sites" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: text/html" \
  -H "Referer: ${ADMIN_URL}/sites/create" \
  --data-urlencode "_token=${CREATE_TOKEN}" \
  --data-urlencode "site_name=testefinal1832" \
  --data-urlencode "domain=testefinal1832.local" \
  --data-urlencode "php_version=8.3" \
  --data-urlencode "create_database=1" \
  -L -w "\n\n=== HTTP CODE: %{http_code} ===\n" \
  > /tmp/create_response.html

echo ""
echo "Resposta da criação:"
tail -30 /tmp/create_response.html

# Step 5: Check if site appears in listing
echo -e "\n[5] Verificando listagem de sites..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites" > /tmp/sites_listing.html

if grep -iq "testefinal1832" /tmp/sites_listing.html; then
    echo "✅✅✅ SUCESSO TOTAL! Site 'testefinal1832' aparece na listagem!"
else
    echo "🔴 Site NÃO aparece na listagem"
fi

# Step 6: Check filesystem
echo -e "\n[6] Verificando filesystem no VPS..."
