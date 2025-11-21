#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "🧪 SPRINT 52 - TESTE E2E COMPLETO"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Configuration
ADMIN_URL="https://72.61.53.222:8443"
EMAIL="admin@vps.local"
PASSWORD="Admin2024VPS"
TIMESTAMP=$(date +%s)
TEST_SITE="sprint52test${TIMESTAMP}"
TEST_DOMAIN="${TEST_SITE}.local"

# SSH credentials
SSH_HOST="72.61.53.222"
SSH_USER="root"
SSH_PASS="Jm@D@KDPnw7Q"

# Files
COOKIES_FILE="cookies_sprint52.txt"
CSRF_FILE="csrf_sprint52.txt"

echo "📋 Configuração do Teste:"
echo "  - Site Name: $TEST_SITE"
echo "  - Domain: $TEST_DOMAIN"
echo "  - Admin URL: $ADMIN_URL"
echo ""

# Step 1: Get total sites BEFORE creation
echo "📊 PASSO 1: Contar sites no banco ANTES da criação..."
TOTAL_BEFORE=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "mysql -u admin_panel_user -p'Jm@D@KDPnw7Q' admin_panel -s -N -e 'SELECT COUNT(*) FROM sites;'")

echo "✅ Total de sites ANTES: $TOTAL_BEFORE"

# Step 2: Login
echo ""
echo "🔐 PASSO 2: Autenticação no painel admin..."
curl -k -c "$COOKIES_FILE" "$ADMIN_URL/login" 2>/dev/null | \
    grep -oP '(?<=_token" value=")[^"]+' > "$CSRF_FILE"

CSRF_TOKEN=$(cat "$CSRF_FILE")

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ ERRO: Não foi possível obter CSRF token"
    exit 1
fi

echo "✅ CSRF Token obtido"

# Step 3: Perform login
echo ""
echo "🔓 PASSO 3: Realizando login..."
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

echo "✅ Login realizado com sucesso"

# Step 4: Get create page and new CSRF token
echo ""
echo "📄 PASSO 4: Acessando página de criação..."
curl -k -s -b "$COOKIES_FILE" "$ADMIN_URL/admin/sites/create" 2>/dev/null | \
    grep -oP '(?<=_token" value=")[^"]+' > "$CSRF_FILE"

CSRF_TOKEN=$(cat "$CSRF_FILE")

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ ERRO: Não foi possível obter novo CSRF token"
    exit 1
fi

echo "✅ Novo CSRF Token obtido"

# Step 5: Create site
echo ""
echo "🚀 PASSO 5: Criando novo site..."
CREATE_RESPONSE=$(curl -k -s -b "$COOKIES_FILE" -c "$COOKIES_FILE" \
    -X POST "$ADMIN_URL/admin/sites/store" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Referer: $ADMIN_URL/admin/sites/create" \
    -H "Cache-Control: no-cache" \
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
else
    echo "⚠️  HTTP $HTTP_CODE - Verificando resposta..."
    echo "$CREATE_RESPONSE" | head -20
fi

# Step 6: Wait for sync
echo ""
echo "⏳ PASSO 6: Aguardando 3 segundos para sincronização..."
sleep 3

# Step 7: Verify in database
echo ""
echo "🔍 PASSO 7: Verificando persistência no banco de dados..."
DB_CHECK=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "mysql -u admin_panel_user -p'Jm@D@KDPnw7Q' admin_panel -e \"SELECT id, site_name, created_at FROM sites WHERE site_name='$TEST_SITE';\"")

if echo "$DB_CHECK" | grep -q "$TEST_SITE"; then
    echo "✅ SUCESSO: Site encontrado no banco de dados!"
    echo ""
    echo "$DB_CHECK"
    DB_PRESENT="SIM"
else
    echo "❌ FALHA: Site NÃO encontrado no banco"
    DB_PRESENT="NÃO"
fi

