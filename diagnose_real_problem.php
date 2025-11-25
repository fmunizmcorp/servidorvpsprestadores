<?php
/**
 * COMPREHENSIVE DIAGNOSTIC SCRIPT
 * 
 * Purpose: Identify why Sites and Email Domains creation is failing
 * Run from command line: php diagnose_real_problem.php
 */

echo "====================================================\n";
echo " DIAGNOSTIC SCRIPT - Identificar Problema Real\n";
echo "====================================================\n\n";

// Test 1: PHP Functions Availability
echo "TEST 1: Verificar funções PHP disponíveis\n";
echo "-------------------------------------------\n";

$disabled = explode(',', ini_get('disable_functions'));
$disabled = array_map('trim', $disabled);

$critical_functions = ['shell_exec', 'exec', 'system', 'passthru', 'proc_open'];

foreach ($critical_functions as $func) {
    $status = in_array($func, $disabled) ? '❌ DESABILITADO' : '✅ HABILITADO';
    echo sprintf("%-15s : %s\n", $func, $status);
    
    if ($status === '✅ HABILITADO' && $func === 'shell_exec') {
        // Test if it actually works
        $test_output = @shell_exec('echo "test"');
        if ($test_output !== null && trim($test_output) === 'test') {
            echo "              └─ ✅ FUNCIONA (testado com echo)\n";
        } else {
            echo "              └─ ❌ NÃO FUNCIONA (mesmo habilitado!)\n";
        }
    }
}

echo "\n";

// Test 2: Sudo Permissions
echo "TEST 2: Verificar permissões sudo\n";
echo "-----------------------------------\n";

$user = posix_getpwuid(posix_geteuid());
$username = $user['name'];

echo "Usuário PHP: $username\n";

// Try to run a simple sudo command
$sudo_test = @shell_exec('sudo -n whoami 2>&1');

if ($sudo_test !== null) {
    if (trim($sudo_test) === 'root') {
        echo "✅ Sudo SEM senha funciona (NOPASSWD configurado)\n";
    } else {
        echo "❌ Sudo requer senha ou não está configurado\n";
        echo "   Output: " . trim($sudo_test) . "\n";
    }
} else {
    echo "❌ Não foi possível testar sudo (shell_exec pode estar desabilitado)\n";
}

echo "\n";

// Test 3: Script Wrapper Existence
echo "TEST 3: Verificar existência de scripts\n";
echo "-----------------------------------------\n";

$wrapper = "/opt/webserver/scripts/wrappers/create-site-wrapper.sh";

if (file_exists($wrapper)) {
    echo "✅ Wrapper existe: $wrapper\n";
    
    if (is_executable($wrapper)) {
        echo "✅ Wrapper é executável\n";
    } else {
        echo "❌ Wrapper NÃO é executável\n";
        $perms = substr(sprintf('%o', fileperms($wrapper)), -4);
        echo "   Permissões: $perms\n";
    }
} else {
    echo "❌ Wrapper NÃO existe: $wrapper\n";
}

echo "\n";

// Test 4: Directory Permissions
echo "TEST 4: Verificar permissões de diretórios\n";
echo "--------------------------------------------\n";

$sites_dir = "/opt/webserver/sites";

if (is_dir($sites_dir)) {
    echo "✅ Diretório existe: $sites_dir\n";
    
    if (is_writable($sites_dir)) {
        echo "✅ Diretório é gravável por PHP\n";
    } else {
        echo "❌ Diretório NÃO é gravável por PHP\n";
        $perms = substr(sprintf('%o', fileperms($sites_dir)), -4);
        $owner = posix_getpwuid(fileowner($sites_dir));
        echo "   Permissões: $perms\n";
        echo "   Proprietário: " . $owner['name'] . "\n";
    }
} else {
    echo "❌ Diretório NÃO existe: $sites_dir\n";
}

echo "\n";

// Test 5: Laravel Log Files
echo "TEST 5: Verificar logs do Laravel\n";
echo "-----------------------------------\n";

$log_file = "/opt/webserver/admin-panel/storage/logs/laravel.log";

if (file_exists($log_file)) {
    echo "✅ Log file existe: $log_file\n";
    
    // Get last 20 lines
    $last_lines = @shell_exec("tail -20 '$log_file' 2>&1");
    
    if ($last_lines !== null) {
        echo "\nÚltimas linhas do log:\n";
        echo "----------------------\n";
        echo $last_lines;
    } else {
        echo "❌ Não foi possível ler o log (shell_exec desabilitado?)\n";
    }
} else {
    echo "❌ Log file NÃO existe: $log_file\n";
}

