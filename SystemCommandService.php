<?php

namespace App\Services;

use Exception;

/**
 * Service para executar comandos do sistema via sudo wrappers seguros
 */
class SystemCommandService
{
    private $wrappersPath = '/opt/webserver/scripts/wrappers';
    
    /**
     * Controlar serviço (start, stop, restart, reload, status)
     */
    public function controlService(string $service, string $action): array
    {
        $allowedServices = ['nginx', 'php8.3-fpm', 'mysql', 'postfix', 'dovecot', 'clamav-daemon', 'fail2ban'];
        $allowedActions = ['start', 'stop', 'restart', 'reload', 'status'];
        
        if (!in_array($service, $allowedServices)) {
            throw new Exception("Service not allowed: $service");
        }
        
        if (!in_array($action, $allowedActions)) {
            throw new Exception("Action not allowed: $action");
        }
        
        $command = "sudo {$this->wrappersPath}/service-control.sh " . escapeshellarg($service) . " " . escapeshellarg($action);
        
        return $this->executeCommand($command);
    }
    
    /**
     * Testar configuração NGINX
     */
    public function testNginxConfig(): array
    {
        $command = "sudo {$this->wrappersPath}/nginx-test.sh";
        return $this->executeCommand($command);
    }
    
    /**
     * Criar backup
     */
    public function createBackup(string $type, string $target): array
    {
        $allowedTypes = ['site', 'database', 'email', 'full'];
        
        if (!in_array($type, $allowedTypes)) {
            throw new Exception("Backup type not allowed: $type");
        }
        
        $command = "sudo {$this->wrappersPath}/create-backup.sh " . escapeshellarg($type) . " " . escapeshellarg($target);
        
        return $this->executeCommand($command);
    }
    
    /**
     * Restaurar backup
     */
    public function restoreBackup(string $backupFile): array
    {
        // Validar que o arquivo está no diretório de backups
        if (!preg_match('#^/opt/webserver/backups/.+#', $backupFile)) {
            throw new Exception("Invalid backup file path");
        }
        
        $command = "sudo {$this->wrappersPath}/restore-backup.sh " . escapeshellarg($backupFile);
        
        return $this->executeCommand($command);
    }
    
    /**
     * Ativar/desativar site
     */
    public function toggleSite(string $siteName, bool $enable): array
    {
        $action = $enable ? 'enable' : 'disable';
        
        $command = "sudo {$this->wrappersPath}/site-toggle.sh " . escapeshellarg($siteName) . " " . escapeshellarg($action);
        
        return $this->executeCommand($command);
    }
    
    /**
     * Obter status de serviço
     */
    public function getServiceStatus(string $service): array
    {
        $command = "sudo systemctl is-active " . escapeshellarg($service) . " 2>/dev/null";
        $output = shell_exec($command);
        
        $isActive = trim($output) === 'active';
        
        $command2 = "sudo systemctl is-enabled " . escapeshellarg($service) . " 2>/dev/null";
        $output2 = shell_exec($command2);
        
        $isEnabled = trim($output2) === 'enabled';
        
        return [
            'success' => true,
            'service' => $service,
            'active' => $isActive,
            'enabled' => $isEnabled,
            'status' => $isActive ? 'running' : 'stopped'
        ];
    }
    
    /**
     * Obter métricas do sistema
     */
    public function getSystemMetrics(): array
    {
        $metrics = [];
        
        // CPU usage
        $cpuLoad = sys_getloadavg();
        $metrics['cpu'] = [
            'load_1min' => round($cpuLoad[0], 2),
            'load_5min' => round($cpuLoad[1], 2),
            'load_15min' => round($cpuLoad[2], 2),
        ];
        
        // Memory usage
        $memInfo = $this->parseMemInfo();
        $metrics['memory'] = $memInfo;
        
        // Disk usage
        $diskTotal = disk_total_space('/');
        $diskFree = disk_free_space('/');
        $diskUsed = $diskTotal - $diskFree;
        
        $metrics['disk'] = [
            'total' => $this->formatBytes($diskTotal),
            'used' => $this->formatBytes($diskUsed),
            'free' => $this->formatBytes($diskFree),
            'usage_percent' => round(($diskUsed / $diskTotal) * 100, 2)
        ];
        
        // Uptime
        $uptime = shell_exec('cat /proc/uptime');
        $uptimeSeconds = (int)explode(' ', $uptime)[0];
        $metrics['uptime'] = $this->formatUptime($uptimeSeconds);
        
        return $metrics;
    }
    
