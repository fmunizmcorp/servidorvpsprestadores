# 🔧 DEPLOYMENT GUIDE - Dashboard Fix

**Date:** 2025-11-16  
**Issue:** Admin Panel Dashboard Error 500  
**Server:** 72.61.53.222  
**Status:** ✅ Solutions Ready for Deployment

---

## 📋 PROBLEM SUMMARY

### What's Broken
- ✅ Login to admin panel works
- ❌ Dashboard page shows Error 500
- ❌ No visual interface displayed

### Root Causes Identified
1. **Missing View File**: `dashboard.blade.php` doesn't exist
2. **open_basedir Restriction**: PHP-FPM pool blocks access to system paths
3. **shell_exec() Blocked**: Can't read system metrics from restricted paths

---

## 🎯 SOLUTIONS PROVIDED

### Solution A: Expand open_basedir (Easier, Less Secure)
**Files to deploy:**
- `admin-panel-pool-FIXED.conf` → `/etc/php/8.3/fpm/pool.d/admin-panel.conf`
- `dashboard.blade.php` → `/opt/webserver/admin-panel/resources/views/dashboard.blade.php`
- Keep existing `DashboardController.php` as-is

**Pros:**
- Minimal changes
- Existing controller works
- Quick to implement

**Cons:**
- Grants admin panel access to more system paths
- Slightly less secure

### Solution B: Replace DashboardController (More Secure)
**Files to deploy:**
- `DashboardController-FIXED.php` → `/opt/webserver/admin-panel/app/Http/Controllers/DashboardController.php`
- `dashboard.blade.php` → `/opt/webserver/admin-panel/resources/views/dashboard.blade.php`
- Keep existing tight `open_basedir` restriction

**Pros:**
- More secure
- No shell_exec() usage
- Respects open_basedir restrictions

**Cons:**
- Replaces entire controller
- Some metrics may be unavailable (email counts)

---

## 📦 FILES TO DEPLOY

### Required Files (Both Solutions)
```
dashboard.blade.php           → /opt/webserver/admin-panel/resources/views/
```

### Solution A Additional Files
```
admin-panel-pool-FIXED.conf   → /etc/php/8.3/fpm/pool.d/admin-panel.conf
```

### Solution B Additional Files
```
DashboardController-FIXED.php → /opt/webserver/admin-panel/app/Http/Controllers/DashboardController.php
```

### Helper Scripts
```
fix-dashboard.sh              → /root/fix-dashboard.sh (optional automated deployment)
```

---

## 🚀 DEPLOYMENT STEPS

### Pre-Deployment Checklist
```bash
# 1. Connect to server
ssh root@72.61.53.222
# Password: Jm@D@KDPnw7Q

# 2. Create backup directory
mkdir -p /opt/webserver/admin-panel/backups/$(date +%Y%m%d_%H%M%S)
cd /opt/webserver/admin-panel/backups/$(date +%Y%m%d_%H%M%S)

# 3. Backup current files
cp /opt/webserver/admin-panel/app/Http/Controllers/DashboardController.php ./
cp /etc/php/8.3/fpm/pool.d/admin-panel.conf ./

# 4. Check current Laravel logs
tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log
```

### Deployment - Solution A (Recommended)

```bash
# Step 1: Deploy dashboard view file
cd /opt/webserver/admin-panel/resources/views/

# Create dashboard.blade.php with the content from repository
# (Upload via scp or paste content)
nano dashboard.blade.php
# Paste content from dashboard.blade.php file

# Set correct ownership
chown www-data:www-data dashboard.blade.php
chmod 644 dashboard.blade.php

# Step 2: Update PHP-FPM pool configuration
cd /etc/php/8.3/fpm/pool.d/

# Backup current config
cp admin-panel.conf admin-panel.conf.backup

# Replace with fixed config
# (Upload via scp or paste content)
nano admin-panel.conf
# Paste content from admin-panel-pool-FIXED.conf

# Step 3: Set correct permissions on Laravel directories
chown -R www-data:www-data /opt/webserver/admin-panel/storage
chown -R www-data:www-data /opt/webserver/admin-panel/bootstrap/cache
chmod -R 775 /opt/webserver/admin-panel/storage
chmod -R 775 /opt/webserver/admin-panel/bootstrap/cache

# Step 4: Clear Laravel caches
cd /opt/webserver/admin-panel
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan route:clear

# Step 5: Restart PHP-FPM
systemctl restart php8.3-fpm
systemctl status php8.3-fpm

# Step 6: Reload NGINX
nginx -t
systemctl reload nginx
```

