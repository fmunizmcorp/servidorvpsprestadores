<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Diagnóstico - Prestadores Clinfec</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .card {
            background: white;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #34495e;
            margin-top: 0;
        }
        .info {
            background: #ecf0f1;
            padding: 15px;
            border-left: 4px solid #3498db;
            margin: 10px 0;
        }
        .success {
            background: #d4edda;
            border-left-color: #28a745;
            color: #155724;
        }
        .warning {
            background: #fff3cd;
            border-left-color: #ffc107;
            color: #856404;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #3498db;
            color: white;
        }
        .code {
            background: #2c3e50;
            color: #ecf0f1;
            padding: 15px;
            border-radius: 4px;
            overflow-x: auto;
            font-family: 'Courier New', monospace;
        }
    </style>
</head>
<body>
    <h1>🔍 Diagnóstico do Sistema - Prestadores Clinfec</h1>
    
    <div class="card">
        <h2>✅ Informações da Requisição</h2>
        <table>
            <tr>
                <th>Variável</th>
                <th>Valor</th>
            </tr>
            <tr>
                <td><strong>HTTP_HOST</strong></td>
                <td><?php echo htmlspecialchars($_SERVER['HTTP_HOST'] ?? 'N/A'); ?></td>
            </tr>
            <tr>
                <td><strong>SERVER_NAME</strong></td>
                <td><?php echo htmlspecialchars($_SERVER['SERVER_NAME'] ?? 'N/A'); ?></td>
            </tr>
            <tr>
                <td><strong>REQUEST_URI</strong></td>
                <td><?php echo htmlspecialchars($_SERVER['REQUEST_URI'] ?? 'N/A'); ?></td>
            </tr>
            <tr>
                <td><strong>SCRIPT_NAME</strong></td>
                <td><?php echo htmlspecialchars($_SERVER['SCRIPT_NAME'] ?? 'N/A'); ?></td>
            </tr>
            <tr>
                <td><strong>PHP_SELF</strong></td>
                <td><?php echo htmlspecialchars($_SERVER['PHP_SELF'] ?? 'N/A'); ?></td>
            </tr>
            <tr>
                <td><strong>HTTPS</strong></td>
                <td><?php echo (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? '✅ Sim' : '❌ Não'; ?></td>
            </tr>
            <tr>
                <td><strong>SERVER_PORT</strong></td>
                <td><?php echo htmlspecialchars($_SERVER['SERVER_PORT'] ?? 'N/A'); ?></td>
            </tr>
            <tr>
                <td><strong>REMOTE_ADDR</strong></td>
                <td><?php echo htmlspecialchars($_SERVER['REMOTE_ADDR'] ?? 'N/A'); ?></td>
            </tr>
            <tr>
                <td><strong>HTTP_REFERER</strong></td>
                <td><?php echo htmlspecialchars($_SERVER['HTTP_REFERER'] ?? 'N/A'); ?></td>
            </tr>
            <tr>
                <td><strong>HTTP_USER_AGENT</strong></td>
                <td><?php echo htmlspecialchars($_SERVER['HTTP_USER_AGENT'] ?? 'N/A'); ?></td>
            </tr>
        </table>
    </div>

    <div class="card">
        <h2>🌐 Detecção de Acesso</h2>
        <?php
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || $_SERVER['SERVER_PORT'] == 443 ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'] ?? 'prestadores.clinfec.com.br';
        $hostWithoutPort = preg_replace('/:\d+$/', '', $host);
        
        $is_ip = preg_match('/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/', $hostWithoutPort);
        $path_prefix = $is_ip ? '/prestadores' : '';
        $base_url = $protocol . '://' . $host . $path_prefix;
        ?>
        
        <div class="info <?php echo $is_ip ? 'warning' : 'success'; ?>">
            <strong>Tipo de Acesso:</strong> <?php echo $is_ip ? '⚠️ Via IP' : '✅ Via Domínio'; ?><br>
            <strong>Host Detectado:</strong> <?php echo htmlspecialchars($hostWithoutPort); ?><br>
            <strong>Prefixo de Path:</strong> <?php echo $path_prefix ?: '(nenhum)'; ?><br>
            <strong>BASE_URL Gerada:</strong> <?php echo htmlspecialchars($base_url); ?>
        </div>
    </div>

    <div class="card">
        <h2>📁 Verificação de Arquivos</h2>
        <?php
        $root_path = dirname(__DIR__);
        $public_path = __DIR__;
        
        $checks = [
            'Diretório Raiz' => $root_path,
            'Diretório Public' => $public_path,
            'index.php' => $public_path . '/index.php',
            'Config' => $root_path . '/config/config.php',
            'Database Config' => $root_path . '/config/database.php',
        ];
        ?>
        <table>
            <tr>
                <th>Item</th>
                <th>Caminho</th>
                <th>Status</th>
            </tr>
            <?php foreach ($checks as $name => $path): ?>
            <tr>
                <td><?php echo htmlspecialchars($name); ?></td>
                <td style="font-family: monospace; font-size: 12px;"><?php echo htmlspecialchars($path); ?></td>
                <td><?php echo file_exists($path) ? '✅ Existe' : '❌ Não encontrado'; ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>

    <div class="card">
        <h2>🔗 URLs Corretas para Acesso</h2>
        <div class="info success">
            <strong>Via Domínio (RECOMENDADO):</strong><br>
            <div class="code">
                https://prestadores.clinfec.com.br/
            </div>
        </div>
        <div class="info warning">
            <strong>Via IP (Alternativo):</strong><br>
            <div class="code">
                https://72.61.53.222/prestadores/
            </div>
        </div>
    </div>

    <div class="card">
        <h2>🛠️ Ações Recomendadas</h2>
        <div class="info">
            <p><strong>Se você está vendo esta página via IP mas queria acessar pelo domínio:</strong></p>
            <ol>
                <li>Limpe o cache do seu navegador (Ctrl+Shift+Delete)</li>
                <li>Feche todas as abas do navegador</li>
                <li>Abra uma nova aba anônima/privada</li>
                <li>Acesse: <strong>https://prestadores.clinfec.com.br/</strong></li>
            </ol>
            
            <p><strong>Se o problema persistir:</strong></p>
            <ul>
                <li>Verifique se o DNS está correto: <code>nslookup prestadores.clinfec.com.br</code></li>
                <li>Deve retornar: <code>72.61.53.222</code></li>
                <li>Aguarde alguns minutos para propagação DNS (se recém alterou)</li>
            </ul>
        </div>
    </div>

    <div class="card">
        <h2>📞 Informações de Suporte</h2>
        <div class="code">
Data/Hora: <?php echo date('Y-m-d H:i:s'); ?>

Servidor: <?php echo php_uname(); ?>

PHP Version: <?php echo PHP_VERSION; ?>

Loaded Extensions: <?php echo implode(', ', get_loaded_extensions()); ?>
        </div>
    </div>

    <div style="text-align: center; margin-top: 30px; color: #7f8c8d;">
        <p>Diagnóstico gerado automaticamente | Sistema Prestadores Clinfec</p>
    </div>
</body>
</html>