    /**
     * Listar backups disponíveis
     */
    public function listBackups(): array
    {
        $backupDir = '/opt/webserver/backups';
        $backups = [];
        
        if (!is_dir($backupDir)) {
            return $backups;
        }
        
        $files = scandir($backupDir);
        
        foreach ($files as $file) {
            if ($file === '.' || $file === '..') {
                continue;
            }
            
            $filePath = $backupDir . '/' . $file;
            
            if (is_file($filePath)) {
                $backups[] = [
                    'name' => $file,
                    'id' => $file,  // Fixed: add 'id' key for view compatibility
                    'path' => $filePath,
                    'size' => $this->formatBytes(filesize($filePath)),
                    'size_bytes' => filesize($filePath),
                    'date' => date('Y-m-d H:i:s', filemtime($filePath)),
                    'time' => date('Y-m-d H:i:s', filemtime($filePath)),  // Fixed: add 'time' key
                    'duration' => 'N/A',  // Fixed: add 'duration' key (not stored in file metadata)
                    'type' => $this->detectBackupType($file)
                ];
            }
        }
        
        // Ordenar por data (mais recente primeiro)
        usort($backups, function($a, $b) {
            return $b['date'] <=> $a['date'];
        });
        
        return $backups;
    }
    
    // ============ HELPER METHODS ============
    
    /**
     * Executar comando e capturar output
     */
    private function executeCommand(string $command): array
    {
        $output = [];
        $returnVar = 0;
        
        exec($command . ' 2>&1', $output, $returnVar);
        
        return [
            'success' => $returnVar === 0,
            'exit_code' => $returnVar,
            'output' => implode("\n", $output),
            'output_lines' => $output
        ];
    }
    
    /**
     * Parse /proc/meminfo
     */
    private function parseMemInfo(): array
    {
        $memInfo = file_get_contents('/proc/meminfo');
        
        preg_match('/MemTotal:\s+(\d+)/', $memInfo, $total);
        preg_match('/MemAvailable:\s+(\d+)/', $memInfo, $available);
        
        $totalKb = isset($total[1]) ? (int)$total[1] : 0;
        $availableKb = isset($available[1]) ? (int)$available[1] : 0;
        $usedKb = $totalKb - $availableKb;
        
        return [
            'total' => $this->formatBytes($totalKb * 1024),
            'used' => $this->formatBytes($usedKb * 1024),
            'free' => $this->formatBytes($availableKb * 1024),
            'usage_percent' => $totalKb > 0 ? round(($usedKb / $totalKb) * 100, 2) : 0
        ];
    }
    
    /**
     * Formatar bytes para formato legível
     */
    private function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        
        for ($i = 0; $bytes >= 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, 2) . ' ' . $units[$i];
    }
    
    /**
     * Formatar uptime
     */
    private function formatUptime(int $seconds): string
    {
        $days = floor($seconds / 86400);
        $hours = floor(($seconds % 86400) / 3600);
        $minutes = floor(($seconds % 3600) / 60);
        
        if ($days > 0) {
            return "{$days}d {$hours}h {$minutes}m";
        } elseif ($hours > 0) {
            return "{$hours}h {$minutes}m";
        } else {
            return "{$minutes}m";
        }
    }
    
    /**
     * Detectar tipo de backup pelo nome do arquivo
     */
    private function detectBackupType(string $filename): string
    {
        if (preg_match('/^site-/', $filename)) {
            return 'Site';
        } elseif (preg_match('/^db-/', $filename)) {
            return 'Database';
        } elseif (preg_match('/^email-/', $filename)) {
            return 'Email';
        } elseif (preg_match('/^full-/', $filename)) {
            return 'Full Backup';
        }
        
        return 'Unknown';
    }
}
