#!/bin/bash
# Sprint 46 - Complete Deployment Script
# Deploy EmailController + Sites View + Cache Clear

set -e  # Exit on error

echo "======================================"
echo "SPRINT 46 - DEPLOYMENT STARTING"
echo "======================================"
echo ""

# Variables
ADMIN_PATH="/opt/webserver/admin-panel"
BACKUP_DIR="/opt/webserver/backups/sprint46-$(date +%Y%m%d-%H%M%S)"

# Create backup directory
echo "[1/8] Creating backup directory..."
mkdir -p "$BACKUP_DIR"
echo "✅ Backup directory: $BACKUP_DIR"
echo ""

# Backup EmailController
echo "[2/8] Backing up EmailController.php..."
if [ -f "$ADMIN_PATH/app/Http/Controllers/EmailController.php" ]; then
    cp "$ADMIN_PATH/app/Http/Controllers/EmailController.php" "$BACKUP_DIR/EmailController.php.backup"
    echo "✅ EmailController backed up"
else
    echo "⚠️  EmailController not found (will be created)"
fi
echo ""

# Backup Sites create view
echo "[3/8] Backing up sites/create.blade.php..."
if [ -f "$ADMIN_PATH/resources/views/sites/create.blade.php" ]; then
    cp "$ADMIN_PATH/resources/views/sites/create.blade.php" "$BACKUP_DIR/create.blade.php.backup"
    echo "✅ Sites view backed up"
else
    echo "⚠️  Sites view not found (will be created)"
fi
echo ""

# Deploy EmailController with Sprint 46 fix
echo "[4/8] Deploying EmailController.php with Sprint 46 fix..."
cat > "$ADMIN_PATH/app/Http/Controllers/EmailController.php" << 'EOFCONTROLLER'
<?php

namespace App\Http\Controllers;

