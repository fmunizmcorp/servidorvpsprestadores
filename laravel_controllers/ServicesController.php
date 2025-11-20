<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

/**
 * Services Controller - SPRINT 37
 * Monitoramento e controle de serviços do sistema
 */
class ServicesController extends Controller
{
    /**
     * Display services status
     */
    public function index()
    {
        $services = $this->getAllServices();
        $systemInfo = $this->getSystemInfo();
        
        return view('services.index', [
            'services' => $services,
            'systemInfo' => $systemInfo
        ]);
    }
    
    /**
     * Restart service
     */
    public function restart($service)
    {
        try {
            $allowedServices = ['nginx', 'php8.3-fpm', 'mysql', 'postfix', 'dovecot'];
            
            if (!in_array($service, $allowedServices)) {
                throw new \Exception("Service not allowed");
            }
            
            // Execute restart command
            $command = "sudo systemctl restart " . escapeshellarg($service) . " 2>&1";
            $output = shell_exec($command);
            
            return redirect()->back()
                ->with('success', "Service $service restarted successfully!")
                ->with('output', $output);
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to restart service: ' . $e->getMessage());
        }
    }
    
    /**
     * Stop service
     */
    public function stop($service)
    {
        try {
            $allowedServices = ['nginx', 'php8.3-fpm', 'mysql', 'postfix', 'dovecot'];
            
            if (!in_array($service, $allowedServices)) {
                throw new \Exception("Service not allowed");
            }
            
            $command = "sudo systemctl stop " . escapeshellarg($service) . " 2>&1";
            $output = shell_exec($command);
            
            return redirect()->back()
                ->with('success', "Service $service stopped successfully!")
                ->with('output', $output);
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to stop service: ' . $e->getMessage());
        }
    }
    
    /**
     * Start service
     */
    public function start($service)
    {
        try {
            $allowedServices = ['nginx', 'php8.3-fpm', 'mysql', 'postfix', 'dovecot'];
            
            if (!in_array($service, $allowedServices)) {
                throw new \Exception("Service not allowed");
            }
            
            $command = "sudo systemctl start " . escapeshellarg($service) . " 2>&1";
            $output = shell_exec($command);
            
            return redirect()->back()
                ->with('success', "Service $service started successfully!")
                ->with('output', $output);
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to start service: ' . $e->getMessage());
        }
    }
    
    // ========== HELPER METHODS ==========
    
    /**
     * Get all services status
     */
    private function getAllServices()
    {
        $services = ['nginx', 'php8.3-fpm', 'mysql', 'postfix', 'dovecot'];
        $result = [];
        
        foreach ($services as $service) {
            $status = $this->getServiceStatus($service);
            $result[] = [
                'name' => $service,
                'display_name' => $this->getServiceDisplayName($service),
                'status' => $status['active'] ? 'running' : 'stopped',
                'enabled' => $status['enabled'],
                'uptime' => $status['uptime'],
                'memory' => $status['memory'],
                'cpu' => $status['cpu']
            ];
        }
        
        return $result;
    }
    
    /**
     * Get service status
     */
    private function getServiceStatus($service)
    {
        $active = shell_exec("systemctl is-active $service 2>/dev/null") === "active\n";
        $enabled = shell_exec("systemctl is-enabled $service 2>/dev/null") === "enabled\n";
        
        // Get uptime
        $uptime = 'Unknown';
        $uptimeOutput = shell_exec("systemctl show $service --property=ActiveEnterTimestamp 2>/dev/null");
        if ($uptimeOutput && strpos($uptimeOutput, '=') !== false) {
            list(, $timestamp) = explode('=', trim($uptimeOutput));
            if (!empty($timestamp) && $timestamp !== 'n/a') {
                $uptime = \Carbon\Carbon::parse($timestamp)->diffForHumans();
            }
        }
        
        // Get memory usage
        $memory = '0 MB';
        $memOutput = shell_exec("systemctl show $service --property=MemoryCurrent 2>/dev/null");
        if ($memOutput && strpos($memOutput, '=') !== false) {
            list(, $bytes) = explode('=', trim($memOutput));
            if (is_numeric($bytes) && $bytes > 0) {
                $memory = round($bytes / 1024 / 1024, 1) . ' MB';
            }
        }
        
        // Get CPU usage (approximate)
        $cpu = '0%';
        $cpuOutput = shell_exec("systemctl show $service --property=CPUUsageNSec 2>/dev/null");
        if ($cpuOutput && strpos($cpuOutput, '=') !== false) {
            list(, $nanoseconds) = explode('=', trim($cpuOutput));
            if (is_numeric($nanoseconds) && $nanoseconds > 0) {
                // Simplified CPU calculation
                $cpu = '< 1%';
            }
        }
        
        return [
            'active' => $active,
            'enabled' => $enabled,
            'uptime' => $uptime,
            'memory' => $memory,
            'cpu' => $cpu
        ];
    }
    
    /**
     * Get service display name
     */
    private function getServiceDisplayName($service)
    {
        $names = [
            'nginx' => 'NGINX Web Server',
            'php8.3-fpm' => 'PHP-FPM 8.3',
            'mysql' => 'MySQL Database',
            'postfix' => 'Postfix Mail Server',
            'dovecot' => 'Dovecot IMAP/POP3'
        ];
        
        return $names[$service] ?? ucfirst($service);
    }
    
    /**
     * Get system information
     */
    private function getSystemInfo()
    {
        // Memory
        $memInfo = shell_exec("free -h | grep Mem");
        $memParts = preg_split('/\s+/', trim($memInfo));
        
        // Disk
        $diskInfo = shell_exec("df -h / | tail -1");
        $diskParts = preg_split('/\s+/', trim($diskInfo));
        
        // CPU Load
        $loadavg = sys_getloadavg();
        
        // Uptime
        $uptime = shell_exec("uptime -p");
        
        return [
            'memory_total' => $memParts[1] ?? 'Unknown',
            'memory_used' => $memParts[2] ?? 'Unknown',
            'memory_free' => $memParts[3] ?? 'Unknown',
            'disk_total' => $diskParts[1] ?? 'Unknown',
            'disk_used' => $diskParts[2] ?? 'Unknown',
            'disk_available' => $diskParts[3] ?? 'Unknown',
            'disk_percent' => rtrim($diskParts[4] ?? '0%', '%'),
            'load_1min' => $loadavg[0],
            'load_5min' => $loadavg[1],
            'load_15min' => $loadavg[2],
            'uptime' => trim($uptime) ?: 'Unknown',
            'php_version' => PHP_VERSION,
            'server_ip' => '72.61.53.222'
        ];
    }
}
