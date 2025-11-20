#!/bin/bash

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="cookies_final.txt"
rm -f "$COOKIES"

echo "=========================================="
echo "TESTE FINAL - CREATE SITE SPRINT 18.2"
echo "=========================================="

# Login
echo -e "\n[1] Login..."
curl -k -s -c "$COOKIES" "${ADMIN_URL}/login" > /tmp/l.html
T=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/l.html | head -1)

curl -k -s -c "$COOKIES" -b "$COOKIES" -L \
  -X POST "${ADMIN_URL}/login" \
  -d "_token=$T&email=admin@vps.local&password=VpsAdmin2024!@#$" \
  > /tmp/d.html

if grep -q "Sites" /tmp/d.html; then
    echo "✅ Login OK!"
else
    echo "🔴 Login falhou!"
    exit 1
fi

# Get create form
echo -e "\n[2] Formulário criação..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites/create" > /tmp/c.html
CT=$(grep -oP 'name="_token" value="\K[^"]+' /tmp/c.html | head -1)
echo "Token: ${CT:0:15}..."

# Check field names
if grep -q 'name="site_name"' /tmp/c.html; then
    echo "✅ Campo site_name OK!"
fi

# Submit
echo -e "\n[3] Criando site..."
curl -k -s -b "$COOKIES" -L -w "\nHTTP:%{http_code}\n" \
  -X POST "${ADMIN_URL}/sites" \
  -H "Referer: ${ADMIN_URL}/sites/create" \
  -d "_token=$CT&site_name=sprintteste18&domain=sprintteste18.local&php_version=8.3&create_database=1" \
  > /tmp/r.html

# Check response
if grep -iq "success\|successfully" /tmp/r.html; then
    echo "✅ Resposta contém SUCCESS!"
elif grep -iq "error\|fail" /tmp/r.html; then
    echo "🔴 Resposta contém ERROR!"
    grep -i "error\|fail" /tmp/r.html | head -5
fi

# Check listing
echo -e "\n[4] Verificando listagem..."
curl -k -s -b "$COOKIES" "${ADMIN_URL}/sites" > /tmp/list.html

if grep -iq "sprintteste18" /tmp/list.html; then
    echo "✅ SUCESSO! Site na listagem!"
else
    echo "🔴 Site NÃO está na listagem"
fi

# Check filesystem
echo -e "\n[5] Verificando filesystem VPS..."
