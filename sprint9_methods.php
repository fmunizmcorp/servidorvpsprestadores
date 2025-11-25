<?php

// ========================================
// SPRINT 9 - EMAIL SERVER ADVANCED
// Methods to add to EmailController
// ========================================

// ========================================
// 1. ENHANCED getDNSRecordsForDomain() with DKIM and DMARC
// Replace existing method at line 454
// ========================================
/*
private function getDNSRecordsForDomain($domain)
{
    $serverIP = '72.61.53.222'; // Use actual server IP
    
    // Generate DKIM selector and keys info
    $dkimSelector = 'mail';
    $dkimDomain = $dkimSelector . '._domainkey.' . $domain;
    
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
*/

// ========================================
// 2. SPAM LOGS VIEWER - New methods
// ========================================
/*
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
            $lines = explode("\n", trim($output));
            foreach ($lines as $line) {
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
        // Clear spam-related logs
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
*/

// ========================================
// 3. EMAIL ALIASES MANAGEMENT - New methods
// ========================================
/*
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
*/

// ========================================
// 4. UPDATE checkCurrentDNS() to check DKIM and DMARC
// Replace existing method at line 480
// ========================================
/*
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
        $dkimExists = false;
        $dmarcExists = false;
        
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
*/
