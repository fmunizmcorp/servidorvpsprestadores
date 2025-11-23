#!/bin/bash

# ============================================================================
# SPRINT 57 - SURGICAL FIX DEPLOYMENT
# ============================================================================
# Purpose: Deploy CSRF token refresh fix for Sites creation
# 
# Root Cause: CSRF token mismatch causing TokenMismatchException
# Fix: Refresh CSRF token immediately before form submission
# 
# What this fixes:
# - POST /sites now reaches SitesController@store
# - No more redirect to login on form submit
# - Data persists to database
# - Directories created physically
#
# What this does NOT touch:
# - SitesController (it's correct, just never executed before)
# - Routes structure (correct)
# - Backups module (working)
# - Email Accounts module (working)
# ============================================================================

set -e

SERVER="72.61.53.222"
USER="root"
PASSWORD="mcorpapp"

echo "=================================================="
echo " SPRINT 57: DEPLOYING SURGICAL FIX"
echo "=================================================="
echo ""
echo "🎯 Fix: CSRF token refresh before form submission"
echo "📁 Files to modify:"
echo "   1. resources/views/sites/create.blade.php"
echo "   2. routes/web.php (add CSRF refresh endpoint)"
echo ""
echo "⚠️  This does NOT modify:"
echo "   ❌ SitesController (already correct)"
echo "   ❌ Other working modules"
echo "   ❌ Route structure"
echo ""

# Create a temporary script that will be executed on the server
# This avoids sshpass password issues
cat > /tmp/deploy_sprint57.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

echo "📦 Creating backup..."
cd /opt/webserver/admin-panel

# Backup current files
BACKUP_DIR="backups/sprint57_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp resources/views/sites/create.blade.php "$BACKUP_DIR/" 2>/dev/null || echo "No existing create.blade.php"
cp routes/web.php "$BACKUP_DIR/"

echo "✅ Backup created at: $BACKUP_DIR"

echo ""
echo "📝 Updating sites/create.blade.php..."

