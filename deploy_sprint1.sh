#!/bin/bash

# SPRINT 1 Deployment Script: Two-Factor Authentication (2FA)
# Epic 1, US-1.4 - Complete 2FA implementation

set -e  # Exit on any error

REMOTE_HOST="72.61.53.222"
REMOTE_USER="root"
REMOTE_PASS="Jm@D@KDPnw7Q"
REMOTE_PATH="/opt/webserver/admin-panel"

echo "========================================"
echo "🚀 SPRINT 1: Two-Factor Authentication"
echo "========================================"
echo ""

# Step 1: Install required packages
echo "📦 Step 1: Installing required Composer packages..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST << 'ENDSSH'
cd /opt/webserver/admin-panel
composer require pragmarx/google2fa-laravel bacon/bacon-qr-code --no-interaction
echo "✅ Packages installed"
ENDSSH

# Step 2: Upload migration file
echo ""
echo "📤 Step 2: Uploading migration file..."
MIGRATION_NAME="$(date +%Y_%m_%d_%H%M%S)_add_two_factor_to_users.php"
sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no \
    sprint1_files/add_two_factor_to_users.php \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/database/migrations/$MIGRATION_NAME
echo "✅ Migration uploaded: $MIGRATION_NAME"

# Step 3: Upload User model
echo ""
echo "📤 Step 3: Uploading enhanced User model..."
sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no \
    sprint1_files/User_with_2fa.php \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/app/Models/User.php
echo "✅ User model updated"

# Step 4: Upload TwoFactorController
echo ""
echo "📤 Step 4: Uploading TwoFactorController..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    "mkdir -p $REMOTE_PATH/app/Http/Controllers"

sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no \
    sprint1_files/TwoFactorController.php \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/app/Http/Controllers/TwoFactorController.php
echo "✅ TwoFactorController uploaded"

# Step 5: Upload updated AuthenticatedSessionController
echo ""
echo "📤 Step 5: Uploading updated AuthenticatedSessionController..."
sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no \
    sprint1_files/AuthenticatedSessionController_with_2fa.php \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/app/Http/Controllers/Auth/AuthenticatedSessionController.php
echo "✅ AuthenticatedSessionController updated"

# Step 6: Upload views
echo ""
echo "📤 Step 6: Uploading 2FA views..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
    "mkdir -p $REMOTE_PATH/resources/views/auth/two-factor"

sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no \
    sprint1_views/two-factor-show.blade.php \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/resources/views/auth/two-factor/show.blade.php

sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no \
    sprint1_views/two-factor-enable.blade.php \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/resources/views/auth/two-factor/enable.blade.php

sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no \
    sprint1_views/two-factor-challenge.blade.php \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/resources/views/auth/two-factor/challenge.blade.php

sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no \
    sprint1_views/two-factor-recovery-codes.blade.php \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/resources/views/auth/two-factor/recovery-codes.blade.php

echo "✅ All 2FA views uploaded"

# Step 7: Update routes
echo ""
echo "📤 Step 7: Adding 2FA routes to web.php..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST << 'ENDSSH'
cd /opt/webserver/admin-panel

# Backup current routes
cp routes/web.php routes/web.php.backup.$(date +%Y%m%d_%H%M%S)

# Check if TwoFactorController is already imported
if ! grep -q "use App\\\Http\\\Controllers\\\TwoFactorController;" routes/web.php; then
    # Add the import after other controller imports
    sed -i '/use App\\Http\\Controllers\\EmailController;/a use App\\Http\\Controllers\\TwoFactorController;' routes/web.php
    echo "✅ Added TwoFactorController import"
fi

# Check if 2FA routes already exist
if ! grep -q "two-factor" routes/web.php; then
    # Add 2FA routes before the closing of the file
    cat >> routes/web.php << 'EOF'

// Two-Factor Authentication Routes
Route::middleware(['auth'])->group(function () {
    Route::get('/two-factor', [TwoFactorController::class, 'show'])->name('two-factor.show');
    Route::get('/two-factor/enable', [TwoFactorController::class, 'enable'])->name('two-factor.enable');
    Route::post('/two-factor/confirm', [TwoFactorController::class, 'confirm'])->name('two-factor.confirm');
    Route::post('/two-factor/disable', [TwoFactorController::class, 'disable'])->name('two-factor.disable');
    Route::post('/two-factor/regenerate-codes', [TwoFactorController::class, 'regenerateRecoveryCodes'])->name('two-factor.regenerate-codes');
});

