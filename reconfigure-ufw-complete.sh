#!/bin/bash

################################################################################
# RECONFIGURE UFW - Complete Firewall Setup
################################################################################
# 
# Script para configurar UFW corretamente após restaurar acesso SSH
#
# Este script configura TODAS as portas necessárias para o servidor web
# e email funcionar corretamente
#
# EXECUTE APÓS RECUPERAR ACESSO SSH
#
################################################################################

set -e

echo "=========================================="
echo "UFW COMPLETE RECONFIGURATION"
echo "=========================================="
echo ""

# Verificar se está sendo executado como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ ERRO: Este script precisa ser executado como root"
    echo "Execute: sudo ./reconfigure-ufw-complete.sh"
    exit 1
fi

echo "✓ Executando como root"
echo ""

# Backup
echo "📦 Fazendo backup..."
mkdir -p /root/ufw-backups
ufw status numbered > /root/ufw-backups/ufw-before-reconfig-$(date +%Y%m%d-%H%M%S).txt 2>/dev/null || true
echo "✓ Backup salvo"
echo ""

# Resetar UFW (limpar todas as regras)
echo "🔄 Resetando UFW para estado limpo..."
ufw --force reset
echo "✓ UFW resetado"
echo ""

# Configurar políticas padrão
echo "🔧 Configurando políticas padrão..."
ufw default deny incoming
ufw default allow outgoing
echo "✓ Políticas configuradas (deny incoming, allow outgoing)"
echo ""

# Adicionar regras essenciais
echo "➕ Adicionando regras de firewall..."
echo ""

# SSH (MAIS IMPORTANTE)
echo "  → SSH (22/tcp) - Acesso remoto"
ufw allow 22/tcp comment 'SSH'

# HTTP/HTTPS (Web)
echo "  → HTTP (80/tcp) - Web"
ufw allow 80/tcp comment 'HTTP'
echo "  → HTTPS (443/tcp) - Web SSL"
ufw allow 443/tcp comment 'HTTPS'

# Admin Panel
echo "  → Admin Panel (8080/tcp)"
ufw allow 8080/tcp comment 'Admin Panel'

# Email - SMTP
echo "  → SMTP (25/tcp) - Email incoming"
ufw allow 25/tcp comment 'SMTP'
echo "  → SMTP Submission (587/tcp) - Email sending"
ufw allow 587/tcp comment 'SMTP Submission'
echo "  → SMTPS (465/tcp) - Email sending SSL"
ufw allow 465/tcp comment 'SMTPS'

# Email - IMAP
echo "  → IMAP (143/tcp) - Email reading"
ufw allow 143/tcp comment 'IMAP'
echo "  → IMAPS (993/tcp) - Email reading SSL"
ufw allow 993/tcp comment 'IMAPS'

# Email - POP3
echo "  → POP3 (110/tcp) - Email reading"
ufw allow 110/tcp comment 'POP3'
echo "  → POP3S (995/tcp) - Email reading SSL"
ufw allow 995/tcp comment 'POP3S'

# DNS (se necessário)
# ufw allow 53/tcp comment 'DNS'
# ufw allow 53/udp comment 'DNS'

# FTP (se necessário)
# ufw allow 21/tcp comment 'FTP'

echo ""
echo "✓ Todas as regras adicionadas"
echo ""

# Habilitar UFW
echo "🔥 Habilitando UFW..."
ufw --force enable
echo "✓ UFW habilitado e ativo"
echo ""

# Verificar status
echo "📊 Status final do UFW:"
echo ""
ufw status verbose
echo ""

# Verificar serviços críticos
echo "🔍 Verificando serviços críticos..."
echo ""

echo "SSH:"
systemctl status ssh --no-pager | grep Active || systemctl status sshd --no-pager | grep Active
echo ""

echo "NGINX:"
systemctl status nginx --no-pager | grep Active
echo ""

echo "Postfix:"
systemctl status postfix --no-pager | grep Active
echo ""

echo "Dovecot:"
systemctl status dovecot --no-pager | grep Active
echo ""

# Resumo
echo "=========================================="
echo "✅ UFW RECONFIGURADO COM SUCESSO"
echo "=========================================="
echo ""
echo "PORTAS ABERTAS:"
echo "  ✓ 22   - SSH (acesso remoto)"
echo "  ✓ 80   - HTTP (web)"
echo "  ✓ 443  - HTTPS (web SSL)"
echo "  ✓ 8080 - Admin Panel"
echo "  ✓ 25   - SMTP (email incoming)"
echo "  ✓ 587  - SMTP Submission (email sending)"
echo "  ✓ 465  - SMTPS (email sending SSL)"
echo "  ✓ 143  - IMAP (email reading)"
echo "  ✓ 993  - IMAPS (email reading SSL)"
echo "  ✓ 110  - POP3 (email reading)"
echo "  ✓ 995  - POP3S (email reading SSL)"
echo ""
echo "POLÍTICAS:"
echo "  ✓ Incoming: DENY (bloqueado por padrão)"
echo "  ✓ Outgoing: ALLOW (permitido por padrão)"
echo ""
echo "SEGURANÇA:"
echo "  ✓ Firewall ativo e protegendo o servidor"
echo "  ✓ Apenas portas necessárias abertas"
echo "  ✓ SSH permanece acessível"
echo ""
echo "TESTE AGORA:"
echo "  ssh root@72.61.53.222"
echo "  curl http://72.61.53.222"
echo "  curl http://72.61.53.222:8080"
echo ""
echo "=========================================="
