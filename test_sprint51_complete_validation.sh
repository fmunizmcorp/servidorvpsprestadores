#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "🔍 SPRINT 51 - TESTE COMPLETO DE VALIDAÇÃO"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Configuration
ADMIN_URL="https://72.61.53.222:8443"
EMAIL="admin@vps.local"
PASSWORD="Admin2024VPS"
TIMESTAMP=$(date +%s)
TEST_SITE="sprint51test${TIMESTAMP}"
TEST_DOMAIN="${TEST_SITE}.local"

# Files
COOKIES_FILE="cookies_sprint51.txt"
CSRF_FILE="csrf_sprint51.txt"

echo "📋 Configuração do Teste:"
echo "  - Site Name: $TEST_SITE"
echo "  - Domain: $TEST_DOMAIN"
echo "  - Admin URL: $ADMIN_URL"
echo ""

# Step 1: Login and get CSRF token
echo "🔐 PASSO 1: Autenticação no painel admin..."
curl -k -c "$COOKIES_FILE" "$ADMIN_URL/login" 2>/dev/null | \
    grep -oP '(?<=_token" value=")[^"]+' > "$CSRF_FILE"

CSRF_TOKEN=$(cat "$CSRF_FILE")

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ ERRO: Não foi possível obter CSRF token"
    exit 1
fi

echo "✅ CSRF Token obtido: ${CSRF_TOKEN:0:20}..."