### Deployment - Solution B (Alternative)

```bash
# Step 1: Deploy dashboard view file (same as Solution A)
cd /opt/webserver/admin-panel/resources/views/
# Upload dashboard.blade.php
nano dashboard.blade.php
# Paste content

chown www-data:www-data dashboard.blade.php
chmod 644 dashboard.blade.php

# Step 2: Replace DashboardController
cd /opt/webserver/admin-panel/app/Http/Controllers/

# Backup current controller
cp DashboardController.php DashboardController.php.backup

# Replace with fixed version
# Upload DashboardController-FIXED.php and rename
nano DashboardController.php
# Paste content from DashboardController-FIXED.php

chown www-data:www-data DashboardController.php
chmod 644 DashboardController.php

# Step 3: Set permissions (same as Solution A)
chown -R www-data:www-data /opt/webserver/admin-panel/storage
chown -R www-data:www-data /opt/webserver/admin-panel/bootstrap/cache
chmod -R 775 /opt/webserver/admin-panel/storage
chmod -R 775 /opt/webserver/admin-panel/bootstrap/cache

# Step 4: Clear caches (same as Solution A)
cd /opt/webserver/admin-panel
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan route:clear

# Step 5: Restart PHP-FPM (same as Solution A)
systemctl restart php8.3-fpm
systemctl status php8.3-fpm

# Step 6: Reload NGINX (same as Solution A)
nginx -t
systemctl reload nginx
```

---

## ✅ TESTING PROCEDURE

### Test 1: Basic Access
```
1. Open browser: http://72.61.53.222:8080
2. Should see login page
3. Enter credentials: admin@localhost / Jm@D@KDPnw7Q
4. Click Login
5. Should redirect to /dashboard
```

**Expected Result:** Dashboard loads without Error 500

### Test 2: Dashboard Display
```
1. After successful login
2. Dashboard should show:
   - CPU Usage metric with percentage and progress bar
   - Memory Usage metric with percentage and progress bar
   - Disk Usage metric with percentage and progress bar
   - Services Status section (NGINX, PHP-FPM, MariaDB, etc.)
   - Summary Statistics (Sites, Email Domains, Email Accounts, Uptime)
   - Quick Actions buttons
```

**Expected Result:** All metrics display with correct values

### Test 3: API Endpoints
```bash
# Test from command line (after login, need session cookie)
curl -H "Cookie: laravel_session=YOUR_SESSION" http://72.61.53.222:8080/api/metrics
curl -H "Cookie: laravel_session=YOUR_SESSION" http://72.61.53.222:8080/api/services
curl -H "Cookie: laravel_session=YOUR_SESSION" http://72.61.53.222:8080/api/summary
```

**Expected Result:** JSON responses with metric data

### Test 4: Verify No Errors in Logs
```bash
# Check Laravel logs
tail -20 /opt/webserver/admin-panel/storage/logs/laravel.log
# Should show no ERROR lines for dashboard access

# Check PHP-FPM logs
tail -20 /var/log/php8.3-fpm.log
# Should show no errors

# Check NGINX error logs
tail -20 /var/log/nginx/admin-panel.error.log
# Should show no 500 errors
```

**Expected Result:** No error messages related to dashboard

---

## 🐛 TROUBLESHOOTING

### If Dashboard Still Shows Error 500

#### Check 1: Verify View File Exists
```bash
ls -la /opt/webserver/admin-panel/resources/views/dashboard.blade.php
```
Should exist with www-data ownership

#### Check 2: Verify Laravel Can Find View
```bash
cd /opt/webserver/admin-panel
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan view:cache
```

#### Check 3: Check Laravel Logs
```bash
tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log | grep ERROR
```
Look for specific error messages

#### Check 4: Check PHP-FPM Pool Is Running
```bash
systemctl status php8.3-fpm
ps aux | grep php8.3-fpm-admin-panel
```

#### Check 5: Verify open_basedir Setting
```bash
# If using Solution A
cat /etc/php/8.3/fpm/pool.d/admin-panel.conf | grep open_basedir
# Should show: /opt/webserver:/etc/postfix:/var/mail:/proc:/tmp
```

#### Check 6: Test PHP Access to /proc
```bash
cd /opt/webserver/admin-panel
sudo -u www-data php -r "echo file_get_contents('/proc/uptime');"
# Should output uptime data without errors
```

### If Services Show as Stopped

This is expected with Solution B as we can't use `systemctl` from PHP.

**Fix:**
- Use Solution A (expanded open_basedir)
- OR accept that service status will always show "running" in Solution B
- OR create a privileged API service (future enhancement)

