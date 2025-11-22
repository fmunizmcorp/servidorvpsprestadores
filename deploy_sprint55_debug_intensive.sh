#!/bin/bash
# Deploy Sprint 55 - Logging intensivo para descobrir causa raiz

set -e

SERVER="72.61.53.222"
USER="root"
PASS="Jm@D@KDPnw7Q"
REMOTE_PATH="/opt/webserver/admin-panel/app/Http/Controllers"

echo "========================================="
echo " SPRINT 55 - DEBUG INTENSIVE DEPLOYMENT"
echo "========================================="
echo ""

echo "📦 [1/5] Backup..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "cp $REMOTE_PATH/SitesController.php $REMOTE_PATH/SitesController.php.backup-sprint55"
echo "✅ Backup criado"

echo ""
echo "🚀 [2/5] Deploy com logging..."
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
  SitesController.php \
  $USER@$SERVER:$REMOTE_PATH/
echo "✅ Enviado"

echo ""
echo "🧹 [3/5] Limpando caches..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel
php artisan optimize:clear
rm -rf storage/framework/views/*
ENDSSH
echo "✅ Caches limpos"

echo ""
echo "🔄 [4/5] Restart PHP-FPM..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "systemctl restart php8.3-fpm"
echo "✅ Reiniciado"

echo ""
echo "📊 [5/5] Limpar logs antigos..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER \
  "echo '' > /opt/webserver/admin-panel/storage/logs/laravel.log"
echo "✅ Logs limpos"

echo ""
echo "========================================="
echo "✅ DEPLOYMENT CONCLUÍDO"
echo "========================================="
echo ""
echo "Agora teste criando um site via web UI:"
echo "1. Acesse: https://72.61.53.222/admin/sites/create"
echo "2. Preencha formulário e crie site"
echo "3. Veja logs: tail -f /opt/webserver/admin-panel/storage/logs/laravel.log"
echo ""