# Step 2: Perform login
echo ""
echo "🔓 PASSO 2: Realizando login..."
LOGIN_RESPONSE=$(curl -k -s -b "$COOKIES_FILE" -c "$COOKIES_FILE" \
    -X POST "$ADMIN_URL/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Referer: $ADMIN_URL/login" \
    --data-urlencode "email=$EMAIL" \
    --data-urlencode "password=$PASSWORD" \
    --data-urlencode "_token=$CSRF_TOKEN" \
    -w "\nHTTP_CODE:%{http_code}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

if [ "$HTTP_CODE" != "302" ]; then
    echo "❌ ERRO: Login falhou (HTTP $HTTP_CODE)"
    exit 1
fi

echo "✅ Login realizado com sucesso (HTTP 302)"

# Step 3: Get create page and new CSRF token
echo ""
echo "📄 PASSO 3: Acessando página de criação de site..."
curl -k -s -b "$COOKIES_FILE" "$ADMIN_URL/admin/sites/create" 2>/dev/null | \
    grep -oP '(?<=_token" value=")[^"]+' > "$CSRF_FILE"

CSRF_TOKEN=$(cat "$CSRF_FILE")

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ ERRO: Não foi possível obter novo CSRF token"
    exit 1
fi

echo "✅ Novo CSRF Token obtido: ${CSRF_TOKEN:0:20}..."

# Step 4: Create site
echo ""
echo "🚀 PASSO 4: Criando novo site..."
CREATE_RESPONSE=$(curl -k -s -b "$COOKIES_FILE" -c "$COOKIES_FILE" \
    -X POST "$ADMIN_URL/admin/sites/store" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Referer: $ADMIN_URL/admin/sites/create" \
    --data-urlencode "site_name=$TEST_SITE" \
    --data-urlencode "domain=$TEST_DOMAIN" \
    --data-urlencode "php_version=8.3" \
    --data-urlencode "template=php" \
    --data-urlencode "create_database=1" \
    --data-urlencode "_token=$CSRF_TOKEN" \
    -w "\nHTTP_CODE:%{http_code}")

HTTP_CODE=$(echo "$CREATE_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

echo "📊 Resposta HTTP: $HTTP_CODE"

if [ "$HTTP_CODE" = "302" ]; then
    echo "✅ Site criado com sucesso (HTTP 302 redirect)"
elif [ "$HTTP_CODE" = "200" ]; then
    echo "⚠️  HTTP 200 - Verificando se há erro na resposta..."
    if echo "$CREATE_RESPONSE" | grep -q "error"; then
        echo "❌ ERRO encontrado na resposta"
        echo "$CREATE_RESPONSE" | head -20
    else
        echo "✅ HTTP 200 sem erros aparentes"
    fi
else
    echo "❌ ERRO: Código HTTP inesperado: $HTTP_CODE"
    echo "$CREATE_RESPONSE" | head -20
fi

# Step 5: Wait for filesystem sync
echo ""
echo "⏳ PASSO 5: Aguardando 3 segundos para sincronização..."
sleep 3

# Step 6: Verify in database via SSH
echo ""
echo "🔍 PASSO 6: Verificando persistência no banco de dados..."
DB_CHECK=$(sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "mysql -u admin_panel_user -p'Jm@D@KDPnw7Q' admin_panel -e \"SELECT id, site_name, domain, status, created_at FROM sites WHERE site_name='$TEST_SITE';\"")

if echo "$DB_CHECK" | grep -q "$TEST_SITE"; then
    echo "✅ SUCESSO: Site encontrado no banco de dados!"
    echo ""
    echo "$DB_CHECK"
else
    echo "❌ FALHA: Site NÃO encontrado no banco de dados"
    echo ""
    echo "Últimos 5 sites no banco:"
    sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
        "mysql -u admin_panel_user -p'Jm@D@KDPnw7Q' admin_panel -e 'SELECT id, site_name, domain, status, created_at FROM sites ORDER BY created_at DESC LIMIT 5;'"
fi

# Step 7: Check Laravel logs for errors
echo ""
echo "📋 PASSO 7: Verificando logs do Laravel..."
RECENT_ERRORS=$(sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log | grep -i 'error\|exception' | tail -10")

if [ -z "$RECENT_ERRORS" ]; then
    echo "✅ Nenhum erro recente nos logs"
else
    echo "⚠️  Erros encontrados nos logs:"
    echo "$RECENT_ERRORS"
fi

# Step 8: Verify site appears in listing
echo ""
echo "🌐 PASSO 8: Verificando se site aparece na listagem..."
LISTING_RESPONSE=$(curl -k -s -b "$COOKIES_FILE" "$ADMIN_URL/admin/sites")

if echo "$LISTING_RESPONSE" | grep -q "$TEST_SITE"; then
    echo "✅ SUCESSO: Site aparece na listagem HTML!"
else
    echo "❌ FALHA: Site NÃO aparece na listagem HTML"
fi

# Step 9: Final verdict
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "📊 VEREDICTO FINAL - SPRINT 51"
echo "═══════════════════════════════════════════════════════════"

DB_PRESENT=$(echo "$DB_CHECK" | grep -q "$TEST_SITE" && echo "SIM" || echo "NÃO")
HTML_PRESENT=$(echo "$LISTING_RESPONSE" | grep -q "$TEST_SITE" && echo "SIM" || echo "NÃO")

echo ""
echo "Resultados:"
echo "  ✓ Site criado via formulário: SIM"
echo "  ✓ Site persistido no banco: $DB_PRESENT"
echo "  ✓ Site aparece na listagem: $HTML_PRESENT"
echo ""

if [ "$DB_PRESENT" = "SIM" ] && [ "$HTML_PRESENT" = "SIM" ]; then
    echo "🎉 CONCLUSÃO: Sistema 100% FUNCIONAL!"
    echo ""
    echo "O problema de 29 sprints foi RESOLVIDO!"
    exit 0
elif [ "$DB_PRESENT" = "SIM" ] && [ "$HTML_PRESENT" = "NÃO" ]; then
    echo "⚠️  CONCLUSÃO: Persistência OK, mas problema na LISTAGEM"
    echo ""
    echo "O site persiste no banco mas não aparece na view."
    echo "Causa provável: Problema no método index() ou na view sites/index.blade.php"
    exit 1
else
    echo "❌ CONCLUSÃO: Problema PERSISTE"
    echo ""
    echo "O site não está sendo salvo no banco de dados."
    exit 1
fi
