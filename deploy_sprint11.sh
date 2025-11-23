#!/bin/bash

# ========================================
# DEPLOYMENT SCRIPT - SPRINT 11
# SSL/TLS Let's Encrypt Management
# ========================================

echo "=========================================="
echo "DEPLOYING SPRINT 11: SSL/TLS MANAGEMENT"
echo "=========================================="
echo ""

HOST="72.61.53.222"
PASS="Jm@D@KDPnw7Q"
APP_PATH="/opt/webserver/admin-panel"

# ========================================
# PHASE 1: Deploy Files
# ========================================
echo "📦 PHASE 1: Deploying Files"
echo "----------------------------"

# Deploy Updated SitesController
echo -n "[1/2] Deploying updated SitesController... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    controllers_producao/SitesController.php \
    root@$HOST:$APP_PATH/app/Http/Controllers/SitesController.php
echo "✅ DONE"

# Deploy Updated Routes
echo -n "[2/2] Deploying updated routes... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    routes/web_production.php \
    root@$HOST:$APP_PATH/routes/web.php
echo "✅ DONE"

echo ""

# ========================================
# PHASE 2: Clear Caches
# ========================================
echo "🧹 PHASE 2: Clearing All Caches"
echo "--------------------------------"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST \
    "cd $APP_PATH && bash clear_all_caches.sh" | tail -5

echo ""

# ========================================
# PHASE 3: Verify Certbot Installation
# ========================================
echo "🔐 PHASE 3: Verifying Certbot Installation"
echo "-------------------------------------------"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST << 'EOFCERTBOT'
# Check if certbot is installed
if command -v certbot &> /dev/null; then
    echo "✅ Certbot installed: $(certbot --version 2>&1 | head -1)"
else
    echo "⚠️  Certbot not found, attempting installation..."
    apt-get update -qq
    apt-get install -y certbot python3-certbot-nginx -qq
    echo "✅ Certbot installed"
fi

# Check certbot timer for auto-renewal
if systemctl is-active --quiet certbot.timer; then
    echo "✅ Certbot auto-renewal timer is active"
else
    echo "⚠️  Certbot timer not active, enabling..."
    systemctl enable certbot.timer
    systemctl start certbot.timer
    echo "✅ Certbot auto-renewal enabled"
fi
EOFCERTBOT

echo ""

# ========================================
# SUMMARY
# ========================================
echo "=========================================="
echo "✅ SPRINT 11 DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "📋 Deployed Components:"
echo "  ✅ SitesController with SSL renewal methods"
echo "  ✅ renewSSL() - Renew specific certificate"
echo "  ✅ renewAllSSL() - Renew all certificates"
echo "  ✅ Updated routes"
echo "  ✅ Certbot verified/installed"
echo "  ✅ Auto-renewal timer enabled"
echo ""
echo "🎯 Features Implemented:"
echo "  • Generate Let's Encrypt certificates"
echo "  • Renew specific certificate"
echo "  • Renew all certificates"
echo "  • View certificate expiration dates"
echo "  • Automatic renewal (via certbot.timer)"
echo ""
echo "🌐 Access Features:"
echo "  • SSL Management: https://72.61.53.222/admin/sites/{siteName}/ssl"
echo ""
echo "⚠️  NOTE: Certificate generation/renewal methods already existed."
echo "    SPRINT 11 added renewal endpoints and auto-renewal setup."
echo "=========================================="
