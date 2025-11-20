#!/bin/bash

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="cookies_final_test.txt"
rm -f "$COOKIES"

echo "=========================================="
echo "TESTE COMPLETO - CREATE SITE SPRINT 18.2"
echo "=========================================="

# Step 1: Get login page and CSRF
echo -e "\n[1] Acessando página de login..."
curl -k -s -c "$COOKIES" -b "$COOKIES" "${ADMIN_URL}/login" > /tmp/login_page.html
LOGIN_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/login_page.html | head -1)
echo "Login CSRF Token: ${LOGIN_TOKEN:0:20}..."

# Step 2: Login
echo -e "\n[2] Efetuando login..."
curl -k -s -c "$COOKIES" -b "$COOKIES" -L \
  -X POST "${ADMIN_URL}/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Referer: ${ADMIN_URL}/login" \
  -d "_token=${LOGIN_TOKEN}&email=admin@prestadores.local&password=AdminSecure123!" \
  > /tmp/login_response.html

# Verify login success
if grep -q "dashboard\|Dashboard\|Sites" /tmp/login_response.html; then
    echo "✅ Login bem-sucedido!"
else
    echo "🔴 Falha no login!"
    exit 1
fi

# Step 3: Get create form
echo -e "\n[3] Acessando formulário de criação de site..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites/create" > /tmp/create_form.html
CREATE_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/create_form.html | head -1)
echo "Create CSRF Token: ${CREATE_TOKEN:0:20}..."

if [ -z "$CREATE_TOKEN" ]; then
    echo "🔴 Não foi possível obter CSRF token do formulário!"
    exit 1
fi

# Step 4: Submit create form
echo -e "\n[4] Submetendo formulário de criação..."
echo "Dados: site_name=testefinal18, domain=testefinal18.local, php_version=8.2"

curl -k -s -b "$COOKIES" -c "$COOKIES" -L -w "\nHTTP_CODE:%{http_code}\n" \
  -X POST "${ADMIN_URL}/sites" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Referer: ${ADMIN_URL}/sites/create" \
  -d "_token=${CREATE_TOKEN}&site_name=testefinal18&domain=testefinal18.local&php_version=8.2&create_database=1" \
  > /tmp/create_response.html

echo ""
cat /tmp/create_response.html | tail -5

# Step 5: Check sites listing
echo -e "\n[5] Verificando listagem de sites..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites" > /tmp/sites_list.html

if grep -iq "testefinal18" /tmp/sites_list.html; then
    echo "✅ SUCESSO! Site 'testefinal18' encontrado na listagem!"
    grep -i "testefinal18" /tmp/sites_list.html | head -3
else
    echo "🔴 FALHOU! Site 'testefinal18' NÃO encontrado na listagem!"
fi

# Step 6: Check response messages
echo -e "\n[6] Verificando mensagens de resposta..."
if grep -iq "success\|successfully\|created" /tmp/create_response.html; then
    echo "✅ Mensagem de sucesso detectada!"
    grep -i "success\|successfully\|created" /tmp/create_response.html | head -2
elif grep -iq "error\|fail\|invalid" /tmp/create_response.html; then
    echo "🔴 Mensagem de erro detectada!"
    grep -i "error\|fail\|invalid" /tmp/create_response.html | head -2
fi

echo -e "\n=========================================="
echo "FIM DO TESTE"
echo "=========================================="