echo "\n";

// Test 6: Database Connection
echo "TEST 6: Verificar conexão com banco de dados\n";
echo "----------------------------------------------\n";

try {
    // Try to connect using Laravel's database configuration
    $env_file = "/opt/webserver/admin-panel/.env";
    
    if (file_exists($env_file)) {
        $env_content = file_get_contents($env_file);
        
        preg_match('/DB_HOST=(.*)/', $env_content, $host_match);
        preg_match('/DB_DATABASE=(.*)/', $env_content, $db_match);
        preg_match('/DB_USERNAME=(.*)/', $env_content, $user_match);
        preg_match('/DB_PASSWORD=(.*)/', $env_content, $pass_match);
        
        $db_host = $host_match[1] ?? 'localhost';
        $db_name = $db_match[1] ?? 'admin_panel';
        $db_user = $user_match[1] ?? 'root';
        $db_pass = $pass_match[1] ?? '';
        
        echo "Tentando conectar:\n";
        echo "  Host: $db_host\n";
        echo "  Database: $db_name\n";
        echo "  User: $db_user\n";
        
        $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
        echo "✅ Conexão com banco de dados OK\n";
        
        // Test sites table
        $stmt = $pdo->query("SELECT COUNT(*) FROM sites");
        $count = $stmt->fetchColumn();
        echo "✅ Tabela 'sites' existe ($count registros)\n";
        
        // Test email_domains table
        $stmt = $pdo->query("SELECT COUNT(*) FROM email_domains");
        $count = $stmt->fetchColumn();
        echo "✅ Tabela 'email_domains' existe ($count registros)\n";
        
    } else {
        echo "❌ Arquivo .env não encontrado\n";
    }
    
} catch (\Exception $e) {
    echo "❌ Erro ao conectar com banco: " . $e->getMessage() . "\n";
}

echo "\n";

// Test 7: PHP Configuration
echo "TEST 7: Configuração PHP\n";
echo "-------------------------\n";

echo "PHP Version: " . phpversion() . "\n";
echo "Max Execution Time: " . ini_get('max_execution_time') . "s\n";
echo "Memory Limit: " . ini_get('memory_limit') . "\n";
echo "Upload Max Size: " . ini_get('upload_max_filesize') . "\n";
echo "Post Max Size: " . ini_get('post_max_size') . "\n";

echo "\n";

// Summary and Recommendations
echo "====================================================\n";
echo " RESUMO E RECOMENDAÇÕES\n";
echo "====================================================\n\n";

$issues = [];

// Check for critical issues
if (in_array('shell_exec', $disabled)) {
    $issues[] = "❌ CRÍTICO: shell_exec está desabilitado. Controller não pode executar scripts.";
}

if (!file_exists($wrapper)) {
    $issues[] = "❌ CRÍTICO: Script wrapper não existe. Sites não podem ser criados.";
}

if ($sudo_test === null || trim($sudo_test) !== 'root') {
    $issues[] = "⚠️  AVISO: Sudo pode não estar configurado corretamente.";
}

if (!empty($issues)) {
    echo "PROBLEMAS IDENTIFICADOS:\n";
    echo "------------------------\n";
    foreach ($issues as $issue) {
        echo "$issue\n";
    }
    echo "\n";
} else {
    echo "✅ Nenhum problema óbvio identificado.\n";
    echo "   O problema pode ser mais sutil (lógica do controller, timing, etc.)\n\n";
}

// Recommendations
echo "RECOMENDAÇÕES:\n";
echo "--------------\n";

if (in_array('shell_exec', $disabled)) {
    echo "1. Habilitar shell_exec no php.ini\n";
    echo "   - Editar: /etc/php/8.3/fpm/php.ini\n";
    echo "   - Remover 'shell_exec' de disable_functions\n";
    echo "   - Reiniciar PHP-FPM: sudo systemctl restart php8.3-fpm\n\n";
    
    echo "2. OU usar função alternativa (exec, proc_open)\n\n";
}

if (!file_exists($wrapper)) {
    echo "1. Verificar se scripts estão instalados em /opt/webserver/scripts/\n";
    echo "2. Executar script de instalação se necessário\n\n";
}

if ($sudo_test !== 'root') {
    echo "1. Configurar sudo NOPASSWD para usuário www-data\n";
    echo "   - Adicionar em /etc/sudoers.d/webserver:\n";
    echo "   www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/\n\n";
}

echo "====================================================\n";
echo " FIM DO DIAGNÓSTICO\n";
echo "====================================================\n";
