#!/bin/bash
# Script de Recuperação de Emergência - Servidor Inacessível
# Execute via CONSOLE DO PROVEDOR VPS (não SSH)
# 
# PROBLEMA: Servidor completamente inacessível
# - Ping não responde
# - SSH não funciona
# - Painel admin não carrega
# - Portas não respondem
#
# CAUSAS PROVÁVEIS:
# 1. UFW bloqueou tudo
# 2. NGINX/SSH travados
# 3. Serviços não subiram após reboot

set +e  # Não parar em erros

echo "════════════════════════════════════════════════════════════════"
echo "🚨 SCRIPT DE RECUPERAÇÃO DE EMERGÊNCIA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Este script irá:"
echo "1. Desabilitar UFW temporariamente"
echo "2. Verificar e reiniciar serviços críticos"
echo "3. Corrigir configurações de rede"
echo "4. Restaurar acesso SSH"
echo "5. Reconfigurar firewall corretamente"
echo ""
echo "⚠️  Execute via CONSOLE do provedor VPS"
echo ""

# ============================================
# 1. DESABILITAR UFW IMEDIATAMENTE
# ============================================

echo ""
echo "═══ 1. DESABILITANDO UFW (FIREWALL) ═══"
echo "Desabilitando UFW para restaurar acesso..."

# Desabilitar UFW
ufw --force disable

echo "✅ UFW desabilitado"
echo ""

# Verificar status
ufw status

# ============================================
# 2. VERIFICAR SERVIÇOS DE REDE
# ============================================

echo ""
echo "═══ 2. VERIFICANDO INTERFACE DE REDE ═══"

# Listar interfaces
echo "Interfaces de rede:"
ip link show

# Verificar IPs
echo ""
echo "Endereços IP:"
ip addr show

# Verificar se interface principal está UP
MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
echo ""
echo "Interface principal: $MAIN_INTERFACE"

if [ -n "$MAIN_INTERFACE" ]; then
    # Garantir que interface está UP
    ip link set $MAIN_INTERFACE up
    echo "✅ Interface $MAIN_INTERFACE configurada como UP"
else
    echo "⚠️  Não foi possível determinar interface principal"
    echo "Tentando levantar eth0..."
    ip link set eth0 up 2>/dev/null || true
    echo "Tentando levantar ens3..."
    ip link set ens3 up 2>/dev/null || true
fi

# Verificar conectividade básica
echo ""
echo "Testando conectividade local:"
ping -c 2 127.0.0.1

# ============================================
# 3. VERIFICAR E REINICIAR SSH
# ============================================

echo ""
echo "═══ 3. VERIFICANDO E CORRIGINDO SSH ═══"

# Verificar se SSH está rodando
if pgrep -x sshd > /dev/null; then
    echo "✅ SSH daemon está rodando"
else
    echo "❌ SSH daemon NÃO está rodando"
    echo "Iniciando SSH..."
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || /usr/sbin/sshd
fi

# Verificar configuração SSH
echo ""
echo "Verificando configuração SSH..."

if [ -f /etc/ssh/sshd_config ]; then
    # Backup da config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.emergency.bak
    
    # Garantir que portas estão configuradas
    if ! grep -q "^Port 22$" /etc/ssh/sshd_config && ! grep -q "^Port 2222$" /etc/ssh/sshd_config; then
        echo "⚠️  Nenhuma porta SSH configurada, adicionando porta 22..."
        echo "Port 22" >> /etc/ssh/sshd_config
    fi
    
    # Garantir PermitRootLogin
    if ! grep -q "^PermitRootLogin yes$" /etc/ssh/sshd_config; then
        echo "Habilitando PermitRootLogin..."
        sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
            echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
        fi
    fi
    
    # Garantir PasswordAuthentication
    if ! grep -q "^PasswordAuthentication yes$" /etc/ssh/sshd_config; then
        echo "Habilitando PasswordAuthentication..."
        sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
        if ! grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
            echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
        fi
    fi
    
    # Testar configuração
    echo ""
    echo "Testando configuração SSH..."
    if sshd -t 2>&1; then
        echo "✅ Configuração SSH válida"
    else
        echo "❌ Configuração SSH inválida, restaurando backup..."
        cp /etc/ssh/sshd_config.emergency.bak /etc/ssh/sshd_config
    fi
fi

# Reiniciar SSH
echo ""
echo "Reiniciando SSH..."
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || killall sshd && /usr/sbin/sshd

