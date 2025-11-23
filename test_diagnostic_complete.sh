#!/bin/bash
################################################################################
# TESTE DIAGNÓSTICO COMPLETO - Sistema VPS Admin
# Verifica se problema é cache, código ou configuração
################################################################################

set -e

echo "=========================================="
echo "TESTE DIAGNÓSTICO COMPLETO"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variáveis
SERVER="72.61.53.222"
PASSWORD="Jm@D@KDPnw7Q"
APP_PATH="/opt/webserver/admin-panel"

echo "🔍 FASE 1: Verificar estado do banco de dados"
echo "----------------------------------------------"

# Contar sites no DB
SITE_COUNT=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
    "mysql -u root -p'$PASSWORD' admin_panel -sN -e 'SELECT COUNT(*) FROM sites;'" 2>/dev/null)

echo "✅ Sites no banco de dados: $SITE_COUNT"

# Últimos 5 sites
echo ""
echo "📋 Últimos 5 sites criados:"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
    "mysql -u root -p'$PASSWORD' admin_panel -e 'SELECT id, site_name, created_at FROM sites ORDER BY created_at DESC LIMIT 5;'" 2>/dev/null

echo ""
echo "🔍 FASE 2: Testar query Eloquent via Tinker"
echo "----------------------------------------------"

# Testar via Tinker
TINKER_COUNT=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
    "cd $APP_PATH && php artisan tinker --execute='echo App\Models\Site::count();'" 2>/dev/null | tail -1)

echo "✅ Sites via Tinker: $TINKER_COUNT"

if [ "$SITE_COUNT" == "$TINKER_COUNT" ]; then
    echo -e "${GREEN}✅ CONSISTENTE: DB e Eloquent retornam mesma contagem${NC}"
else
    echo -e "${RED}❌ INCONSISTENTE: DB=$SITE_COUNT, Eloquent=$TINKER_COUNT${NC}"
fi

echo ""
echo "🔍 FASE 3: Verificar estado dos caches Laravel"
echo "----------------------------------------------"

# Verificar arquivos de cache
echo "Cache config:"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
    "ls -lh $APP_PATH/bootstrap/cache/*.php 2>/dev/null | wc -l || echo '0'" 2>/dev/null

echo "Cache views compiladas:"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
    "ls -1 $APP_PATH/storage/framework/views/*.php 2>/dev/null | wc -l || echo '0'" 2>/dev/null

echo "Cache application:"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
    "ls -1 $APP_PATH/storage/framework/cache/data/*/* 2>/dev/null | wc -l || echo '0'" 2>/dev/null

echo ""
echo "🔍 FASE 4: Testar controller diretamente"
echo "----------------------------------------------"

# Criar site de teste via curl (simulando browser)
TEST_SITE="diagnostic$(date +%s)"
echo "Criando site de teste: $TEST_SITE"

# Login e get CSRF token
COOKIES="/tmp/test_cookies_$$.txt"
CSRF_TOKEN=$(curl -sk -c $COOKIES "http://$SERVER/admin/login" 2>/dev/null | grep -oP 'name="_token" value="\K[^"]+' | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    echo -e "${RED}❌ Falha ao obter CSRF token${NC}"
    exit 1
fi

echo "✅ CSRF token obtido"

# Login
curl -sk -b $COOKIES -c $COOKIES -X POST "http://$SERVER/admin/login" \
    -d "_token=$CSRF_TOKEN" \
    -d "email=admin@admin.com" \
    -d "password=admin123" \
    > /dev/null 2>&1

echo "✅ Login realizado"

# Get new CSRF for sites page
CSRF_CREATE=$(curl -sk -b $COOKIES "http://$SERVER/admin/sites/create" 2>/dev/null | grep -oP 'name="_token" value="\K[^"]+' | head -1)

echo "✅ CSRF create obtido"

# Contar sites ANTES da criação
COUNT_BEFORE=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
    "mysql -u root -p'$PASSWORD' admin_panel -sN -e 'SELECT COUNT(*) FROM sites;'" 2>/dev/null)

echo "Sites ANTES: $COUNT_BEFORE"

# Criar site
curl -sk -b $COOKIES -X POST "http://$SERVER/admin/sites" \
    -d "_token=$CSRF_CREATE" \
    -d "site_name=$TEST_SITE" \
    -d "domain=${TEST_SITE}.test" \
    -d "php_version=8.3" \
    -d "create_database=1" \
    -d "template=php" \
    > /dev/null 2>&1

sleep 2

# Contar sites DEPOIS da criação
COUNT_AFTER=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
    "mysql -u root -p'$PASSWORD' admin_panel -sN -e 'SELECT COUNT(*) FROM sites;'" 2>/dev/null)

echo "Sites DEPOIS: $COUNT_AFTER"

if [ "$COUNT_AFTER" -gt "$COUNT_BEFORE" ]; then
    echo -e "${GREEN}✅ Site criado com sucesso no banco${NC}"
    
    # Verificar se aparece via Tinker
    TINKER_HAS_SITE=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
        "cd $APP_PATH && php artisan tinker --execute='echo App\Models\Site::where(\"site_name\", \"$TEST_SITE\")->exists() ? \"YES\" : \"NO\";'" 2>/dev/null | tail -1)
    
    if [ "$TINKER_HAS_SITE" == "YES" ]; then
        echo -e "${GREEN}✅ Site aparece via Tinker/Eloquent${NC}"
    else
        echo -e "${RED}❌ Site NÃO aparece via Tinker/Eloquent${NC}"
    fi
else
    echo -e "${RED}❌ Site NÃO foi criado no banco${NC}"
fi

# Cleanup
rm -f $COOKIES

echo ""
echo "🔍 FASE 5: Verificar logs recentes"
echo "----------------------------------------------"

echo "Últimas entradas do log Laravel:"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER \
    "tail -20 $APP_PATH/storage/logs/laravel.log | grep -E '(SPRINT55|Site|ERROR)' || echo 'Nenhum erro recente'" 2>/dev/null

echo ""
echo "=========================================="
echo "DIAGNÓSTICO COMPLETO"
echo "=========================================="
echo ""
echo "RESUMO:"
echo "- Sites no DB: $COUNT_AFTER"
echo "- Sites via Eloquent: $TINKER_COUNT"
echo "- Site de teste criado: $([ "$COUNT_AFTER" -gt "$COUNT_BEFORE" ] && echo 'SIM' || echo 'NÃO')"
echo ""

if [ "$COUNT_AFTER" -gt "$COUNT_BEFORE" ] && [ "$TINKER_HAS_SITE" == "YES" ]; then
    echo -e "${GREEN}✅ CONCLUSÃO: Controller e Model funcionando PERFEITAMENTE${NC}"
    echo -e "${YELLOW}⚠️  Se sites não aparecem na UI web, problema é CACHE DE VIEW ou BROWSER${NC}"
    exit 0
else
    echo -e "${RED}❌ CONCLUSÃO: Problema no controller ou model${NC}"
    exit 1
fi
