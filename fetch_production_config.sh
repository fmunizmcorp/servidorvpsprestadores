#!/bin/bash

# ============================================================================
# FETCH PRODUCTION CONFIGURATION FOR INVESTIGATION
# ============================================================================
# Purpose: Download key Laravel configuration files to investigate why
#          requests don't reach SitesController
# ============================================================================

set -e

SERVER="72.61.53.222"
USER="root"
export SSHPASS="mcorpapp"

echo "=================================================="
echo " FETCHING PRODUCTION CONFIGURATION FILES"
echo "=================================================="
echo ""

# Create local directory for production files
mkdir -p production_config
cd production_config

echo "📥 Downloading routes/web.php..."
sshpass -e scp -o StrictHostKeyChecking=no $USER@$SERVER:/opt/webserver/admin-panel/routes/web.php ./web.php 2>&1

echo "📥 Downloading app/Http/Kernel.php..."
sshpass -e scp -o StrictHostKeyChecking=no $USER@$SERVER:/opt/webserver/admin-panel/app/Http/Kernel.php ./Kernel.php 2>&1

echo "📥 Downloading app/Http/Middleware/VerifyCsrfToken.php..."
sshpass -e scp -o StrictHostKeyChecking=no $USER@$SERVER:/opt/webserver/admin-panel/app/Http/Middleware/VerifyCsrfToken.php ./VerifyCsrfToken.php 2>&1

echo "📥 Downloading config/session.php..."
sshpass -e scp -o StrictHostKeyChecking=no $USER@$SERVER:/opt/webserver/admin-panel/config/session.php ./session.php 2>&1

echo "📥 Downloading bootstrap/app.php..."
sshpass -e scp -o StrictHostKeyChecking=no $USER@$SERVER:/opt/webserver/admin-panel/bootstrap/app.php ./app.php 2>&1

echo "📥 Downloading current SitesController.php..."
sshpass -e scp -o StrictHostKeyChecking=no $USER@$SERVER:/opt/webserver/admin-panel/app/Http/Controllers/SitesController.php ./SitesController_current.php 2>&1

echo ""
echo "✅ Files downloaded to production_config/"
echo ""
echo "📋 Getting Laravel route list..."
sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH' > route_list.txt 2>&1
cd /opt/webserver/admin-panel
php artisan route:list | grep -E "(sites|POST)"
ENDSSH

echo "✅ Route list saved to route_list.txt"
echo ""
echo "📋 Getting last 100 lines of Laravel log..."
sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH' > laravel_log.txt 2>&1
tail -100 /opt/webserver/admin-panel/storage/logs/laravel.log
ENDSSH

echo "✅ Laravel log saved to laravel_log.txt"
echo ""
echo "📋 Checking NGINX configuration..."
sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH' > nginx_config.txt 2>&1
cat /etc/nginx/sites-enabled/admin-panel
ENDSSH

echo "✅ NGINX config saved to nginx_config.txt"
echo ""
echo "📋 Checking PHP-FPM pool configuration..."
sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH' > phpfpm_pool.txt 2>&1
cat /etc/php/8.3/fpm/pool.d/admin-panel.conf 2>/dev/null || echo "Pool config not found"
ENDSSH

echo "✅ PHP-FPM pool config saved to phpfpm_pool.txt"
echo ""
echo "=================================================="
echo " ✅ ALL CONFIGURATION FILES FETCHED"
echo "=================================================="
echo ""
echo "Downloaded files:"
ls -lh
echo ""
echo "Now analyze these files to find why POST /sites doesn't reach controller"
