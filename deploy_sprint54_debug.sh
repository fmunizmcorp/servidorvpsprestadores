#!/bin/bash
# Deploy Sprint 54 - Debug version para encontrar causa raiz
# Data: 2025-11-22

set -e

echo "========================================="
echo " SPRINT 54 - DEBUG DEPLOYMENT"
echo "========================================="

# Variáveis
SERVER="72.61.53.222"
USER="root"
PASS="Jm@D@KDPnw7Q"
REMOTE_PATH="/opt/webserver/admin-panel/app/Http/Controllers"
LOCAL_FILE="SitesController.php"

echo ""
echo "📦 [1/6] Fazendo backup da versão atual..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "cp $REMOTE_PATH/SitesController.php $REMOTE_PATH/SitesController.php.backup-sprint54-debug"
echo "✅ Backup criado: SitesController.php.backup-sprint54-debug"

echo ""
echo "🚀 [2/6] Enviando nova versão com DEBUG..."
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
  "$LOCAL_FILE" \
  $USER@$SERVER:$REMOTE_PATH/
echo "✅ Arquivo enviado"

echo ""
echo "🧹 [3/6] Limpando TODOS os caches Laravel..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel

# Limpar caches Laravel
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
php artisan clear-compiled

# Limpar cache compilado de views manualmente
rm -rf storage/framework/views/*

# Criar novo autoload otimizado
composer dump-autoload --optimize 2>/dev/null || echo "Composer dump-autoload skipped"

echo "✅ Caches limpos"
ENDSSH

echo ""
echo "🔄 [4/6] Reiniciando PHP-FPM..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "systemctl restart php8.3-fpm"
echo "✅ PHP-FPM reiniciado"

echo ""
echo "🔍 [5/6] Verificando deployment..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "md5sum $REMOTE_PATH/SitesController.php"

echo ""
echo "📊 [6/6] Verificando logs antes do teste..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "tail -n 5 /opt/webserver/admin-panel/storage/logs/laravel.log"

echo ""
echo "========================================="
echo "✅ DEPLOYMENT CONCLUÍDO"
echo "========================================="
echo ""
echo "🧪 PRÓXIMOS PASSOS:"
echo "1. Acesse: http://72.61.53.222/admin/sites"
echo "2. Verifique os logs: tail -f /opt/webserver/admin-panel/storage/logs/laravel.log"
echo "3. Analise o output de DEBUG no log"
echo ""
echo "Para ver logs em tempo real:"
echo "  ssh root@72.61.53.222"
echo "  tail -f /opt/webserver/admin-panel/storage/logs/laravel.log"
echo ""
