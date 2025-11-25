#!/bin/bash
set -e
echo "=========================================="
echo "🚀 SPRINT 3 DEPLOYMENT - Email Accounts EDIT"
echo "=========================================="

SSH_HOST="root@72.61.53.222"
SSH_PASS="Jm@D@KDPnw7Q"
ADMIN_PATH="/opt/webserver/admin-panel"

echo "📦 Deploying SPRINT 3 files..."

# DEPLOY EmailController
echo "1️⃣ Deploying EmailController..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST 'bash -s' << 'REMOTE1'
BACKUP_DIR="/opt/webserver/backups/sprint3_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php "$BACKUP_DIR/"
REMOTE1
cat EmailController_SPRINT3.php | sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "cat > $ADMIN_PATH/app/Http/Controllers/EmailController.php"
echo "✅ EmailController deployed"

# DEPLOY accounts-edit view
echo "2️⃣ Deploying accounts-edit.blade.php..."
cat accounts-edit.blade.php | sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "cat > $ADMIN_PATH/resources/views/email/accounts-edit.blade.php"
echo "✅ accounts-edit.blade.php deployed"

# DEPLOY accounts view updated
echo "3️⃣ Deploying updated accounts.blade.php..."
cat accounts_updated.blade.php | sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "cat > $ADMIN_PATH/resources/views/email/accounts.blade.php"
echo "✅ accounts.blade.php deployed"

# DEPLOY routes
echo "4️⃣ Deploying routes..."
cat routes_web_SPRINT3.php | sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST "cat > $ADMIN_PATH/routes/web.php"
echo "✅ web.php deployed"

# CLEAR CACHES
echo "🧹 Clearing caches..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST 'bash -s' << 'REMOTECACHE'
cd /opt/webserver/admin-panel
php artisan optimize:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
rm -rf storage/framework/views/*
rm -rf storage/framework/cache/*
systemctl restart php8.3-fpm
nginx -s reload
REMOTECACHE

echo "✅ SPRINT 3 DEPLOYMENT COMPLETE"
