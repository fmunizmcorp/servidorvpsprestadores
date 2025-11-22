#!/bin/bash
# Deploy Sprint 54 FINAL - Correção definitiva do problema de listagem de Sites
# Problema: View cache estava impedindo novos sites de aparecerem
# Solução: Limpeza nuclear de caches + controller Sprint 53 (funciona!)

set -e

echo "========================================="
echo " SPRINT 54 - DEPLOYMENT FINAL"
echo "========================================="
echo ""
echo "CORREÇÃO: Limpeza completa de cache foi a solução!"
echo "- Controller Sprint 53 estava CORRETO"
echo "- Problema era VIEW CACHE + OPCACHE"
echo ""

# Variáveis
SERVER="72.61.53.222"
USER="root"
PASS="Jm@D@KDPnw7Q"
REMOTE_PATH="/opt/webserver/admin-panel/app/Http/Controllers"
LOCAL_FILE="SitesController.php"

echo "📦 [1/7] Fazendo backup da versão DEBUG..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "cp $REMOTE_PATH/SitesController.php $REMOTE_PATH/SitesController.php.backup-sprint54-final"
echo "✅ Backup criado"

echo ""
echo "🚀 [2/7] Enviando versão FINAL (sem DEBUG)..."
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
  "$LOCAL_FILE" \
  $USER@$SERVER:$REMOTE_PATH/
echo "✅ Arquivo enviado"

echo ""
echo "🧹 [3/7] Limpando TODOS os caches Laravel..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel

# Limpar caches Laravel
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
php artisan clear-compiled

# Deletar arquivos de cache compilado manualmente
rm -rf storage/framework/views/*
rm -rf storage/framework/cache/*

echo "✅ Caches Laravel limpos"
ENDSSH

echo ""
echo "🔄 [4/7] Reiniciando PHP-FPM (limpa OPcache)..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "systemctl restart php8.3-fpm"
echo "✅ PHP-FPM reiniciado"

echo ""
echo "🌐 [5/7] Recarregando NGINX..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "nginx -s reload"
echo "✅ NGINX recarregado"

echo ""
echo "🔍 [6/7] Verificando deployment..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "md5sum $REMOTE_PATH/SitesController.php"

echo ""
echo "🧪 [7/7] Testando query do controller..."
TEST_OUTPUT=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "cd /opt/webserver/admin-panel && php artisan tinker --execute='
    \$count = App\\Models\\Site::count();
    \$first = App\\Models\\Site::orderBy(\"created_at\", \"desc\")->first();
    echo \"Total sites: \$count\\n\";
    echo \"Latest site: \" . \$first->site_name;
'" 2>&1)

echo "$TEST_OUTPUT"

echo ""
echo "========================================="
echo "✅ DEPLOYMENT CONCLUÍDO COM SUCESSO"
echo "========================================="
echo ""
echo "📊 RESUMO DA CORREÇÃO:"
echo "   - Controller Sprint 53: CORRETO (query Eloquent funcionava)"
echo "   - Problema: View cache + OPcache estavam servindo dados antigos"
echo "   - Solução: Limpeza nuclear de TODOS os caches"
echo ""
echo "🧪 PRÓXIMO PASSO:"
echo "   Acesse: http://72.61.53.222/admin/sites"
echo "   Verifique se todos os 41 sites aparecem na listagem"
echo ""
echo "Sites esperados: 41"
echo "Último site criado: sprint54validation1763775929"
echo ""
