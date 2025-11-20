#!/bin/bash

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="cookies_correct.txt"
rm -f "$COOKIES"

echo "=========================================="
echo "TESTE CREATE SITE - CREDENCIAIS CORRETAS"
echo "=========================================="

# Step 1: Get login page
echo -e "\n[1] Obtendo página de login..."
curl -k -s -c "$COOKIES" "${ADMIN_URL}/login" > /tmp/login.html
TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/login.html | head -1)
echo "CSRF Token: ${TOKEN:0:20}..."

# Step 2: Login with correct credentials
echo -e "\n[2] Login com admin@vps.local..."
curl -k -s -c "$COOKIES" -b "$COOKIES" -L \
  -X POST "${ADMIN_URL}/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=${TOKEN}&email=admin@vps.local&password=Admin123!@#" \
  > /tmp/dashboard.html

if grep -q "Dashboard\|Sites" /tmp/dashboard.html; then
    echo "✅ Login bem-sucedido!"
else
    echo "🔴 Falha no login!"
    echo "Tentando admin@localhost..."
    
    # Try admin@localhost
    curl -k -s -c "$COOKIES" "${ADMIN_URL}/login" > /tmp/login2.html
    TOKEN2=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/login2.html | head -1)
    
    curl -k -s -c "$COOKIES" -b "$COOKIES" -L \
      -X POST "${ADMIN_URL}/login" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "_token=${TOKEN2}&email=admin@localhost&password=Admin123!@#" \
      > /tmp/dashboard2.html
      
    if grep -q "Dashboard\|Sites" /tmp/dashboard2.html; then
        echo "✅ Login com admin@localhost bem-sucedido!"
    else
        echo "🔴 Ambos os logins falharam!"
        exit 1
    fi
fi

# Step 3: Get create form
echo -e "\n[3] Acessando formulário de criação..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites/create" > /tmp/create.html
CREATE_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/create.html | head -1)
echo "Create Token: ${CREATE_TOKEN:0:20}..."

# Verify form has correct field names
if grep -q 'name="site_name"' /tmp/create.html; then
    echo "✅ Formulário tem campo site_name (correto!)"
else
    echo "🔴 Formulário ainda tem campo siteName (errado!)"
fi

# Step 4: Submit form
echo -e "\n[4] Submetendo formulário..."
echo "Dados: site_name=sitefinalsprint18, domain=sitefinalsprint18.local, php_version=8.3"

curl -k -s -b "$COOKIES" -L -w "\nHTTP:%{http_code}\n" \
  -X POST "${ADMIN_URL}/sites" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Referer: ${ADMIN_URL}/sites/create" \
  -d "_token=${CREATE_TOKEN}&site_name=sitefinalsprint18&domain=sitefinalsprint18.local&php_version=8.3&create_database=1" \
  > /tmp/result.html

cat /tmp/result.html | tail -10

# Step 5: Check listing
echo -e "\n[5] Verificando listagem..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites" > /tmp/list.html

if grep -iq "sitefinalsprint18" /tmp/list.html; then
    echo "✅ SUCESSO! Site encontrado na listagem!"
else
    echo "🔴 Site NÃO encontrado na listagem"
fi

echo -e "\n=========================================="
