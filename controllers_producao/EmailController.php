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
     * SPRINT 49 FIX: Show create account form
     */
    public function createAccount()
    {
        // Get all available domains
        $domains = EmailDomain::orderBy('created_at', 'desc')->pluck('domain')->toArray();
        
        return view('email.accounts-create', [
            'domains' => $domains
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
        // SPRINT 50 FIX: Campo 'username' faltando causava erro SQL
        $emailAccount = EmailAccount::create([
            'email' => $email,
            'username' => $request->username,
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
        $serverIP = '72.61.53.222'; // Server IP
        $dkimSelector = 'mail';
        
        return [
            // MX Record
            [
                'type' => 'MX',
                'name' => '@',
                'priority' => '10',
                'value' => "mail.{$domain}",
                'ttl' => '3600',
                'description' => 'Mail Exchange record pointing to your mail server'
            ],
            // A Record for mail subdomain
            [
                'type' => 'A',
                'name' => 'mail',
                'value' => $serverIP,
                'ttl' => '3600',
                'description' => 'Mail server hostname resolution'
            ],
            // SPF Record
            [
                'type' => 'TXT',
                'name' => '@',
                'value' => "v=spf1 mx a ip4:{$serverIP} ~all",
                'ttl' => '3600',
                'description' => 'SPF - Sender Policy Framework (authorized mail servers)'
            ],
            // DKIM Record
            [
                'type' => 'TXT',
                'name' => "{$dkimSelector}._domainkey",
                'value' => "v=DKIM1; k=rsa; p=<YOUR_PUBLIC_KEY_HERE>",
                'ttl' => '3600',
                'description' => 'DKIM - DomainKeys Identified Mail (email authentication)',
                'note' => 'Generate keys with: opendkim-genkey -s mail -d ' . $domain
            ],
            // DMARC Record
            [
                'type' => 'TXT',
                'name' => '_dmarc',
                'value' => "v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@{$domain}; ruf=mailto:dmarc-forensics@{$domain}; fo=1",
                'ttl' => '3600',
                'description' => 'DMARC - Domain-based Message Authentication (policy enforcement)'
            ],
        ];
    }
    
    private function checkCurrentDNS($domain)
    {
        $results = [];
        
        // Check MX record
        try {
            $mx = @dns_get_record($domain, DNS_MX);
            $results['mx'] = !empty($mx);
        } catch (\Exception $e) {
            $results['mx'] = false;
        }
        
        // Check SPF, DKIM, DMARC records
        try {
            $txt = @dns_get_record($domain, DNS_TXT);
            
            $spfExists = false;
            
            foreach ($txt as $record) {
                $txtValue = $record['txt'] ?? '';
                
                if (stripos($txtValue, 'v=spf1') !== false) {
                    $spfExists = true;
                }
            }
            
            $results['spf'] = $spfExists;
            
            // Check DKIM (mail._domainkey subdomain)
            $dkimRecords = @dns_get_record("mail._domainkey.{$domain}", DNS_TXT);
            $results['dkim'] = !empty($dkimRecords);
            
            // Check DMARC (_dmarc subdomain)
            $dmarcRecords = @dns_get_record("_dmarc.{$domain}", DNS_TXT);
            $results['dmarc'] = !empty($dmarcRecords);
            
        } catch (\Exception $e) {
            $results['spf'] = false;
            $results['dkim'] = false;
            $results['dmarc'] = false;
        }
        
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
    
    // ========================================
    // SPRINT 9: SPAM LOGS VIEWER
    // ========================================
    
    public function spamLogs(Request $request)
    {
        $lines = $request->get('lines', 100);
        $filter = $request->get('filter', '');
        
        $logs = $this->getSpamLogs($lines, $filter);
        
        return view('email.spam-logs', [
            'logs' => $logs,
            'lines' => $lines,
            'filter' => $filter
        ]);
    }
    
    private function getSpamLogs($lines = 100, $filter = '')
    {
        $logFiles = [
            '/var/log/mail.log',
            '/var/log/mail.err',
        ];
        
        $logs = [];
        
        foreach ($logFiles as $logFile) {
            if (!file_exists($logFile)) {
                continue;
            }
            
            $command = "grep -i 'spam\\|reject\\|block\\|blacklist' {$logFile} | tail -n {$lines}";
            
            if (!empty($filter)) {
                $command .= " | grep -i " . escapeshellarg($filter);
            }
            
            $output = shell_exec($command . ' 2>&1');
            
            if ($output) {
                $logLines = explode("\n", trim($output));
                foreach ($logLines as $line) {
                    if (empty(trim($line))) continue;
                    
                    $logs[] = [
                        'timestamp' => $this->extractTimestamp($line),
                        'severity' => $this->extractSeverity($line),
                        'message' => $line,
                        'type' => $this->detectSpamType($line)
                    ];
                }
            }
        }
        
        // Sort by timestamp descending
        usort($logs, function($a, $b) {
            return strtotime($b['timestamp']) - strtotime($a['timestamp']);
        });
        
        return $logs;
    }
    
    private function detectSpamType($line)
    {
        if (stripos($line, 'spamassassin') !== false) return 'SpamAssassin';
        if (stripos($line, 'blacklist') !== false) return 'Blacklist';
        if (stripos($line, 'reject') !== false) return 'Rejected';
        if (stripos($line, 'block') !== false) return 'Blocked';
        return 'Other';
    }
    
    private function extractSeverity($line)
    {
        if (stripos($line, 'error') !== false || stripos($line, 'reject') !== false) return 'high';
        if (stripos($line, 'warning') !== false || stripos($line, 'suspect') !== false) return 'medium';
        return 'low';
    }
    
    public function clearSpamLogs()
    {
        try {
            $logFiles = [
                '/var/log/mail.log',
                '/var/log/mail.err',
            ];
            
            foreach ($logFiles as $logFile) {
                if (file_exists($logFile)) {
                    exec("sudo truncate -s 0 {$logFile}");
                }
            }
            
            return redirect()->back()->with('success', 'Spam logs cleared successfully');
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Failed to clear spam logs: ' . $e->getMessage());
        }
    }
    
    // ========================================
    // SPRINT 9: EMAIL ALIASES MANAGEMENT
    // ========================================
    
    public function aliases(Request $request)
    {
        $domain = $request->get('domain');
        $aliases = $this->getEmailAliases($domain);
        $domains = EmailDomain::orderBy('domain')->pluck('domain');
        
        return view('email.aliases', [
            'aliases' => $aliases,
            'domains' => $domains,
            'selectedDomain' => $domain
        ]);
    }
    
    public function createAlias(Request $request)
    {
        $domains = EmailDomain::orderBy('domain')->pluck('domain');
        return view('email.aliases-create', ['domains' => $domains]);
    }
    
    public function storeAlias(Request $request)
    {
        $request->validate([
            'alias' => 'required|email',
            'destination' => 'required|email',
        ]);
        
        $alias = strtolower($request->alias);
        $destination = strtolower($request->destination);
        
        // Check if alias already exists
        $virtualFile = '/etc/postfix/virtual';
        if (file_exists($virtualFile)) {
            $content = file_get_contents($virtualFile);
            if (stripos($content, $alias) !== false) {
                return redirect()->back()
                    ->with('error', "Alias {$alias} already exists")
                    ->withInput();
            }
        }
        
        // Add alias to virtual file
        $aliasLine = "{$alias}    {$destination}\n";
        file_put_contents($virtualFile, $aliasLine, FILE_APPEND);
        
        // Rebuild postfix database
        exec('sudo postmap /etc/postfix/virtual');
        exec('sudo systemctl reload postfix');
        
        return redirect()->route('email.aliases')
            ->with('success', "Alias {$alias} created successfully");
    }
    
    public function deleteAlias(Request $request)
    {
        $request->validate([
            'alias' => 'required|email'
        ]);
        
        $alias = strtolower($request->alias);
        $virtualFile = '/etc/postfix/virtual';
        
        if (!file_exists($virtualFile)) {
            return redirect()->back()->with('error', 'Virtual aliases file not found');
        }
        
        // Read file and remove alias
        $lines = file($virtualFile, FILE_IGNORE_NEW_LINES);
        $newLines = [];
        
        foreach ($lines as $line) {
            if (stripos($line, $alias) === false || empty(trim($line)) || strpos(trim($line), '#') === 0) {
                $newLines[] = $line;
            }
        }
        
        // Write back
        file_put_contents($virtualFile, implode("\n", $newLines) . "\n");
        
        // Rebuild postfix database
        exec('sudo postmap /etc/postfix/virtual');
        exec('sudo systemctl reload postfix');
        
        return redirect()->back()
            ->with('success', "Alias {$alias} deleted successfully");
    }
    
    private function getEmailAliases($domain = null)
    {
        $virtualFile = '/etc/postfix/virtual';
        $aliases = [];
        
        if (!file_exists($virtualFile)) {
            return $aliases;
        }
        
        $lines = file($virtualFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        
        foreach ($lines as $line) {
            $line = trim($line);
            
            // Skip comments and empty lines
            if (empty($line) || strpos($line, '#') === 0) {
                continue;
            }
            
            // Parse alias line: alias@domain.com    destination@domain.com
            if (preg_match('/^([^\s]+)\s+(.+)$/', $line, $matches)) {
                $aliasEmail = trim($matches[1]);
                $destination = trim($matches[2]);
                
                // Filter by domain if specified
                if ($domain) {
                    $aliasDomain = substr($aliasEmail, strpos($aliasEmail, '@') + 1);
                    if (strcasecmp($aliasDomain, $domain) !== 0) {
                        continue;
                    }
                }
                
                $aliases[] = [
                    'alias' => $aliasEmail,
                    'destination' => $destination,
                    'domain' => substr($aliasEmail, strpos($aliasEmail, '@') + 1)
                ];
            }
        }
        
        return $aliases;
    }
}