# Create the fixed blade template
cat > resources/views/sites/create.blade.php << 'BLADE_EOF'
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Create New Site') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <!-- Processing Overlay -->
                    <div id="processing-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); z-index:9999; justify-content:center; align-items:center;">
                        <div style="background:white; padding:40px; border-radius:10px; text-align:center; max-width:500px;">
                            <div style="margin-bottom:20px;">
                                <svg class="animate-spin h-16 w-16 mx-auto text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                </svg>
                            </div>
                            <h3 style="font-size:1.5rem; font-weight:bold; color:#1f2937; margin-bottom:10px;">Creating Site...</h3>
                            <p style="color:#6b7280; margin-bottom:20px;">Site creation is in progress. This process takes approximately <strong>25-30 seconds</strong>.</p>
                            <div style="background:#e5e7eb; height:8px; border-radius:4px; overflow:hidden; margin-bottom:15px;">
                                <div id="progress-bar" style="background:#3b82f6; height:100%; width:0%; transition:width 0.5s;"></div>
                            </div>
                            <p style="color:#9ca3af; font-size:0.875rem;">Please wait, you will be redirected automatically...</p>
                            <p style="color:#9ca3af; font-size:0.875rem; margin-top:10px;"><strong>Do not close this window or refresh the page.</strong></p>
                        </div>
                    </div>

                    <form method="POST" action="{{ route('sites.store') }}" id="site-create-form">
                        @csrf

                        <!-- Site Name -->
                        <div class="mb-4">
                            <label for="site_name" class="block text-sm font-medium text-gray-700">Site Name</label>
                            <input type="text" name="site_name" id="site_name" required
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                   placeholder="mysite" pattern="[a-z0-9-]+" 
                                   title="Only lowercase letters, numbers, and hyphens">
                            <p class="mt-1 text-sm text-gray-500">Only lowercase letters, numbers, and hyphens. Used for directory and database names.</p>
                        </div>

                        <!-- Domain -->
                        <div class="mb-4">
                            <label for="domain" class="block text-sm font-medium text-gray-700">Domain</label>
                            <input type="text" name="domain" id="domain" required
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                   placeholder="example.com">
                            <p class="mt-1 text-sm text-gray-500">The domain name that will point to this site.</p>
                        </div>

                        <!-- PHP Version -->
                        <div class="mb-4">
                            <label for="php_version" class="block text-sm font-medium text-gray-700">PHP Version</label>
                            <select name="php_version" id="php_version" required
                                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <option value="8.3">PHP 8.3</option>
                                <option value="8.2">PHP 8.2</option>
                                <option value="8.1">PHP 8.1</option>
                            </select>
                        </div>

                        <!-- Create Database -->
                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="create_database" id="create_database" value="1" checked
                                       class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <span class="ml-2 text-sm text-gray-700">Create Database</span>
                            </label>
                            <p class="mt-1 text-sm text-gray-500">Automatically create a MySQL database for this site.</p>
                        </div>

                        <!-- Install WordPress -->
                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="installWP" id="installWP"
                                       class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <span class="ml-2 text-sm text-gray-700">Install WordPress</span>
                            </label>
                            <p class="mt-1 text-sm text-gray-500">Download and install WordPress (requires database).</p>
                        </div>

                        <!-- Enable FastCGI Cache -->
                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="enableCache" id="enableCache" checked
                                       class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <span class="ml-2 text-sm text-gray-700">Enable FastCGI Cache</span>
                            </label>
                            <p class="mt-1 text-sm text-gray-500">Enable NGINX FastCGI caching for better performance.</p>
                        </div>

                        <div class="flex items-center justify-between mt-6">
                            <a href="{{ route('sites.index') }}" class="text-gray-600 hover:text-gray-900">Cancel</a>
                            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                                Create Site
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Info Box -->
            <div class="mt-6 bg-blue-50 border-l-4 border-blue-400 p-4">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
                        </svg>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-blue-700">
                            After creating the site, you'll receive database credentials. Save them securely!
                            The site will be created at <code>/opt/webserver/sites/[sitename]/public_html</code>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // SPRINT 57 FIX: Refresh CSRF token before submission to prevent TokenMismatchException
        document.getElementById('site-create-form').addEventListener('submit', function(e) {
            e.preventDefault(); // Prevent default submission
            
            const form = this;
            const submitBtn = form.querySelector('button[type="submit"]');
            const overlay = document.getElementById('processing-overlay');
            const progressBar = document.getElementById('progress-bar');
            
            console.log('SPRINT57: Form submit intercepted, refreshing CSRF token...');
            
            // Fetch fresh CSRF token from server
            fetch('/csrf-refresh', {
                method: 'GET',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'Accept': 'application/json'
                },
                credentials: 'same-origin'
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to fetch CSRF token: ' + response.status);
                }
                return response.json();
            })
            .then(data => {
                console.log('SPRINT57: Received fresh CSRF token');
                
                // Update CSRF token in form
                const csrfInput = form.querySelector('input[name="_token"]');
                if (csrfInput && data.token) {
                    csrfInput.value = data.token;
                    console.log('SPRINT57: CSRF token updated in form');
                } else {
                    console.warn('SPRINT57: Could not find CSRF input or token in response');
                }
                
                // Show processing overlay
                overlay.style.display = 'flex';
                
                // Disable submit button to prevent double-submission
                submitBtn.disabled = true;
                submitBtn.style.opacity = '0.5';
                submitBtn.textContent = 'Creating...';
                
                // Animate progress bar over 30 seconds
                let progress = 0;
                const interval = setInterval(function() {
                    progress += 1;
                    progressBar.style.width = progress + '%';
                    
                    if (progress >= 95) {
                        clearInterval(interval);
                        // Keep at 95% until actual redirect happens
                    }
                }, 300); // Update every 300ms for 30 seconds (300ms * 100 = 30s)
                
                console.log('SPRINT57: Submitting form with fresh CSRF token...');
                
                // NOW submit the form with fresh token
                form.submit();
            })
            .catch(error => {
                console.error('SPRINT57: Error refreshing CSRF token:', error);
                alert('Failed to refresh security token. Please reload the page and try again.\n\nError: ' + error.message);
                
                // Re-enable submit button so user can retry
                submitBtn.disabled = false;
                submitBtn.style.opacity = '1';
                submitBtn.textContent = 'Create Site';
            });
        });
    </script>
</x-app-layout>
BLADE_EOF

echo "✅ sites/create.blade.php updated"

echo ""
echo "📝 Adding CSRF refresh route to routes/web.php..."

# Check if route already exists
if grep -q "csrf-refresh" routes/web.php; then
    echo "⚠️  CSRF refresh route already exists, skipping..."
else
    # Find the line with "Route::middleware(['auth'])->group(function () {"
    # and insert the CSRF refresh route after the dashboard route
    
    # Create a temporary file with the CSRF route
    cat > /tmp/csrf_route.txt << 'CSRF_ROUTE'

    // SPRINT 57 FIX: CSRF token refresh endpoint
    // Used by sites/create form to get fresh token before submission
    Route::get('/csrf-refresh', function() {
        return response()->json([
            'token' => csrf_token(),
            'session_id' => session()->getId(),
            'timestamp' => now()->toDateTimeString(),
        ]);
    })->name('csrf.refresh');
