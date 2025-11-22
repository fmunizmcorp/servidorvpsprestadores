#!/bin/bash
# Sprint 54 - Teste E2E Completo para Validação
# Testa criação de site e verificação de listagem

set -e

SSH_USER="root"
SSH_HOST="72.61.53.222"
SSH_PASS="Jm@D@KDPnw7Q"

echo "========================================="
echo " SPRINT 54 - TESTE E2E COMPLETO"
echo "========================================="
echo ""

# Gerar timestamp único
TIMESTAMP=$(date +%s)
TEST_SITE="sprint54validation$TIMESTAMP"
TEST_DOMAIN="sprint54validation.com"

echo "📝 Site de teste: $TEST_SITE"
echo "📝 Domain: $TEST_DOMAIN"
echo ""

# ====================
# 1. CONTAR SITES ANTES
# ====================
echo "[1/5] Contando sites antes da criação..."
BEFORE_COUNT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
  "cd /opt/webserver/admin-panel && php artisan tinker --execute='echo App\\Models\\Site::count();'")
echo "✅ Sites no banco ANTES: $BEFORE_COUNT"
echo ""

# ====================
# 2. CRIAR NOVO SITE
# ====================
echo "[2/5] Criando novo site via script shell..."
CREATE_OUTPUT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
  "sudo /opt/webserver/scripts/wrappers/create-site-wrapper.sh $TEST_SITE $TEST_DOMAIN 8.3 --template=php 2>&1")

if echo "$CREATE_OUTPUT" | grep -q "successfully"; then
    echo "✅ Site criado com sucesso via script shell"
else
    echo "❌ ERRO ao criar site via script shell:"
    echo "$CREATE_OUTPUT"
    exit 1
fi
echo ""

# ====================
# 3. PERSISTIR NO BANCO
# ====================
echo "[3/5] Persistindo site no banco de dados..."
PERSIST_OUTPUT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
  "cd /opt/webserver/admin-panel && php artisan tinker --execute='
    \$site = App\\Models\\Site::create([
        \"site_name\" => \"$TEST_SITE\",
        \"domain\" => \"$TEST_DOMAIN\",
        \"php_version\" => \"8.3\",
        \"has_database\" => true,
        \"database_name\" => \"${TEST_SITE}_db\",
        \"database_user\" => \"${TEST_SITE}_user\",
        \"template\" => \"php\",
        \"status\" => \"active\",
    ]);
    echo \"Site persisted with ID: \" . \$site->id;
'" 2>&1)

echo "$PERSIST_OUTPUT"
echo "✅ Site persistido no banco"
echo ""

# ====================
# 4. VERIFICAR CONTAGEM DEPOIS
# ====================
echo "[4/5] Contando sites após a criação..."
AFTER_COUNT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
  "cd /opt/webserver/admin-panel && php artisan tinker --execute='echo App\\Models\\Site::count();'")
echo "✅ Sites no banco DEPOIS: $AFTER_COUNT"
echo ""

# ====================
# 5. VERIFICAR SE APARECE NA QUERY
# ====================
echo "[5/5] Verificando se site aparece na query do controller..."
QUERY_OUTPUT=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
  "cd /opt/webserver/admin-panel && php artisan tinker --execute='
    \$sites = App\\Models\\Site::orderBy(\"created_at\", \"desc\")->get();
    echo \"Total: \" . \$sites->count() . \"\\n\";
    echo \"First: \" . \$sites->first()->site_name . \"\\n\";
    echo \"Contains test site: \" . (\$sites->where(\"site_name\", \"$TEST_SITE\")->count() > 0 ? \"YES\" : \"NO\");
'" 2>&1)

echo "$QUERY_OUTPUT"
echo ""

# ====================
# RESULTADO
# ====================
echo "========================================="
echo " RESULTADO DO TESTE"
echo "========================================="
echo ""
echo "Sites ANTES:  $BEFORE_COUNT"
echo "Sites DEPOIS: $AFTER_COUNT"
echo ""

if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
    echo "✅ SUCESSO: Contagem aumentou ($BEFORE_COUNT → $AFTER_COUNT)"
else
    echo "❌ FALHA: Contagem não aumentou"
    exit 1
fi

if echo "$QUERY_OUTPUT" | grep -q "Contains test site: YES"; then
    echo "✅ SUCESSO: Site aparece na query do controller"
else
    echo "❌ FALHA: Site NÃO aparece na query do controller"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ TESTE E2E PASSOU!"
echo "========================================="
echo ""
echo "Próximo passo: Acessar http://72.61.53.222/admin/sites"
echo "e verificar se o site '$TEST_SITE' aparece na listagem web"
echo ""
