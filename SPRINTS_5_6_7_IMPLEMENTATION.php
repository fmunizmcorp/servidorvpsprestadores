<?php
// SPRINT 5: BackupsController::download()
public function download($backupId)
{
    $backups = $this->systemCommand->listBackups();
    $backup = null;
    
    foreach ($backups as $b) {
        if ($b['id'] == $backupId || $b['name'] == $backupId) {
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
        'Content-Disposition' => 'attachment; filename="' . basename($filePath) . '"'
    ]);
}

// SPRINT 6: LogsController methods
public function index()
{
    $logFiles = $this->getAvailableLogFiles();
    $currentLog = request('file', 'laravel');
    $lines = request('lines', 100);
    
    $logContent = $this->readLogFile($currentLog, $lines);
    
    return view('logs.index', [
        'logFiles' => $logFiles,
        'currentLog' => $currentLog,
        'logContent' => $logContent,
        'lines' => $lines
    ]);
}

public function clear(Request $request)
{
    $request->validate([
        'log_file' => 'required|string'
    ]);
    
    $logFile = $request->log_file;
    $logPath = storage_path('logs/' . $logFile . '.log');
    
    if (!file_exists($logPath)) {
        return redirect()->back()->with('error', 'Log file not found');
    }
    
    // Clear log file
    file_put_contents($logPath, '');
    
    return redirect()->back()->with('success', 'Log file cleared successfully');
}

// SPRINT 7: ServicesController methods  
public function stop(Request $request)
{
    $request->validate([
        'service' => 'required|in:nginx,php8.3-fpm,mysql,postfix,dovecot'
    ]);
    
    $service = $request->service;
    $output = [];
    $returnVar = 0;
    
    exec("sudo systemctl stop {$service} 2>&1", $output, $returnVar);
    
    if ($returnVar === 0) {
        return redirect()->back()->with('success', "Service {$service} stopped successfully");
    } else {
        return redirect()->back()->with('error', "Failed to stop {$service}: " . implode("\n", $output));
    }
}

public function start(Request $request)
{
    $request->validate([
        'service' => 'required|in:nginx,php8.3-fpm,mysql,postfix,dovecot'
    ]);
    
    $service = $request->service;
    $output = [];
    $returnVar = 0;
    
    exec("sudo systemctl start {$service} 2>&1", $output, $returnVar);
    
    if ($returnVar === 0) {
        return redirect()->back()->with('success', "Service {$service} started successfully");
    } else {
        return redirect()->back()->with('error', "Failed to start {$service}: " . implode("\n", $output));
    }
}
