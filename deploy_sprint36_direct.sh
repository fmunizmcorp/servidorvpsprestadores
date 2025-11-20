#!/bin/bash
# SPRINT 36 - Direct File Deployment via SCP

set -e

VPS_IP="72.61.53.222"
VPS_USER="root"
VPS_PASS="Jm@D@KDPnw7Q"
REMOTE_PATH="/opt/webserver/admin-panel"

echo "========================================="
echo "  SPRINT 36 - DIRECT DEPLOYMENT"
echo "========================================="
echo ""

# Function to execute remote commands
remote_exec() {
    sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "$1"
}

# Function to copy files
remote_copy() {
    sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no "$1" "$VPS_USER@$VPS_IP:$2"
}

echo "[1/8] Backing up current SitesController..."
remote_exec "cp $REMOTE_PATH/app/Http/Controllers/SitesController.php $REMOTE_PATH/app/Http/Controllers/SitesController.php.sprint35.backup"
echo "✅ Backup created"
echo ""

echo "[2/8] Deploying Sprint 36 SitesController.php..."
remote_copy "laravel_controllers/SitesController.php" "$REMOTE_PATH/app/Http/Controllers/SitesController.php"
echo "✅ SitesController.php deployed"
echo ""

echo "[3/8] Deploying Sprint 36 post_site_creation.sh..."
remote_copy "storage/app/post_site_creation.sh" "$REMOTE_PATH/storage/app/post_site_creation.sh"
remote_exec "chmod 755 $REMOTE_PATH/storage/app/post_site_creation.sh"
echo "✅ post_site_creation.sh deployed"
echo ""

echo "[4/8] Clearing Composer cache..."
remote_exec "cd $REMOTE_PATH && composer dump-autoload --optimize 2>&1"
echo "✅ Composer cache cleared"
echo ""

echo "[5/8] Clearing Laravel caches..."
remote_exec "cd $REMOTE_PATH && php artisan cache:clear 2>&1"
remote_exec "cd $REMOTE_PATH && php artisan config:clear 2>&1"
remote_exec "cd $REMOTE_PATH && php artisan view:clear 2>&1"
echo "✅ Laravel caches cleared"
echo ""

echo "[6/8] Clearing PHP OPcache..."
remote_exec "systemctl reload php8.3-fpm"
echo "✅ PHP-FPM reloaded (OPcache cleared)"
echo ""

echo "[7/8] Verifying Sprint 36 deployment..."
VERIFICATION=$(remote_exec "grep -c 'SPRINT 36' $REMOTE_PATH/app/Http/Controllers/SitesController.php || echo 0")
echo "Sprint 36 markers found: $VERIFICATION"

if [ "$VERIFICATION" -gt "0" ]; then
    echo "✅ Sprint 36 code verified"
else
    echo "❌ ERROR: Sprint 36 code not found!"
    exit 1
fi
echo ""

echo "[8/8] Testing file permissions..."
remote_exec "test -x $REMOTE_PATH/storage/app/post_site_creation.sh && echo '✅ post_site_creation.sh is executable' || echo '❌ ERROR: Not executable'"
echo ""

echo "========================================="
echo "  DEPLOYMENT SUCCESSFUL"
echo "========================================="
echo ""
echo "READY FOR VALIDATION TEST"
echo ""
echo "Next: Execute end-to-end validation via web form"
echo ""
