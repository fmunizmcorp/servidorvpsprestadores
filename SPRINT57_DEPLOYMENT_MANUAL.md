# 🚀 SPRINT 57: MANUAL DEPLOYMENT INSTRUCTIONS

**Date:** November 23, 2025  
**Purpose:** Deploy CSRF token refresh fix for Sites creation  
**Status:** ⏳ **READY FOR DEPLOYMENT**

---

## 📋 PRE-DEPLOYMENT CHECKLIST

- [ ] You have SSH access to 72.61.53.222
- [ ] You have root privileges
- [ ] Admin panel is accessible at https://72.61.53.222/admin/
- [ ] Current behavior confirmed: Site creation redirects to login

---

## 🎯 WHAT THIS FIX DOES

### Problem:
- User submits "Create Site" form
- Laravel's VerifyCsrfToken middleware detects token mismatch
- Throws TokenMismatchException
- Exception handler redirects to /login
- **Controller NEVER executes**

### Solution:
- JavaScript intercepts form submission
- Fetches fresh CSRF token from server
- Updates form token value
- Submits form with fresh token
- Token matches → No exception → Controller executes!

---

## 📁 FILES TO MODIFY

1. `/opt/webserver/admin-panel/resources/views/sites/create.blade.php`
2. `/opt/webserver/admin-panel/routes/web.php`

---

## 🔧 DEPLOYMENT STEPS

### Step 1: Connect to Server

```bash
ssh root@72.61.53.222
# Password: mcorpapp
```

### Step 2: Navigate to Admin Panel Directory

```bash
cd /opt/webserver/admin-panel
```

### Step 3: Create Backup

```bash
# Create backup directory
mkdir -p backups/sprint57_$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/sprint57_$(date +%Y%m%d_%H%M%S)"

# Backup files
cp resources/views/sites/create.blade.php "$BACKUP_DIR/" 2>/dev/null || echo "No existing create.blade.php"
cp routes/web.php "$BACKUP_DIR/"

echo "✅ Backup created at: $BACKUP_DIR"
```

### Step 4: Update sites/create.blade.php

**Option A: Download from GitHub**

```bash
cd /opt/webserver/admin-panel/resources/views/sites
wget https://raw.githubusercontent.com/fmunizmcorp/servidorvpsprestadores/genspark_ai_developer/sites_create_FIXED.blade.php -O create.blade.php
```

**Option B: Create manually** (if GitHub is not accessible)

```bash
cd /opt/webserver/admin-panel/resources/views/sites

# Create new file with vi/nano
nano create.blade.php
# Or
vi create.blade.php
```

Then paste the contents from `sites_create_FIXED.blade.php` (see attached file in repository).

**Key changes in this file:**
- Line 126: `e.preventDefault()` added to intercept form submission
- Lines 133-152: Fetch fresh CSRF token from `/csrf-refresh` endpoint
- Line 154: Updates `_token` input with fresh value
- Line 178: Submits form with fresh token

### Step 5: Add CSRF Refresh Route

```bash
cd /opt/webserver/admin-panel
nano routes/web.php
```

**Find this section** (around line 34):

```php
Route::middleware(['auth'])->group(function () {
    
    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
```

**Add this code RIGHT AFTER the dashboard route:**

```php
    // SPRINT 57 FIX: CSRF token refresh endpoint
    // Used by sites/create form to get fresh token before submission
    Route::get('/csrf-refresh', function() {
        return response()->json([
            'token' => csrf_token(),
            'session_id' => session()->getId(),
            'timestamp' => now()->toDateTimeString(),
        ]);
    })->name('csrf.refresh');
```

**The result should look like:**

```php
Route::middleware(['auth'])->group(function () {
    
    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    
    // SPRINT 57 FIX: CSRF token refresh endpoint
    Route::get('/csrf-refresh', function() {
        return response()->json([
            'token' => csrf_token(),
            'session_id' => session()->getId(),
            'timestamp' => now()->toDateTimeString(),
        ]);
    })->name('csrf.refresh');
    
    // Profile Routes (Laravel Breeze default)
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    // ... rest of routes
```

### Step 6: Set Permissions

