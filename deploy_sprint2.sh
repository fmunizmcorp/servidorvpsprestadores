#!/bin/bash
##############################################
# DEPLOY SPRINT 2 - Email Domains EDIT
# Automated deployment with ZERO manual intervention
##############################################

set -e

echo "============================================"
echo "🚀 SPRINT 2 DEPLOYMENT - Email Domains EDIT"
echo "============================================"
echo ""

SSH_HOST="root@72.61.53.222"
SSH_PASS="Jm@D@KDPnw7Q"
ADMIN_PATH="/opt/webserver/admin-panel"

echo "📦 Deploying 3 files to production:"
echo "  1. EmailController.php (with editDomain/updateDomain methods)"
echo "  2. domains.blade.php (updated with Edit button)"
echo "  3. domains-edit.blade.php (new edit form)"
echo "  4. web.php (routes with EDIT endpoints)"
echo ""

# DEPLOY 1: EmailController.php
echo "============================================"
echo "1️⃣  Deploying EmailController.php"
echo "============================================"

sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST 'bash -s' << 'REMOTE1'
# Backup existing controller
BACKUP_DIR="/opt/webserver/backups/sprint2_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Backup created: $BACKUP_DIR/EmailController.php"
REMOTE1

# Upload new controller
cat EmailController_SPRINT2.php | sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "cat > $ADMIN_PATH/app/Http/Controllers/EmailController.php"

echo "✅ EmailController.php deployed"
echo ""

# DEPLOY 2: domains.blade.php (updated)
echo "============================================"
echo "2️⃣  Deploying updated domains.blade.php"
echo "============================================"

sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "cp $ADMIN_PATH/resources/views/email/domains.blade.php $BACKUP_DIR/ 2>/dev/null || true"

cat domains_updated.blade.php | sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "cat > $ADMIN_PATH/resources/views/email/domains.blade.php"

echo "✅ domains.blade.php deployed"
echo ""

# DEPLOY 3: domains-edit.blade.php (new)
echo "============================================"
echo "3️⃣  Deploying NEW domains-edit.blade.php"
echo "============================================"

cat domains-edit.blade.php | sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "cat > $ADMIN_PATH/resources/views/email/domains-edit.blade.php"

echo "✅ domains-edit.blade.php deployed"
echo ""

# DEPLOY 4: web.php (routes)
echo "============================================"
echo "4️⃣  Deploying updated web.php with routes"
echo "============================================"

sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "cp $ADMIN_PATH/routes/web.php $BACKUP_DIR/ 2>/dev/null || true"

cat routes_web_SPRINT2.php | sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST \
  "cat > $ADMIN_PATH/routes/web.php"

echo "✅ web.php deployed"
echo ""

# CLEAR ALL CACHES
echo "============================================"
echo "🧹 Clearing ALL caches"
echo "============================================"

sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_HOST 'bash -s' << 'REMOTECACHE'
cd /opt/webserver/admin-panel

echo "Clearing Laravel caches..."
php artisan optimize:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

echo "Removing compiled views..."
rm -rf storage/framework/views/*
rm -rf storage/framework/cache/*

echo "Restarting services..."
systemctl restart php8.3-fpm
nginx -s reload

echo "✅ All caches cleared and services restarted"
REMOTECACHE

echo ""
echo "============================================"
echo "✅ SPRINT 2 DEPLOYMENT COMPLETE"
echo "============================================"
echo ""
echo "📋 DEPLOYED COMPONENTS:"
echo "  ✅ EmailController::editDomain() method"
echo "  ✅ EmailController::updateDomain() method"
echo "  ✅ Route: GET /admin/email/domains/{id}/edit"
echo "  ✅ Route: PUT /admin/email/domains/{id}"
echo "  ✅ View: email.domains-edit.blade.php"
echo "  ✅ Updated: email.domains.blade.php (with Edit button)"
echo ""
echo "🔍 NEXT STEPS:"
echo "  1. Run validation tests"
echo "  2. Git commit changes"
echo "  3. Update PR"
echo ""
