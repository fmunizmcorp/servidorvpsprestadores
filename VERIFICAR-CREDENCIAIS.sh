#!/bin/bash
# Script para verificar e criar credenciais do painel admin se necessário

echo "=================================================="
echo "VERIFICANDO CREDENCIAIS DO PAINEL ADMINISTRATIVO"
echo "=================================================="

# Verificar se arquivo de credenciais existe
if [ -f "/root/admin-panel-credentials.txt" ]; then
    echo "✅ Arquivo de credenciais encontrado!"
    cat /root/admin-panel-credentials.txt
elif [ -f "/opt/webserver/admin-panel-credentials.txt" ]; then
    echo "✅ Arquivo de credenciais encontrado!"
    cat /opt/webserver/admin-panel-credentials.txt
else
    echo "⚠️ Arquivo de credenciais não encontrado"
    echo "📝 Vou criar um novo usuário admin..."
    
    cd /opt/webserver/admin-panel
    
    # Criar usuário via artisan tinker
    php artisan tinker --execute="
        \$user = new App\Models\User;
        \$user->name = 'Administrator';
        \$user->email = 'admin@localhost';
        \$user->password = Hash::make('Admin123!@#');
        \$user->email_verified_at = now();
        \$user->save();
        echo '✅ Usuário criado com sucesso!\n';
    "
    
    # Salvar credenciais
    cat > /root/admin-panel-credentials.txt << 'EOF'
==============================================
PAINEL ADMINISTRATIVO - CREDENCIAIS
==============================================

URL: http://72.61.53.222:8080
Email: admin@localhost
Senha: Admin123!@#

⚠️ IMPORTANTE: Altere a senha após primeiro login!

Acesso via: http://72.61.53.222:8080/login
Dashboard: http://72.61.53.222:8080/dashboard

Módulos Disponíveis:
- Sites: http://72.61.53.222:8080/sites
- Email: http://72.61.53.222:8080/email
- Backups: http://72.61.53.222:8080/backups
- Security: http://72.61.53.222:8080/security
- Monitoring: http://72.61.53.222:8080/monitoring

==============================================
GERADO EM: $(date '+%Y-%m-%d %H:%M:%S')
==============================================
EOF
    
    echo ""
    echo "✅ Credenciais salvas em /root/admin-panel-credentials.txt"
    cat /root/admin-panel-credentials.txt
fi

echo ""
echo "=================================================="
echo "TESTANDO ACESSO AO PAINEL"
echo "=================================================="

# Testar se painel está respondendo
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login)

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Painel admin está ONLINE e respondendo!"
    echo "   URL de acesso: http://72.61.53.222:8080/login"
else
    echo "❌ Painel admin retornou status: $HTTP_STATUS"
    echo "🔧 Verificando serviços..."
    
    systemctl status nginx --no-pager | head -5
    systemctl status php8.3-fpm --no-pager | head -5
fi

echo ""
echo "=================================================="
echo "INFORMAÇÕES ADICIONAIS"
echo "=================================================="

echo "📊 Banco de Dados:"
mysql -e "SELECT User, Host FROM mysql.user WHERE User LIKE 'admin%' OR User = 'root';" 2>/dev/null || echo "❌ Não foi possível conectar ao MySQL"

echo ""
echo "🔥 PHP-FPM Pools Ativos:"
ls -1 /etc/php/8.3/fpm/pool.d/*.conf | xargs -I{} basename {} .conf

echo ""
echo "🌐 NGINX Sites Habilitados:"
ls -1 /etc/nginx/sites-enabled/

echo ""
echo "=================================================="
echo "PRÓXIMOS PASSOS"
echo "=================================================="
echo "1. Acesse: http://72.61.53.222:8080/login"
echo "2. Faça login com as credenciais acima"
echo "3. Vá em Sites → Create New Site para criar seu primeiro site"
echo "4. Consulte o arquivo ACESSO-COMPLETO.md para guia detalhado"
echo "=================================================="
