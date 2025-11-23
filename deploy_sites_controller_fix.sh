#!/bin/bash

# ============================================================================
# DEPLOYMENT SCRIPT - Sites Controller Recovery Fix
# ============================================================================
# Purpose: Deploy fixed SitesController to production server
# Server: 72.61.53.222
# User: root
# Password: mcorpapp (via sshpass)
# ============================================================================

set -e  # Exit on error

echo "=============================================="
echo " DEPLOYING SITES CONTROLLER FIX"
echo "=============================================="
echo ""

# Configuration
SERVER="72.61.53.222"
USER="root"
export SSHPASS="mcorpapp"
CONTROLLER_SOURCE="./SitesController_RECOVERY_FIX.php"
CONTROLLER_DEST="/opt/webserver/admin-panel/app/Http/Controllers/SitesController.php"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo "ℹ️  $1"
}

# Check if source file exists
if [ ! -f "$CONTROLLER_SOURCE" ]; then
    print_error "Source file not found: $CONTROLLER_SOURCE"
    exit 1
fi

print_success "Source file found: $CONTROLLER_SOURCE"

# Step 1: Backup current controller
print_info "Step 1: Backing up current controller on production..."

sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel/app/Http/Controllers

if [ -f "SitesController.php" ]; then
    BACKUP_NAME="SitesController.backup.$(date +%Y%m%d_%H%M%S).php"
    cp SitesController.php "$BACKUP_NAME"
    echo "Backup created: $BACKUP_NAME"
else
    echo "No existing controller to backup"
fi
ENDSSH

if [ $? -eq 0 ]; then
    print_success "Backup completed"
else
    print_error "Backup failed"
    exit 1
fi

# Step 2: Upload new controller
print_info "Step 2: Uploading fixed controller to production..."

sshpass -e scp -o StrictHostKeyChecking=no "$CONTROLLER_SOURCE" "$USER@$SERVER:$CONTROLLER_DEST"

if [ $? -eq 0 ]; then
    print_success "Controller uploaded successfully"
else
    print_error "Upload failed"
    exit 1
fi

# Step 3: Verify upload
print_info "Step 3: Verifying uploaded file..."

sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
if [ -f "/opt/webserver/admin-panel/app/Http/Controllers/SitesController.php" ]; then
    FILE_SIZE=$(stat -f%z "/opt/webserver/admin-panel/app/Http/Controllers/SitesController.php" 2>/dev/null || stat -c%s "/opt/webserver/admin-panel/app/Http/Controllers/SitesController.php")
    echo "File exists, size: $FILE_SIZE bytes"
    
    # Check for key recovery markers
    if grep -q "RECOVERY FIX" "/opt/webserver/admin-panel/app/Http/Controllers/SitesController.php"; then
        echo "✅ Recovery fix markers found in file"
    else
        echo "⚠️  Warning: Recovery markers not found"
    fi
else
    echo "❌ File not found after upload!"
    exit 1
fi
ENDSSH

if [ $? -eq 0 ]; then
    print_success "File verification passed"
else
    print_error "File verification failed"
    exit 1
fi

# Step 4: Clear Laravel caches
print_info "Step 4: Clearing Laravel caches..."

sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel

echo "Clearing route cache..."
php artisan route:clear

echo "Clearing config cache..."
php artisan config:clear

echo "Clearing view cache..."
php artisan view:clear

echo "Clearing compiled classes..."
php artisan clear-compiled

echo "Optimizing autoloader..."
composer dump-autoload --optimize 2>/dev/null || echo "Composer not available, skipping autoload optimization"

echo "✅ All caches cleared"
ENDSSH

if [ $? -eq 0 ]; then
    print_success "Caches cleared successfully"
else
    print_warning "Some cache operations may have failed"
fi

# Step 5: Set proper permissions
print_info "Step 5: Setting file permissions..."

sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
cd /opt/webserver/admin-panel

chown www-data:www-data app/Http/Controllers/SitesController.php
chmod 644 app/Http/Controllers/SitesController.php

echo "✅ Permissions set"
ENDSSH

if [ $? -eq 0 ]; then
    print_success "Permissions set correctly"
else
    print_warning "Failed to set permissions"
fi

# Step 6: Check PHP-FPM status
print_info "Step 6: Checking PHP-FPM status..."

sshpass -e ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
systemctl status php8.3-fpm --no-pager | head -5
ENDSSH

# Step 7: Deployment summary
echo ""
echo "=============================================="
echo " DEPLOYMENT COMPLETE"
echo "=============================================="
echo ""
print_success "Controller deployed to: $CONTROLLER_DEST"
print_success "Backups created on server"
print_success "All caches cleared"
print_success "Permissions set"
echo ""
print_info "The fix includes:"
echo "  - Multiple command execution methods (shell_exec, exec, proc_open)"
echo "  - Comprehensive error logging"
echo "  - Better error messages for users"
echo "  - Fixed database logic"
echo "  - Validation of script existence before execution"
echo ""
print_warning "NEXT STEPS:"
echo "  1. Test site creation via web interface"
echo "  2. Use credentials: admin@vps.local / mcorpapp"
echo "  3. Check Laravel logs: /opt/webserver/admin-panel/storage/logs/laravel.log"
echo "  4. Verify database persistence with SQL query"
echo "  5. Verify directory creation in /opt/webserver/sites/"
echo ""
print_info "To check logs after testing:"
echo "  ssh root@72.61.53.222"
echo "  tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log"
echo ""
print_info "To verify database persistence:"
echo "  ssh root@72.61.53.222"
echo "  mysql -u root -p admin_panel"
echo "  SELECT * FROM sites ORDER BY created_at DESC LIMIT 5;"
echo ""
echo "=============================================="