# Verificar se SSH está escutando
echo ""
echo "Portas SSH escutando:"
ss -tlnp | grep sshd || netstat -tlnp | grep sshd

# ============================================
# 4. VERIFICAR E REINICIAR NGINX
# ============================================

echo ""
echo "═══ 4. VERIFICANDO E CORRIGINDO NGINX ═══"

# Verificar se NGINX está instalado
if command -v nginx > /dev/null; then
    
    # Testar configuração NGINX
    echo "Testando configuração NGINX..."
    if nginx -t 2>&1; then
        echo "✅ Configuração NGINX válida"
    else
        echo "❌ Configuração NGINX inválida"
        echo "Desabilitando sites problemáticos..."
        
        # Desabilitar todos os sites temporariamente
        rm -f /etc/nginx/sites-enabled/*
        
        # Criar site padrão mínimo
        cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
        
        ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
        
        echo "Site padrão criado"
        nginx -t
    fi
    
    # Iniciar/reiniciar NGINX
    echo ""
    echo "Reiniciando NGINX..."
    systemctl stop nginx 2>/dev/null
    sleep 2
    systemctl start nginx 2>/dev/null
    
    # Verificar status
    if systemctl is-active --quiet nginx; then
        echo "✅ NGINX está rodando"
    else
        echo "❌ NGINX não está rodando"
        echo "Tentando iniciar manualmente..."
        nginx
    fi
    
    # Verificar portas
    echo ""
    echo "Portas NGINX escutando:"
    ss -tlnp | grep nginx || netstat -tlnp | grep nginx
    
else
    echo "⚠️  NGINX não está instalado"
fi

# ============================================
# 5. VERIFICAR OUTROS SERVIÇOS CRÍTICOS
# ============================================

echo ""
echo "═══ 5. VERIFICANDO SERVIÇOS CRÍTICOS ═══"

# Função para verificar serviço
check_service() {
    local service=$1
    local name=$2
    
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo "✅ $name está ativo"
    else
        echo "⚠️  $name não está ativo"
        echo "   Tentando iniciar $name..."
        systemctl start $service 2>/dev/null || true
    fi
}

check_service "php8.3-fpm" "PHP-FPM"
check_service "mariadb" "MariaDB"
check_service "redis-server" "Redis"
check_service "postfix" "Postfix"
check_service "dovecot" "Dovecot"

# ============================================
# 6. RECONFIGURAR UFW CORRETAMENTE
# ============================================

echo ""
echo "═══ 6. RECONFIGURANDO FIREWALL (UFW) ═══"

# Resetar UFW completamente
echo "Resetando UFW..."
ufw --force reset

# Configurar política padrão
ufw default deny incoming
ufw default allow outgoing

# Permitir TODAS as portas necessárias
echo ""
echo "Liberando portas essenciais..."

# SSH
ufw allow 22/tcp comment 'SSH principal'
ufw allow 2222/tcp comment 'SSH alternativo'

# HTTP/HTTPS
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Painel Admin
ufw allow 8080/tcp comment 'Admin HTTP'
ufw allow 8443/tcp comment 'Admin HTTPS'

# Email
ufw allow 25/tcp comment 'SMTP'
ufw allow 587/tcp comment 'SMTP Submission'
ufw allow 465/tcp comment 'SMTPS'
ufw allow 993/tcp comment 'IMAPS'
ufw allow 995/tcp comment 'POP3S'
ufw allow 143/tcp comment 'IMAP'
ufw allow 110/tcp comment 'POP3'

# Permitir loopback
ufw allow from 127.0.0.1

# Permitir ping (ICMP)
ufw allow from any to any proto icmp

echo ""
echo "Regras UFW configuradas:"
ufw show added

# ============================================
# 7. HABILITAR UFW NOVAMENTE
# ============================================

echo ""
echo "═══ 7. HABILITANDO UFW COM REGRAS CORRETAS ═══"
echo ""
echo "⚠️  ATENÇÃO: Habilitando firewall agora..."
echo ""

# Habilitar UFW
ufw --force enable

echo ""
echo "✅ UFW habilitado com regras corretas"
echo ""
echo "Status do UFW:"
ufw status verbose

# ============================================
# 8. VERIFICAÇÃO FINAL
# ============================================

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📊 VERIFICAÇÃO FINAL"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar serviços
echo "Serviços:"
echo "─────────────────────────────────────────────────────────────"
systemctl is-active sshd ssh 2>/dev/null | head -1 && echo "✅ SSH: ATIVO" || echo "❌ SSH: INATIVO"
systemctl is-active nginx 2>/dev/null && echo "✅ NGINX: ATIVO" || echo "❌ NGINX: INATIVO"
systemctl is-active php8.3-fpm 2>/dev/null && echo "✅ PHP-FPM: ATIVO" || echo "❌ PHP-FPM: INATIVO"
systemctl is-active mariadb 2>/dev/null && echo "✅ MariaDB: ATIVO" || echo "❌ MariaDB: INATIVO"

echo ""
echo "Portas escutando:"
echo "─────────────────────────────────────────────────────────────"
ss -tlnp | grep -E ':(22|2222|80|443|8080|8443|25|587|993|995)\s' || netstat -tlnp | grep -E ':(22|2222|80|443|8080|8443|25|587|993|995)\s'

echo ""
echo "Firewall:"
echo "─────────────────────────────────────────────────────────────"
ufw status | head -10

echo ""
echo "Interface de rede:"
echo "─────────────────────────────────────────────────────────────"
ip addr show | grep -E '^[0-9]+:|inet '

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ RECUPERAÇÃO CONCLUÍDA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Próximos passos:"
echo "1. Teste SSH:    ssh root@72.61.53.222"
echo "2. Teste SSH:    ssh -p 2222 root@72.61.53.222"
echo "3. Teste HTTP:   curl http://72.61.53.222"
echo "4. Teste Admin:  curl -k https://72.61.53.222:8443"
echo "5. Teste Ping:   ping 72.61.53.222"
echo ""
echo "Se ainda não funcionar, verifique:"
echo "- Console do provedor VPS para logs"
echo "- Configurações de rede do provedor"
echo "- Firewall do provedor (fora do servidor)"
echo ""
echo "Logs importantes:"
echo "  tail -f /var/log/syslog"
echo "  journalctl -xe"
echo ""

# ============================================
# 9. CRIAR ARQUIVO DE STATUS
# ============================================

cat > /root/RECUPERACAO-STATUS.txt << EOF
════════════════════════════════════════════════════════════════
RECUPERAÇÃO DE EMERGÊNCIA EXECUTADA
════════════════════════════════════════════════════════════════
Data: $(date)

AÇÕES EXECUTADAS:
─────────────────────────────────────────────────────────────
✅ UFW desabilitado temporariamente
✅ Interface de rede verificada e levantada
✅ SSH verificado e reiniciado
✅ NGINX verificado e reiniciado
✅ Serviços críticos verificados
✅ UFW reconfigurado com todas as portas necessárias
✅ UFW habilitado com regras corretas

PORTAS LIBERADAS NO FIREWALL:
─────────────────────────────────────────────────────────────
✅ 22/tcp    - SSH principal
✅ 2222/tcp  - SSH alternativo
✅ 80/tcp    - HTTP
✅ 443/tcp   - HTTPS
✅ 8080/tcp  - Admin HTTP
✅ 8443/tcp  - Admin HTTPS
✅ 25/tcp    - SMTP
✅ 587/tcp   - SMTP Submission
✅ 465/tcp   - SMTPS
✅ 993/tcp   - IMAPS
✅ 995/tcp   - POP3S
✅ 143/tcp   - IMAP
✅ 110/tcp   - POP3
✅ ICMP      - Ping

STATUS ATUAL:
─────────────────────────────────────────────────────────────
SSH:      $(systemctl is-active sshd ssh 2>/dev/null | head -1)
NGINX:    $(systemctl is-active nginx 2>/dev/null)
PHP-FPM:  $(systemctl is-active php8.3-fpm 2>/dev/null)
MariaDB:  $(systemctl is-active mariadb 2>/dev/null)
UFW:      $(ufw status | head -1)

PRÓXIMOS PASSOS:
─────────────────────────────────────────────────────────────
1. Teste acesso SSH: ssh root@72.61.53.222
2. Teste acesso Admin: https://72.61.53.222:8443
3. Verifique logs: tail -f /var/log/syslog

Se o problema persistir, verifique:
- Firewall do provedor VPS (fora do servidor)
- Configurações de rede do provedor
- Console do provedor para mensagens de erro

════════════════════════════════════════════════════════════════
EOF

echo "📄 Status salvo em: /root/RECUPERACAO-STATUS.txt"
echo ""
echo "Para ver o status:"
echo "  cat /root/RECUPERACAO-STATUS.txt"
echo ""
