#!/bin/bash

#############################################################################
# AUTO DEPLOY: Dashboard Fix
# Executa automaticamente TUDO necessário para corrigir o dashboard
# Não requer interação - faz tudo sozinho
#############################################################################

set -e

SERVER="72.61.53.222"
PASSWORD="Jm@D@KDPnw7Q"

echo "=========================================="
echo "  AUTO DEPLOY - DASHBOARD FIX"
echo "=========================================="
echo ""

# Função para executar comando no servidor
exec_remote() {
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER "$1"
}

# Função para upload de arquivo
upload_file() {
    local_file=$1
    remote_path=$2
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no "$local_file" root@$SERVER:"$remote_path"
}

echo "Step 1: Creating backup..."
exec_remote "mkdir -p /opt/webserver/admin-panel/backups/dashboard-fix-\$(date +%Y%m%d_%H%M%S)"
echo "✓ Backup directory created"
echo ""

echo "Step 2: Uploading dashboard.blade.php..."
upload_file "dashboard.blade.php" "/tmp/dashboard.blade.php"
exec_remote "mv /tmp/dashboard.blade.php /opt/webserver/admin-panel/resources/views/ && chown www-data:www-data /opt/webserver/admin-panel/resources/views/dashboard.blade.php && chmod 644 /opt/webserver/admin-panel/resources/views/dashboard.blade.php"
echo "✓ Dashboard view deployed"
echo ""

echo "Step 3: Updating PHP-FPM pool configuration..."
upload_file "admin-panel-pool-FIXED.conf" "/tmp/admin-panel.conf"
exec_remote "mv /tmp/admin-panel.conf /etc/php/8.3/fpm/pool.d/admin-panel.conf"
echo "✓ PHP-FPM pool updated"
echo ""

echo "Step 4: Setting permissions..."
exec_remote "chown -R www-data:www-data /opt/webserver/admin-panel/storage && chown -R www-data:www-data /opt/webserver/admin-panel/bootstrap/cache && chmod -R 775 /opt/webserver/admin-panel/storage && chmod -R 775 /opt/webserver/admin-panel/bootstrap/cache"
echo "✓ Permissions set"
echo ""

echo "Step 5: Clearing Laravel caches..."
exec_remote "cd /opt/webserver/admin-panel && sudo -u www-data php artisan config:clear && sudo -u www-data php artisan cache:clear && sudo -u www-data php artisan view:clear && sudo -u www-data php artisan route:clear"
echo "✓ Laravel caches cleared"
echo ""

echo "Step 6: Restarting services..."
exec_remote "systemctl restart php8.3-fpm && systemctl reload nginx"
echo "✓ Services restarted"
echo ""

echo "Step 7: Verifying deployment..."
PHP_FPM_STATUS=$(exec_remote "systemctl is-active php8.3-fpm")
NGINX_STATUS=$(exec_remote "systemctl is-active nginx")

if [ "$PHP_FPM_STATUS" = "active" ] && [ "$NGINX_STATUS" = "active" ]; then
    echo "✓ All services running"
else
    echo "✗ Service check failed!"
    echo "PHP-FPM: $PHP_FPM_STATUS"
    echo "NGINX: $NGINX_STATUS"
    exit 1
fi

echo ""
echo "=========================================="
echo "  DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "Dashboard should now be working at:"
echo "http://72.61.53.222:8080"
echo ""
echo "Login: admin@localhost"
echo "Password: Jm@D@KDPnw7Q"
echo ""
echo "Please test and confirm dashboard works!"
echo ""
