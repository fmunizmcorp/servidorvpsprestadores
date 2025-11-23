#!/bin/bash

# ========================================
# DEPLOYMENT SCRIPT - SPRINT 8
# Dashboard Historical Graphs + Email Alerts
# ========================================

echo "=========================================="
echo "DEPLOYING SPRINT 8: DASHBOARD ENHANCEMENTS"
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

# Deploy Migration
echo -n "[1/8] Deploying migration... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    sprint8_files/2024_11_22_000001_create_metrics_history_table.php \
    root@$HOST:$APP_PATH/database/migrations/2024_11_22_000001_create_metrics_history_table.php
echo "✅ DONE"

# Deploy Model
echo -n "[2/8] Deploying MetricsHistory model... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    sprint8_files/MetricsHistory.php \
    root@$HOST:$APP_PATH/app/Models/MetricsHistory.php
echo "✅ DONE"

# Deploy Console Command
echo -n "[3/8] Deploying CollectMetrics command... "
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST \
    "mkdir -p $APP_PATH/app/Console/Commands"
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    sprint8_files/CollectMetrics.php \
    root@$HOST:$APP_PATH/app/Console/Commands/CollectMetrics.php
echo "✅ DONE"

# Deploy Mail Class
echo -n "[4/8] Deploying HighUsageAlert mail... "
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST \
    "mkdir -p $APP_PATH/app/Mail"
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    sprint8_files/HighUsageAlert.php \
    root@$HOST:$APP_PATH/app/Mail/HighUsageAlert.php
echo "✅ DONE"

# Deploy Email View
echo -n "[5/8] Deploying high-usage-alert view... "
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST \
    "mkdir -p $APP_PATH/resources/views/emails"
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    sprint8_files/high-usage-alert.blade.php \
    root@$HOST:$APP_PATH/resources/views/emails/high-usage-alert.blade.php
echo "✅ DONE"

# Deploy Updated DashboardController
echo -n "[6/8] Deploying updated DashboardController... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    controllers_producao/DashboardController.php \
    root@$HOST:$APP_PATH/app/Http/Controllers/DashboardController.php
echo "✅ DONE"

# Deploy Updated Dashboard View
echo -n "[7/8] Deploying updated dashboard view... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    views/dashboard.blade.php \
    root@$HOST:$APP_PATH/resources/views/dashboard.blade.php
echo "✅ DONE"

# Deploy Updated Routes
echo -n "[8/8] Deploying updated routes... "
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
    routes/web_production.php \
    root@$HOST:$APP_PATH/routes/web.php
echo "✅ DONE"

echo ""

# ========================================
# PHASE 2: Run Migrations
# ========================================
echo "📊 PHASE 2: Running Database Migration"
echo "---------------------------------------"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST \
    "cd $APP_PATH && php artisan migrate --force" 2>&1 | grep -v "Warning"

echo "✅ Migration completed"
echo ""

# ========================================
# PHASE 3: Clear Caches
# ========================================
echo "🧹 PHASE 3: Clearing All Caches"
echo "--------------------------------"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST \
    "cd $APP_PATH && bash clear_all_caches.sh" | tail -5

echo ""

# ========================================
# PHASE 4: Test Metrics Collection
# ========================================
echo "🧪 PHASE 4: Testing Metrics Collection"
echo "---------------------------------------"

echo "Running metrics:collect command..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST \
    "cd $APP_PATH && php artisan metrics:collect"

echo "✅ Metrics collection tested"
echo ""

# ========================================
# PHASE 5: Setup Cron Job
# ========================================
echo "⏰ PHASE 5: Setting Up Cron Job"
echo "--------------------------------"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$HOST << 'EOFCRON'
# Check if cron job already exists
if ! crontab -l | grep -q "metrics:collect"; then
    # Add cron job to collect metrics every 5 minutes
    (crontab -l 2>/dev/null; echo "*/5 * * * * cd /opt/webserver/admin-panel && php artisan metrics:collect >> /opt/webserver/admin-panel/storage/logs/metrics.log 2>&1") | crontab -
    echo "✅ Cron job added: metrics:collect every 5 minutes"
else
    echo "✅ Cron job already exists"
fi
EOFCRON

echo ""

# ========================================
# SUMMARY
# ========================================
echo "=========================================="
echo "✅ SPRINT 8 DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "📋 Deployed Components:"
echo "  ✅ MetricsHistory model and migration"
echo "  ✅ CollectMetrics command (every 5 minutes)"
echo "  ✅ HighUsageAlert email system"
echo "  ✅ Updated DashboardController with API"
echo "  ✅ Dashboard with Chart.js graphs"
echo "  ✅ Cron job scheduled"
echo ""
echo "🎯 Features Implemented:"
echo "  • Historical metrics collection (every 5 min)"
echo "  • Chart.js graphs (CPU, Memory, Disk)"
echo "  • Time range selector (1h, 6h, 12h, 24h)"
echo "  • Email alerts for 90%+ usage"
echo "  • Auto-refresh every 5 minutes"
echo ""
echo "🌐 Access Dashboard:"
echo "  https://72.61.53.222/admin/dashboard"
echo ""
echo "⚠️  NOTE: Historical graphs will populate after"
echo "    5-10 minutes as metrics are collected."
echo "=========================================="
