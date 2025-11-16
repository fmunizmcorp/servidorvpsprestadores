<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\SystemCommandService;

class ServicesController extends Controller
{
    private $systemCommand;
    
    public function __construct()
    {
        $this->systemCommand = new SystemCommandService();
    }
    
    /**
     * Display list of all services
     */
    public function index()
    {
        $services = $this->getAllServices();
        
        return view('services.index', [
            'services' => $services
        ]);
    }
    
    /**
     * Control service (start, stop, restart, reload)
     */
    public function control(Request $request, $serviceName)
    {
        $action = $request->input('action');
        
        if (!in_array($action, ['start', 'stop', 'restart', 'reload'])) {
            return redirect()->back()
                ->with('error', 'Invalid action');
        }
        
        try {
            $result = $this->systemCommand->controlService($serviceName, $action);
            
            if ($result['success']) {
                return redirect()->back()
                    ->with('success', "Service {$serviceName} {$action}ed successfully!");
            } else {
                return redirect()->back()
                    ->with('error', "Failed to {$action} service: " . $result['output']);
            }
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Error: ' . $e->getMessage());
        }
    }
    
    /**
     * Show service details
     */
    public function show($serviceName)
    {
        try {
            $status = $this->systemCommand->getServiceStatus($serviceName);
            
            // Get service logs
            $logs = $this->getServiceLogs($serviceName);
            
            return view('services.show', [
                'service' => $serviceName,
                'status' => $status,
                'logs' => $logs
            ]);
        } catch (\Exception $e) {
            abort(404, 'Service not found');
        }
    }
    
    /**
     * Get status of all services
     */
    public function status()
    {
        $services = $this->getAllServices();
        
        return response()->json([
            'success' => true,
            'services' => $services
        ]);
    }
    
    // ========== HELPER METHODS ==========
    
    /**
     * Get all monitored services with their status
     */
    private function getAllServices()
    {
        $serviceList = [
            'nginx' => [
                'name' => 'NGINX',
                'description' => 'Web server and reverse proxy',
                'icon' => 'server'
            ],
            'php8.3-fpm' => [
                'name' => 'PHP-FPM 8.3',
                'description' => 'PHP FastCGI Process Manager',
                'icon' => 'code'
            ],
            'mysql' => [
                'name' => 'MySQL',
                'description' => 'Database server',
                'icon' => 'database'
            ],
            'postfix' => [
                'name' => 'Postfix',
                'description' => 'Mail transfer agent (SMTP)',
                'icon' => 'mail'
            ],
            'dovecot' => [
                'name' => 'Dovecot',
                'description' => 'IMAP/POP3 server',
                'icon' => 'inbox'
            ],
            'fail2ban' => [
                'name' => 'Fail2Ban',
                'description' => 'Intrusion prevention system',
                'icon' => 'shield'
            ],
            'clamav-daemon' => [
                'name' => 'ClamAV',
                'description' => 'Antivirus engine',
                'icon' => 'shield-check'
            ]
        ];
        
        $services = [];
        
        foreach ($serviceList as $serviceKey => $serviceInfo) {
            try {
                $status = $this->systemCommand->getServiceStatus($serviceKey);
                
                $services[] = array_merge($serviceInfo, [
                    'key' => $serviceKey,
                    'status' => $status['status'],
                    'active' => $status['active'],
                    'enabled' => $status['enabled']
                ]);
            } catch (\Exception $e) {
                $services[] = array_merge($serviceInfo, [
                    'key' => $serviceKey,
                    'status' => 'unknown',
                    'active' => false,
                    'enabled' => false,
                    'error' => $e->getMessage()
                ]);
            }
        }
        
        return $services;
    }
    
    /**
     * Get service logs
     */
    private function getServiceLogs($serviceName, $lines = 50)
    {
        try {
            $command = "sudo journalctl -u " . escapeshellarg($serviceName) . " -n " . escapeshellarg($lines) . " --no-pager 2>/dev/null";
            $output = shell_exec($command);
            
            if ($output) {
                return array_reverse(explode("\n", trim($output)));
            }
            
            return [];
        } catch (\Exception $e) {
            return [];
        }
    }
}