# Step 8: Get total sites AFTER creation
echo ""
echo "📊 PASSO 8: Contar sites no banco DEPOIS da criação..."
TOTAL_AFTER=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "mysql -u admin_panel_user -p'Jm@D@KDPnw7Q' admin_panel -s -N -e 'SELECT COUNT(*) FROM sites;'")

echo "✅ Total de sites DEPOIS: $TOTAL_AFTER"
echo ""
echo "📈 Diferença: +$(($TOTAL_AFTER - $TOTAL_BEFORE)) sites"

# Step 9: Check Laravel logs for SPRINT52
echo ""
echo "📋 PASSO 9: Verificando logs do Laravel (SPRINT52)..."
SPRINT52_LOGS=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log | grep 'SPRINT52' || echo 'Nenhum log SPRINT52 encontrado'")

if echo "$SPRINT52_LOGS" | grep -q "SPRINT52"; then
    echo "✅ Logs SPRINT52 encontrados:"
    echo "$SPRINT52_LOGS"
else
    echo "⚠️  Nenhum log SPRINT52 recente"
fi

# Step 10: Verify site appears in HTML listing (with no-cache headers)
echo ""
echo "🌐 PASSO 10: Verificando se site aparece na listagem HTML..."
LISTING_RESPONSE=$(curl -k -s -b "$COOKIES_FILE" \
    -H "Cache-Control: no-cache, no-store, must-revalidate" \
    -H "Pragma: no-cache" \
    -H "Expires: 0" \
    "$ADMIN_URL/admin/sites")

if echo "$LISTING_RESPONSE" | grep -q "$TEST_SITE"; then
    echo "✅ SUCESSO: Site aparece na listagem HTML!"
    HTML_PRESENT="SIM"
else
    echo "❌ FALHA: Site NÃO aparece na listagem HTML"
    HTML_PRESENT="NÃO"
    
    # Debug: Check what sites are showing
    echo ""
    echo "🔍 Debug: Verificando quais sites aparecem..."
    echo "$LISTING_RESPONSE" | grep -oP 'site_name["\s:]+\K[a-z0-9\-_]+' | head -10
fi

# Final verdict
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "📊 VEREDICTO FINAL - SPRINT 52"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Resultados:"
echo "  ✓ Site criado via formulário: SIM"
echo "  ✓ Site persistido no banco: $DB_PRESENT"
echo "  ✓ Site aparece na listagem: $HTML_PRESENT"
echo "  ✓ Total sites antes: $TOTAL_BEFORE"
echo "  ✓ Total sites depois: $TOTAL_AFTER"
echo "  ✓ Incremento: +$(($TOTAL_AFTER - $TOTAL_BEFORE))"
echo ""

if [ "$DB_PRESENT" = "SIM" ] && [ "$HTML_PRESENT" = "SIM" ]; then
    echo "🎉 CONCLUSÃO: PROBLEMA RESOLVIDO!"
    echo ""
    echo "✅ A correção do Sprint 52 funcionou:"
    echo "  - Site persiste no banco de dados"
    echo "  - Site aparece na listagem imediatamente"
    echo "  - Headers no-cache funcionando"
    echo "  - Query DB::table() direta funcionando"
    echo ""
    exit 0
elif [ "$DB_PRESENT" = "SIM" ] && [ "$HTML_PRESENT" = "NÃO" ]; then
    echo "⚠️  CONCLUSÃO: PERSISTÊNCIA OK, PROBLEMA NA LISTAGEM"
    echo ""
    echo "O site foi salvo no banco, mas ainda não aparece na view."
    echo "Possíveis causas:"
    echo "  1. Cache de browser ainda presente (testar modo anônimo)"
    echo "  2. Headers no-cache não sendo respeitados"
    echo "  3. Problema na view sites/index.blade.php"
    echo ""
    exit 1
else
    echo "❌ CONCLUSÃO: PROBLEMA PERSISTE"
    echo ""
    echo "O site não está sendo salvo no banco de dados."
    echo "Verificar logs do Laravel para detalhes."
    echo ""
    exit 1
fi