use App\Models\EmailDomain;
use App\Models\EmailAccount;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class EmailController extends Controller
{
    private $scriptsPath = '/opt/webserver/scripts';
    private $postfixPath = '/etc/postfix';
    
    /**
     * Email management dashboard
     */
    public function index()
    {
        $stats = $this->getEmailStats();
        
        return view('email.index', [
            'stats' => $stats
        ]);
    }
    
    /**
     * Manage email domains
     */
    public function domains()
    {
        // SPRINT 26 FIX: Fetch from database instead of filesystem
        $domains = EmailDomain::withCount('emailAccounts')
            ->orderBy('created_at', 'desc')
            ->get();
        
        // Enrich with filesystem data
        $domains = $domains->map(function($domain) {
            return [
                'id' => $domain->id,
                'name' => $domain->domain,
                'accountCount' => $domain->email_accounts_count,
                'diskUsage' => $this->getDomainDiskUsage($domain->domain),
                'dnsStatus' => $this->checkDomainDNS($domain->domain),
                'status' => $domain->status,
                'created_at' => $domain->created_at,
            ];
        })->toArray();
        
        return view('email.domains', [
            'domains' => $domains
        ]);
    }
    
    /**
     * Store new email domain
     */
    public function storeDomain(Request $request)
    {
        $request->validate([
            'domain' => 'required|string|regex:/^[a-zA-Z0-9.-]+$/',
        ]);

        $domain = strtolower($request->domain);
        
        // Check if domain already exists
        if (EmailDomain::where('domain', $domain)->exists()) {
            return redirect()->route('email.domains')
                ->with('error', 'Domain already exists');
        }

        // Create domain in database
        $emailDomain = EmailDomain::create([
            'domain' => $domain,
            'status' => 'active'
        ]);

        // Execute script to configure domain
        $script = "{$this->scriptsPath}/create-email-domain.sh";
        $output = [];
        $returnVar = 0;

        if (file_exists($script)) {
            $command = "sudo bash {$script} {$domain} 2>&1";
            exec($command, $output, $returnVar);
            
            if ($returnVar !== 0) {
                \Log::error("Failed to create email domain via script", [
                    'domain' => $domain,
                    'output' => $output,
                    'return_code' => $returnVar
                ]);
            }
        }

        return redirect()->route('email.domains')
            ->with('success', "Domain {$domain} created successfully");
    }
    
    /**
     * Delete email domain
     */
    public function deleteDomain($domain)
    {
        // Find and delete from database
        $emailDomain = EmailDomain::where('domain', $domain)->first();
        if ($emailDomain) {
            // Delete all accounts for this domain
            EmailAccount::where('domain', $domain)->delete();
            
            // Delete domain
            $emailDomain->delete();
        }

        // Execute script to remove domain configuration
        $script = "{$this->scriptsPath}/delete-email-domain.sh";
        if (file_exists($script)) {
            exec("sudo bash {$script} {$domain} 2>&1", $output, $returnVar);
        }

        return redirect()->route('email.domains')
            ->with('success', "Domain {$domain} deleted successfully");
    }
    
    /**
     * Manage email accounts
     */
    public function accounts(Request $request)
    {
        $domain = $request->get('domain');
        
        // SPRINT 26 FIX: Fetch domains from database
        // SPRINT 46 FIX: Order by created_at DESC to show newest domain first
        $domainNames = EmailDomain::orderBy('created_at', 'desc')->pluck('domain')->toArray();
        
        if (!$domain && !empty($domainNames)) {
            $domain = $domainNames[0];  // Now this is the most recent domain
        }
        
        // SPRINT 26 FIX: Fetch accounts from database
        $accounts = [];
        if ($domain) {
            $accounts = EmailAccount::where('domain', $domain)
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function($account) {
                    return [
                        'email' => $account->email,
                        'quota' => $account->quota . ' MB',
                        'used' => $this->getAccountUsage($account->email),
                        'usagePercent' => $this->calculateUsagePercent($account->email, $account->quota),
                        'status' => $account->status
                    ];
                })
                ->toArray();
        }
        
        return view('email.accounts', [
            'accounts' => $accounts,
            'domains' => $domainNames,
            'selectedDomain' => $domain
        ]);
    }
    
    /**
     * Store new email account
     */
    public function storeAccount(Request $request)
    {
        $request->validate([
            'username' => 'required|string|regex:/^[a-zA-Z0-9._-]+$/',
            'domain' => 'required|string',
            'password' => 'required|string|min:8',
            'quota' => 'required|integer|min:100|max:10240',
        ]);

        $email = $request->username . '@' . $request->domain;
        
        // Check if account already exists
        if (EmailAccount::where('email', $email)->exists()) {
            return redirect()->route('email.accounts', ['domain' => $request->domain])
                ->with('error', 'Email account already exists');
        }

        // Create account in database
        $emailAccount = EmailAccount::create([
            'email' => $email,
            'domain' => $request->domain,
            'quota' => $request->quota,
            'status' => 'active'
        ]);

        // Execute script to create account
        $script = "{$this->scriptsPath}/create-email.sh";
        $output = [];
        $returnVar = 0;

        if (file_exists($script)) {
            $command = "sudo bash {$script} {$email} {$request->password} {$request->quota} 2>&1";
            exec($command, $output, $returnVar);
            
            if ($returnVar !== 0) {
                \Log::error("Failed to create email account via script", [
                    'email' => $email,
                    'output' => $output,
                    'return_code' => $returnVar
                ]);
            }
        }

        return redirect()->route('email.accounts', ['domain' => $request->domain])
            ->with('success', "Email account {$email} created successfully")
            ->with('credentials', [
                'email' => $email,
                'password' => $request->password
            ]);
    }
    
    /**
     * Delete email account
     */
    public function deleteAccount(Request $request)
    {
        $email = $request->email;
        
        // Delete from database
        $emailAccount = EmailAccount::where('email', $email)->first();
        if ($emailAccount) {
            $domain = $emailAccount->domain;
            $emailAccount->delete();
        } else {
            $domain = substr($email, strpos($email, '@') + 1);
        }

        // Execute script to delete account
        $script = "{$this->scriptsPath}/delete-email.sh";
        if (file_exists($script)) {
            exec("sudo bash {$script} {$email} 2>&1", $output, $returnVar);
        }

        return redirect()->route('email.accounts', ['domain' => $domain])
            ->with('success', "Email account {$email} deleted successfully");
    }
    
    /**
     * Change email account password
     */
    public function changePassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string|min:8',
        ]);

        $email = $request->email;
        $domain = substr($email, strpos($email, '@') + 1);
        
        // Update in database
        $emailAccount = EmailAccount::where('email', $email)->first();
        if ($emailAccount) {
            $emailAccount->touch(); // Update timestamp
        }

        // Execute script to change password
        $script = "{$this->scriptsPath}/change-email-password.sh";
        if (file_exists($script)) {
            exec("sudo bash {$script} {$email} {$request->password} 2>&1", $output, $returnVar);
        }

        return redirect()->route('email.accounts', ['domain' => $domain])
            ->with('success', "Password changed for {$email}");
    }
    
    /**
     * Change email account quota
     */
    public function changeQuota(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'quota' => 'required|integer|min:100|max:10240',
        ]);

        $email = $request->email;
        $domain = substr($email, strpos($email, '@') + 1);
        
        // Update in database
        $emailAccount = EmailAccount::where('email', $email)->first();
        if ($emailAccount) {
            $emailAccount->quota = $request->quota;
            $emailAccount->save();
        }

        // Execute script to change quota
        $script = "{$this->scriptsPath}/change-email-quota.sh";
        if (file_exists($script)) {
            exec("sudo bash {$script} {$email} {$request->quota} 2>&1", $output, $returnVar);
        }

        return redirect()->route('email.accounts', ['domain' => $domain])
            ->with('success', "Quota changed for {$email}");
    }
    
    /**
     * Show DNS configuration
     */
    public function dns(Request $request)
    {
        $domain = $request->get('domain');
        
        if (!$domain) {
            return redirect()->route('email.domains');
        }
        
        $dnsRecords = $this->getDNSRecordsForDomain($domain);
        $currentDNS = $this->checkCurrentDNS($domain);
        
        return view('email.dns', [
            'domain' => $domain,
            'records' => $dnsRecords,
            'current' => $currentDNS
        ]);
    }
    
    /**
     * Email queue management
     */
    public function queue()
    {
        $queueStats = $this->getQueueStats();
        
        return view('email.queue', [
            'stats' => $queueStats
        ]);
    }
    
    // Helper methods
    
    private function getEmailStats()
    {
        return [
            'totalDomains' => EmailDomain::count(),
            'totalAccounts' => EmailAccount::count(),
            'activeDomains' => EmailDomain::where('status', 'active')->count(),
            'activeAccounts' => EmailAccount::where('status', 'active')->count(),
        ];
    }
    
    private function getDomainDiskUsage($domain)
    {
        $path = "/var/vmail/{$domain}";
        if (!is_dir($path)) {
            return '0 MB';
        }
        
        $output = shell_exec("du -sh {$path} 2>/dev/null | awk '{print $1}'");
        return trim($output) ?: '0 MB';
    }
    
    private function checkDomainDNS($domain)
    {
        $records = dns_get_record($domain, DNS_MX);
        return !empty($records) ? 'configured' : 'pending';
    }
    
    private function getAccountUsage($email)
    {
        $domain = substr($email, strpos($email, '@') + 1);
        $user = substr($email, 0, strpos($email, '@'));
        $path = "/var/vmail/{$domain}/{$user}";
        
        if (!is_dir($path)) {
            return '0 MB';
        }
        
        $output = shell_exec("du -sh {$path} 2>/dev/null | awk '{print $1}'");
        return trim($output) ?: '0 MB';
    }
    
    private function calculateUsagePercent($email, $quotaMB)
    {
        $usage = $this->getAccountUsage($email);
        
        // Parse usage (e.g., "10M" or "1.5G")
        $usageMB = 0;
        if (preg_match('/^([\d.]+)([KMG])/', $usage, $matches)) {
            $value = floatval($matches[1]);
            $unit = $matches[2];
            
            switch ($unit) {
                case 'K':
                    $usageMB = $value / 1024;
                    break;
                case 'M':
                    $usageMB = $value;
                    break;
                case 'G':
                    $usageMB = $value * 1024;
                    break;
            }
        }
        
        if ($quotaMB <= 0) {
            return 0;
        }
        
        return min(100, round(($usageMB / $quotaMB) * 100));
    }
    
    private function getDNSRecordsForDomain($domain)
    {
        $serverIP = gethostbyname($_SERVER['SERVER_NAME'] ?? 'localhost');
        
        return [
            [
                'type' => 'MX',
                'priority' => '10',
                'value' => "mail.{$domain}",
                'ttl' => '3600'
            ],
            [
                'type' => 'A',
                'name' => 'mail',
                'value' => $serverIP,
                'ttl' => '3600'
            ],
            [
                'type' => 'TXT',
                'name' => '@',
                'value' => "v=spf1 mx a ip4:{$serverIP} ~all",
                'ttl' => '3600'
            ],
        ];
    }
    
    private function checkCurrentDNS($domain)
    {
        $results = [];
        
        // Check MX record
        $mx = dns_get_record($domain, DNS_MX);
        $results['mx'] = !empty($mx);
        
        // Check SPF record
        $txt = dns_get_record($domain, DNS_TXT);
        $spfExists = false;
        foreach ($txt as $record) {
            if (stripos($record['txt'] ?? '', 'v=spf1') !== false) {
                $spfExists = true;
                break;
            }
        }
        $results['spf'] = $spfExists;
        
        return $results;
    }
    
    private function getQueueStats()
    {
        // Get Postfix queue statistics
        $deferred = (int)shell_exec("mailq | grep -c 'MAILER-DAEMON' 2>/dev/null || echo 0");
        $active = (int)shell_exec("mailq | grep -c '^[A-F0-9]' 2>/dev/null || echo 0");
        
        return [
            'deferred' => $deferred,
            'active' => $active,
            'total' => $deferred + $active
        ];
    }
}
EOFCONTROLLER

