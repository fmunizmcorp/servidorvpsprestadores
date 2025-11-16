#!/bin/bash

#############################################################################
# FIX DASHBOARD ERROR 500 - Complete Solution
# Date: 2025-11-16
# Server: 72.61.53.222
# Issue: Admin Panel Dashboard showing Error 500
#############################################################################

set -e  # Exit on error

echo "=================================================="
echo "  FIX DASHBOARD ERROR 500 - DEPLOYMENT SCRIPT"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

print_info "Starting dashboard fix deployment..."
echo ""

##############################################################################
# STEP 1: Backup Current Files
##############################################################################

echo "Step 1: Creating backups..."

BACKUP_DIR="/opt/webserver/admin-panel/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup DashboardController if exists
if [ -f "/opt/webserver/admin-panel/app/Http/Controllers/DashboardController.php" ]; then
    cp /opt/webserver/admin-panel/app/Http/Controllers/DashboardController.php "$BACKUP_DIR/"
    print_success "Backed up DashboardController.php"
fi

# Backup PHP-FPM pool config
if [ -f "/etc/php/8.3/fpm/pool.d/admin-panel.conf" ]; then
    cp /etc/php/8.3/fpm/pool.d/admin-panel.conf "$BACKUP_DIR/"
    print_success "Backed up admin-panel.conf"
fi

echo ""

##############################################################################
# STEP 2: Check Laravel Logs for Exact Error
##############################################################################

echo "Step 2: Checking Laravel logs..."

if [ -f "/opt/webserver/admin-panel/storage/logs/laravel.log" ]; then
    echo "Last 20 lines of Laravel log:"
    tail -20 /opt/webserver/admin-panel/storage/logs/laravel.log
else
    print_info "No Laravel log file found yet"
fi

echo ""

##############################################################################
# STEP 3: Check if View File Exists
##############################################################################

echo "Step 3: Checking for dashboard view file..."

VIEW_FILE="/opt/webserver/admin-panel/resources/views/dashboard.blade.php"

if [ -f "$VIEW_FILE" ]; then
    print_info "Dashboard view already exists at $VIEW_FILE"
else
    print_error "Dashboard view NOT FOUND - This is likely the cause of Error 500"
    echo "Will create the view file..."
fi

echo ""

##############################################################################
# STEP 4: Deploy Fixed Dashboard View
##############################################################################

echo "Step 4: Deploying dashboard.blade.php..."

# Create the view file (content would be piped here or uploaded separately)
print_info "Dashboard view needs to be uploaded to: $VIEW_FILE"
print_info "Use scp or paste the content of dashboard.blade.php"

echo ""

##############################################################################
# STEP 5: Choose Fix Strategy for DashboardController
##############################################################################

echo "Step 5: Fixing DashboardController..."
echo ""
echo "Two fix options available:"
echo "  A) Expand open_basedir in PHP-FPM pool (easier, less secure)"
echo "  B) Replace DashboardController with version that doesn't need shell_exec (more secure)"
echo ""
read -p "Choose option (A/B): " choice

case $choice in
    [Aa]* )
        print_info "Applying option A: Expanding open_basedir..."
        
        # Update PHP-FPM pool configuration
        cat > /etc/php/8.3/fpm/pool.d/admin-panel.conf << 'POOLEOF'
[admin-panel]
user = www-data
group = www-data
listen = /run/php/php8.3-fpm-admin-panel.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

php_admin_value[open_basedir] = /opt/webserver:/etc/postfix:/var/mail:/proc:/tmp
php_admin_value[upload_max_filesize] = 50M
php_admin_value[post_max_size] = 50M
php_admin_value[max_execution_time] = 300
php_admin_value[max_input_time] = 300
php_admin_value[memory_limit] = 256M
php_admin_value[error_log] = /opt/webserver/admin-panel/storage/logs/php-errors.log
php_admin_flag[log_errors] = on
php_admin_value[display_errors] = off
php_admin_value[disable_functions] = 
php_value[opcache.enable] = 1
php_value[opcache.memory_consumption] = 128
php_value[opcache.interned_strings_buffer] = 8
php_value[opcache.max_accelerated_files] = 10000
php_value[opcache.revalidate_freq] = 2
php_value[session.save_handler] = files
php_value[session.save_path] = /opt/webserver/admin-panel/storage/framework/sessions
POOLEOF
        
        print_success "Updated PHP-FPM pool configuration"
        print_info "DashboardController can remain as-is with shell_exec calls"
        ;;
        
    [Bb]* )
        print_info "Applying option B: Replacing DashboardController..."
        print_info "Upload DashboardController-FIXED.php to replace the current controller"
        print_info "Target: /opt/webserver/admin-panel/app/Http/Controllers/DashboardController.php"
        ;;
        
    * )
        print_error "Invalid choice. Please run script again and choose A or B."
        exit 1
        ;;
esac

echo ""

##############################################################################
# STEP 6: Set Correct Permissions
##############################################################################

echo "Step 6: Setting correct permissions..."

# Ensure Laravel directories are writable
chown -R www-data:www-data /opt/webserver/admin-panel/storage
chown -R www-data:www-data /opt/webserver/admin-panel/bootstrap/cache
chmod -R 775 /opt/webserver/admin-panel/storage
chmod -R 775 /opt/webserver/admin-panel/bootstrap/cache

print_success "Permissions set correctly"
echo ""

##############################################################################
# STEP 7: Clear Laravel Caches
##############################################################################

echo "Step 7: Clearing Laravel caches..."

cd /opt/webserver/admin-panel

# Clear various caches
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan route:clear

print_success "Laravel caches cleared"
echo ""

##############################################################################
# STEP 8: Restart PHP-FPM
##############################################################################

echo "Step 8: Restarting PHP-FPM..."

systemctl restart php8.3-fpm

if systemctl is-active --quiet php8.3-fpm; then
    print_success "PHP-FPM restarted successfully"
else
    print_error "PHP-FPM failed to restart!"
    systemctl status php8.3-fpm
    exit 1
fi

echo ""

##############################################################################
# STEP 9: Test Dashboard Access
##############################################################################

echo "Step 9: Testing dashboard access..."

# Test NGINX config
nginx -t
if [ $? -eq 0 ]; then
    print_success "NGINX configuration valid"
    systemctl reload nginx
else
    print_error "NGINX configuration has errors"
    exit 1
fi

echo ""

##############################################################################
# STEP 10: Verification
##############################################################################

echo "=================================================="
echo "  DEPLOYMENT COMPLETE - VERIFICATION STEPS"
echo "=================================================="
echo ""

print_info "Please perform the following manual tests:"
echo ""
echo "1. Access admin panel: http://72.61.53.222:8080"
echo "2. Login with: admin@localhost / Jm@D@KDPnw7Q"
echo "3. Click on Dashboard link"
echo "4. Verify dashboard loads without Error 500"
echo "5. Verify metrics are displayed (CPU, RAM, Disk)"
echo "6. Verify service status is shown"
echo "7. Verify summary stats are shown"
echo ""

print_info "If dashboard still shows errors:"
echo "1. Check Laravel logs: tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log"
echo "2. Check PHP-FPM logs: tail -50 /var/log/php8.3-fpm.log"
echo "3. Check NGINX error logs: tail -50 /var/log/nginx/admin-panel.error.log"
echo ""

print_info "Backup location: $BACKUP_DIR"
echo ""

print_success "Fix deployment script completed!"
echo ""
echo "=================================================="
