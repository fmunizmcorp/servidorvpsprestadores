#!/bin/bash
# Deploy Sprint 55 FINAL - Correção definitiva: Browser Cache Headers

set -e

SERVER="72.61.53.222"
USER="root"
PASS="Jm@D@KDPnw7Q"
REMOTE_PATH="/opt/webserver/admin-panel/app/Http/Controllers"

echo "========================================="
echo " SPRINT 55 - FINAL FIX DEPLOYMENT"
echo "========================================="
echo ""
echo "CORREÇÃO: Adicionar headers no-cache explícitos"
echo "- Cache-Control: no-cache, no-store, must-revalidate"
echo "- Pragma: no-cache"
echo "- Expires: 0"
echo ""

echo "📦 [1/6] Backup..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "cp $REMOTE_PATH/SitesController.php $REMOTE_PATH/SitesController.php.backup-sprint55-final"
echo "✅ Backup criado"

echo ""
echo "🚀 [2/6] Deploy versão final..."
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
  SitesController.php \
  $USER@$SERVER:$REMOTE_PATH/
echo "✅ Enviado"

echo ""
echo "🧹 [3/6] Limpando TODOS os caches..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel
php artisan optimize:clear
rm -rf storage/framework/views/*
rm -rf storage/framework/cache/*
echo "✅ Caches Laravel limpos"
ENDSSH

echo ""
echo "🔄 [4/6] Restart PHP-FPM..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "systemctl restart php8.3-fpm"
echo "✅ PHP-FPM reiniciado"

echo ""
echo "🌐 [5/6] Reload NGINX..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "nginx -s reload"
echo "✅ NGINX reloaded"

echo ""
echo "🧪 [6/6] Teste de verificação..."
TEST_OUTPUT=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "cd /opt/webserver/admin-panel && php artisan tinker --execute='
    \$sites = App\\Models\\Site::count();
    echo \"Total sites no banco: \$sites\";
'" 2>&1 | tail -1)

echo "$TEST_OUTPUT"

echo ""
echo "========================================="
echo "✅ DEPLOYMENT CONCLUÍDO COM SUCESSO"
echo "========================================="
echo ""
echo "📊 CORREÇÃO IMPLEMENTADA:"
echo "   - Headers no-cache explícitos no index()"
echo "   - Logging intensivo no store()"
echo "   - Melhor validação de sucesso do script shell"
echo ""
echo "🧪 PRÓXIMO PASSO:"
echo "   Testar via navegador com CTRL+F5 (hard refresh)"
echo "   URL: https://72.61.53.222/admin/sites"
echo ""
echo "Sites esperados: 43"
echo "Último site: sprint55webtest1763808002"
echo ""
