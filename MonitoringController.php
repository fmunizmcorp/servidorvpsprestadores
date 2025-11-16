<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class MonitoringController extends Controller
{
    public function index()
    {
        $metrics = $this->getSystemMetrics();
        $services = $this->getServicesStatus();
        
        return view('monitoring.index', [
            'metrics' => $metrics,
            'services' => $services
        ]);
    }
    
    public function services()
    {
        $services = $this->getAllServicesDetailed();
        
        return view('monitoring.services', [
            'services' => $services
        ]);
    }
    
    public function restartService(Request $request)
    {
        $service = $request->service;
        
        $allowedServices = ['nginx', 'php8.3-fpm', 'mariadb', 'redis-server', 'postfix', 'dovecot', 'fail2ban'];
        
        if (!in_array($service, $allowedServices)) {
            return redirect()->back()
                ->with('error', 'Service not allowed to restart');
        }
        
        $output = shell_exec("systemctl restart $service 2>&1");
        
        return redirect()->route('monitoring.services')
            ->with('success', "Service $service restarted");
    }
    
    public function processes()
    {
        $topProcesses = $this->getTopProcesses();
        
        return view('monitoring.processes', [
            'processes' => $topProcesses
        ]);
    }
    
    public function killProcess(Request $request)
    {
        $pid = $request->pid;
        
        if (!is_numeric($pid)) {
            return redirect()->back()
                ->with('error', 'Invalid PID');
        }
        
        shell_exec("kill -9 $pid 2>&1");
        
        return redirect()->route('monitoring.processes')
            ->with('success', "Process $pid killed");
    }
    
    public function logs(Request $request)
    {
        $logType = $request->get('type', 'syslog');
        $lines = $request->get('lines', 100);
        
        $logs = $this->getSystemLogs($logType, $lines);
        
        return view('monitoring.logs', [
            'logs' => $logs,
            'logType' => $logType,
            'lines' => $lines
        ]);
    }
    
    public function apiMetrics()
    {
        return response()->json($this->getSystemMetrics());
    }
    
    public function apiServices()
    {
        return response()->json($this->getServicesStatus());
    }
    
    private function getSystemMetrics()
    {
        // CPU
        $cpuLoad = sys_getloadavg();
        $cpuUsage = round($cpuLoad[0] * 100 / 2, 2);
        
        // Memory
        $memInfo = [];
        $memData = @file_get_contents('/proc/meminfo');
        if ($memData) {
            preg_match('/MemTotal:\\s+(\\d+)/', $memData, $totalMatch);
            preg_match('/MemAvailable:\\s+(\\d+)/', $memData, $availMatch);
            
            if (!empty($totalMatch[1]) && !empty($availMatch[1])) {
                $total = (int)$totalMatch[1];
                $available = (int)$availMatch[1];
                $used = $total - $available;
                $memUsage = round(($used / $total) * 100, 2);
            } else {
                $memUsage = 0;
            }
        } else {
            $memUsage = 0;
        }
        
        // Disk
        $diskTotal = @disk_total_space('/');
        $diskFree = @disk_free_space('/');
        $diskUsage = 0;
        
        if ($diskTotal && $diskFree) {
            $diskUsage = round((($diskTotal - $diskFree) / $diskTotal) * 100, 2);
        }
        
        // Network (simplified)
        $networkStats = @file_get_contents('/proc/net/dev');
        $rxBytes = 0;
        $txBytes = 0;
        
        if ($networkStats && preg_match('/eth0:\\s*(\\d+)\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s+(\\d+)/', $networkStats, $matches)) {
            $rxBytes = (int)$matches[1];
            $txBytes = (int)$matches[2];
        }
        
        // Uptime
        $uptimeData = @file_get_contents('/proc/uptime');
        $uptime = 'Unknown';
        
        if ($uptimeData) {
            $uptimeSeconds = (int)explode(' ', $uptimeData)[0];
            $days = floor($uptimeSeconds / 86400);
            $hours = floor(($uptimeSeconds % 86400) / 3600);
            $minutes = floor(($uptimeSeconds % 3600) / 60);
            
            $parts = [];
            if ($days > 0) $parts[] = "$days day" . ($days != 1 ? 's' : '');
            if ($hours > 0) $parts[] = "$hours hour" . ($hours != 1 ? 's' : '');
            if ($minutes > 0) $parts[] = "$minutes minute" . ($minutes != 1 ? 's' : '');
            
            $uptime = implode(', ', $parts) ?: 'Just started';
        }
        
        return [
            'cpu' => [
                'usage' => $cpuUsage,
                'load' => $cpuLoad
            ],
            'memory' => [
                'usage' => $memUsage
            ],
            'disk' => [
                'usage' => $diskUsage,
                'total' => $this->formatBytes($diskTotal ?? 0),
                'free' => $this->formatBytes($diskFree ?? 0)
            ],
            'network' => [
                'rx' => $this->formatBytes($rxBytes),
                'tx' => $this->formatBytes($txBytes)
            ],
            'uptime' => $uptime
        ];
    }
    
    private function getServicesStatus()
    {
        $services = [
            'nginx' => 'NGINX',
            'php8.3-fpm' => 'PHP-FPM',
            'mariadb' => 'MariaDB',
            'redis-server' => 'Redis',
            'postfix' => 'Postfix',
            'dovecot' => 'Dovecot',
            'fail2ban' => 'Fail2Ban'
        ];
        
        $status = [];
        
        foreach ($services as $service => $name) {
            $isActive = $this->isServiceActive($service);
            $uptime = $this->getServiceUptime($service);
            
            $status[$service] = [
                'name' => $name,
                'status' => $isActive ? 'running' : 'stopped',
                'uptime' => $uptime
            ];
        }
        
        return $status;
    }
    
    private function getAllServicesDetailed()
    {
        $services = $this->getServicesStatus();
        
        foreach ($services as $key => &$service) {
            $service['memory'] = $this->getServiceMemory($key);
            $service['cpu'] = $this->getServiceCPU($key);
            $service['pid'] = $this->getServicePID($key);
        }
        
        return $services;
    }
    
    private function getTopProcesses($limit = 20)
    {
        $output = shell_exec("ps aux --sort=-%cpu | head -n " . ($limit + 1));
        $processes = [];
        
        if ($output) {
            $lines = explode("\\n", trim($output));
            array_shift($lines); // Remove header
            
            foreach ($lines as $line) {
                if (empty($line)) continue;
                
                $parts = preg_split('/\\s+/', $line, 11);
                
                if (count($parts) >= 11) {
                    $processes[] = [
                        'user' => $parts[0],
                        'pid' => $parts[1],
                        'cpu' => $parts[2],
                        'mem' => $parts[3],
                        'vsz' => $parts[4],
                        'rss' => $parts[5],
                        'tty' => $parts[6],
                        'stat' => $parts[7],
                        'start' => $parts[8],
                        'time' => $parts[9],
                        'command' => $parts[10]
                    ];
                }
            }
        }
        
        return $processes;
    }
    
    private function getSystemLogs($type, $lines)
    {
        $logFiles = [
            'syslog' => '/var/log/syslog',
            'auth' => '/var/log/auth.log',
            'nginx-access' => '/var/log/nginx/access.log',
            'nginx-error' => '/var/log/nginx/error.log',
            'php' => '/var/log/php8.3-fpm.log',
            'mail' => '/var/log/mail.log',
            'fail2ban' => '/var/log/fail2ban.log'
        ];
        
        $logFile = $logFiles[$type] ?? $logFiles['syslog'];
        
        if (!file_exists($logFile)) {
            return [];
        }
        
        $output = shell_exec("tail -n $lines $logFile 2>/dev/null");
        
        if (!$output) {
            return [];
        }
        
        return array_reverse(explode("\\n", trim($output)));
    }
    
    private function isServiceActive($service)
    {
        $output = shell_exec("systemctl is-active $service 2>&1");
        return trim($output) === 'active';
    }
    
    private function getServiceUptime($service)
    {
        $output = shell_exec("systemctl show $service --property=ActiveEnterTimestamp 2>&1");
        
        if ($output && preg_match('/ActiveEnterTimestamp=(.+)/', $output, $matches)) {
            $startTime = strtotime($matches[1]);
            if ($startTime) {
                $diff = time() - $startTime;
                $days = floor($diff / 86400);
                $hours = floor(($diff % 86400) / 3600);
                
                if ($days > 0) {
                    return "{$days}d {$hours}h";
                } elseif ($hours > 0) {
                    return "{$hours}h";
                } else {
                    return "<1h";
                }
            }
        }
        
        return 'Unknown';
    }
    
    private function getServiceMemory($service)
    {
        $pid = $this->getServicePID($service);
        
        if (!$pid) {
            return '0 MB';
        }
        
        $output = shell_exec("ps -p $pid -o rss= 2>&1");
        
        if ($output && is_numeric(trim($output))) {
            $kb = (int)trim($output);
            return $this->formatBytes($kb * 1024);
        }
        
        return '0 MB';
    }
    
    private function getServiceCPU($service)
    {
        $pid = $this->getServicePID($service);
        
        if (!$pid) {
            return '0%';
        }
        
        $output = shell_exec("ps -p $pid -o %cpu= 2>&1");
        
        if ($output && is_numeric(trim($output))) {
            return trim($output) . '%';
        }
        
        return '0%';
    }
    
    private function getServicePID($service)
    {
        $output = shell_exec("systemctl show $service --property=MainPID 2>&1");
        
        if ($output && preg_match('/MainPID=(\\d+)/', $output, $matches)) {
            return (int)$matches[1];
        }
        
        return null;
    }
    
    private function formatBytes($bytes, $precision = 2)
    {
        if ($bytes == 0) return '0 B';
        
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $base = log($bytes) / log(1024);
        
        return round(pow(1024, $base - floor($base)), $precision) . ' ' . $units[floor($base)];
    }
}
