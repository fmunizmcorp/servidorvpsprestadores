<?php

namespace App\Http\Controllers;

use App\Models\EmailDomain;
use App\Models\EmailAccount;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class EmailController extends Controller
{
    private $scriptsPath = '/tmp';
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
        $validator = Validator::make($request->all(), [
            'domain' => 'required|regex:/^[a-z0-9\.\-]+$/|max:255'
        ]);
        
        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }
        
        try {
            $domain = $request->domain;
            $script = "{$this->scriptsPath}/create-email-domain.sh";
            
            if (!file_exists($script)) {
                throw new \Exception("Script create-email-domain.sh not found");
            }
            
            $command = "bash $script $domain 2>&1";
            $output = shell_exec($command);
            
            // SPRINT 26 FIX: Save to database after successful creation
            // Parse DKIM key from output if present
            $dkimPublicKey = null;
            if (preg_match('/p=([A-Za-z0-9+\/=]+)/', $output, $matches)) {
                $dkimPublicKey = $matches[1];
            }
            
            EmailDomain::create([
                'domain' => $domain,
                'status' => 'active',
                'dkim_selector' => 'mail',
                'dkim_public_key' => $dkimPublicKey,
                'mx_record' => "mail.{$domain}",
                'spf_record' => "v=spf1 mx a ip4:72.61.53.222 ~all",
                'dmarc_record' => "v=DMARC1; p=quarantine; rua=mailto:dmarc@{$domain}",
            ]);
            
            return redirect()->route('email.domains')
                ->with('success', "Email domain $domain created successfully!")
                ->with('output', $output);
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to create domain: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    /**
     * Manage email accounts
     */
    public function accounts(Request $request)
    {
        $domain = $request->get('domain');
        
        // SPRINT 26 FIX: Fetch domains from database
        $domainNames = EmailDomain::pluck('domain')->toArray();
        
        if (!$domain && !empty($domainNames)) {
            $domain = $domainNames[0];
        }
        
        // SPRINT 26 FIX: Fetch accounts from database
        $accounts = [];
        if ($domain) {
            $accounts = EmailAccount::where('domain', $domain)
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function($account) {
                    $mailPath = "/opt/webserver/mail/mailboxes/{$account->domain}/{$account->username}";
                    $diskUsageBytes = 0;
                    $diskUsageStr = '0 MB';
                    
                    if (is_dir($mailPath)) {
                        $duOutput = shell_exec("du -sb " . escapeshellarg($mailPath) . " 2>/dev/null");
                        if ($duOutput) {
                            $diskUsageBytes = (int)trim(explode("\t", $duOutput)[0]);
                            $diskUsageMB = round($diskUsageBytes / 1024 / 1024, 2);
                            $diskUsageStr = $diskUsageMB . ' MB';
                        }
                    }
                    
                    $usagePercent = $account->quota_mb > 0 ? min(100, round(($diskUsageBytes / 1024 / 1024 / $account->quota_mb) * 100, 1)) : 0;
                    
                    return [
                        'email' => $account->email,
                        'username' => $account->username,
                        'quota' => $account->quota_mb . ' MB',
                        'used' => $diskUsageStr,
                        'percent' => $usagePercent,
                        'status' => $account->status,
                        'created_at' => $account->created_at,
                    ];
                })->toArray();
        }
        
        return view('email.accounts', [
            'domains' => $domainNames,  // Pass simple array of strings
            'selectedDomain' => $domain,
            'accounts' => $accounts
        ]);
    }
    
    /**
     * Store new email account
     */
    public function storeAccount(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'domain' => 'required',
            'username' => 'required|alpha_dash|max:50',
            'password' => 'required|min:8',
            'quota' => 'nullable|integer|min:100|max:10000'
        ]);
        
        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }
        
        try {
            $domain = $request->domain;
            $username = $request->username;
            $password = $request->password;
            $email = "$username@$domain";
            $quota = $request->quota ?? 1000;
            
            $script = "{$this->scriptsPath}/create-email.sh";
            
            if (!file_exists($script)) {
                throw new \Exception("Script create-email.sh not found");
            }
            
            // Script expects: domain username password quota
            $command = "bash $script " . escapeshellarg($domain) . " " . 
                       escapeshellarg($username) . " " . 
                       escapeshellarg($password) . " " . 
                       escapeshellarg($quota) . " 2>&1";
            $output = shell_exec($command);
            
            // SPRINT 26 FIX: Save to database after successful creation
            EmailAccount::create([
                'email' => $email,
                'domain' => $domain,
                'username' => $username,
                'quota_mb' => $quota,
                'used_mb' => 0,
                'status' => 'active',
            ]);
            
            return redirect()->route('email.accounts', ['domain' => $domain])
                ->with('success', "Email account $email created successfully!");
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to create account: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    /**
     * View email queue
     */
    public function queue()
    {
        $queueData = $this->getQueueStatus();
        
        return view('email.queue', [
            'queue' => $queueData
        ]);
    }
    
    /**
     * View email logs
     */
    public function logs(Request $request)
    {
        $filter = $request->get('filter', '');
        $lines = $request->get('lines', 100);
        
        $logs = $this->getMailLogs($filter, $lines);
        
        return view('email.logs', [
            'logs' => $logs,
            'filter' => $filter,
            'lines' => $lines
        ]);
    }
    
    /**
     * DNS verification tool
     */
    public function dns(Request $request)
    {
        $domain = $request->get('domain');
        $domains = $this->getAllDomains();
        
        if (!$domain && !empty($domains)) {
            $domain = $domains[0]['name'];
        }
        
        $dnsRecords = [];
        if ($domain) {
            $dnsRecords = $this->checkDNSRecords($domain);
        }
        
        return view('email.dns', [
            'domains' => $domains,
            'selectedDomain' => $domain,
            'dnsRecords' => $dnsRecords
        ]);
    }
    
    // ========== HELPER METHODS ==========
    
    /**
     * Get email statistics
     */
    private function getEmailStats()
    {
        $stats = [
            'domains' => 0,
            'accounts' => 0,
            'sentToday' => 0,
            'receivedToday' => 0,
            'spamBlocked' => 0,
            'queueSize' => 0
        ];
        
        // Count domains
        $domainsFile = "{$this->postfixPath}/virtual_domains";
        if (file_exists($domainsFile)) {
            $domains = file($domainsFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            $stats['domains'] = count($domains);
        }
        
        // Count accounts
        $accountsFile = "{$this->postfixPath}/virtual_mailbox_maps";
        if (file_exists($accountsFile)) {
            $accounts = file($accountsFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            $stats['accounts'] = count(array_filter($accounts, function($line) {
                return !empty(trim($line)) && strpos($line, '#') !== 0;
            }));
        }
        
        // Get today's email stats from mail.log
        $today = date('M d');
        $mailLog = '/var/log/mail.log';
        
        if (file_exists($mailLog)) {
            $logContent = shell_exec("grep '$today' $mailLog 2>/dev/null");
            
            if ($logContent) {
                $stats['sentToday'] = substr_count($logContent, 'status=sent');
                $stats['receivedToday'] = substr_count($logContent, 'from=<');
                $stats['spamBlocked'] = substr_count(strtolower($logContent), 'spam') + 
                                        substr_count(strtolower($logContent), 'reject');
            }
        }
        
        // Get queue size
        $queueOutput = shell_exec('mailq 2>/dev/null | tail -1');
        if ($queueOutput && preg_match('/(\d+) Request/', $queueOutput, $matches)) {
            $stats['queueSize'] = (int)$matches[1];
        }
        
        return $stats;
    }
    
    /**
     * Get all email domains
     */
    private function getAllDomains()
    {
        $domains = [];
        $domainsFile = "{$this->postfixPath}/virtual_domains";
        
        if (!file_exists($domainsFile)) {
            return $domains;
        }
        
        $lines = file($domainsFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        
        foreach ($lines as $line) {
            $line = trim($line);
            if (empty($line) || strpos($line, '#') === 0) {
                continue;
            }
            
            $accountCount = $this->countAccountsForDomain($line);
            $diskUsage = $this->getDomainDiskUsage($line);
            $dnsStatus = $this->checkDomainDNS($line);
            
            $domains[] = [
                'name' => $line,
                'accountCount' => $accountCount,
                'diskUsage' => $diskUsage,
                'dnsStatus' => $dnsStatus
            ];
        }
        
        return $domains;
    }
    
    /**
     * Count accounts for domain
     */
    private function countAccountsForDomain($domain)
    {
        $accountsFile = "{$this->postfixPath}/virtual_mailbox_maps";
        
        if (!file_exists($accountsFile)) {
            return 0;
        }
        
        $count = 0;
        $lines = file($accountsFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        
        foreach ($lines as $line) {
            if (strpos($line, "@$domain") !== false && strpos($line, '#') !== 0) {
                $count++;
            }
        }
        
        return $count;
    }
    
    /**
     * Get disk usage for domain
     */
    private function getDomainDiskUsage($domain)
    {
        $mailPath = "/var/mail/vhosts/$domain";
        
        if (!is_dir($mailPath)) {
            return '0 MB';
        }
        
        $output = shell_exec("du -sh $mailPath 2>/dev/null");
        
        if ($output) {
            return trim(explode("\t", $output)[0]);
        }
        
        return '0 MB';
    }
    
    /**
     * Check domain DNS status
     */
    private function checkDomainDNS($domain)
    {
        $hasMX = false;
        $hasSPF = false;
        $hasDKIM = false;
        
        // Check MX
        $mxOutput = shell_exec("dig +short MX $domain 2>/dev/null");
        if (!empty(trim($mxOutput))) {
            $hasMX = true;
        }
        
        // Check SPF
        $spfOutput = shell_exec("dig +short TXT $domain 2>/dev/null | grep 'v=spf1'");
        if (!empty(trim($spfOutput))) {
            $hasSPF = true;
        }
        
        // Check DKIM (common selector: mail)
        $dkimOutput = shell_exec("dig +short TXT mail._domainkey.$domain 2>/dev/null | grep 'v=DKIM1'");
        if (!empty(trim($dkimOutput))) {
            $hasDKIM = true;
        }
        
        if ($hasMX && $hasSPF && $hasDKIM) {
            return 'complete';
        } elseif ($hasMX) {
            return 'partial';
        } else {
            return 'missing';
        }
    }
    
    /**
     * Get accounts for domain
     */
    private function getAccountsForDomain($domain)
    {
        $accounts = [];
        $accountsFile = "{$this->postfixPath}/virtual_mailbox_maps";
        
        if (!file_exists($accountsFile)) {
            return $accounts;
        }
        
        $lines = file($accountsFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        
        foreach ($lines as $line) {
            // Skip comments and empty lines
            $line = trim($line);
            if (empty($line) || strpos($line, '#') === 0) {
                continue;
            }
            
            // Parse line: email path
            $parts = preg_split('/\s+/', $line, 2);
            if (count($parts) < 2) {
                continue; // Skip malformed lines
            }
            
            list($email, $path) = $parts;
            
            // Validate email format and check if it belongs to this domain
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                continue; // Skip invalid emails
            }
            
            if (strpos($email, "@$domain") === false) {
                continue; // Not for this domain
            }
            
            // Extract username from email
            $emailParts = explode('@', $email);
            if (count($emailParts) != 2) {
                continue; // Malformed email
            }
            
            $username = $emailParts[0];
            $mailPath = "/var/mail/vhosts/$domain/$username";
            
            $diskUsageBytes = 0;
            $diskUsageStr = '0 MB';
            $quotaMB = 1024; // Default quota 1GB
            
            if (is_dir($mailPath)) {
                $duOutput = shell_exec("du -sb " . escapeshellarg($mailPath) . " 2>/dev/null");
                if ($duOutput) {
                    $diskUsageBytes = (int)trim(explode("\t", $duOutput)[0]);
                    $diskUsageMB = round($diskUsageBytes / 1024 / 1024, 2);
                    $diskUsageStr = $diskUsageMB . ' MB';
                }
            }
            
            $usagePercent = $quotaMB > 0 ? min(100, round(($diskUsageBytes / 1024 / 1024 / $quotaMB) * 100, 1)) : 0;
            
            $accounts[] = [
                'email' => $email,
                'quota' => $quotaMB . ' MB',
                'used' => $diskUsageStr,
                'usagePercent' => $usagePercent
            ];
        }
        
        return $accounts;
    }
    
    /**
     * Get queue status
     */
    private function getQueueStatus()
    {
        $queue = [
            'size' => 0,
            'items' => []
        ];
        
        // Get queue size
        $queueOutput = shell_exec('mailq 2>/dev/null');
        
        if ($queueOutput) {
            // Parse queue size
            if (preg_match('/(\d+) Request/', $queueOutput, $matches)) {
                $queue['size'] = (int)$matches[1];
            }
            
            // Parse queue items (simplified)
            $lines = explode("\n", $queueOutput);
            foreach ($lines as $line) {
                if (preg_match('/^([A-F0-9]+)/', $line, $matches)) {
                    $queue['items'][] = [
                        'id' => $matches[1],
                        'line' => $line
                    ];
                }
            }
        }
        
        return $queue;
    }
    
    /**
     * Get mail logs
     */
    private function getMailLogs($filter, $lines)
    {
        $mailLog = '/var/log/mail.log';
        
        if (!file_exists($mailLog)) {
            return [];
        }
        
        $command = "tail -n $lines $mailLog";
        
        if (!empty($filter)) {
            $command .= " | grep -i " . escapeshellarg($filter);
        }
        
        $output = shell_exec("$command 2>/dev/null");
        
        if (!$output) {
            return [];
        }
        
        return array_reverse(explode("\n", trim($output)));
    }
    
    /**
     * Check DNS records for domain
     */
    private function checkDNSRecords($domain)
    {
        $records = [
            'mx' => ['status' => 'fail', 'value' => ''],
            'a' => ['status' => 'fail', 'value' => ''],
            'spf' => ['status' => 'fail', 'value' => ''],
            'dkim' => ['status' => 'fail', 'value' => ''],
            'dmarc' => ['status' => 'fail', 'value' => ''],
            'ptr' => ['status' => 'fail', 'value' => '']
        ];
        
        // Check MX
        $mxOutput = shell_exec("dig +short MX $domain 2>/dev/null");
        if (!empty(trim($mxOutput))) {
            $records['mx']['status'] = 'pass';
            $records['mx']['value'] = trim($mxOutput);
        }
        
        // Check A
        $aOutput = shell_exec("dig +short A $domain 2>/dev/null");
        if (!empty(trim($aOutput))) {
            $records['a']['status'] = 'pass';
            $records['a']['value'] = trim($aOutput);
        }
        
        // Check SPF
        $spfOutput = shell_exec("dig +short TXT $domain 2>/dev/null | grep 'v=spf1'");
        if (!empty(trim($spfOutput))) {
            $records['spf']['status'] = 'pass';
            $records['spf']['value'] = trim(str_replace('"', '', $spfOutput));
        }
        
        // Check DKIM
        $dkimOutput = shell_exec("dig +short TXT mail._domainkey.$domain 2>/dev/null | grep 'v=DKIM1'");
        if (!empty(trim($dkimOutput))) {
            $records['dkim']['status'] = 'pass';
            $records['dkim']['value'] = 'DKIM record found (selector: mail)';
        }
        
        // Check DMARC
        $dmarcOutput = shell_exec("dig +short TXT _dmarc.$domain 2>/dev/null | grep 'v=DMARC1'");
        if (!empty(trim($dmarcOutput))) {
            $records['dmarc']['status'] = 'pass';
            $records['dmarc']['value'] = trim(str_replace('"', '', $dmarcOutput));
        }
        
        // Check PTR (reverse DNS)
        $serverIP = shell_exec("curl -s ifconfig.me 2>/dev/null");
        if ($serverIP) {
            $ptrOutput = shell_exec("dig +short -x " . trim($serverIP) . " 2>/dev/null");
            if (!empty(trim($ptrOutput))) {
                $records['ptr']['status'] = 'pass';
                $records['ptr']['value'] = trim($ptrOutput);
            }
        }
        
        return $records;
    }
}
