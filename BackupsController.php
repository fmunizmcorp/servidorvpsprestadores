<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class BackupsController extends Controller
{
    private $backupPath = '/opt/webserver/backups';
    private $scriptsPath = '/opt/webserver/scripts';
    private $resticRepo = '/opt/webserver/backups/restic-repo';
    
    /**
     * Backups dashboard
     */
    public function index()
    {
        $stats = $this->getBackupStats();
        $recentBackups = $this->getRecentBackups(10);
        
        return view('backups.index', [
            'stats' => $stats,
            'recentBackups' => $recentBackups
        ]);
    }
    
    /**
     * List all backups
     */
    public function list(Request $request)
    {
        $type = $request->get('type', 'all'); // all, sites, email
        $backups = $this->getAllBackups($type);
        
        return view('backups.list', [
            'backups' => $backups,
            'type' => $type
        ]);
    }
    
    /**
     * Trigger manual backup
     */
    public function trigger(Request $request)
    {
        $type = $request->get('type', 'full'); // full, sites, email
        
        try {
            $output = '';
            
            switch ($type) {
                case 'sites':
                    $output = $this->runBackupScript('backup.sh');
                    break;
                    
                case 'email':
                    $output = $this->runBackupScript('backup-mail.sh');
                    break;
                    
                case 'full':
                default:
                    $output = $this->runBackupScript('backup.sh');
                    $output .= "\n\n";
                    $output .= $this->runBackupScript('backup-mail.sh');
                    break;
            }
            
            return redirect()->route('backups.index')
                ->with('success', "Backup triggered successfully!")
                ->with('output', $output);
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to trigger backup: ' . $e->getMessage());
        }
    }
    
    /**
     * Restore wizard
     */
    public function restore(Request $request)
    {
        $snapshotId = $request->get('snapshot');
        $backups = $this->getAllBackups('all');
        
        $snapshotDetails = null;
        if ($snapshotId) {
            $snapshotDetails = $this->getSnapshotDetails($snapshotId);
        }
        
        return view('backups.restore', [
            'backups' => $backups,
            'snapshotId' => $snapshotId,
            'snapshotDetails' => $snapshotDetails
        ]);
    }
    
    /**
     * Execute restore
     */
    public function executeRestore(Request $request)
    {
        $snapshotId = $request->snapshot_id;
        $restoreType = $request->restore_type; // full, selective
        $targetPath = $request->target_path;
        
        if (empty($snapshotId) || empty($restoreType)) {
            return redirect()->back()
                ->with('error', 'Invalid restore parameters');
        }
        
        try {
            $script = "{$this->scriptsPath}/restore.sh";
            
            if (!file_exists($script)) {
                throw new \Exception("Restore script not found");
            }
            
            // Execute restore script
            $command = "bash $script $snapshotId";
            
            if ($restoreType === 'selective' && !empty($targetPath)) {
                $command .= " $targetPath";
            }
            
            $output = shell_exec("$command 2>&1");
            
            return redirect()->route('backups.index')
                ->with('success', 'Restore completed successfully!')
                ->with('output', $output);
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to restore: ' . $e->getMessage());
        }
    }
    
    /**
     * View backup logs
     */
    public function logs(Request $request)
    {
        $lines = $request->get('lines', 100);
        $logs = $this->getBackupLogs($lines);
        
        return view('backups.logs', [
            'logs' => $logs,
            'lines' => $lines
        ]);
    }
    
    /**
     * Delete backup snapshot
     */
    public function delete($snapshotId)
    {
        try {
            // Use restic forget to delete snapshot
            $command = "restic -r {$this->resticRepo} forget $snapshotId --prune 2>&1";
            $output = shell_exec($command);
            
            if (strpos($output, 'removed') !== false || strpos($output, 'successfully') !== false) {
                return redirect()->route('backups.index')
                    ->with('success', "Backup snapshot deleted successfully!");
            } else {
                throw new \Exception("Failed to delete snapshot: $output");
            }
            
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to delete backup: ' . $e->getMessage());
        }
    }
    
    // ========== HELPER METHODS ==========
    
    /**
     * Get backup statistics
     */
    private function getBackupStats()
    {
        $stats = [
            'total_backups' => 0,
            'total_size' => '0 B',
            'last_backup' => 'Never',
            'last_backup_status' => 'unknown',
            'disk_usage' => '0%',
            'disk_available' => '0 B'
        ];
        
        // Check if restic repo exists
        if (!is_dir($this->resticRepo)) {
            return $stats;
        }
        
        // Get restic stats
        $statsOutput = shell_exec("restic -r {$this->resticRepo} stats --json 2>/dev/null");
        
        if ($statsOutput) {
            $statsData = json_decode($statsOutput, true);
            if ($statsData) {
                $stats['total_size'] = $this->formatBytes($statsData['total_size'] ?? 0);
            }
        }
        
        // Count snapshots
        $snapshotsOutput = shell_exec("restic -r {$this->resticRepo} snapshots --json 2>/dev/null");
        
        if ($snapshotsOutput) {
            $snapshots = json_decode($snapshotsOutput, true);
            if (is_array($snapshots)) {
                $stats['total_backups'] = count($snapshots);
                
                // Get last backup time
                if (!empty($snapshots)) {
                    $lastSnapshot = end($snapshots);
                    $stats['last_backup'] = date('Y-m-d H:i:s', strtotime($lastSnapshot['time']));
                    $stats['last_backup_status'] = 'success';
                }
            }
        }
        
        // Get disk usage
        $diskTotal = disk_total_space($this->backupPath);
        $diskFree = disk_free_space($this->backupPath);
        
        if ($diskTotal && $diskFree) {
            $diskUsed = $diskTotal - $diskFree;
            $stats['disk_usage'] = round(($diskUsed / $diskTotal) * 100, 2) . '%';
            $stats['disk_available'] = $this->formatBytes($diskFree);
        }
        
        return $stats;
    }
    
    /**
     * Get recent backups
     */
    private function getRecentBackups($limit = 10)
    {
        $backups = [];
        
        if (!is_dir($this->resticRepo)) {
            return $backups;
        }
        
        $snapshotsOutput = shell_exec("restic -r {$this->resticRepo} snapshots --json 2>/dev/null");
        
        if (!$snapshotsOutput) {
            return $backups;
        }
        
        $snapshots = json_decode($snapshotsOutput, true);
        
        if (!is_array($snapshots)) {
            return $backups;
        }
        
        // Sort by time (most recent first)
        usort($snapshots, function($a, $b) {
            return strtotime($b['time']) - strtotime($a['time']);
        });
        
        // Limit results
        $snapshots = array_slice($snapshots, 0, $limit);
        
        foreach ($snapshots as $snapshot) {
            $backups[] = [
                'id' => $snapshot['short_id'],
                'time' => date('Y-m-d H:i:s', strtotime($snapshot['time'])),
                'hostname' => $snapshot['hostname'] ?? 'unknown',
                'paths' => implode(', ', $snapshot['paths'] ?? []),
                'tags' => implode(', ', $snapshot['tags'] ?? [])
            ];
        }
        
        return $backups;
    }
    
    /**
     * Get all backups
     */
    private function getAllBackups($type = 'all')
    {
        $backups = [];
        
        if (!is_dir($this->resticRepo)) {
            return $backups;
        }
        
        $snapshotsOutput = shell_exec("restic -r {$this->resticRepo} snapshots --json 2>/dev/null");
        
        if (!$snapshotsOutput) {
            return $backups;
        }
        
        $snapshots = json_decode($snapshotsOutput, true);
        
        if (!is_array($snapshots)) {
            return $backups;
        }
        
        foreach ($snapshots as $snapshot) {
            $paths = implode(', ', $snapshot['paths'] ?? []);
            $tags = implode(', ', $snapshot['tags'] ?? []);
            
            // Filter by type
            if ($type !== 'all') {
                if ($type === 'sites' && strpos($paths, '/opt/webserver/sites') === false) {
                    continue;
                }
                if ($type === 'email' && strpos($paths, '/var/mail') === false) {
                    continue;
                }
            }
            
            $backups[] = [
                'id' => $snapshot['id'],
                'short_id' => $snapshot['short_id'],
                'time' => date('Y-m-d H:i:s', strtotime($snapshot['time'])),
                'hostname' => $snapshot['hostname'] ?? 'unknown',
                'paths' => $paths,
                'tags' => $tags
            ];
        }
        
        // Sort by time (most recent first)
        usort($backups, function($a, $b) {
            return strtotime($b['time']) - strtotime($a['time']);
        });
        
        return $backups;
    }
    
    /**
     * Get snapshot details
     */
    private function getSnapshotDetails($snapshotId)
    {
        $command = "restic -r {$this->resticRepo} snapshots $snapshotId --json 2>/dev/null";
        $output = shell_exec($command);
        
        if (!$output) {
            return null;
        }
        
        $snapshots = json_decode($output, true);
        
        if (!is_array($snapshots) || empty($snapshots)) {
            return null;
        }
        
        $snapshot = $snapshots[0];
        
        // Get file list for this snapshot
        $filesCommand = "restic -r {$this->resticRepo} ls $snapshotId --json 2>/dev/null | head -100";
        $filesOutput = shell_exec($filesCommand);
        
        $files = [];
        if ($filesOutput) {
            $lines = explode("\n", trim($filesOutput));
            foreach ($lines as $line) {
                if (empty($line)) continue;
                $fileData = json_decode($line, true);
                if ($fileData && isset($fileData['path'])) {
                    $files[] = $fileData['path'];
                }
            }
        }
        
        return [
            'id' => $snapshot['id'],
            'short_id' => $snapshot['short_id'],
            'time' => date('Y-m-d H:i:s', strtotime($snapshot['time'])),
            'hostname' => $snapshot['hostname'] ?? 'unknown',
            'paths' => $snapshot['paths'] ?? [],
            'tags' => $snapshot['tags'] ?? [],
            'files' => array_slice($files, 0, 100) // Limit to 100 files for display
        ];
    }
    
    /**
     * Run backup script
     */
    private function runBackupScript($scriptName)
    {
        $script = "{$this->scriptsPath}/$scriptName";
        
        if (!file_exists($script)) {
            throw new \Exception("Backup script $scriptName not found");
        }
        
        $command = "bash $script 2>&1";
        $output = shell_exec($command);
        
        return $output;
    }
    
    /**
     * Get backup logs
     */
    private function getBackupLogs($lines = 100)
    {
        $logFile = '/var/log/webserver/backup.log';
        
        if (!file_exists($logFile)) {
            return [];
        }
        
        $output = shell_exec("tail -n $lines $logFile 2>/dev/null");
        
        if (!$output) {
            return [];
        }
        
        return array_reverse(explode("\n", trim($output)));
    }
    
    /**
     * Format bytes to human readable
     */
    private function formatBytes($bytes, $precision = 2)
    {
        if ($bytes == 0) return '0 B';
        
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $base = log($bytes) / log(1024);
        
        return round(pow(1024, $base - floor($base)), $precision) . ' ' . $units[floor($base)];
    }
}
