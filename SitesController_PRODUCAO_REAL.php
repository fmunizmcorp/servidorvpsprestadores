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
     * SPRINT 54: Fixed with cache clearing (Sprint 53 pattern + cache flush)
     */
    public function index()
    {
        // SPRINT 54: Query direta Eloquent como EmailController (FUNCIONA!)
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
        
        return view('sites.index', [
            'sites' => $sites,
            'total' => count($sites)
        ]);
    }
    
    /**
     * Show create site form
     */
    public function create()
    {
        // Only show PHP versions that are actually installed
        $phpVersions = ['8.3'];
        
        return view('sites.create', [
            'phpVersions' => $phpVersions
        ]);
    }
    
    /**
     * Store new site
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
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }
        
        try {
            // Prepare arguments
            $siteName = $request->site_name;
            $domain = $request->domain;
            $phpVersion = $request->php_version;
            $createDB = $request->has('create_database') && $request->create_database ? '' : '--no-db';
            $template = $request->input('template', 'php');
            
            // Build command with wrapper
            $wrapper = "/opt/webserver/scripts/wrappers/create-site-wrapper.sh";
            
            $args = [
                escapeshellarg($siteName),
                escapeshellarg($domain),
                escapeshellarg($phpVersion),
            ];
            
            if ($createDB) {
                $args[] = $createDB;
            }
            
            $args[] = "--template=" . escapeshellarg($template);
            
            $command = "sudo " . $wrapper . " " . implode(" ", $args) . " 2>&1";
            
            // Execute command
            $output = shell_exec($command);
            
            // Check if site was created successfully
            if (strpos($output, 'successfully') === false && strpos($output, 'ERROR') !== false) {
                throw new \Exception("Site creation failed: " . substr($output, 0, 500));
            }
            
            // SPRINT 53: Persistir no banco como EmailController (SIMPLES E DIRETO)
            $site = Site::create([
                'site_name' => $siteName,
                'domain' => $domain,
                'php_version' => $phpVersion,
                'has_database' => !$createDB,
                'database_name' => !$createDB ? $siteName . '_db' : null,
                'database_user' => !$createDB ? $siteName . '_user' : null,
                'template' => $template,
                'status' => 'active',
            ]);
            
            // Parse output for credentials
            $credentialsFile = "/opt/webserver/sites/$siteName/CREDENTIALS.txt";
            $credentials = [];
            
            if (file_exists($credentialsFile)) {
                $credContent = file_get_contents($credentialsFile);
                $credentials = $this->parseCredentialsFromFile($credContent);
            }
            
            // SPRINT 53: Redirect simples como EmailController
            return redirect()->route('sites.index')
                ->with('success', 'Site created successfully!')
                ->with('output', $output)
                ->with('credentials', $credentials);
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to create site: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    /**
     * Show site details
     */
    public function show($siteName)
    {
        $site = $this->getSiteDetails($siteName);
        
        if (!$site) {
            abort(404, 'Site not found');
        }
        
        return view('sites.show', [
            'site' => $site
        ]);
    }
    
    /**
     * Show edit form
     */
    public function edit($siteName)
    {
        $site = $this->getSiteDetails($siteName);
        
        if (!$site) {
            abort(404, 'Site not found');
        }
        
        return view('sites.edit', [
            'site' => $site
        ]);
    }
    
    /**
     * Update site configuration
     */
    public function update(Request $request, $siteName)
    {
        $validator = Validator::make($request->all(), [
            'memory_limit' => 'required|integer|min:64|max:1024',
            'max_execution_time' => 'required|integer|min:30|max:300',
            'upload_max_filesize' => 'required|integer|min:2|max:100'
        ]);
        
        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }
        
        try {
            // Update PHP-FPM pool configuration
            $poolFile = "/etc/php/8.3/fpm/pool.d/{$siteName}.conf";
            
            if (!file_exists($poolFile)) {
                throw new \Exception("Pool configuration not found");
            }
            
            // Read current config
            $config = file_get_contents($poolFile);
            
            // Update values
            $config = preg_replace(
                '/php_admin_value\[memory_limit\]\s*=\s*\d+M/',
                'php_admin_value[memory_limit] = ' . $request->memory_limit . 'M',
                $config
            );
            
            $config = preg_replace(
                '/php_admin_value\[max_execution_time\]\s*=\s*\d+/',
                'php_admin_value[max_execution_time] = ' . $request->max_execution_time,
                $config
            );
            
            $config = preg_replace(
                '/php_admin_value\[upload_max_filesize\]\s*=\s*\d+M/',
                'php_admin_value[upload_max_filesize] = ' . $request->upload_max_filesize . 'M',
                $config
            );
            
            // Write back
            file_put_contents($poolFile, $config);
            
            // Restart PHP-FPM
            shell_exec('systemctl reload php8.3-fpm');
            
            return redirect()->route('sites.show', $siteName)
                ->with('success', 'Site configuration updated successfully!');
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to update site: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    /**
     * Delete site
     */
    public function destroy($siteName)
    {
        try {
            // Execute delete-site.sh script (needs to be created)
            $script = "{$this->scriptsPath}/delete-site.sh";
            
            if (!file_exists($script)) {
                throw new \Exception("Script delete-site.sh not found");
            }
            
            $command = "bash $script $siteName 2>&1";
            $output = shell_exec($command);
            
            return redirect()->route('sites.index')
                ->with('success', 'Site deleted successfully!');
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to delete site: ' . $e->getMessage());
        }
    }
    
    /**
     * View site logs
     */
    public function logs($siteName)
    {
        $site = $this->getSiteDetails($siteName);
        
        if (!$site) {
            abort(404, 'Site not found');
        }
        
        $accessLog = $this->readLog("/var/log/nginx/{$siteName}.access.log", 100);
        $errorLog = $this->readLog("/var/log/nginx/{$siteName}.error.log", 100);
        $phpLog = $this->readLog("/opt/webserver/sites/{$siteName}/logs/php-errors.log", 100);
        
        return view('sites.logs', [
            'site' => $site,
            'accessLog' => $accessLog,
            'errorLog' => $errorLog,
            'phpLog' => $phpLog
        ]);
    }
    
    /**
     * Manage SSL
     */
    public function ssl($siteName)
    {
        $site = $this->getSiteDetails($siteName);
        
        if (!$site) {
            abort(404, 'Site not found');
        }
        
        $sslStatus = $this->checkSSLStatus($siteName);
        
        return view('sites.ssl', [
            'site' => $site,
            'sslStatus' => $sslStatus
        ]);
    }
    
    /**
     * Generate SSL certificate
     */
    public function generateSSL(Request $request, $siteName)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email'
        ]);
        
        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator);
        }
        
        try {
            $site = $this->getSiteDetails($siteName);
            
            if (!$site) {
                throw new \Exception("Site not found");
            }
            
            $domain = $site['domain'];
            $email = $request->email;
            
            // Execute certbot
            $command = "certbot --nginx -d $domain --non-interactive --agree-tos --email $email 2>&1";
            $output = shell_exec($command);
            
            // Check if successful
            if (strpos($output, 'Successfully') !== false || strpos($output, 'Certificate not yet due') !== false) {
                return redirect()->route('sites.ssl', $siteName)
                    ->with('success', 'SSL certificate generated successfully!');
            } else {
                throw new \Exception("Certbot failed: $output");
            }
            
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to generate SSL: ' . $e->getMessage());
        }
    }
    
    // ========== HELPER METHODS ==========
    

    /**
     * Get site details
     */
    private function getSiteDetails($siteName)
    {
        $sitePath = $this->sitesPath . '/' . $siteName;
        
        if (!is_dir($sitePath)) {
            return null;
        }
        
        // Get disk usage
        $diskUsage = $this->getDiskUsage($sitePath);
        
        // Get domain from NGINX config
        $domain = $this->getDomainFromNginx($siteName);
        
        // Get PHP version from pool
        $phpVersion = $this->getPhpVersion($siteName);
        
        // Check if SSL is enabled
        $sslEnabled = $this->isSSLEnabled($siteName);
        
        // Check if site is active
        $isActive = $this->isSiteActive($siteName);
        
        return [
            'name' => $siteName,
            'domain' => $domain,
            'path' => $sitePath,
            'disk_usage' => $diskUsage,
            'phpVersion' => $phpVersion,  // Fixed: camelCase for view compatibility
            'ssl' => $sslEnabled,  // Fixed: shorter key name for view
            'nginxEnabled' => $isActive,  // Fixed: renamed for view compatibility
            'created_at' => filectime($sitePath)
        ];
    }
    
    /**
     * Get disk usage
     */
    private function getDiskUsage($path)
    {
        $output = shell_exec("du -sh $path 2>/dev/null");
        
        if ($output) {
            return trim(explode("\t", $output)[0]);
        }
        
        return '0';
    }
    
    /**
     * Get domain from NGINX config
     */
    private function getDomainFromNginx($siteName)
    {
        try {
            // Try common NGINX config filename patterns
            $possibleConfigs = [
                "/etc/nginx/sites-available/$siteName",
                "/etc/nginx/sites-available/$siteName.conf",
            ];
            
            // Also try to find by pattern (e.g., sitename.domain.com.conf)
            $sitesAvailableDir = '/etc/nginx/sites-available';
            if (@is_dir($sitesAvailableDir)) {
                $files = @scandir($sitesAvailableDir);
                if ($files) {
                    foreach ($files as $file) {
                        if (strpos($file, $siteName) === 0 && strpos($file, '.conf') !== false) {
                            $possibleConfigs[] = "$sitesAvailableDir/$file";
                        }
                    }
                }
            }
            
            foreach ($possibleConfigs as $nginxConfig) {
                if (@file_exists($nginxConfig)) {
                    $content = @file_get_contents($nginxConfig);
                    
                    if ($content && preg_match('/server_name\s+([a-z0-9\.\-]+)/', $content, $matches)) {
                        // Return first domain (skip www, IP, and underscore)
                        $serverNames = preg_split('/\s+/', $matches[0]);
                        foreach ($serverNames as $name) {
                            if ($name !== 'server_name' && 
                                $name !== '_' && 
                                !preg_match('/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/', $name) &&
                                strpos($name, 'www.') !== 0) {
                                return rtrim($name, ';');
                            }
                        }
                        // If no clean domain found, return first non-underscore
                        if (isset($serverNames[1]) && $serverNames[1] !== '_') {
                            return rtrim($serverNames[1], ';');
                        }
                    }
                    break;
                }
            }
            
            return 'N/A';
        } catch (\Exception $e) {
            // Fallback if open_basedir restricts access
            return 'N/A';
        }
    }
    
    /**
     * Get PHP version
     */
    private function getPhpVersion($siteName)
    {
        try {
            $poolFile = "/etc/php/8.3/fpm/pool.d/{$siteName}.conf";
            
            if (@file_exists($poolFile)) {
                return '8.3';
            }
            
            return 'N/A';
        } catch (\Exception $e) {
            return 'N/A';
        }
    }
    
    /**
     * Check if SSL is enabled
     */
    private function isSSLEnabled($siteName)
    {
        try {
            // Try to find NGINX config file
            $configFile = $this->findNginxConfig($siteName);
            
            if (!$configFile || !@file_exists($configFile)) {
                return false;
            }
            
            $content = @file_get_contents($configFile);
            
            return ($content && strpos($content, 'ssl_certificate') !== false);
        } catch (\Exception $e) {
            return false;
        }
    }
    
    /**
     * Is site active
     */
    private function isSiteActive($siteName)
    {
        try {
            // Try common patterns
            $possibleSymlinks = [
                "/etc/nginx/sites-enabled/$siteName",
                "/etc/nginx/sites-enabled/$siteName.conf",
            ];
            
            // Also scan directory
            $sitesEnabledDir = '/etc/nginx/sites-enabled';
            if (@is_dir($sitesEnabledDir)) {
                $files = @scandir($sitesEnabledDir);
                if ($files) {
                    foreach ($files as $file) {
                        if (strpos($file, $siteName) === 0) {
                            return true;
                        }
                    }
                }
            }
            
            return false;
        } catch (\Exception $e) {
            return false;
        }
    }
    
    /**
     * Find NGINX config file for a site
     */
    private function findNginxConfig($siteName)
    {
        try {
            $sitesAvailableDir = '/etc/nginx/sites-available';
            
            // Try common patterns first
            $patterns = [
                "$sitesAvailableDir/$siteName",
                "$sitesAvailableDir/$siteName.conf",
            ];
            
            foreach ($patterns as $file) {
                if (@file_exists($file)) {
                    return $file;
                }
            }
            
            // Scan directory for matching files
            if (@is_dir($sitesAvailableDir)) {
                $files = @scandir($sitesAvailableDir);
                if ($files) {
                    foreach ($files as $file) {
                        if (strpos($file, $siteName) === 0 && strpos($file, '.conf') !== false) {
                            return "$sitesAvailableDir/$file";
                        }
                    }
                }
            }
            
            return null;
        } catch (\Exception $e) {
            return null;
        }
    }
    
    /**
     * Read log file
     */
    private function readLog($logFile, $lines = 100)
    {
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
     * Check SSL status
     */
    private function checkSSLStatus($siteName)
    {
        $site = $this->getSiteDetails($siteName);
        $domain = $site['domain'];
        
        $certPath = "/etc/letsencrypt/live/$domain/fullchain.pem";
        
        $status = [
            'enabled' => $site['ssl_enabled'],
            'certificate_exists' => file_exists($certPath),
            'expiry_date' => null,
            'days_until_expiry' => null
        ];
        
        if (file_exists($certPath)) {
            $certInfo = shell_exec("openssl x509 -enddate -noout -in $certPath 2>/dev/null");
            
            if ($certInfo && preg_match('/notAfter=(.+)/', $certInfo, $matches)) {
                $expiryDate = strtotime($matches[1]);
                $status['expiry_date'] = date('Y-m-d H:i:s', $expiryDate);
                $status['days_until_expiry'] = floor(($expiryDate - time()) / 86400);
            }
        }
        
        return $status;
    }
    
    /**
     * Parse credentials from script output
     */
    private function parseCredentials($output)
    {
        $credentials = [];
        
        // Parse FTP/SSH username
        if (preg_match('/Username:\s+(\S+)/', $output, $matches)) {
            $credentials['username'] = $matches[1];
        }
        
        // Parse password
        if (preg_match('/Password:\s+(\S+)/', $output, $matches)) {
            $credentials['password'] = $matches[1];
        }
        
        // Parse database
        if (preg_match('/Database:\s+(\S+)/', $output, $matches)) {
            $credentials['database'] = $matches[1];
        }
        
        // Parse DB user
        if (preg_match('/DB User:\s+(\S+)/', $output, $matches)) {
            $credentials['db_user'] = $matches[1];
        }
        
        // Parse DB password
        if (preg_match('/DB Password:\s+(\S+)/', $output, $matches)) {
            $credentials['db_password'] = $matches[1];
        }
        
        return $credentials;
    }
    
    /**
     * Parse credentials from CREDENTIALS.txt file
     */
    private function parseCredentialsFromFile($content)
    {
        $credentials = [];
        
        // Extract SSH username
        if (preg_match('/Username:\s*(.+)/m', $content, $matches)) {
            $credentials['ssh_username'] = trim($matches[1]);
        }
        
        // Extract SSH password
        if (preg_match('/Password:\s*(.+)/m', $content, $matches)) {
            $credentials['ssh_password'] = trim($matches[1]);
        }
        
        // Extract database name
        if (preg_match('/Database Name:\s*(.+)/m', $content, $matches)) {
            $credentials['database'] = trim($matches[1]);
        }
        
        // Extract database user
        if (preg_match('/Database User:\s*(.+)/m', $content, $matches)) {
            $credentials['db_user'] = trim($matches[1]);
        }
        
        // Extract database password
        if (preg_match('/Database Password:\s*(.+)/m', $content, $matches)) {
            $credentials['db_password'] = trim($matches[1]);
        }
        
        // Extract domain
        if (preg_match('/Primary Domain:\s*(.+)/m', $content, $matches)) {
            $credentials['domain'] = trim($matches[1]);
        }
        
        return $credentials;
    }
}
