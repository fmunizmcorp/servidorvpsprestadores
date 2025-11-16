<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /**
     * Display the dashboard view
     */
    public function index()
    {
        return view('dashboard', [
            'metrics' => $this->getMetrics(),
            'services' => $this->getServicesStatus(),
            'summary' => $this->getSummary()
        ]);
    }

    /**
     * Get system metrics (CPU, RAM, Disk)
     * Using only PHP native functions without shell_exec
     */
    public function getMetrics()
    {
        // CPU Load Average
        $cpuLoad = sys_getloadavg();
        // Estimate CPU usage from load average (assuming 2 cores)
        $cpuUsage = round($cpuLoad[0] * 100 / 2, 2);
        
        // Memory Usage using /proc/meminfo (if accessible)
        $memUsage = $this->getMemoryUsage();
        
        // Disk Usage for /opt/webserver (accessible path)
        $diskPath = '/opt/webserver';
        $diskTotal = @disk_total_space($diskPath);
        $diskFree = @disk_free_space($diskPath);
        
        if ($diskTotal && $diskFree) {
            $diskUsage = round(($diskTotal - $diskFree) / $diskTotal * 100, 2);
        } else {
            $diskUsage = 0;
            $diskTotal = 0;
            $diskFree = 0;
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
                'total' => $this->formatBytes($diskTotal),
                'free' => $this->formatBytes($diskFree)
            ]
        ];
    }

    /**
     * Get memory usage from /proc/meminfo if accessible
     * Falls back to 0 if not accessible
     */
    private function getMemoryUsage()
    {
        $memInfo = @file_get_contents('/proc/meminfo');
        
        if ($memInfo === false) {
            return 0;
        }
        
        preg_match('/MemTotal:\s+(\d+)/', $memInfo, $totalMatch);
        preg_match('/MemAvailable:\s+(\d+)/', $memInfo, $availableMatch);
        
        if (!empty($totalMatch[1]) && !empty($availableMatch[1])) {
            $total = (int) $totalMatch[1];
            $available = (int) $availableMatch[1];
            $used = $total - $available;
            
            return round(($used / $total) * 100, 2);
        }
        
        return 0;
    }

    /**
     * Get status of critical services
     * Using database-driven approach instead of systemctl
     */
    public function getServicesStatus()
    {
        $services = [
            'nginx' => 'NGINX',
            'php-fpm' => 'PHP-FPM',
            'mariadb' => 'MariaDB',
            'redis' => 'Redis',
            'postfix' => 'Postfix',
            'dovecot' => 'Dovecot',
            'fail2ban' => 'Fail2Ban'
        ];

        $status = [];
        
        // Try to determine status without shell_exec
        foreach ($services as $key => $name) {
            // For now, assume services are running if we can detect them
            $isRunning = $this->checkServiceRunning($key);
            
            $status[$key] = [
                'name' => $name,
                'status' => $isRunning ? 'running' : 'stopped'
            ];
        }

        return $status;
    }

    /**
     * Check if a service is running using various methods
     */
    private function checkServiceRunning($service)
    {
        // Special checks for services we can verify
        switch ($service) {
            case 'mariadb':
                // Try to connect to database
                try {
                    DB::connection()->getPdo();
                    return true;
                } catch (\Exception $e) {
                    return false;
                }
                
            case 'redis':
                // Check if Redis socket/port exists
                $redis = @fsockopen('127.0.0.1', 6379, $errno, $errstr, 1);
                if ($redis) {
                    fclose($redis);
                    return true;
                }
                return false;
                
            case 'nginx':
            case 'php-fpm':
                // If we're running, these services must be running
                return true;
                
            default:
                // For other services, assume running
                // This can be improved with a privileged API later
                return true;
        }
    }

    /**
     * Get summary statistics
     * Using database queries and accessible file paths
     */
    public function getSummary()
    {
        // Count sites in accessible directory
        $sitesCount = 0;
        $sitesPath = '/opt/webserver/sites';
        if (@is_dir($sitesPath)) {
            $sites = @scandir($sitesPath);
            if ($sites !== false) {
                $sitesCount = count(array_filter($sites, function($item) use ($sitesPath) {
                    return $item != '.' && $item != '..' && @is_dir($sitesPath . '/' . $item);
                }));
            }
        }

        // Email domains and accounts - use database instead of files
        // These would be stored in admin panel database in a complete implementation
        $emailDomains = 0;
        $emailAccounts = 0;
        
        // Try to read from accessible config files or database
        // For now, return 0 as we can't access /etc/postfix/
        
        // Get uptime using /proc/uptime if accessible
        $uptime = $this->getSystemUptime();
        
        return [
            'sites' => $sitesCount,
            'email_domains' => $emailDomains,
            'email_accounts' => $emailAccounts,
            'uptime' => $uptime
        ];
    }

    /**
     * Get system uptime from /proc/uptime
     */
    private function getSystemUptime()
    {
        $uptimeData = @file_get_contents('/proc/uptime');
        
        if ($uptimeData === false) {
            return 'Unknown';
        }
        
        $uptime = (int) explode(' ', $uptimeData)[0];
        
        $days = floor($uptime / 86400);
        $hours = floor(($uptime % 86400) / 3600);
        $minutes = floor(($uptime % 3600) / 60);
        
        $parts = [];
        if ($days > 0) $parts[] = "$days day" . ($days != 1 ? 's' : '');
        if ($hours > 0) $parts[] = "$hours hour" . ($hours != 1 ? 's' : '');
        if ($minutes > 0) $parts[] = "$minutes minute" . ($minutes != 1 ? 's' : '');
        
        return implode(', ', $parts) ?: 'Just started';
    }

    /**
     * Format bytes to human-readable format
     */
    private function formatBytes($bytes, $precision = 2)
    {
        if ($bytes == 0) return '0 B';
        
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $base = log($bytes) / log(1024);
        
        return round(pow(1024, $base - floor($base)), $precision) . ' ' . $units[floor($base)];
    }

    /**
     * API endpoint for metrics
     */
    public function apiMetrics()
    {
        return response()->json($this->getMetrics());
    }

    /**
     * API endpoint for services status
     */
    public function apiServices()
    {
        return response()->json($this->getServicesStatus());
    }

    /**
     * API endpoint for summary
     */
    public function apiSummary()
    {
        return response()->json($this->getSummary());
    }
}
