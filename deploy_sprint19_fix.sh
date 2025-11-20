#!/bin/bash

# ==========================================================================
# SPRINT 19 - AUTOMATED DEPLOYMENT SCRIPT
# Deploys NGINX fix + EmailController fix + APP_URL fix
# ==========================================================================

set -e  # Exit on error

VPS_HOST="72.61.53.222"
VPS_USER="root"
VPS_PASS="Jm@D@KDPnw7Q"

echo "========================================"
echo "SPRINT 19 - AUTOMATED DEPLOYMENT"
echo "========================================"
echo ""

# Install sshpass if not available
if ! command -v sshpass &> /dev/null; then
    echo "[1/7] Installing sshpass..."
    sudo apt-get update -qq && sudo apt-get install -y sshpass
else
    echo "[1/7] sshpass already installed ✓"
fi

# Define sshpass command
SSHCMD="sshpass -p '$VPS_PASS' ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_HOST"
SCPCMD="sshpass -p '$VPS_PASS' scp -o StrictHostKeyChecking=no"

echo ""
echo "[2/7] Backing up current NGINX config..."
$SSHCMD "cp /etc/nginx/sites-available/ip-server-admin.conf /etc/nginx/sites-available/ip-server-admin.conf.backup_sprint19_$(date +%Y%m%d_%H%M%S)"

echo ""
echo "[3/7] Deploying NEW NGINX configuration..."
$SCPCMD nginx/ip-server-admin-FINAL.conf $VPS_USER@$VPS_HOST:/etc/nginx/sites-available/ip-server-admin.conf

echo ""
echo "[4/7] Testing NGINX configuration..."
if $SSHCMD "nginx -t"; then
    echo "NGINX config is valid ✓"
else
    echo "ERROR: NGINX config invalid! Restoring backup..."
    $SSHCMD "cp /etc/nginx/sites-available/ip-server-admin.conf.backup_sprint19_* /etc/nginx/sites-available/ip-server-admin.conf"
    exit 1
fi

echo ""
echo "[5/7] Reloading NGINX..."
$SSHCMD "systemctl reload nginx"
echo "NGINX reloaded ✓"

echo ""
echo "[6/7] Updating APP_URL in Laravel .env..."
$SSHCMD "cd /opt/webserver/admin-panel && sed -i 's|APP_URL=.*|APP_URL=https://72.61.53.222|' .env && grep APP_URL .env"

echo ""
echo "[7/7] Deploying EmailController fix..."
$SCPCMD EmailController.php $VPS_USER@$VPS_HOST:/opt/webserver/admin-panel/app/Http/Controllers/EmailController.php

echo ""
echo "Clearing Laravel caches..."
$SSHCMD "cd /opt/webserver/admin-panel && php artisan config:clear && php artisan route:clear && php artisan cache:clear && php artisan view:clear"

echo ""
echo "========================================"
echo "DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "Testing endpoints..."
echo ""

# Test 1: Admin login page
echo "[TEST 1] Fetching /admin/login..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://72.61.53.222/admin/login)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Login page accessible (HTTP $HTTP_CODE)"
else
    echo "✗ Login page returned HTTP $HTTP_CODE"
fi

# Test 2: Admin dashboard (should redirect to login)
echo ""
echo "[TEST 2] Fetching /admin/dashboard..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://72.61.53.222/admin/dashboard)
if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Dashboard accessible (HTTP $HTTP_CODE)"
else
    echo "✗ Dashboard returned HTTP $HTTP_CODE"
fi

# Test 3: Email accounts page
echo ""
echo "[TEST 3] Fetching /admin/email/accounts (should redirect to login)..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://72.61.53.222/admin/email/accounts)
if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Email accounts route exists (HTTP $HTTP_CODE)"
else
    echo "✗ Email accounts returned HTTP $HTTP_CODE"
fi

echo ""
echo "========================================"
echo "NEXT STEP: Run authenticated tests"
echo "========================================"
echo ""
echo "Command: ./test_sprint19_full.sh"
echo ""

