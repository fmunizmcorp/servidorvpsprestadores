#!/bin/bash

################################################################################
# FIX SSH ACCESS - UFW Firewall Configuration
################################################################################
# 
# PROBLEMA: UFW está bloqueando acesso SSH externo
# SOLUÇÃO: Reconfigurar UFW para permitir SSH de qualquer origem
#
# EXECUTE ESTE SCRIPT DIRETAMENTE NO SERVIDOR VIA:
# - Console web do provedor
# - Terminal físico
# - KVM/IPMI
#
# COMO EXECUTAR:
#   chmod +x fix-ssh-firewall.sh
#   ./fix-ssh-firewall.sh
#
################################################################################

set -e

echo "=========================================="
echo "FIX SSH ACCESS - UFW RECONFIGURATION"
echo "=========================================="
echo ""

# Verificar se está sendo executado como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ ERRO: Este script precisa ser executado como root"
    echo "Execute: sudo ./fix-ssh-firewall.sh"
    exit 1
fi

echo "✓ Executando como root"
echo ""

# Backup da configuração atual do UFW
echo "📦 Fazendo backup das regras UFW atuais..."
ufw status numbered > /root/ufw-backup-$(date +%Y%m%d-%H%M%S).txt
echo "✓ Backup salvo em /root/ufw-backup-*.txt"
echo ""

# PASSO 1: Permitir SSH ANTES de habilitar o firewall
echo "🔓 PASSO 1: Permitindo SSH (porta 22) de QUALQUER origem..."
ufw allow 22/tcp comment 'SSH Access'
echo "✓ Regra SSH adicionada"
echo ""

# PASSO 2: Verificar se SSH já está na lista
echo "📋 PASSO 2: Verificando regras atuais..."
ufw status numbered
echo ""

# PASSO 3: Garantir que SSH está permitido
echo "🔧 PASSO 3: Garantindo que SSH está permitido..."
ufw allow ssh
ufw allow 22/tcp
echo "✓ SSH permitido em múltiplas regras (redundância de segurança)"
echo ""

# PASSO 4: Recarregar UFW
echo "🔄 PASSO 4: Recarregando UFW..."
ufw reload
echo "✓ UFW recarregado"
echo ""

# PASSO 5: Verificar status final
echo "📊 PASSO 5: Status final do UFW..."
echo ""
ufw status verbose
echo ""

# PASSO 6: Testar se SSH está realmente permitido
echo "🧪 PASSO 6: Verificando se porta 22 está aberta..."
if ss -tlnp | grep -q ':22 '; then
    echo "✓ SSH está escutando na porta 22"
else
    echo "⚠️  AVISO: SSH pode não estar rodando corretamente"
fi
echo ""

# PASSO 7: Verificar serviço SSH
echo "🔍 PASSO 7: Verificando serviço SSH..."
systemctl status ssh --no-pager || systemctl status sshd --no-pager
echo ""

# RESUMO FINAL
echo "=========================================="
echo "✅ CONFIGURAÇÃO CONCLUÍDA"
echo "=========================================="
echo ""
echo "AÇÕES REALIZADAS:"
echo "  ✓ Backup das regras UFW criado"
echo "  ✓ Porta 22/tcp permitida no UFW"
echo "  ✓ Regra SSH permitida no UFW"
echo "  ✓ UFW recarregado"
echo ""
echo "PRÓXIMOS PASSOS:"
echo "  1. Teste a conexão SSH de uma máquina externa:"
echo "     ssh root@72.61.53.222"
echo ""
echo "  2. Se ainda não funcionar, execute:"
echo "     ufw disable"
echo "     ufw enable"
echo ""
echo "  3. Como último recurso (TEMPORÁRIO):"
echo "     ufw disable"
echo "     (isto desabilita o firewall completamente)"
echo ""
echo "IMPORTANTE:"
echo "  - SSH agora deve estar acessível"
echo "  - Firewall continua protegendo outras portas"
echo "  - Backup das regras antigas foi salvo"
echo ""
echo "=========================================="
