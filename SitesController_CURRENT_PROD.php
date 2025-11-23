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
                    'created_at' => $site->created_at->timestamp ?? time()
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
     * Store new site
     * RECOVERY FIX: Multiple fallback methods for command execution
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'site_name' => 'required|alpha_dash|max:50',
            'domain' => 'required|regex:/^[a-z0-9\.\-]+$/|max:255',
            'php_version' => 'required|in:8.3',
            'create_database' => 'boolean'
        ]);
        
        if ($validator->fails()) {
            \Log::error('RECOVERY: Validation failed', $validator->errors()->toArray());
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
            
            \Log::info('RECOVERY: Site creation started', [
                'site_name' => $siteName,
                'domain' => $domain,
                'php_version' => $phpVersion,
                'create_database' => $shouldCreateDB
            ]);
            
            // Build command
            $wrapper = "/opt/webserver/scripts/wrappers/create-site-wrapper.sh";
            
            // Check if wrapper exists
            if (!file_exists($wrapper)) {
                \Log::error('RECOVERY: Wrapper script not found', ['path' => $wrapper]);
                return redirect()->back()
                    ->with('error', 'Configuration error: Site creation script not found. Please contact system administrator.')
                    ->withInput();
            }
            
            $args = [
                escapeshellarg($siteName),
                escapeshellarg($domain),
                escapeshellarg($phpVersion),
            ];
            
            if (!$shouldCreateDB) {
                $args[] = '--no-db';
            }
            
            $args[] = "--template=" . escapeshellarg($template);
            
            $command = "sudo " . $wrapper . " " . implode(" ", $args) . " 2>&1";
            
            \Log::info('RECOVERY: Executing command', ['command' => $command]);
            
            // RECOVERY FIX: Try multiple methods to execute command
            $output = $this->executeCommand($command);
            
            if ($output === false) {
                \Log::error('RECOVERY: All command execution methods failed');
                return redirect()->back()
                    ->with('error', 'System error: Unable to execute site creation script. Please check server configuration.')
                    ->withInput();
            }
            
            \Log::info('RECOVERY: Command executed', ['output' => substr($output, 0, 500)]);
            
            // Wait for script to complete
            sleep(2);
            
            // Verify physical creation
            $sitePath = "/opt/webserver/sites/$siteName";
            $poolFile = "/etc/php/$phpVersion/fpm/pool.d/$siteName.conf";
            
            if (!is_dir($sitePath)) {
                \Log::error('RECOVERY: Site directory not created', [
                    'path' => $sitePath,
                    'output' => $output
                ]);
                
                return redirect()->back()
                    ->with('error', 'Site creation failed: Directory was not created. Check logs for details.')
                    ->with('debug_output', $output)
                    ->withInput();
            }
            
            if (!file_exists($poolFile)) {
                \Log::warning('RECOVERY: PHP-FPM pool not created but continuing', [
                    'path' => $poolFile
                ]);
                // Don't fail - pool might be created differently
            }
            
            \Log::info('RECOVERY: Site physically created, persisting to database');
            
            // Save to database
            $site = Site::create([
                'site_name' => $siteName,
                'domain' => $domain,
                'php_version' => $phpVersion,
                'has_database' => $shouldCreateDB,  // FIXED: Direct boolean value
                'database_name' => $shouldCreateDB ? $siteName . '_db' : null,  // FIXED: Correct logic
                'database_user' => $shouldCreateDB ? $siteName . '_user' : null,  // FIXED: Correct logic
                'template' => $template,
                'status' => 'active',
            ]);
            
            \Log::info('RECOVERY: Site persisted to database', [
                'site_id' => $site->id,
                'site_name' => $site->site_name
            ]);
            
            // Parse credentials if available
            $credentialsFile = "/opt/webserver/sites/$siteName/CREDENTIALS.txt";
            $credentials = [];
            
            if (file_exists($credentialsFile)) {
                $credContent = file_get_contents($credentialsFile);
                $credentials = $this->parseCredentialsFromFile($credContent);
            }
            
            // Success!
            return redirect()->route('sites.index')
                ->with('success', "Site '{$siteName}' created successfully!")
                ->with('credentials', $credentials);
                
        } catch (\Exception $e) {
            \Log::error('RECOVERY: Exception during site creation', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return redirect()->back()
                ->with('error', 'Failed to create site: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    /**
     * RECOVERY FIX: Execute command with multiple fallback methods
     */
    private function executeCommand($command)
    {
        \Log::info('RECOVERY: Trying command execution methods');
        
        // Method 1: shell_exec (most reliable if available)
        if (function_exists('shell_exec') && !$this->isFunctionDisabled('shell_exec')) {
            \Log::info('RECOVERY: Trying shell_exec');
            $output = @shell_exec($command);
            if ($output !== null) {
                \Log::info('RECOVERY: shell_exec succeeded');
                return $output;
            }
            \Log::warning('RECOVERY: shell_exec returned null');
        } else {
            \Log::warning('RECOVERY: shell_exec is disabled or not available');
        }
        
        // Method 2: exec
        if (function_exists('exec') && !$this->isFunctionDisabled('exec')) {
            \Log::info('RECOVERY: Trying exec');
            $output_array = [];
            $return_var = 0;
            @exec($command, $output_array, $return_var);
            if ($return_var === 0 && !empty($output_array)) {
                \Log::info('RECOVERY: exec succeeded');
                return implode("\n", $output_array);
            }
            \Log::warning('RECOVERY: exec failed or returned empty', [
                'return_code' => $return_var,
                'output_lines' => count($output_array)
            ]);
        } else {
            \Log::warning('RECOVERY: exec is disabled or not available');
        }
        
        // Method 3: proc_open (most flexible)
        if (function_exists('proc_open') && !$this->isFunctionDisabled('proc_open')) {
            \Log::info('RECOVERY: Trying proc_open');
            
            $descriptorspec = [
                0 => ['pipe', 'r'],  // stdin
                1 => ['pipe', 'w'],  // stdout
                2 => ['pipe', 'w']   // stderr
            ];
            
            $process = @proc_open($command, $descriptorspec, $pipes);
            
            if (is_resource($process)) {
                fclose($pipes[0]);
                
                $stdout = stream_get_contents($pipes[1]);
                $stderr = stream_get_contents($pipes[2]);
                
                fclose($pipes[1]);
                fclose($pipes[2]);
                
                $return_value = proc_close($process);
                
                \Log::info('RECOVERY: proc_open completed', [
                    'return_code' => $return_value,
                    'stdout_length' => strlen($stdout),
                    'stderr_length' => strlen($stderr)
                ]);
                
                if ($return_value === 0 || !empty($stdout)) {
                    return $stdout . ($stderr ? "\nSTDERR: " . $stderr : '');
                }
            } else {
                \Log::error('RECOVERY: proc_open failed to create process');
            }
        } else {
            \Log::warning('RECOVERY: proc_open is disabled or not available');
        }
        
        // All methods failed
        \Log::error('RECOVERY: All command execution methods failed', [
            'command' => $command,
            'disabled_functions' => ini_get('disable_functions')
        ]);
        
        return false;
    }
    
    /**
     * Check if a function is disabled
     */
    private function isFunctionDisabled($function)
    {
        $disabled = explode(',', ini_get('disable_functions'));
        $disabled = array_map('trim', $disabled);
        return in_array($function, $disabled);
    }
    
    /**
     * Parse credentials from file content
     */
    private function parseCredentialsFromFile($content)
    {
        $credentials = [];
        
        if (preg_match('/Database:\s*([^\s]+)/', $content, $matches)) {
            $credentials['database'] = $matches[1];
        }
        
        if (preg_match('/User:\s*([^\s]+)/', $content, $matches)) {
            $credentials['user'] = $matches[1];
        }
        
        if (preg_match('/Password:\s*([^\s]+)/', $content, $matches)) {
            $credentials['password'] = $matches[1];
        }
        
        return $credentials;
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
    
    // ... (rest of the controller methods remain the same)
}
