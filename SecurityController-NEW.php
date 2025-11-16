<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class SecurityController extends Controller
{
    public function index()
    {
        $securityStatus = $this->getSecurityStatus();
        
        // Map to view-expected keys
        $stats = [
            'activeRules' => count($this->getFirewallRules()),
            'bannedIPs' => $securityStatus['banned_ips_count'] ?? 0,
            'lastScan' => $securityStatus['last_scan'] ?? 'Never'
        ];
        
        return view('security.index', [
            'status' => $securityStatus,
            'stats' => $stats
        ]);
    }
    
    public function firewall()
    {
        $rules = $this->getFirewallRules();
        
        return view('security.firewall', [
            'rules' => $rules
        ]);
    }
    
    public function addFirewallRule(Request $request)
    {
        $port = $request->port;
        $protocol = $request->protocol ?? 'tcp';
        
        $command = "ufw allow $port/$protocol 2>&1";
        $output = shell_exec($command);
        
        return redirect()->route('security.firewall')
            ->with('success', "Firewall rule added: $port/$protocol");
    }
    
    public function fail2ban()
    {
        $jails = $this->getFail2banStatus();
        $bannedIps = $this->getBannedIPs();
        
        return view('security.fail2ban', [
            'jails' => $jails,
            'bannedIps' => $bannedIps
        ]);
    }
    
    public function unbanIP(Request $request)
    {
        $ip = $request->ip;
        $jail = $request->jail ?? 'sshd';
        
        $command = "fail2ban-client set $jail unbanip $ip 2>&1";
        $output = shell_exec($command);
        
        return redirect()->route('security.fail2ban')
            ->with('success', "IP $ip unbanned from $jail");
    }
    
    public function clamav()
    {
        $clamavStatus = $this->getClamAVStatus();
        
        return view('security.clamav', [
            'status' => $clamavStatus,
            'lastUpdate' => $clamavStatus['last_update'] ?? 'Unknown',
            'active' => $clamavStatus['active'] ?? false,
            'version' => $clamavStatus['version'] ?? 'Unknown',
            'signatures' => $clamavStatus['signatures'] ?? 0
        ]);
    }
    
    private function getSecurityStatus()
    {
        return [
            'firewall_active' => $this->isServiceActive('ufw'),
            'fail2ban_active' => $this->isServiceActive('fail2ban'),
            'clamav_active' => $this->isServiceActive('clamav-daemon'),
            'open_ports' => $this->getOpenPorts(),
            'banned_ips_count' => count($this->getBannedIPs()),
            'last_scan' => $this->getLastSecurityScan()
        ];
    }
    
    private function getFirewallRules()
    {
        $output = shell_exec('ufw status numbered 2>&1');
        $rules = [];
        
        if ($output) {
            $lines = explode("\n", $output);
            foreach ($lines as $line) {
                if (preg_match('/\[(\d+)\]\s+(.+)/', $line, $matches)) {
                    $rules[] = [
                        'number' => $matches[1],
                        'rule' => trim($matches[2])
                    ];
                }
            }
        }
        
        return $rules;
    }
    
    private function getFail2banStatus()
    {
        $output = shell_exec('fail2ban-client status 2>&1');
        $jails = [];
        
        if ($output && preg_match('/Jail list:\s+(.+)/', $output, $matches)) {
            $jailNames = array_map('trim', explode(',', $matches[1]));
            
            foreach ($jailNames as $jail) {
                $jailStatus = shell_exec("fail2ban-client status $jail 2>&1");
                $currentlyBanned = 0;
                $totalBanned = 0;
                
                if (preg_match('/Currently banned:\s+(\d+)/', $jailStatus, $m)) {
                    $currentlyBanned = (int)$m[1];
                }
                if (preg_match('/Total banned:\s+(\d+)/', $jailStatus, $m)) {
                    $totalBanned = (int)$m[1];
                }
                
                $jails[] = [
                    'name' => $jail,
                    'currently_banned' => $currentlyBanned,
                    'total_banned' => $totalBanned
                ];
            }
        }
        
        return $jails;
    }
    
    private function getBannedIPs()
    {
        $bannedIPs = [];
        $jails = ['sshd', 'nginx-http-auth', 'postfix', 'dovecot'];
        
        foreach ($jails as $jail) {
            $output = shell_exec("fail2ban-client status $jail 2>&1 | grep 'Banned IP list'" );
            
            if ($output && preg_match('/Banned IP list:\s+(.+)/', $output, $matches)) {
                $ips = array_filter(array_map('trim', explode(' ', $matches[1])));
                
                foreach ($ips as $ip) {
                    $bannedIPs[] = [
                        'ip' => $ip,
                        'jail' => $jail
                    ];
                }
            }
        }
        
        return $bannedIPs;
    }
    
    private function getClamAVStatus()
    {
        $status = [
            'active' => $this->isServiceActive('clamav-daemon'),
            'signatures' => 0,
            'last_update' => 'Unknown',
            'version' => 'Unknown'
        ];
        
        // Get ClamAV version
        $versionOutput = shell_exec('clamdscan --version 2>&1');
        if ($versionOutput && preg_match('/ClamAV ([\d\.]+)/', $versionOutput, $matches)) {
            $status['version'] = $matches[1];
        }
        
        // Get signature count
        $sigOutput = shell_exec('sigtool --info /var/lib/clamav/main.cvd 2>&1');
        if ($sigOutput && preg_match('/Signatures: (\d+)/', $sigOutput, $matches)) {
            $status['signatures'] = (int)$matches[1];
        }
        
        // Get last update time
        $updateLog = '/var/log/clamav/freshclam.log';
        if (file_exists($updateLog)) {
            $lastLine = shell_exec("tail -1 $updateLog");
            if ($lastLine && preg_match('/^([A-Za-z]+ [A-Za-z]+ \d+ \d+:\d+:\d+ \d+)/', $lastLine, $matches)) {
                $status['last_update'] = $matches[1];
            }
        }
        
        return $status;
    }
    
    private function isServiceActive($service)
    {
        $output = shell_exec("systemctl is-active $service 2>&1");
        return trim($output) === 'active';
    }
    
    private function getOpenPorts()
    {
        $output = shell_exec('ss -tlnp 2>&1 | grep LISTEN');
        $ports = [];
        
        if ($output) {
            $lines = explode("\n", $output);
            foreach ($lines as $line) {
                if (preg_match('/:(\ d+)\s/', $line, $matches)) {
                    $ports[] = (int)$matches[1];
                }
            }
        }
        
        return array_unique($ports);
    }
    
    private function getLastSecurityScan()
    {
        $logFile = '/var/log/webserver/security-scan.log';
        
        if (!file_exists($logFile)) {
            return 'Never';
        }
        
        $lastLine = shell_exec("tail -1 $logFile");
        
        if ($lastLine && preg_match('/\[(.*?)\]/', $lastLine, $matches)) {
            return $matches[1];
        }
        
        return 'Unknown';
    }
}