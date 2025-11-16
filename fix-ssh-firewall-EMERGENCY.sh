#!/bin/bash

################################################################################
# EMERGENCY SSH FIX - Disable UFW Temporarily
################################################################################
# 
# ⚠️  USE APENAS SE O SCRIPT NORMAL NÃO FUNCIONAR ⚠️
#
# Este script DESABILITA o UFW completamente para restaurar acesso SSH
# É uma solução TEMPORÁRIA de emergência
#
# EXECUTE ESTE SCRIPT DIRETAMENTE NO SERVIDOR VIA:
# - Console web do provedor
# - Terminal físico
# - KVM/IPMI
#
# COMO EXECUTAR:
#   chmod +x fix-ssh-firewall-EMERGENCY.sh
#   ./fix-ssh-firewall-EMERGENCY.sh
#
################################################################################

set -e

echo "=========================================="
echo "⚠️  EMERGENCY SSH FIX - UFW DISABLE ⚠️"
echo "=========================================="
echo ""

# Verificar se está sendo executado como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ ERRO: Este script precisa ser executado como root"
    echo "Execute: sudo ./fix-ssh-firewall-EMERGENCY.sh"
    exit 1
fi

echo "✓ Executando como root"
echo ""

# Backup completo
echo "📦 Fazendo backup completo do UFW..."
mkdir -p /root/ufw-backup-emergency-$(date +%Y%m%d-%H%M%S)
cp -r /etc/ufw/* /root/ufw-backup-emergency-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
ufw status numbered > /root/ufw-status-before-emergency-$(date +%Y%m%d-%H%M%S).txt
echo "✓ Backup completo salvo em /root/"
echo ""

# DESABILITAR UFW
echo "🔴 DESABILITANDO UFW COMPLETAMENTE..."
ufw --force disable
echo "✓ UFW desabilitado"
echo ""

# Verificar status
echo "📊 Status do UFW:"
ufw status verbose
echo ""

# Verificar SSH
echo "🔍 Verificando serviço SSH..."
systemctl status ssh --no-pager || systemctl status sshd --no-pager
echo ""

# Garantir que SSH está rodando
echo "🔧 Garantindo que SSH está ativo..."
systemctl enable ssh || systemctl enable sshd
systemctl restart ssh || systemctl restart sshd
echo "✓ SSH reiniciado"
echo ""

# Verificar porta 22
echo "🧪 Verificando porta 22..."
ss -tlnp | grep ':22 '
echo ""

# RESUMO
echo "=========================================="
echo "✅ MODO EMERGÊNCIA ATIVADO"
echo "=========================================="
echo ""
echo "AÇÕES REALIZADAS:"
echo "  ✓ Backup completo do UFW criado"
echo "  ✓ UFW DESABILITADO (firewall OFF)"
echo "  ✓ SSH reiniciado"
echo ""
echo "⚠️  IMPORTANTE - SEGURANÇA:"
echo "  - O firewall está DESABILITADO"
echo "  - O servidor está EXPOSTO"
echo "  - Reconecte via SSH IMEDIATAMENTE"
echo "  - Execute o script de reconfiguração do firewall"
echo ""
echo "PRÓXIMOS PASSOS OBRIGATÓRIOS:"
echo "  1. Teste SSH AGORA:"
echo "     ssh root@72.61.53.222"
echo ""
echo "  2. Após conectar via SSH, RECONFIGURE o UFW:"
echo "     ufw default deny incoming"
echo "     ufw default allow outgoing"
echo "     ufw allow 22/tcp"
echo "     ufw allow 80/tcp"
echo "     ufw allow 443/tcp"
echo "     ufw allow 25/tcp"
echo "     ufw allow 587/tcp"
echo "     ufw allow 465/tcp"
echo "     ufw allow 993/tcp"
echo "     ufw allow 995/tcp"
echo "     ufw allow 8080/tcp"
echo "     ufw --force enable"
echo ""
echo "=========================================="
