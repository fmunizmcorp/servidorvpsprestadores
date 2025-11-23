<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use App\Services\SystemCommandService;

class BackupsController extends Controller
{
    private $systemCommand;
    
    public function __construct()
    {
        $this->systemCommand = new SystemCommandService();
    }
    
    /**
     * Backups dashboard
     */
    public function index()
    {
        $backups = $this->systemCommand->listBackups();
        
        // Calculate stats
        $totalBackups = count($backups);
        $totalSizeBytes = array_sum(array_column($backups, 'size_bytes'));
        $lastBackup = $totalBackups > 0 ? $backups[0]['date'] : 'Never';
        
        $stats = [
            'totalBackups' => $totalBackups,
            'totalSize' => $this->formatBytes($totalSizeBytes),
            'lastBackup' => $lastBackup,
            'nextScheduled' => 'Daily at 02:00'
        ];
        
        return view('backups.index', [
            'stats' => $stats,
            'recentBackups' => array_slice($backups, 0, 10)
        ]);
    }
    
    /**
     * List all backups
     */
    public function list(Request $request)
    {
        $type = $request->get('type', 'all');
        $backups = $this->systemCommand->listBackups();
        
        // Filter by type if needed
        if ($type !== 'all') {
            $backups = array_filter($backups, function($backup) use ($type) {
                return stripos($backup['type'], $type) !== false;
            });
        }
        
        return view('backups.list', [
            'backups' => $backups,
            'type' => $type
        ]);
    }
    
    /**
     * Show create backup form
     */
    public function create()
    {
        // Get available sites for backup
        $sitesPath = '/opt/webserver/sites';
        $sites = [];
        
        if (is_dir($sitesPath)) {
            $dirs = scandir($sitesPath);
            foreach ($dirs as $dir) {
                if ($dir !== '.' && $dir !== '..' && is_dir($sitesPath . '/' . $dir)) {
                    $sites[] = $dir;
                }
            }
        }
        
        // Get available databases
        $databases = $this->getAvailableDatabases();
        
        return view('backups.create', [
            'sites' => $sites,
            'databases' => $databases
        ]);
    }
    
    /**
     * Store - Create new backup
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:site,database,email,full',
            'target' => 'required_unless:type,full'
        ]);
        
        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }
        
        try {
            $type = $request->input('type');
            $target = $request->input('target', 'full');
            
            $result = $this->systemCommand->createBackup($type, $target);
            
            if ($result['success']) {
                return redirect()->route('backups.index')
                    ->with('success', 'Backup created successfully!')
                    ->with('output', $result['output']);
            } else {
                return redirect()->back()
                    ->with('error', 'Backup failed: ' . $result['output'])
                    ->withInput();
            }
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Error creating backup: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    /**
     * Show restore form
     */
    public function restore($backupName)
    {
        $backups = $this->systemCommand->listBackups();
        
        $backup = null;
        foreach ($backups as $b) {
            if ($b['name'] === $backupName) {
                $backup = $b;
                break;
            }
        }
        
        if (!$backup) {
            abort(404, 'Backup not found');
        }
        
        return view('backups.restore', [
            'backup' => $backup
        ]);
    }
    
    /**
     * Process restore
     */
    public function processRestore(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'backup_path' => 'required'
        ]);
        
        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator);
        }
        
        try {
            $backupPath = $request->input('backup_path');
            
            // Validate backup path
            if (!preg_match('#^/opt/webserver/backups/.+#', $backupPath)) {
                throw new \Exception('Invalid backup path');
            }
            
            $result = $this->systemCommand->restoreBackup($backupPath);
            
            if ($result['success']) {
                return redirect()->route('backups.index')
                    ->with('success', 'Backup restored successfully!')
                    ->with('output', $result['output']);
            } else {
                return redirect()->back()
                    ->with('error', 'Restore failed: ' . $result['output']);
            }
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Error restoring backup: ' . $e->getMessage());
        }
    }
    
    /**
     * Delete backup
     */
    public function destroy($backupName)
    {
        try {
            $backups = $this->systemCommand->listBackups();
            
            $backup = null;
            foreach ($backups as $b) {
                if ($b['name'] === $backupName) {
                    $backup = $b;
                    break;
                }
            }
            
            if (!$backup) {
                throw new \Exception('Backup not found');
            }
            
            if (unlink($backup['path'])) {
                return redirect()->route('backups.index')
                    ->with('success', 'Backup deleted successfully!');
            } else {
                throw new \Exception('Failed to delete backup file');
            }
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Error deleting backup: ' . $e->getMessage());
        }
    }
    
    /**
     * Download backup
     */
    public function download($backupName)
    {
        $backups = $this->systemCommand->listBackups();
        
        $backup = null;
    
    /**
     * SPRINT 5: Download backup file
     */
    public function download($backupId)
    {
        $backups = $this->systemCommand->listBackups();
        $backup = null;
        
        foreach ($backups as $b) {
            if (isset($b['id']) && $b['id'] == $backupId) {
                $backup = $b;
                break;
            }
            if (isset($b['name']) && $b['name'] == $backupId) {
                $backup = $b;
                break;
            }
        }
        
        if (!$backup || !isset($backup['path'])) {
            abort(404, 'Backup not found');
        }
        
        $filePath = $backup['path'];
        
        if (!file_exists($filePath)) {
            abort(404, 'Backup file not found on disk');
        }
        
        return response()->download($filePath, basename($filePath), [
            'Content-Type' => 'application/gzip',
        ]);
    }
    
    // Helper methods continue...
    private function formatBytes($bytes)
    {
        if ($bytes >= 1073741824) {
            return number_format($bytes / 1073741824, 2) . ' GB';
        } elseif ($bytes >= 1048576) {
            return number_format($bytes / 1048576, 2) . ' MB';
        } elseif ($bytes >= 1024) {
            return number_format($bytes / 1024, 2) . ' KB';
        } else {
            return $bytes . ' bytes';
        }
    }
    
    private function getAvailableDatabases()
    {
        return ['admin_panel', 'site_db'];
    }
}