```bash
cd /opt/webserver/admin-panel

chown www-data:www-data resources/views/sites/create.blade.php
chown www-data:www-data routes/web.php
chmod 644 resources/views/sites/create.blade.php
chmod 644 routes/web.php
```

### Step 7: Clear Laravel Caches

```bash
cd /opt/webserver/admin-panel

php artisan route:clear
php artisan config:clear
php artisan view:clear
php artisan cache:clear
php artisan clear-compiled

echo "✅ All caches cleared"
```

### Step 8: Verify Deployment

```bash
# Check if SPRINT57 markers exist in blade file
grep -c "SPRINT57" resources/views/sites/create.blade.php
# Should output a number > 0

# Check if CSRF refresh route exists
grep -c "csrf-refresh" routes/web.php
# Should output 1 or more

# List available routes (should include csrf.refresh)
php artisan route:list | grep csrf
```

---

## 🧪 TESTING PROCEDURE

### Test 1: Verify CSRF Refresh Endpoint

```bash
# From your local machine or server:
curl -X GET https://72.61.53.222/admin/csrf-refresh \
  -H "Cookie: laravel_session=YOUR_SESSION_COOKIE" \
  -H "Accept: application/json"

# Expected response:
# {"token":"SOME_TOKEN_VALUE","session_id":"SESSION_ID","timestamp":"2025-11-23 ..."}
```

### Test 2: Create Site via Web Interface

1. **Open browser** and navigate to: https://72.61.53.222/admin/

2. **Login** with:
   - Email: `admin@vps.local`
   - Password: `mcorpapp`

3. **Navigate** to: Sites → Create New Site

4. **Fill form:**
   - Site Name: `sprint57_test`
   - Domain: `sprint57-test.local`
   - PHP Version: `8.3`
   - Create Database: ✓ (checked)

5. **Open browser console** (F12 → Console tab)

6. **Click "Create Site"**

7. **Watch console logs:**
   ```
   SPRINT57: Form submit intercepted, refreshing CSRF token...
   SPRINT57: Received fresh CSRF token
   SPRINT57: CSRF token updated in form
   SPRINT57: Submitting form with fresh token...
   ```

8. **Expected behavior:**
   - Processing overlay appears with spinner
   - Progress bar animates over ~30 seconds
   - ✅ **NO redirect to login!**
   - ✅ **Redirects to /admin/sites with success message**
   - ✅ **New site appears in the list!**

### Test 3: Verify in Laravel Logs

```bash
ssh root@72.61.53.222
tail -100 /opt/webserver/admin-panel/storage/logs/laravel.log | grep -A 5 "SPRINT55"
```

**Expected log entries:**
```
[2025-11-23 ...] production.INFO: === SPRINT55: store() called === {"site_name":"sprint57_test",...}
[2025-11-23 ...] production.INFO: SPRINT55: Executing command {...}
[2025-11-23 ...] production.INFO: SPRINT_RECOVERY: Site physically created {...}
[2025-11-23 ...] production.INFO: SPRINT55: Site persisted to database {"site_id":123}
```

**✅ If you see these logs, the controller IS executing! Fix worked!**

### Test 4: Verify Database Persistence

```bash
ssh root@72.61.53.222
mysql -u root -p admin_panel
# Enter MySQL password when prompted
```

```sql
SELECT * FROM sites WHERE site_name = 'sprint57_test' \G

-- Expected output:
-- site_name: sprint57_test
-- domain: sprint57-test.local
-- status: active
-- created_at: 2025-11-23 ...
```

### Test 5: Verify Physical Directory Creation

```bash
ssh root@72.61.53.222
ls -la /opt/webserver/sites/sprint57_test/
```

**Expected output:**
```
drwxr-xr-x  5 www-data www-data 4096 Nov 23 ... .
drwxr-xr-x 10 www-data www-data 4096 Nov 23 ... ..
-rw-r--r--  1 www-data www-data  XXX Nov 23 ... CREDENTIALS.txt
drwxr-xr-x  2 www-data www-data 4096 Nov 23 ... logs
drwxr-xr-x  2 www-data www-data 4096 Nov 23 ... public_html
```

---

## ✅ SUCCESS CRITERIA

Mark as ✅ when ALL of these are true:

