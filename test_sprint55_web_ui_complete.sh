#!/bin/bash
# Sprint 55 - Teste COMPLETO via Web UI (Simulando QA)
# Objetivo: Reproduzir EXATAMENTE o que o QA fez

set -e

SERVER="72.61.53.222"
BASE_URL="http://$SERVER"
ADMIN_URL="$BASE_URL/admin"

echo "========================================="
echo " SPRINT 55 - TESTE WEB UI COMPLETO"
echo " (Simulando protocolo QA)"
echo "========================================="
echo ""

TIMESTAMP=$(date +%s)
TEST_SITE="qasimulation$TIMESTAMP"
TEST_DOMAIN="qasimulation.com"

echo "📝 Site de teste: $TEST_SITE"
echo "📝 Domain: $TEST_DOMAIN"
echo ""

# ====================
# 1. LOGIN
# ====================
echo "[1/6] Fazendo login no painel..."
curl -s -c cookies_sprint55.txt -b cookies_sprint55.txt \
  "$ADMIN_URL/login" > /dev/null

CSRF_TOKEN=$(curl -s -b cookies_sprint55.txt "$ADMIN_URL/login" | \
  grep -oP 'name="_token" value="\K[^"]+' | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ ERRO: Não conseguiu obter CSRF token"
    exit 1
fi

curl -s -X POST -b cookies_sprint55.txt -c cookies_sprint55.txt \
  "$ADMIN_URL/login" \
  -d "email=admin@admin.com" \
  -d "password=admin123" \
  -d "_token=$CSRF_TOKEN" \
  -L > /dev/null

echo "✅ Login realizado"
echo ""

# ====================
# 2. ACESSAR LISTAGEM ANTES
# ====================
echo "[2/6] Acessando listagem ANTES da criação..."
BEFORE_HTML=$(curl -s -b cookies_sprint55.txt "$ADMIN_URL/sites")

BEFORE_COUNT=$(echo "$BEFORE_HTML" | grep -o '<tr>' | wc -l)
echo "✅ Sites visíveis ANTES: $BEFORE_COUNT linhas <tr>"
echo ""

# ====================
# 3. OBTER CSRF PARA CRIAÇÃO
# ====================
echo "[3/6] Obtendo CSRF token para criação..."
CREATE_PAGE=$(curl -s -b cookies_sprint55.txt "$ADMIN_URL/sites/create")
CREATE_CSRF=$(echo "$CREATE_PAGE" | grep -oP 'name="_token" value="\K[^"]+' | head -1)

if [ -z "$CREATE_CSRF" ]; then
    echo "❌ ERRO: Não conseguiu obter CSRF token da página de criação"
    exit 1
fi

echo "✅ CSRF obtido: ${CREATE_CSRF:0:20}..."
echo ""

# ====================
# 4. CRIAR SITE VIA POST
# ====================
echo "[4/6] Criando site via POST (simulando formulário)..."
CREATE_RESPONSE=$(curl -s -X POST -b cookies_sprint55.txt -c cookies_sprint55.txt \
  "$ADMIN_URL/sites" \
  -d "site_name=$TEST_SITE" \
  -d "domain=$TEST_DOMAIN" \
  -d "php_version=8.3" \
  -d "template=php" \
  -d "create_database=1" \
  -d "_token=$CREATE_CSRF" \
  -L -w "\nHTTP_CODE:%{http_code}\n")

HTTP_CODE=$(echo "$CREATE_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ ERRO: HTTP $HTTP_CODE"
    echo "$CREATE_RESPONSE" | head -50
    exit 1
fi

echo "✅ Requisição HTTP 200 OK"

# Verificar se foi redirecionado para listagem
if echo "$CREATE_RESPONSE" | grep -q "Sites Management"; then
    echo "✅ Redirecionado para página de listagem"
else
    echo "⚠️  AVISO: Pode não ter redirecionado corretamente"
fi
echo ""

# ====================
# 5. AGUARDAR E RECARREGAR
# ====================
echo "[5/6] Aguardando 3 segundos e recarregando listagem..."
sleep 3

AFTER_HTML=$(curl -s -b cookies_sprint55.txt "$ADMIN_URL/sites")
AFTER_COUNT=$(echo "$AFTER_HTML" | grep -o '<tr>' | wc -l)

echo "✅ Sites visíveis DEPOIS: $AFTER_COUNT linhas <tr>"
echo ""

# ====================
# 6. VERIFICAR SE APARECE
# ====================
echo "[6/6] Verificando se site '$TEST_SITE' aparece na listagem..."

if echo "$AFTER_HTML" | grep -q "$TEST_SITE"; then
    echo "✅ SUCESSO: Site '$TEST_SITE' FOI ENCONTRADO na listagem HTML!"
else
    echo "❌ FALHA: Site '$TEST_SITE' NÃO FOI ENCONTRADO na listagem HTML!"
    echo ""
    echo "Verificando no banco de dados..."
    ssh root@$SERVER "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e \"SELECT id, site_name, created_at FROM sites WHERE site_name='$TEST_SITE';\""
fi

echo ""
echo "========================================="
echo " RESULTADO DO TESTE"
echo "========================================="
echo ""
echo "Sites ANTES:  $BEFORE_COUNT linhas"
echo "Sites DEPOIS: $AFTER_COUNT linhas"
echo "Diferença:    $((AFTER_COUNT - BEFORE_COUNT)) linhas"
echo ""

if echo "$AFTER_HTML" | grep -q "$TEST_SITE"; then
    echo "✅ TESTE PASSOU: Site aparece na listagem web"
    exit 0
else
    echo "❌ TESTE FALHOU: Site NÃO aparece na listagem web"
    exit 1
fi
