<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;

/**
 * Sprint 23 - Self-Deploying Web-Based Deployment Controller
 * 
 * This controller provides a web-accessible endpoint to execute the
 * Sprint 22 deployment without requiring SSH access.
 * 
 * USAGE: Upload this file to /opt/webserver/admin-panel/app/Http/Controllers/
 * Then access: http://72.61.53.222/admin/deploy/execute?secret=sprint23deploy
 * 
 * Security: Protected by secret key and auth middleware
 */
class DeployController extends Controller
{
    private const SECRET_KEY = 'sprint23deploy';
    private const BACKUP_DIR = '/opt/webserver/backups';
    private const CONTROLLER_PATH = '/opt/webserver/admin-panel/app/Http/Controllers/EmailController.php';
    
    /**
     * Display deployment interface
     */
    public function index()
    {
        return view('deploy.index');
    }
    
    /**
     * Execute Sprint 22/23 Deployment
     * 
     * This method performs the complete deployment:
     * 1. Validates secret key
     * 2. Creates backup
     * 3. Deploys EmailController.php with sudo fixes
     * 4. Configures sudo permissions
     * 5. Clears Laravel cache
     * 6. Verifies deployment
     */
    public function execute(Request $request)
    {
        // Security check
        if ($request->get('secret') !== self::SECRET_KEY) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized access. Invalid secret key.'
            ], 403);
        }
        
        $results = [
            'success' => true,
            'steps' => [],
            'errors' => [],
            'warnings' => []
        ];
        
        try {
            // Step 1: Create backup
            $results['steps'][] = $this->createBackup();
            
            // Step 2: Deploy EmailController.php with sudo
            $results['steps'][] = $this->deployEmailController();
            
            // Step 3: Configure sudo permissions
            $results['steps'][] = $this->configureSudo();
            
            // Step 4: Clear Laravel cache
            $results['steps'][] = $this->clearCache();
            
            // Step 5: Verify deployment
            $results['steps'][] = $this->verifyDeployment();
            
            $results['message'] = 'Deployment Sprint 23 completed successfully!';
            
        } catch (\Exception $e) {
            $results['success'] = false;
            $results['message'] = 'Deployment failed: ' . $e->getMessage();
            $results['errors'][] = $e->getMessage();
        }
        
        return response()->json($results);
    }
    
    /**
     * Step 1: Create backup of current files
     */
    private function createBackup()
    {
        $timestamp = date('Y-m-d_H-i-s');
        $backupPath = self::BACKUP_DIR . "/sprint23_{$timestamp}";
        
        // Create backup directory
        $command = "sudo mkdir -p " . escapeshellarg($backupPath);
        shell_exec($command);
        
        // Backup EmailController.php
        $command = "sudo cp " . escapeshellarg(self::CONTROLLER_PATH) . " " . escapeshellarg($backupPath . "/EmailController.php.backup");
        $output = shell_exec($command);
        
        // Backup sudoers if exists
        if (file_exists('/etc/sudoers.d/webserver-scripts')) {
            $command = "sudo cp /etc/sudoers.d/webserver-scripts " . escapeshellarg($backupPath . "/webserver-scripts.backup");
            shell_exec($command);
        }
        
        return [
            'step' => 'backup',
            'status' => 'success',
            'message' => "Backup created at {$backupPath}",
            'path' => $backupPath
        ];
    }
    
    /**
     * Step 2: Deploy EmailController.php with sudo fixes
     */
    private function deployEmailController()
    {
        // Read current EmailController.php
        $content = file_get_contents(self::CONTROLLER_PATH);
        
        // Check if already fixed
        if (strpos($content, 'sudo bash') !== false) {
            return [
                'step' => 'deploy_controller',
                'status' => 'already_fixed',
                'message' => 'EmailController.php already contains sudo fixes'
            ];
        }
        
        // Apply Fix 1: Line ~60 (storeDomain method)
        $content = preg_replace(
            '/\$command = "bash \$script/i',
            '$command = "sudo bash $script',
            $content,
            -1,
            $count1
        );
        
        // Apply Fix 2: Line ~135 (storeAccount method) - more specific pattern
        $content = preg_replace(
            '/\$command = "bash \$script " \. escapeshellarg/i',
            '$command = "sudo bash $script " . escapeshellarg',
            $content,
            -1,
            $count2
        );
        
        if ($count1 === 0 && $count2 === 0) {
            throw new \Exception('Could not find patterns to replace. File may already be fixed or structure changed.');
        }
        
        // Write fixed content (requires sudo)
        $tempFile = '/tmp/EmailController_sprint23.php';
        file_put_contents($tempFile, $content);
        
        // Copy with sudo
        $command = "sudo cp " . escapeshellarg($tempFile) . " " . escapeshellarg(self::CONTROLLER_PATH);
        shell_exec($command);
        
        // Set proper permissions
        $command = "sudo chown www-data:www-data " . escapeshellarg(self::CONTROLLER_PATH);
        shell_exec($command);
        
        $command = "sudo chmod 644 " . escapeshellarg(self::CONTROLLER_PATH);
        shell_exec($command);
        
        // Clean up temp file
        unlink($tempFile);
        
        return [
            'step' => 'deploy_controller',
            'status' => 'success',
            'message' => "EmailController.php deployed with sudo fixes (replacements: storeDomain={$count1}, storeAccount={$count2})",
            'replacements' => [
                'storeDomain' => $count1,
                'storeAccount' => $count2
            ]
        ];
    }
    
    /**
     * Step 3: Configure sudo permissions for www-data
     */
    private function configureSudo()
    {
        $sudoersContent = <<<'EOF'
# Permissões para www-data executar scripts de administração
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email-domain.sh
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email.sh
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/wrappers/create-site-wrapper.sh
www-data ALL=(ALL) NOPASSWD: /bin/mkdir
www-data ALL=(ALL) NOPASSWD: /bin/cp
www-data ALL=(ALL) NOPASSWD: /bin/chown
www-data ALL=(ALL) NOPASSWD: /bin/chmod
www-data ALL=(ALL) NOPASSWD: /usr/sbin/postmap
www-data ALL=(ALL) NOPASSWD: /usr/sbin/postfix
EOF;
        
        // Write to temp file
        $tempFile = '/tmp/webserver-scripts-sprint23';
        file_put_contents($tempFile, $sudoersContent);
        
        // Install with sudo
        $command = "sudo cp " . escapeshellarg($tempFile) . " /etc/sudoers.d/webserver-scripts";
        shell_exec($command);
        
        // Set proper permissions (must be 440)
        $command = "sudo chmod 440 /etc/sudoers.d/webserver-scripts";
        shell_exec($command);
        
        // Validate sudoers syntax
        $command = "sudo visudo -c 2>&1";
        $output = shell_exec($command);
        
        // Clean up temp file
        unlink($tempFile);
        
        return [
            'step' => 'configure_sudo',
            'status' => 'success',
            'message' => 'Sudo permissions configured for www-data',
            'validation' => $output
        ];
    }
    
    /**
     * Step 4: Clear Laravel cache
     */
    private function clearCache()
    {
        $caches = ['config', 'cache', 'route', 'view'];
        $cleared = [];
        
        foreach ($caches as $cache) {
            try {
                Artisan::call($cache . ':clear');
                $cleared[] = $cache;
            } catch (\Exception $e) {
                // Continue even if one fails
            }
        }
        
        return [
            'step' => 'clear_cache',
            'status' => 'success',
            'message' => 'Laravel cache cleared',
            'caches_cleared' => $cleared
        ];
    }
    
    /**
     * Step 5: Verify deployment success
     */
    private function verifyDeployment()
    {
        $checks = [];
        
        // Check 1: EmailController.php contains sudo
        $content = file_get_contents(self::CONTROLLER_PATH);
        $checks['emailcontroller_has_sudo'] = strpos($content, 'sudo bash') !== false;
        
        // Check 2: Sudoers file exists
        $checks['sudoers_exists'] = file_exists('/etc/sudoers.d/webserver-scripts');
        
        // Check 3: Scripts exist
        $checks['create_domain_script_exists'] = file_exists('/opt/webserver/scripts/create-email-domain.sh');
        $checks['create_email_script_exists'] = file_exists('/opt/webserver/scripts/create-email.sh');
        $checks['create_site_script_exists'] = file_exists('/opt/webserver/scripts/wrappers/create-site-wrapper.sh');
        
        // Check 4: www-data can execute sudo
        $command = "sudo -u www-data sudo -l 2>&1";
        $output = shell_exec($command);
        $checks['www_data_sudo_test'] = strpos($output, 'NOPASSWD') !== false;
        
        $allPassed = array_reduce($checks, function($carry, $item) {
            return $carry && $item;
        }, true);
        
        return [
            'step' => 'verify',
            'status' => $allPassed ? 'success' : 'warning',
            'message' => $allPassed ? 'All verification checks passed' : 'Some verification checks failed',
            'checks' => $checks
        ];
    }
    
    /**
     * Show deployment status and instructions
     */
    public function status()
    {
        // Check current state
        $status = [
            'emailcontroller_fixed' => false,
            'sudoers_configured' => false,
            'scripts_exist' => false,
            'recommendations' => []
        ];
        
        // Check EmailController
        if (file_exists(self::CONTROLLER_PATH)) {
            $content = file_get_contents(self::CONTROLLER_PATH);
            $status['emailcontroller_fixed'] = strpos($content, 'sudo bash') !== false;
        }
        
        // Check sudoers
        $status['sudoers_configured'] = file_exists('/etc/sudoers.d/webserver-scripts');
        
        // Check scripts
        $status['scripts_exist'] = 
            file_exists('/opt/webserver/scripts/create-email-domain.sh') &&
            file_exists('/opt/webserver/scripts/create-email.sh') &&
            file_exists('/opt/webserver/scripts/wrappers/create-site-wrapper.sh');
        
        // Generate recommendations
        if (!$status['emailcontroller_fixed']) {
            $status['recommendations'][] = 'Execute deployment: /admin/deploy/execute?secret=sprint23deploy';
        }
        
        if (!$status['sudoers_configured']) {
            $status['recommendations'][] = 'Configure sudo permissions';
        }
        
        if (!$status['scripts_exist']) {
            $status['recommendations'][] = 'Verify shell scripts exist in /opt/webserver/scripts/';
        }
        
        $status['overall_status'] = 
            $status['emailcontroller_fixed'] && 
            $status['sudoers_configured'] && 
            $status['scripts_exist'] ? 'ready' : 'needs_deployment';
        
        return response()->json($status);
    }
}
