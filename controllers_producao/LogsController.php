<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

/**
 * Logs Controller - SPRINT 37
 * Visualização de logs do sistema
 */
class LogsController extends Controller
{
    /**
     * Display logs page
     */
    public function index(Request $request)
    {
        $logType = $request->get('type', 'laravel');
        $lines = $request->get('lines', 100);
        $filter = $request->get('filter', '');
        
        $logs = $this->getLogs($logType, $lines, $filter);
        $logTypes = $this->getAvailableLogTypes();
        
        return view('logs.index', [
            'logs' => $logs,
            'logTypes' => $logTypes,
            'selectedType' => $logType,
            'lines' => $lines,
            'filter' => $filter
        ]);
    }
    
    /**
     * Download log file
     */
    public function download($type)
    {
        $filePath = $this->getLogFilePath($type);
        
        if (!file_exists($filePath)) {
            return redirect()->back()
                ->with('error', "Log file not found");
        }
        
        return response()->download($filePath);
    }
    
    /**
     * Clear log file
     */
    public function clear($type)
    {
        try {
            $filePath = $this->getLogFilePath($type);
            
            if (file_exists($filePath)) {
                file_put_contents($filePath, '');
            }
            
            return redirect()->back()
                ->with('success', "Log cleared successfully!");
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to clear log: ' . $e->getMessage());
        }
    }
    
    // ========== HELPER METHODS ==========
    
    /**
     * Get available log types
     */
    private function getAvailableLogTypes()
    {
        return [
            'laravel' => 'Laravel Application',
            'nginx' => 'NGINX Access',
            'nginx-error' => 'NGINX Error',
            'php-fpm' => 'PHP-FPM',
            'mysql' => 'MySQL',
            'mail' => 'Mail Server'
        ];
    }
    
    /**
     * Get log file path by type
     */
    private function getLogFilePath($type)
    {
        $paths = [
            'laravel' => storage_path('logs/laravel.log'),
            'nginx' => '/var/log/nginx/access.log',
            'nginx-error' => '/var/log/nginx/error.log',
            'php-fpm' => '/var/log/php8.3-fpm.log',
            'mysql' => '/var/log/mysql/error.log',
            'mail' => '/var/log/mail.log'
        ];
        
        return $paths[$type] ?? storage_path('logs/laravel.log');
    }
    
    /**
     * Get logs from file
     */
    private function getLogs($type, $lines, $filter)
    {
        $filePath = $this->getLogFilePath($type);
        
        if (!file_exists($filePath)) {
            return [
                ['timestamp' => now(), 'level' => 'info', 'message' => 'Log file not found']
            ];
        }
        
        $command = "tail -n $lines " . escapeshellarg($filePath);
        
        if (!empty($filter)) {
            $command .= " | grep -i " . escapeshellarg($filter);
        }
        
        $output = shell_exec("$command 2>&1");
        
        if (!$output) {
            return [
                ['timestamp' => now(), 'level' => 'info', 'message' => 'No logs found']
            ];
        }
        
        $lines = explode("\n", trim($output));
        $logs = [];
        
        foreach (array_reverse($lines) as $line) {
            if (empty(trim($line))) continue;
            
            $logs[] = [
                'timestamp' => $this->extractTimestamp($line),
                'level' => $this->extractLogLevel($line),
                'message' => $line
            ];
        }
        
        return $logs;
    }
    
    /**
     * Extract timestamp from log line
     */
    private function extractTimestamp($line)
    {
        // Try to extract timestamp
        if (preg_match('/\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]/', $line, $matches)) {
            return $matches[1];
        }
        
        return now()->format('Y-m-d H:i:s');
    }
    
    /**
     * Extract log level from line
     */
    private function extractLogLevel($line)
    {
        if (stripos($line, 'error') !== false) return 'error';
        if (stripos($line, 'warning') !== false) return 'warning';
        if (stripos($line, 'info') !== false) return 'info';
        if (stripos($line, 'debug') !== false) return 'debug';
        
        return 'info';
    }
}