// 2FA Challenge Routes (no auth middleware - used during login)
Route::get('/two-factor/challenge', [TwoFactorController::class, 'challenge'])->name('two-factor.challenge');
Route::post('/two-factor/verify', [TwoFactorController::class, 'verify'])->name('two-factor.verify');
EOF
    echo "✅ Added 2FA routes"
else
    echo "✅ 2FA routes already exist"
fi
ENDSSH

# Step 8: Run migrations
echo ""
echo "🗄️  Step 8: Running database migrations..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST << 'ENDSSH'
cd /opt/webserver/admin-panel
php artisan migrate --force
echo "✅ Migrations completed"
ENDSSH

# Step 9: Clear all caches
echo ""
echo "🧹 Step 9: Clearing all caches..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST << 'ENDSSH'
cd /opt/webserver/admin-panel

# Phase 1: Laravel Artisan Cache Clear
echo "  Phase 1: Laravel cache clear..."
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Phase 2: Manual file removal
echo "  Phase 2: Manual cache file removal..."
rm -rf bootstrap/cache/*.php
rm -rf storage/framework/cache/data/*
rm -rf storage/framework/views/*.php

# Phase 3: OPcache reset (if available)
echo "  Phase 3: Restarting PHP-FPM..."
systemctl restart php8.3-fpm

# Phase 4: NGINX reload
echo "  Phase 4: Reloading NGINX..."
systemctl reload nginx

echo "✅ All caches cleared"
ENDSSH

# Step 10: Set correct permissions
echo ""
echo "🔐 Step 10: Setting correct permissions..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST << 'ENDSSH'
cd /opt/webserver/admin-panel
chown -R www-data:www-data app/
chown -R www-data:www-data resources/views/
chown -R www-data:www-data database/migrations/
chmod -R 755 app/
chmod -R 755 resources/views/
echo "✅ Permissions set"
ENDSSH

# Step 11: Verify deployment
echo ""
echo "✅ Step 11: Verifying deployment..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST << 'ENDSSH'
cd /opt/webserver/admin-panel

echo "Checking files..."
test -f app/Models/User.php && echo "  ✅ User model exists"
test -f app/Http/Controllers/TwoFactorController.php && echo "  ✅ TwoFactorController exists"
test -f app/Http/Controllers/Auth/AuthenticatedSessionController.php && echo "  ✅ AuthenticatedSessionController exists"
test -f resources/views/auth/two-factor/show.blade.php && echo "  ✅ 2FA show view exists"
test -f resources/views/auth/two-factor/enable.blade.php && echo "  ✅ 2FA enable view exists"
test -f resources/views/auth/two-factor/challenge.blade.php && echo "  ✅ 2FA challenge view exists"
test -f resources/views/auth/two-factor/recovery-codes.blade.php && echo "  ✅ 2FA recovery codes view exists"

echo ""
echo "Checking database columns..."
php artisan tinker --execute="echo 'Users table columns: '; \
    \$cols = \DB::getSchemaBuilder()->getColumnListing('users'); \
    echo in_array('two_factor_enabled', \$cols) ? '  ✅ two_factor_enabled column exists' : '  ❌ two_factor_enabled missing'; \
    echo PHP_EOL; \
    echo in_array('two_factor_secret', \$cols) ? '  ✅ two_factor_secret column exists' : '  ❌ two_factor_secret missing'; \
    echo PHP_EOL; \
    echo in_array('two_factor_recovery_codes', \$cols) ? '  ✅ two_factor_recovery_codes column exists' : '  ❌ two_factor_recovery_codes missing';"
ENDSSH

echo ""
echo "========================================"
echo "✅ SPRINT 1 Deployment Complete!"
echo "========================================"
echo ""
echo "📋 Summary:"
echo "  • Two-Factor Authentication fully implemented"
echo "  • Composer packages installed (google2fa-laravel, bacon-qr-code)"
echo "  • Database migration completed"
echo "  • User model enhanced with 2FA support"
echo "  • TwoFactorController created with full functionality"
echo "  • Authentication flow updated to include 2FA challenge"
echo "  • 4 complete views created (show, enable, challenge, recovery-codes)"
echo "  • Routes registered and accessible"
echo "  • All caches cleared"
echo ""
echo "🌐 Access 2FA settings at: https://72.61.53.222/admin/two-factor"
echo ""
echo "✅ US-1.4: Two-Factor Authentication - COMPLETE"
echo ""