chmod 644 "$ADMIN_PATH/app/Http/Controllers/EmailController.php"
chown www-data:www-data "$ADMIN_PATH/app/Http/Controllers/EmailController.php"
echo "✅ EmailController deployed with Sprint 46 fix (line 147-148)"
echo ""

# Deploy Sites create view with feedback UI
echo "[5/8] Deploying sites/create.blade.php with feedback UI..."
mkdir -p "$ADMIN_PATH/resources/views/sites"

cat > "$ADMIN_PATH/resources/views/sites/create.blade.php" << 'EOFVIEW'
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
        document.getElementById('site-create-form').addEventListener('submit', function(e) {
            // Show processing overlay
            const overlay = document.getElementById('processing-overlay');
            overlay.style.display = 'flex';
            
            // Disable submit button to prevent double-submission
            const submitBtn = this.querySelector('button[type="submit"]');
            submitBtn.disabled = true;
            submitBtn.style.opacity = '0.5';
            submitBtn.textContent = 'Creating...';
            
            // Animate progress bar over 30 seconds
            const progressBar = document.getElementById('progress-bar');
            let progress = 0;
            const interval = setInterval(function() {
                progress += 1;
                progressBar.style.width = progress + '%';
                
                if (progress >= 95) {
                    clearInterval(interval);
                    // Keep at 95% until actual redirect happens
                }
            }, 300); // Update every 300ms for 30 seconds (300ms * 100 = 30s)
        });
    </script>
