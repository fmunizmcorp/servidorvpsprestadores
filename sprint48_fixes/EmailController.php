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
     * SPRINT 48 FIX: Show create domain form
     */
    public function createDomain()
    {
        return view('email.domains-create');
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
        // SPRINT 47 FIX: Handle open_basedir restriction gracefully
        try {
            $path = "/var/vmail/{$domain}";
            
            // Use @ to suppress errors from open_basedir restriction
            if (!@is_dir($path)) {
                return '0 MB';
            }
            
            $output = @shell_exec("du -sh {$path} 2>/dev/null | awk '{print $1}'");
            return trim($output) ?: '0 MB';
        } catch (\Exception $e) {
            // If open_basedir blocks access, return default
            return 'N/A';
        }
    }
    
    private function checkDomainDNS($domain)
    {
        // SPRINT 47 FIX: Handle DNS query failures gracefully
        try {
            $records = @dns_get_record($domain, DNS_MX);
            return !empty($records) ? 'configured' : 'pending';
        } catch (\Exception $e) {
            // If DNS query fails, return pending status
            return 'pending';
        }
    }
    
    private function getAccountUsage($email)
    {
        // SPRINT 47 FIX: Handle open_basedir restriction gracefully
        try {
            $domain = substr($email, strpos($email, '@') + 1);
            $user = substr($email, 0, strpos($email, '@'));
            $path = "/var/vmail/{$domain}/{$user}";
            
            // Use @ to suppress errors from open_basedir restriction
            if (!@is_dir($path)) {
                return '0 MB';
            }
            
            $output = @shell_exec("du -sh {$path} 2>/dev/null | awk '{print $1}'");
            return trim($output) ?: '0 MB';
        } catch (\Exception $e) {
            // If open_basedir blocks access, return default
            return 'N/A';
        }
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
