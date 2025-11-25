<?php

namespace App\Http\Controllers;

use App\Models\Site;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SitesController extends Controller
{
    private $sitesPath = '/opt/webserver/sites';
    private $scriptsPath = '/opt/webserver/scripts';
    
    /**
     * Display list of all sites
     */
    public function index()
    {
        $sites = Site::orderBy('created_at', 'desc')
            ->get()
            ->map(function($site) {
                $sitePath = $this->sitesPath . '/' . $site->site_name;
                $diskUsage = is_dir($sitePath) ? $this->getDiskUsage($sitePath) : 'N/A';
                
                return [
                    'name' => $site->site_name,
                    'domain' => $site->domain,
                    'path' => $sitePath,
                    'disk_usage' => $diskUsage,
                    'phpVersion' => $site->php_version,
                    'ssl' => $site->ssl_enabled ?? false,
                    'nginxEnabled' => $site->status === 'active',
                    'created_at' => $site->created_at->timestamp ?? time(),
                    'status' => $site->status ?? 'active'
                ];
            })
            ->toArray();
        
        return response()
            ->view('sites.index', [
                'sites' => $sites,
                'total' => count($sites)
            ])
            ->header('Cache-Control', 'no-cache, no-store, must-revalidate, max-age=0')
            ->header('Pragma', 'no-cache')
            ->header('Expires', '0');
    }
    
    /**
     * Show create site form
     */
    public function create()
    {
        $phpVersions = ['8.3'];
        
        return view('sites.create', [
            'phpVersions' => $phpVersions
        ]);
    }
    
    /**
     * Store new site - v3.5 HYBRID SOLUTION
     * 
     * CHANGES:
     * 1. Save to database FIRST with status='creating'
     * 2. Execute script in BACKGROUND (no waiting)
     * 3. Return immediately with success message
     * 4. Script updates status to 'active' when complete
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'site_name' => 'required|alpha_dash|max:50|unique:sites,site_name',
            'domain' => 'required|regex:/^[a-z0-9\.\-]+$/|max:255',
            'php_version' => 'required|in:8.3',
            'create_database' => 'boolean'
        ]);
        
        if ($validator->fails()) {
            \Log::error('SPRINT57 v3.5: Validation failed', $validator->errors()->toArray());
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }
        
        try {
            // Extract request data
            $siteName = $request->site_name;
            $domain = $request->domain;
            $phpVersion = $request->php_version;
            $shouldCreateDB = $request->has('create_database') && $request->create_database;
            $template = $request->input('template', 'php');
            
            \Log::info('SPRINT57 v3.5: Site creation started', [
                'site_name' => $siteName,
                'domain' => $domain,
                'php_version' => $phpVersion,
                'create_database' => $shouldCreateDB
            ]);
            
            // ============================================================
            // SPRINT57 v3.5 CHANGE #1: SAVE TO DATABASE FIRST
            // ============================================================
            $site = Site::create([
                'site_name' => $siteName,
                'domain' => $domain,
                'php_version' => $phpVersion,
                'has_database' => $shouldCreateDB,
                'database_name' => $shouldCreateDB ? $siteName . '_db' : null,
                'database_user' => $shouldCreateDB ? $siteName . '_user' : null,
                'template' => $template,
                'status' => 'creating',  // ← Temporary status
            ]);
            
            \Log::info('SPRINT57 v3.5: Site saved to database with status=creating', [
                'site_id' => $site->id,
                'site_name' => $site->site_name
            ]);
            
            // ============================================================
            // SPRINT57 v3.5 CHANGE #2: EXECUTE SCRIPT IN BACKGROUND
            // ============================================================
            $wrapper = "/opt/webserver/scripts/wrappers/create-site-wrapper.sh";
            
            // Check if wrapper exists
            if (!file_exists($wrapper)) {
                \Log::error('SPRINT57 v3.5: Wrapper script not found', ['path' => $wrapper]);
                
                // Update site status to failed
                $site->update(['status' => 'failed']);
                
                return redirect()->back()
                    ->with('error', 'Wrapper script not found. Please contact administrator.')
                    ->withInput();
            }
            
            // Build command with background execution
            $dbFlag = $shouldCreateDB ? '' : '--no-db';
            $logFile = "/tmp/site_creation_{$siteName}_" . time() . ".log";
            
            // CRITICAL: Add & at the end to run in background
            $command = "sudo " . escapeshellarg($wrapper) . " " 
                     . escapeshellarg($siteName) . " " 
                     . escapeshellarg($domain) . " " 
                     . escapeshellarg($phpVersion) . " "
                     . $dbFlag . " "
                     . "--template=" . escapeshellarg($template) . " "
                     . "--callback-url=http://localhost:8080/api/sites/callback "
                     . "--site-id=" . $site->id . " "
                     . "> " . escapeshellarg($logFile) . " 2>&1 & echo $!";
            
            \Log::info('SPRINT57 v3.5: Executing command in background', [
                'command' => $command,
                'log_file' => $logFile
            ]);
            
            // Execute in background and get PID
            $pid = trim(shell_exec($command));
            
            if ($pid && is_numeric($pid)) {
                \Log::info('SPRINT57 v3.5: Background process started', [
                    'pid' => $pid,
                    'site_id' => $site->id
                ]);
                
                // Store PID in site record for tracking
                $site->update([
                    'creation_pid' => $pid,
                    'creation_log' => $logFile
                ]);
            } else {
                \Log::warning('SPRINT57 v3.5: Could not get PID for background process', [
                    'output' => $pid
                ]);
            }
            
            // ============================================================
            // SPRINT57 v3.5 CHANGE #3: RETURN IMMEDIATELY
            // ============================================================
            \Log::info('SPRINT57 v3.5: Returning success response immediately', [
                'site_id' => $site->id,
                'status' => 'creating'
            ]);
            
            return redirect()->route('sites.index')
                ->with('success', "Site '{$siteName}' is being created! This may take 30-60 seconds.")
                ->with('creating_site_id', $site->id)
                ->with('creating_site_name', $siteName);
                
        } catch (\Exception $e) {
            \Log::error('SPRINT57 v3.5: Exception during site creation', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            // If site was created in DB, mark as failed
            if (isset($site) && $site->exists) {
                $site->update(['status' => 'failed']);
            }
            
            return redirect()->back()
                ->with('error', 'Failed to create site: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    /**
     * API endpoint: Get site status (for polling)
     */
    public function getStatus($id)
    {
        $site = Site::findOrFail($id);
        
        return response()->json([
            'id' => $site->id,
            'site_name' => $site->site_name,
            'status' => $site->status,
            'created_at' => $site->created_at,
            'updated_at' => $site->updated_at,
        ]);
    }
    
    /**
     * API endpoint: Callback from wrapper script when creation completes
     */
    public function callback(Request $request)
    {
        \Log::info('SPRINT57 v3.5: Callback received', $request->all());
        
        $siteId = $request->input('site_id');
        $siteName = $request->input('site_name');
        $status = $request->input('status', 'active');
        $error = $request->input('error');
        
        if (!$siteId && $siteName) {
            // Find by name if ID not provided
            $site = Site::where('site_name', $siteName)->first();
        } else {
            $site = Site::find($siteId);
        }
        
        if (!$site) {
            \Log::error('SPRINT57 v3.5: Site not found in callback', [
                'site_id' => $siteId,
                'site_name' => $siteName
            ]);
            return response()->json(['error' => 'Site not found'], 404);
        }
        
        // Update site status
        $site->update([
            'status' => $status,
            'creation_error' => $error
        ]);
        
        \Log::info('SPRINT57 v3.5: Site status updated via callback', [
            'site_id' => $site->id,
            'status' => $status
        ]);
        
        return response()->json(['success' => true]);
    }
    
    /**
     * Get disk usage for a path
     */
    private function getDiskUsage($path)
    {
        if (!is_dir($path)) {
            return 'N/A';
        }
        
        $output = @shell_exec("du -sh " . escapeshellarg($path) . " 2>/dev/null | cut -f1");
        return $output ? trim($output) : 'N/A';
    }
}
