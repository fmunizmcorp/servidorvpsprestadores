<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        return view('dashboard', [
            'metrics' => $this->getMetrics(),
            'services' => $this->getServicesStatus(),
            'summary' => $this->getSummary()
        ]);
    }

    public function getMetrics()
    {
        $cpuLoad = sys_getloadavg();
        $cpuUsage = round($cpuLoad[0] * 100 / 2, 2);
        
        $memInfo = shell_exec("free | grep Mem | awk '{print $3/$2 * 100.0}'");
        $memUsage = round(floatval($memInfo), 2);
        
        $diskTotal = disk_total_space("/");
        $diskFree = disk_free_space("/");
        $diskUsage = round(($diskTotal - $diskFree) / $diskTotal * 100, 2);
        
        return [
            'cpu' => ['usage' => $cpuUsage, 'load' => $cpuLoad],
            'memory' => ['usage' => $memUsage],
            'disk' => [
                'usage' => $diskUsage,
                'total' => $this->formatBytes($diskTotal),
                'free' => $this->formatBytes($diskFree)
            ]
        ];
    }

    public function getServicesStatus()
    {
        $services = [
            'nginx' => 'nginx',
            'php-fpm' => 'php8.3-fpm',
            'mariadb' => 'mariadb',
            'redis' => 'redis-server',
            'postfix' => 'postfix',
            'dovecot' => 'dovecot',
            'fail2ban' => 'fail2ban'
        ];

        $status = [];
        foreach ($services as $name => $service) {
            $result = shell_exec("systemctl is-active $service 2>&1");
            $status[$name] = [
                'name' => ucfirst($name),
                'status' => trim($result) === 'active' ? 'running' : 'stopped'
            ];
        }

        return $status;
    }

    public function getSummary()
    {
        $sitesCount = 0;
        if (is_dir('/opt/webserver/sites')) {
            $sites = scandir('/opt/webserver/sites');
            $sitesCount = count(array_filter($sites, function($item) {
                return $item != '.' && $item != '..' && is_dir('/opt/webserver/sites/' . $item);
            }));
        }

        $emailDomains = 0;
        if (file_exists('/etc/postfix/virtual_domains')) {
            $domains = file('/etc/postfix/virtual_domains', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            $emailDomains = count($domains);
        }

        $emailAccounts = 0;
        if (file_exists('/etc/postfix/virtual_mailbox_maps')) {
            $accounts = file('/etc/postfix/virtual_mailbox_maps', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            $emailAccounts = count(array_filter($accounts, function($line) {
                return !empty(trim($line)) && strpos($line, '#') !== 0;
            }));
        }

        $uptime = shell_exec("uptime -p");
        
        return [
            'sites' => $sitesCount,
            'email_domains' => $emailDomains,
            'email_accounts' => $emailAccounts,
            'uptime' => trim(str_replace('up ', '', $uptime))
        ];
    }

    private function formatBytes($bytes, $precision = 2)
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        for ($i = 0; $bytes > 1024; $i++) {
            $bytes /= 1024;
        }
        return round($bytes, $precision) . ' ' . $units[$i];
    }

    public function apiMetrics()
    {
        return response()->json($this->getMetrics());
    }

    public function apiServices()
    {
        return response()->json($this->getServicesStatus());
    }

    public function apiSummary()
    {
        return response()->json($this->getSummary());
    }
}
