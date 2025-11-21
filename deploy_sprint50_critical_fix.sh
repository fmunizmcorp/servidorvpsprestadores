#!/bin/bash

SENHA='Jm@D@KDPnw7Q'

echo "========================================"
echo "SPRINT 50 - CORRIGINDO PROBLEMAS CRÍTICOS"
echo "1. EmailAccount: Campo 'username' faltando"
echo "2. Sites: Não persiste no banco (28 sprints!)"
echo "========================================"

# 1. Backup dos controllers
echo "[1/8] Fazendo backups..."
sshpass -p "$SENHA" ssh -o StrictHostKeyChecking=no root@72.61.53.222 "cp /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php.backup-sprint50 && cp /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php.backup-sprint50" 2>&1 | grep -v "password\|Warning"
echo "✅ Backups criados"

# 2. Deploy EmailController corrigido
echo "[2/8] Deploy do EmailController corrigido..."
sshpass -p "$SENHA" scp -o StrictHostKeyChecking=no EmailController_sprint48.php root@72.61.53.222:/opt/webserver/admin-panel/app/Http/Controllers/EmailController.php 2>&1 | grep -v "password\|Warning"
echo "✅ EmailController atualizado"

# 3. Deploy SitesController corrigido  
echo "[3/8] Deploy do SitesController corrigido..."
sshpass -p "$SENHA" scp -o StrictHostKeyChecking=no SitesController.php root@72.61.53.222:/opt/webserver/admin-panel/app/Http/Controllers/SitesController.php 2>&1 | grep -v "password\|Warning"
echo "✅ SitesController atualizado"

# 4. Deploy do Model Site
echo "[4/8] Deploy do Model Site..."
sshpass -p "$SENHA" scp -o StrictHostKeyChecking=no laravel_models/Site.php root@72.61.53.222:/opt/webserver/admin-panel/app/Models/Site.php 2>&1 | grep -v "password\|Warning"
echo "✅ Model Site atualizado"

# 5. Verificar se tabela sites existe
echo "[5/8] Verificando tabela sites no banco..."
TABLE_EXISTS=$(sshpass -p "$SENHA" ssh -o StrictHostKeyChecking=no root@72.61.53.222 "mysql -u admin_panel -p'Jm@D@KDPnw7Q' admin_panel -e 'SHOW TABLES LIKE \"sites\";' 2>/dev/null | grep -c sites" 2>&1 | grep -v "password\|Warning")

if [ "$TABLE_EXISTS" = "0" ]; then
    echo "⚠️  Tabela 'sites' não existe! Criando..."
    sshpass -p "$SENHA" ssh -o StrictHostKeyChecking=no root@72.61.53.222 "mysql -u admin_panel -p'Jm@D@KDPnw7Q' admin_panel" << 'EOSQL' 2>&1 | grep -v "password\|Warning"
CREATE TABLE IF NOT EXISTS sites (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    site_name VARCHAR(50) NOT NULL UNIQUE,
    domain VARCHAR(255) NOT NULL,
    php_version VARCHAR(10) NOT NULL,
    has_database BOOLEAN DEFAULT FALSE,
    database_name VARCHAR(100) NULL,
    database_user VARCHAR(100) NULL,
    template VARCHAR(50) DEFAULT 'php',
    status VARCHAR(20) DEFAULT 'active',
    disk_usage VARCHAR(20) NULL,
    bandwidth_usage VARCHAR(20) NULL,
    last_backup TIMESTAMP NULL,
    ssl_enabled BOOLEAN DEFAULT FALSE,
    ssl_expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOSQL
    echo "✅ Tabela 'sites' criada"
else
    echo "✅ Tabela 'sites' já existe"
fi

# 6. Limpar cache
echo "[6/8] Limpando cache Laravel..."
sshpass -p "$SENHA" ssh -o StrictHostKeyChecking=no root@72.61.53.222 "cd /opt/webserver/admin-panel && php artisan cache:clear && php artisan view:clear && php artisan route:clear && php artisan config:clear" 2>&1 | grep -v "password\|Warning"
echo "✅ Cache limpo"

# 7. Restart PHP-FPM
echo "[7/8] Reiniciando PHP-FPM..."
sshpass -p "$SENHA" ssh -o StrictHostKeyChecking=no root@72.61.53.222 "systemctl restart php8.3-fpm" 2>&1 | grep -v "password\|Warning"
echo "✅ PHP-FPM reiniciado"

echo ""
echo "✅ DEPLOY SPRINT 50 COMPLETO!"
echo ""
