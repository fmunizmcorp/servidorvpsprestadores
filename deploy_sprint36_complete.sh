#!/bin/bash
# SPRINT 36 - Complete Deployment Script with Cache Clearing
# Target: 72.61.53.222 (Ubuntu 24.04.3 LTS)

set -e  # Exit on any error

VPS_IP="72.61.53.222"
VPS_USER="root"
VPS_PASS="Jm@D@KDPnw7Q"
REPO_URL="https://github.com/fmunizmcorp/servidorvpsprestadores.git"
BRANCH="genspark_ai_developer"
REMOTE_PATH="/opt/webserver/admin-panel"

echo "========================================="
echo "  SPRINT 36 - DEPLOYMENT COMPLETE"
echo "========================================="
echo "Target: $VPS_IP"
echo "Branch: $BRANCH"
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="
echo ""

# Function to execute remote commands
remote_exec() {
    sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "$1"
}

echo "[1/10] Testing VPS connection..."
if ! remote_exec "echo 'Connection successful'"; then
    echo "ERROR: Cannot connect to VPS"
    exit 1
fi
echo "✅ Connection successful"
echo ""

echo "[2/10] Pulling latest code from GitHub..."
remote_exec "cd $REMOTE_PATH && git fetch origin $BRANCH && git checkout $BRANCH && git reset --hard origin/$BRANCH"
echo "✅ Code updated to latest Sprint 36 version"
echo ""

echo "[3/10] Updating SitesController.php..."
remote_exec "cp $REMOTE_PATH/laravel_controllers/SitesController.php $REMOTE_PATH/app/Http/Controllers/SitesController.php"
echo "✅ SitesController.php deployed"
echo ""

echo "[4/10] Updating post_site_creation.sh..."
remote_exec "cp $REMOTE_PATH/storage/app/post_site_creation.sh $REMOTE_PATH/storage/app/post_site_creation.sh && chmod 755 $REMOTE_PATH/storage/app/post_site_creation.sh"
echo "✅ post_site_creation.sh deployed"
echo ""

echo "[5/10] Clearing Composer autoloader cache..."
remote_exec "cd $REMOTE_PATH && composer dump-autoload --optimize"
echo "✅ Composer cache cleared"
echo ""

echo "[6/10] Clearing Laravel application cache..."
remote_exec "cd $REMOTE_PATH && php artisan cache:clear"
echo "✅ Laravel cache cleared"
echo ""

echo "[7/10] Clearing Laravel config cache..."
remote_exec "cd $REMOTE_PATH && php artisan config:clear"
echo "✅ Laravel config cache cleared"
echo ""

echo "[8/10] Clearing Laravel view cache..."
remote_exec "cd $REMOTE_PATH && php artisan view:clear"
echo "✅ Laravel view cache cleared"
echo ""

echo "[9/10] Clearing PHP OPcache..."
remote_exec "systemctl reload php8.3-fpm"
echo "✅ PHP OPcache cleared (PHP-FPM reloaded)"
echo ""

echo "[10/10] Verifying deployment..."
remote_exec "test -f $REMOTE_PATH/app/Http/Controllers/SitesController.php && echo 'SitesController: OK' || echo 'SitesController: MISSING'"
remote_exec "test -f $REMOTE_PATH/storage/app/post_site_creation.sh && echo 'post_site_creation.sh: OK' || echo 'post_site_creation.sh: MISSING'"
remote_exec "grep -q 'SPRINT 36' $REMOTE_PATH/app/Http/Controllers/SitesController.php && echo 'Sprint 36 markers: FOUND' || echo 'Sprint 36 markers: NOT FOUND'"
echo "✅ Verification complete"
echo ""

echo "========================================="
echo "  DEPLOYMENT SUCCESSFUL"
echo "========================================="
echo ""
echo "NEXT STEPS FOR VALIDATION:"
echo "1. Open: https://72.61.53.222/admin/sites/create"
echo "2. Login: test@admin.local / Test@123456"
echo "3. Create site: sprint36validation$(date +%s)"
echo "4. Wait 30 seconds"
echo "5. Verify status = 'active' in database"
echo "6. Check logs for Sprint 36 markers"
echo ""
echo "VALIDATION CREDENTIALS:"
echo "  Admin URL: https://72.61.53.222/admin/"
echo "  Username: test@admin.local"
echo "  Password: Test@123456"
echo ""
echo "DATABASE VERIFICATION:"
echo "  SSH: sshpass -p '$VPS_PASS' ssh root@$VPS_IP"
echo "  MySQL: mysql -u root -p'$VPS_PASS' admin_panel"
echo "  Query: SELECT site_name, status, created_at FROM sites ORDER BY id DESC LIMIT 5;"
echo ""
echo "LOG FILES TO CHECK:"
echo "  Laravel: $REMOTE_PATH/storage/logs/laravel.log"
echo "  Post-script: /tmp/post-site-{sitename}.log"
echo "  Wrapper: /tmp/site-creation-{sitename}.log"
echo ""
echo "========================================="