### If Metrics Show 0

**Possible causes:**
1. open_basedir still too restrictive
2. /proc not accessible
3. Permissions on /opt/webserver

**Fix:**
```bash
# Check access
sudo -u www-data php -r "echo disk_free_space('/opt/webserver');"
sudo -u www-data php -r "var_dump(sys_getloadavg());"
```

---

## 📊 EXPECTED DASHBOARD APPEARANCE

### Metrics Section (Top Row)
```
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   CPU Usage     │ │  Memory Usage   │ │   Disk Usage    │
│                 │ │                 │ │                 │
│     45.2%       │ │     62.5%       │ │     38.3%       │
│ Load: 0.9, ... │ │   RAM in use    │ │ Free: 120GB/... │
│ [████████░░░░] │ │ [████████░░░░] │ │ [█████░░░░░░░] │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

### Services Status Section
```
┌─────────────────────────────────────────────────────────┐
│ Services Status                                         │
├─────────────────────────────────────────────────────────┤
│ NGINX ✓ Running    │ PHP-FPM ✓ Running                 │
│ MariaDB ✓ Running  │ Redis ✓ Running                   │
│ Postfix ✓ Running  │ Dovecot ✓ Running                 │
│ Fail2Ban ✓ Running │                                   │
└─────────────────────────────────────────────────────────┘
```

### Summary Statistics
```
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Hosted Sites │ │Email Domains │ │Email Accounts│ │Server Uptime │
│      2       │ │      1       │ │      3       │ │ 2 days, 5h   │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

---

## 📁 FILE UPLOAD METHODS

### Method 1: SCP Upload (Recommended)
```bash
# From your local machine with the files
scp dashboard.blade.php root@72.61.53.222:/tmp/
scp admin-panel-pool-FIXED.conf root@72.61.53.222:/tmp/
scp DashboardController-FIXED.php root@72.61.53.222:/tmp/

# Then on server, move to correct locations
ssh root@72.61.53.222
mv /tmp/dashboard.blade.php /opt/webserver/admin-panel/resources/views/
mv /tmp/admin-panel-pool-FIXED.conf /etc/php/8.3/fpm/pool.d/admin-panel.conf
chown www-data:www-data /opt/webserver/admin-panel/resources/views/dashboard.blade.php
```

### Method 2: Git Clone (If files in GitHub)
```bash
ssh root@72.61.53.222
cd /tmp
git clone https://github.com/fmunizmcorp/servidorvpsprestadores.git
cd servidorvpsprestadores

# Copy files to correct locations
cp dashboard.blade.php /opt/webserver/admin-panel/resources/views/
cp admin-panel-pool-FIXED.conf /etc/php/8.3/fpm/pool.d/admin-panel.conf
chown www-data:www-data /opt/webserver/admin-panel/resources/views/dashboard.blade.php
```

### Method 3: Manual Paste (Fallback)
```bash
ssh root@72.61.53.222

# Create view file
nano /opt/webserver/admin-panel/resources/views/dashboard.blade.php
# Paste entire content from dashboard.blade.php
# Save with Ctrl+X, Y, Enter

# Update pool config
nano /etc/php/8.3/fpm/pool.d/admin-panel.conf
# Paste entire content from admin-panel-pool-FIXED.conf
# Save with Ctrl+X, Y, Enter

chown www-data:www-data /opt/webserver/admin-panel/resources/views/dashboard.blade.php
```

---

## ✅ SUCCESS CRITERIA

Dashboard is considered FIXED when:

```
✅ No Error 500 when accessing /dashboard
✅ Dashboard page loads with visual layout
✅ CPU metric displays with value > 0
✅ Memory metric displays with value > 0
✅ Disk metric displays with value > 0
✅ Services status section shows all services
✅ Summary statistics display
✅ No errors in Laravel logs
✅ No errors in PHP-FPM logs
✅ User can logout successfully
✅ Auto-refresh works (every 30 seconds)
```

---

## 📞 NEXT STEPS AFTER FIX

Once dashboard is working:

1. ✅ Mark Sprint 5.2 as COMPLETE
2. ⏳ Begin Sprint 5.3: Sites Management Module
3. ⏳ Continue with remaining visual modules
4. ⏳ Complete end-to-end testing
5. ⏳ Update documentation with accurate status

---

**Document Created:** 2025-11-16  
**Last Updated:** 2025-11-16  
**Status:** Ready for Deployment  
**Recommended Solution:** Solution A (Expanded open_basedir)
