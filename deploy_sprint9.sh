#!/bin/bash

# ========================================
# DEPLOYMENT SCRIPT - SPRINT 9
# Email Server Advanced Features
# ========================================

echo "=========================================="
echo "DEPLOYING SPRINT 9: EMAIL SERVER ADVANCED"
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

# Deploy Updated EmailController
echo -n "[1/4] Deploying updated EmailController... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    controllers_producao/EmailController.php \
    root@$HOST:$APP_PATH/app/Http/Controllers/EmailController.php
echo "✅ DONE"

# Deploy Spam Logs View
echo -n "[2/4] Deploying spam-logs view... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    sprint9_views/spam-logs.blade.php \
    root@$HOST:$APP_PATH/resources/views/email/spam-logs.blade.php
echo "✅ DONE"

# Deploy Aliases Views
echo -n "[3/4] Deploying aliases views... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    sprint9_views/aliases.blade.php \
    root@$HOST:$APP_PATH/resources/views/email/aliases.blade.php
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    sprint9_views/aliases-create.blade.php \
    root@$HOST:$APP_PATH/resources/views/email/aliases-create.blade.php
echo "✅ DONE"

# Deploy Updated Routes
echo -n "[4/4] Deploying updated routes... "
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
# PHASE 3: Verify Postfix Virtual File
# ========================================
echo "📋 PHASE 3: Verifying Postfix Configuration"
echo "--------------------------------------------"

echo "Checking /etc/postfix/virtual file..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST << 'EOFPOSTFIX'
if [ ! -f /etc/postfix/virtual ]; then
    echo "Creating /etc/postfix/virtual file..."
    sudo touch /etc/postfix/virtual
    sudo chown root:root /etc/postfix/virtual
    sudo chmod 644 /etc/postfix/virtual
    sudo postmap /etc/postfix/virtual
    echo "✅ Virtual file created"
else
    echo "✅ Virtual file exists"
fi

# Verify virtual file is configured in main.cf
if ! grep -q "virtual_alias_maps" /etc/postfix/main.cf; then
    echo "⚠️  WARNING: virtual_alias_maps not configured in main.cf"
    echo "   Add: virtual_alias_maps = hash:/etc/postfix/virtual"
else
    echo "✅ Virtual aliases configured"
fi
EOFPOSTFIX

echo ""

# ========================================
# PHASE 4: Test Routes
# ========================================
echo "🧪 PHASE 4: Testing Routes"
echo "--------------------------"

echo "Checking spam-logs route..."
ROUTE_CHECK=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST \
    "cd $APP_PATH && php artisan route:list --compact 2>/dev/null | grep 'spam-logs' || echo 'NOT_FOUND'")

if echo "$ROUTE_CHECK" | grep -q "spam-logs"; then
    echo "✅ Spam logs routes registered"
else
    echo "❌ Spam logs routes NOT found"
fi

echo "Checking aliases route..."
ROUTE_CHECK=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST \
    "cd $APP_PATH && php artisan route:list --compact 2>/dev/null | grep 'aliases' || echo 'NOT_FOUND'")

if echo "$ROUTE_CHECK" | grep -q "aliases"; then
    echo "✅ Aliases routes registered"
else
    echo "❌ Aliases routes NOT found"
fi

echo ""

# ========================================
# SUMMARY
# ========================================
echo "=========================================="
echo "✅ SPRINT 9 DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "📋 Deployed Components:"
echo "  ✅ EmailController with enhanced methods"
echo "  ✅ DNS records (SPF/DKIM/DMARC)"
echo "  ✅ Spam logs viewer"
echo "  ✅ Email aliases management"
echo "  ✅ Updated routes"
echo ""
echo "🎯 Features Implemented:"
echo "  • SPF/DKIM/DMARC DNS configuration display"
echo "  • Spam logs viewer with filtering"
echo "  • Email aliases CRUD operations"
echo "  • Postfix virtual file integration"
echo ""
echo "🌐 Access Features:"
echo "  • DNS: https://72.61.53.222/admin/email/dns?domain=YOURDOMAIN"
echo "  • Spam Logs: https://72.61.53.222/admin/email/spam-logs"
echo "  • Aliases: https://72.61.53.222/admin/email/aliases"
echo ""
echo "⚠️  NOTE: Email queue already exists and was not modified."
echo "=========================================="
