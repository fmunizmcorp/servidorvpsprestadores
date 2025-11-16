<?php
/**
 * Clinfec Prestadores - Front Controller
 * Sprint 64 - URL HÍBRIDA: Suporta acesso via domínio OU via IP/prestadores
 */

// ==================== CONFIGURAÇÕES INICIAIS ====================

session_start();
date_default_timezone_set('America/Sao_Paulo');

error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);

// ==================== DEFINIR CAMINHOS ====================

define('ROOT_PATH', dirname(__DIR__));
define('PUBLIC_PATH', __DIR__);
define('SRC_PATH', ROOT_PATH . '/src');
define('CONFIG_PATH', ROOT_PATH . '/config');
define('VENDOR_PATH', ROOT_PATH . '/vendor');

// ==================== DEFINIR BASE_URL (HÍBRIDO) ====================

// Detectar protocolo (HTTP ou HTTPS)
$protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || $_SERVER['SERVER_PORT'] == 443 ? 'https' : 'http';

// Detectar como o usuário acessou o site
$host = $_SERVER['HTTP_HOST'] ?? 'prestadores.clinfec.com.br';

// Remover porta se presente (ex: 72.61.53.222:443 -> 72.61.53.222)
$hostWithoutPort = preg_replace('/:\d+$/', '', $host);

// Verificar se foi acessado via IP
$path_prefix = '';
if (preg_match('/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/', $hostWithoutPort)) {
    // Acessado via IP - adicionar prefixo /prestadores
    $path_prefix = '/prestadores';
}

// Base URL completa com prefixo condicional
define('BASE_URL', $protocol . '://' . $host . $path_prefix);

// Log para debug (opcional - pode comentar em produção)
error_log("[PRESTADORES] Access Method: " . ($path_prefix ? "IP-based" : "Domain-based"));
error_log("[PRESTADORES] HTTP_HOST: " . $host);
error_log("[PRESTADORES] BASE_URL: " . BASE_URL);

// ==================== CSRF TOKEN ====================

if (!isset($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// ==================== AUTOLOADER PSR-4 ====================

spl_autoload_register(function($class) {
    // Remove namespace base 'App\\'
    $class = str_replace('App\\', '', $class);
    
    // Converter namespace para caminho (mantém PascalCase)
    $file = SRC_PATH . '/' . str_replace('\\', '/', $class) . '.php';
    
    // Carregar arquivo se existir
    if (file_exists($file)) {
        require_once $file;
        return true;
    }
    
    return false;
});

// ==================== CARREGAR CONFIGURAÇÕES ====================

if (!file_exists(CONFIG_PATH . '/config.php')) {
    die('ERRO: Arquivo config/config.php não encontrado!');
}

if (!file_exists(CONFIG_PATH . '/database.php')) {
    die('ERRO: Arquivo config/database.php não encontrado!');
}

$config = require CONFIG_PATH . '/config.php';
$dbConfig = require CONFIG_PATH . '/database.php';

// ==================== VERIFICAR SE SISTEMA ESTÁ INSTALADO ====================

try {
    $dsn = "mysql:host={$dbConfig['host']};dbname={$dbConfig['database']};charset=utf8mb4";
    $testPdo = new PDO($dsn, $dbConfig['username'], $dbConfig['password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);
    
    // Verificar se tabela database_version existe
    $stmt = $testPdo->query("SHOW TABLES LIKE 'database_version'");
    if ($stmt->rowCount() == 0) {
        // Sistema não instalado - redirecionar para instalação
        if (basename($_SERVER['PHP_SELF']) !== 'install.php') {
            header('Location: /install.php');
            exit;
        }
    }
} catch (PDOException $e) {
    die('ERRO: Não foi possível conectar ao banco de dados.');
}

// ==================== CARREGAR DATABASE ====================

require_once SRC_PATH . '/Database.php';

// ==================== OBTER PARÂMETROS ====================

$page = $_GET['page'] ?? 'dashboard';
$action = $_GET['action'] ?? 'index';
$id = $_GET['id'] ?? null;

// ==================== ROTEAMENTO ====================

// Mapeamento de páginas para controllers
$routes = [
    'dashboard' => 'DashboardController',
    'auth' => 'AuthController',
    'login' => 'AuthController@showLoginForm',
    'logout' => 'AuthController@logout',
    'empresas-tomadoras' => 'EmpresaTomadoraController',
    'empresas-prestadoras' => 'EmpresaPrestadoraController',
    'servicos' => 'ServicoController',
    'contratos' => 'ContratoController',
    'projetos' => 'ProjetoController',
    'atividades' => 'AtividadeController',
    'financeiro' => 'FinanceiroController',
    'notas-fiscais' => 'NotaFiscalController',
    'documentos' => 'DocumentoController',
    'usuarios' => 'UsuarioController',
    'relatorios' => 'RelatorioController',
];

// Processar rotas especiais (controller@method)
if (isset($routes[$page]) && strpos($routes[$page], '@') !== false) {
    list($controllerName, $methodName) = explode('@', $routes[$page]);
    $controllerName = 'App\\Controllers\\' . $controllerName;
    $action = $methodName;
} else {
    // Buscar controller padrão
    if (!isset($routes[$page])) {
        $page = 'dashboard';
    }
    
    $controllerName = 'App\\Controllers\\' . $routes[$page];
}

// Verificar se controller existe
if (!class_exists($controllerName)) {
    die("ERRO: Controller $controllerName não encontrado!");
}

// Instanciar e chamar ação
$controller = new $controllerName();

if (!method_exists($controller, $action)) {
    die("ERRO: Ação $action não encontrada em $controllerName!");
}

// Executar ação
$controller->$action($id);