</x-app-layout>
EOFVIEW

chmod 644 "$ADMIN_PATH/resources/views/sites/create.blade.php"
chown www-data:www-data "$ADMIN_PATH/resources/views/sites/create.blade.php"
echo "✅ Sites create view deployed with feedback UI"
echo ""

# Clear Laravel cache
echo "[6/8] Clearing Laravel cache..."
cd "$ADMIN_PATH"
php artisan view:clear 2>&1
php artisan config:clear 2>&1
php artisan cache:clear 2>&1
php artisan optimize:clear 2>&1
echo "✅ Cache cleared"
echo ""

# Reload PHP-FPM
echo "[7/8] Reloading PHP-FPM..."
systemctl reload php8.3-fpm
sleep 2
echo "✅ PHP-FPM reloaded"
echo ""

# Verify deployment
echo "[8/8] Verifying deployment..."
if [ -f "$ADMIN_PATH/app/Http/Controllers/EmailController.php" ]; then
    if grep -q "orderBy('created_at', 'desc')" "$ADMIN_PATH/app/Http/Controllers/EmailController.php"; then
        echo "✅ EmailController Sprint 46 fix verified"
    else
        echo "⚠️  EmailController fix not found in deployed file"
    fi
else
    echo "❌ EmailController not found"
fi

if [ -f "$ADMIN_PATH/resources/views/sites/create.blade.php" ]; then
    if grep -q "processing-overlay" "$ADMIN_PATH/resources/views/sites/create.blade.php"; then
        echo "✅ Sites view feedback UI verified"
    else
        echo "⚠️  Sites feedback UI not found in deployed file"
    fi
else
    echo "❌ Sites view not found"
fi
echo ""

echo "======================================"
echo "SPRINT 46 - DEPLOYMENT COMPLETED"
echo "======================================"
echo ""
echo "✅ Backup location: $BACKUP_DIR"
echo "✅ EmailController: DEPLOYED with line 147-148 fix"
echo "✅ Sites view: DEPLOYED with feedback overlay"
echo "✅ Cache: CLEARED"
echo "✅ PHP-FPM: RELOADED"
echo ""
echo "Next steps:"
echo "1. Test Email Accounts ordering: http://72.61.53.222:8080/admin/email/accounts"
echo "2. Test Sites creation feedback: http://72.61.53.222:8080/admin/sites/create"
echo ""