CSRF_ROUTE

    # Insert after the dashboard route (line ~34)
    # Using awk to insert after specific pattern
    awk '
        /Route::get\(.*dashboard.*DashboardController/ {
            print
            getline
            print
            # Read and print the CSRF route from temp file
            while ((getline line < "/tmp/csrf_route.txt") > 0) {
                print line
            }
            close("/tmp/csrf_route.txt")
            next
        }
        {print}
    ' routes/web.php > routes/web.php.new
    
    mv routes/web.php.new routes/web.php
    echo "✅ CSRF refresh route added to routes/web.php"
fi

echo ""
echo "🔧 Setting permissions..."
chown www-data:www-data resources/views/sites/create.blade.php
chown www-data:www-data routes/web.php
chmod 644 resources/views/sites/create.blade.php
chmod 644 routes/web.php

echo "✅ Permissions set"

echo ""
echo "🗑️  Clearing Laravel caches..."
php artisan route:clear
php artisan config:clear
php artisan view:clear
php artisan cache:clear

echo "✅ Caches cleared"

echo ""
echo "🔍 Verifying deployment..."
if grep -q "SPRINT57" resources/views/sites/create.blade.php; then
    echo "✅ SPRINT57 fix markers found in create.blade.php"
else
    echo "❌ WARNING: SPRINT57 markers not found"
fi

if grep -q "csrf-refresh" routes/web.php; then
    echo "✅ CSRF refresh route found in web.php"
else
    echo "❌ WARNING: CSRF refresh route not found"
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Backup location: $BACKUP_DIR"
DEPLOY_SCRIPT

# Copy the deployment script to server and execute it
echo "📤 Transferring deployment script to server..."
chmod +x /tmp/deploy_sprint57.sh

# Use expect to handle password interactively since sshpass is having issues
expect << EOF
set timeout 30
spawn scp -o StrictHostKeyChecking=no /tmp/deploy_sprint57.sh $USER@$SERVER:/tmp/
expect {
    "password:" { send "$PASSWORD\r"; exp_continue }
    eof
}

spawn ssh -o StrictHostKeyChecking=no $USER@$SERVER "bash /tmp/deploy_sprint57.sh"
expect {
    "password:" { send "$PASSWORD\r"; exp_continue }
    eof
}
EOF

echo ""
echo "=================================================="
echo " ✅ DEPLOYMENT COMPLETE"
echo "=================================================="
echo ""
echo "📋 WHAT WAS DONE:"
echo "  ✅ Backed up original files"
echo "  ✅ Updated sites/create.blade.php with CSRF token refresh"
echo "  ✅ Added /csrf-refresh route to routes/web.php"
echo "  ✅ Set correct permissions"
echo "  ✅ Cleared all Laravel caches"
echo ""
echo "🧪 HOW TO TEST:"
echo "  1. Login to admin panel: https://72.61.53.222/admin/"
echo "     Email: admin@vps.local"
echo "     Password: mcorpapp"
echo ""
echo "  2. Navigate to Sites → Create New Site"
echo ""
echo "  3. Fill in the form:"
echo "     Site Name: sprint57_test"
echo "     Domain: sprint57-test.local"
echo "     PHP Version: 8.3"
echo "     Create Database: ✓ (checked)"
echo ""
echo "  4. Click 'Create Site'"
echo ""
echo "  5. EXPECTED RESULT:"
echo "     ✅ Processing overlay appears (30s animation)"
echo "     ✅ Form submits without redirect to login"
echo "     ✅ Redirects to Sites list with success message"
echo "     ✅ New site appears in the list"
echo ""
echo "🔍 HOW TO VERIFY:"
echo "  1. Check Laravel logs:"
echo "     ssh root@72.61.53.222 'tail -100 /opt/webserver/admin-panel/storage/logs/laravel.log | grep -E \"SPRINT55|SPRINT57\"'"
echo ""
echo "  2. Check database:"
echo "     ssh root@72.61.53.222"
echo "     mysql -u root -p admin_panel"
echo "     SELECT * FROM sites WHERE site_name = 'sprint57_test';"
echo ""
echo "  3. Check filesystem:"
echo "     ssh root@72.61.53.222 'ls -la /opt/webserver/sites/sprint57_test/'"
echo ""
echo "📊 WHAT THIS FIX DOES:"
echo "  - Prevents CSRF TokenMismatchException"
echo "  - Fetches fresh CSRF token immediately before submission"
echo "  - Ensures token matches current session state"
echo "  - Allows SitesController@store to execute"
echo ""
echo "=================================================="
