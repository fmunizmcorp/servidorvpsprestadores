#!/bin/bash

echo "=================================="
echo "SPRINT 49 - CORRIGINDO ERRO 500"
echo "URL: /admin/email/accounts/create"
echo "=================================="

# 1. Backup do controller
echo "[1/5] Fazendo backup do EmailController..."
curl -k -s https://72.61.53.222/admin/email/domains > /dev/null 2>&1
sshpass -p 'admin' ssh -o StrictHostKeyChecking=no root@72.61.53.222 "cp /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php.backup-sprint49" 2>&1 | grep -v "password\|Warning"

# 2. Deploy do controller corrigido
echo "[2/5] Deploy do EmailController corrigido..."
sshpass -p 'admin' scp -o StrictHostKeyChecking=no EmailController_sprint48.php root@72.61.53.222:/opt/webserver/admin-panel/app/Http/Controllers/EmailController.php 2>&1 | grep -v "password\|Warning"

# 3. Deploy da view accounts-create.blade.php
echo "[3/5] Deploy da view accounts-create.blade.php..."
sshpass -p 'admin' scp -o StrictHostKeyChecking=no accounts-create.blade.php root@72.61.53.222:/opt/webserver/admin-panel/resources/views/email/accounts-create.blade.php 2>&1 | grep -v "password\|Warning"

# 4. Limpar cache
echo "[4/5] Limpando cache Laravel..."
sshpass -p 'admin' ssh -o StrictHostKeyChecking=no root@72.61.53.222 "cd /opt/webserver/admin-panel && php artisan cache:clear && php artisan view:clear && php artisan route:clear && php artisan config:clear" 2>&1 | grep -v "password\|Warning"

# 5. Restart PHP-FPM
echo "[5/5] Reiniciando PHP-FPM..."
sshpass -p 'admin' ssh -o StrictHostKeyChecking=no root@72.61.53.222 "systemctl restart php8.3-fpm" 2>&1 | grep -v "password\|Warning"

echo ""
echo "✅ DEPLOY COMPLETO!"
echo ""