- [ ] Site creation form submits without redirect to login
- [ ] Laravel logs show "SPRINT55: store() called"
- [ ] Laravel logs show "SPRINT55: Site persisted to database"
- [ ] Database has new site record
- [ ] Physical directory exists at /opt/webserver/sites/[sitename]
- [ ] Success message appears after creation
- [ ] New site appears in Sites list
- [ ] Browser console shows SPRINT57 log messages

---

## 🔄 ROLLBACK PROCEDURE

If the fix doesn't work or causes issues:

```bash
cd /opt/webserver/admin-panel

# Find your backup directory
ls -lt backups/ | head -5

# Restore files
BACKUP_DIR="backups/sprint57_YYYYMMDD_HHMMSS"  # Use actual directory name
cp "$BACKUP_DIR/create.blade.php" resources/views/sites/create.blade.php
cp "$BACKUP_DIR/web.php" routes/web.php

# Set permissions
chown www-data:www-data resources/views/sites/create.blade.php
chown www-data:www-data routes/web.php

# Clear caches
php artisan route:clear
php artisan config:clear
php artisan view:clear

echo "✅ Rollback complete"
```

---

## 🐛 TROUBLESHOOTING

### Issue: "Failed to fetch CSRF token" alert appears

**Cause:** `/csrf-refresh` route not accessible

**Solution:**
1. Verify route exists: `php artisan route:list | grep csrf`
2. Check routes/web.php has the csrf-refresh route
3. Clear route cache: `php artisan route:clear`

### Issue: Still redirects to login after fix

**Possible Causes:**

1. **Blade file not updated properly**
   - Check: `grep "SPRINT57" resources/views/sites/create.blade.php`
   - Should return multiple matches

2. **View cache not cleared**
   - Run: `php artisan view:clear`
   - Try: `rm -rf storage/framework/views/*`

3. **Different issue (not CSRF)**
   - Check logs: `tail -100 storage/logs/laravel.log`
   - Look for actual error message
   - May need different fix

### Issue: Console shows CORS error

**Cause:** Browser blocking fetch request

**Solution:**
- CSRF refresh endpoint is on same domain, should not have CORS issues
- Check browser console for actual error
- Verify fetch URL is correct ('/csrf-refresh')

---

## 📊 EXPECTED IMPACT

### Before Fix:
- ❌ Sites creation: **BROKEN**
- ❌ Success rate: 50% (2/4 modules working)
- ❌ Controller never executes
- ❌ Data not saved
- ❌ Directories not created

### After Fix:
- ✅ Sites creation: **WORKING**
- ✅ Success rate: 75% (3/4 modules working)
- ✅ Controller executes normally
- ✅ Data persists to database
- ✅ Directories created physically

### Still To Test:
- Email Domains creation (may have same CSRF issue)

---

## 📝 AFTER SUCCESSFUL DEPLOYMENT

1. **Test Email Domains** (may have same issue):
   - Navigate to Email → Domains → Add Domain
   - Try creating a domain
   - If same redirect to login occurs, apply same fix to domains/create.blade.php

2. **Report Results:**
   - Document test results
   - Include logs showing controller execution
   - Include screenshots of successful creation
   - Include database and filesystem verification

3. **Update Documentation:**
   - Mark Sites module as ✅ WORKING
   - Update success rate
   - Document any additional findings

---

## 🔗 RELATED FILES IN REPOSITORY

- `sites_create_FIXED.blade.php` - Fixed blade template
- `SPRINT57_SURGICAL_FIX.md` - Detailed fix explanation
- `SPRINT57_ROOT_CAUSE_ANALYSIS.md` - Root cause analysis
- `add_csrf_refresh_route.txt` - Route addition instructions

---

## 💬 QUESTIONS?

If you encounter issues not covered here:

1. Check Laravel logs: `storage/logs/laravel.log`
2. Check browser console for JavaScript errors
3. Check NGINX logs: `/var/log/nginx/error.log`
4. Verify PHP-FPM is running: `systemctl status php8.3-fpm`
5. Test CSRF refresh endpoint directly (curl command above)

---

**THIS IS A SURGICAL FIX. ONLY TWO FILES MODIFIED. NO IMPACT ON WORKING MODULES.**

**Ready for deployment!** 🚀
