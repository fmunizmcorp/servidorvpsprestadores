<?php
/**
 * EMERGENCY DEPLOY - SPRINT 24
 * 
 * Este script PHP pode ser colocado em qualquer lugar acessível via web no VPS
 * e executado diretamente via browser ou cURL para fazer o deploy.
 * 
 * UPLOAD: Coloque este arquivo em /opt/webserver/sites/deploy.php
 * ACESSO: http://72.61.53.222/deploy.php?action=execute&secret=emergency24deploy
 * 
 * AÇÕES:
 * 1. Aplica sudo fixes no EmailController.php
 * 2. Configura sudoers para www-data
 * 3. Limpa cache Laravel
 * 4. Retorna resultado em JSON
 */

// Security check
if (!isset($_GET['secret']) || $_GET['secret'] !== 'emergency24deploy') {
    http_response_code(403);
    die(json_encode(['error' => 'Unauthorized']));
}

// Configuration
$emailControllerPath = '/opt/webserver/admin-panel/app/Http/Controllers/EmailController.php';
$sudoersPath = '/etc/sudoers.d/webserver-scripts';
$laravelPath = '/opt/webserver/admin-panel';

// Response array
$response = [
    'success' => false,
    'steps' => [],
    'errors' => [],
    'timestamp' => date('Y-m-d H:i:s')
];

try {
    // Action parameter
    $action = $_GET['action'] ?? 'status';
    
    if ($action === 'status') {
        // Check current status
        $response['status'] = [
            'emailcontroller_exists' => file_exists($emailControllerPath),
            'emailcontroller_has_sudo' => false,
            'sudoers_exists' => file_exists($sudoersPath),
            'laravel_path_exists' => file_exists($laravelPath)
        ];
        
        if (file_exists($emailControllerPath)) {
            $content = file_get_contents($emailControllerPath);
            $response['status']['emailcontroller_has_sudo'] = strpos($content, 'sudo bash') !== false;
        }
        
        $response['success'] = true;
        
    } elseif ($action === 'execute') {
        // STEP 1: Backup
        $backupDir = '/opt/webserver/backups/sprint24_' . date('Y-m-d_H-i-s');
        exec("sudo mkdir -p " . escapeshellarg($backupDir), $output1, $ret1);
        
        if ($ret1 === 0) {
            exec("sudo cp " . escapeshellarg($emailControllerPath) . " " . escapeshellarg($backupDir . "/EmailController.php.backup"), $output2, $ret2);
            $response['steps'][] = [
                'step' => 'backup',
                'status' => $ret2 === 0 ? 'success' : 'warning',
                'message' => "Backup created at $backupDir"
            ];
        }
        
        // STEP 2: Fix EmailController.php - Add sudo to bash commands
        if (file_exists($emailControllerPath)) {
            $content = file_get_contents($emailControllerPath);
            $originalContent = $content;
            
            // Check if already fixed
            if (strpos($content, 'sudo bash') !== false) {
                $response['steps'][] = [
                    'step' => 'fix_emailcontroller',
                    'status' => 'already_fixed',
                    'message' => 'EmailController.php already contains sudo fixes'
                ];
            } else {
                // Apply fixes - Pattern 1: storeDomain method (line ~60)
                $content = preg_replace(
                    '/\$command\s*=\s*"bash\s+\$script/i',
                    '$command = "sudo bash $script',
                    $content,
                    -1,
                    $count1
                );
                
                // Apply fixes - Pattern 2: storeAccount method (line ~135)
                $content = preg_replace(
                    '/\$command\s*=\s*"bash\s+\$script\s+"\s*\.\s*escapeshellarg/i',
                    '$command = "sudo bash $script " . escapeshellarg',
                    $content,
                    -1,
                    $count2
                );
                
                if ($count1 > 0 || $count2 > 0) {
                    // Write to temp file
                    $tempFile = '/tmp/EmailController_sprint24.php';
                    file_put_contents($tempFile, $content);
                    
                    // Copy with sudo
                    exec("sudo cp " . escapeshellarg($tempFile) . " " . escapeshellarg($emailControllerPath), $output3, $ret3);
                    exec("sudo chown www-data:www-data " . escapeshellarg($emailControllerPath), $output4, $ret4);
                    exec("sudo chmod 644 " . escapeshellarg($emailControllerPath), $output5, $ret5);
                    
                    unlink($tempFile);
                    
                    $response['steps'][] = [
                        'step' => 'fix_emailcontroller',
                        'status' => $ret3 === 0 ? 'success' : 'error',
                        'message' => "Applied sudo fixes (storeDomain: $count1, storeAccount: $count2)",
                        'replacements' => ['storeDomain' => $count1, 'storeAccount' => $count2]
                    ];
                } else {
                    $response['errors'][] = 'Could not find patterns to replace in EmailController.php';
                }
            }
        } else {
            $response['errors'][] = 'EmailController.php not found at ' . $emailControllerPath;
        }
        
        // STEP 3: Configure sudoers
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
        
        $tempSudoers = '/tmp/webserver-scripts-sprint24';
        file_put_contents($tempSudoers, $sudoersContent);
        
        exec("sudo cp " . escapeshellarg($tempSudoers) . " " . escapeshellarg($sudoersPath), $output6, $ret6);
        exec("sudo chmod 440 " . escapeshellarg($sudoersPath), $output7, $ret7);
        
        unlink($tempSudoers);
        
        $response['steps'][] = [
            'step' => 'configure_sudoers',
            'status' => ($ret6 === 0 && $ret7 === 0) ? 'success' : 'error',
            'message' => 'Sudoers configured for www-data'
        ];
        
        // STEP 4: Clear Laravel cache
        $cacheCommands = [
            "cd $laravelPath && php artisan config:clear 2>&1",
            "cd $laravelPath && php artisan cache:clear 2>&1",
            "cd $laravelPath && php artisan route:clear 2>&1",
            "cd $laravelPath && php artisan view:clear 2>&1"
        ];
        
        $cacheResults = [];
        foreach ($cacheCommands as $cmd) {
            exec($cmd, $output, $ret);
            $cacheResults[] = $ret === 0 ? 'success' : 'warning';
        }
        
        $response['steps'][] = [
            'step' => 'clear_cache',
            'status' => 'success',
            'message' => 'Laravel cache cleared',
            'results' => $cacheResults
        ];
        
        // STEP 5: Verification
        $finalContent = file_get_contents($emailControllerPath);
        $checks = [
            'emailcontroller_has_sudo' => strpos($finalContent, 'sudo bash') !== false,
            'sudoers_exists' => file_exists($sudoersPath),
            'sudoers_readable' => is_readable($sudoersPath)
        ];
        
        $response['steps'][] = [
            'step' => 'verification',
            'status' => $checks['emailcontroller_has_sudo'] && $checks['sudoers_exists'] ? 'success' : 'warning',
            'checks' => $checks
        ];
        
        $response['success'] = $checks['emailcontroller_has_sudo'] && $checks['sudoers_exists'];
        $response['message'] = $response['success'] ? 'Deploy executed successfully!' : 'Deploy completed with warnings';
    }
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['errors'][] = $e->getMessage();
}

// Return JSON
header('Content-Type: application/json');
echo json_encode($response, JSON_PRETTY_PRINT);
