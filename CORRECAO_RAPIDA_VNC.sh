#!/bin/bash
#############################################################################
# SCRIPT DE CORREÇÃO RÁPIDA - VIA CONSOLE VNC HOSTINGER
# Servidor: 72.61.53.222
# Data: 20/11/2025
#############################################################################

echo "=========================================================================="
echo "🚨 INICIANDO CORREÇÃO DE EMERGÊNCIA - SERVIDOR VPS"
echo "=========================================================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#############################################################################
# PASSO 1: DIAGNÓSTICO INICIAL
#############################################################################
echo -e "${YELLOW}[PASSO 1] Diagnóstico Inicial${NC}"
echo "----------------------------------------------------------------------"

echo -n "Verificando NGINX... "
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ ATIVO${NC}"
else
    echo -e "${RED}❌ INATIVO - Iniciando...${NC}"
    systemctl start nginx
fi

echo -n "Verificando PHP-FPM 8.3... "
if systemctl is-active --quiet php8.3-fpm; then
    echo -e "${GREEN}✅ ATIVO${NC}"
else
    echo -e "${RED}❌ INATIVO - Iniciando...${NC}"
    systemctl start php8.3-fpm
fi

echo -n "Verificando MySQL... "
if systemctl is-active --quiet mysql; then
    echo -e "${GREEN}✅ ATIVO${NC}"
else
    echo -e "${RED}❌ INATIVO - Iniciando...${NC}"
    systemctl start mysql
fi

echo ""

#############################################################################
# PASSO 2: CORRIGIR 403 FORBIDDEN NO HTTPS
#############################################################################
echo -e "${YELLOW}[PASSO 2] Corrigindo 403 Forbidden no HTTPS${NC}"
echo "----------------------------------------------------------------------"

echo "Verificando logs NGINX para erro 403..."
NGINX_403=$(tail -50 /var/log/nginx/error.log | grep -i "403\|forbidden" | tail -5)
if [ -n "$NGINX_403" ]; then
    echo -e "${RED}Erros 403 encontrados:${NC}"
    echo "$NGINX_403"
else
    echo -e "${GREEN}Nenhum erro 403 recente nos logs${NC}"
fi

echo ""
echo "Corrigindo permissões do DocumentRoot..."
chown -R www-data:www-data /opt/webserver/admin-panel/public/
chmod -R 755 /opt/webserver/admin-panel/public/
echo -e "${GREEN}✅ Permissões corrigidas${NC}"

echo ""
echo "Recarregando NGINX..."
systemctl reload nginx
echo -e "${GREEN}✅ NGINX recarregado${NC}"

echo ""
echo "Testando HTTPS localmente..."
HTTPS_TEST=$(curl -k -I https://127.0.0.1/admin/ 2>/dev/null | head -1)
if echo "$HTTPS_TEST" | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ HTTPS respondendo corretamente: $HTTPS_TEST${NC}"
else
    echo -e "${RED}❌ HTTPS ainda com problema: $HTTPS_TEST${NC}"
fi

echo ""
echo "Testando HTTPS via IP externo..."
HTTPS_EXT_TEST=$(curl -k -I https://72.61.53.222/admin/ 2>/dev/null | head -1)
if echo "$HTTPS_EXT_TEST" | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ HTTPS externo funcionando: $HTTPS_EXT_TEST${NC}"
else
    echo -e "${RED}⚠️ HTTPS externo: $HTTPS_EXT_TEST${NC}"
    echo "Se ainda for 403, verifique configuração NGINX manualmente"
fi

echo ""

#############################################################################
# PASSO 3: ATIVAR SSH PORTA 2222
#############################################################################
echo -e "${YELLOW}[PASSO 3] Ativando SSH Porta 2222${NC}"
echo "----------------------------------------------------------------------"

echo "Verificando configuração SSH..."
SSH_PORTS=$(grep -E '^Port' /etc/ssh/sshd_config)
echo "Portas configuradas:"
echo "$SSH_PORTS"

echo ""
echo "Reiniciando SSH para ativar porta 2222..."
systemctl restart sshd
sleep 2
echo -e "${GREEN}✅ SSH reiniciado${NC}"

echo ""
echo "Verificando se SSH está escutando na porta 2222..."
if ss -tlnp | grep -q ':2222'; then
    echo -e "${GREEN}✅ SSH escutando na porta 2222${NC}"
    ss -tlnp | grep ':2222'
else
    echo -e "${RED}❌ Porta 2222 NÃO está ativa${NC}"
    echo "Verifique /etc/ssh/sshd_config manualmente"
fi

echo ""
echo "Testando conexão SSH local na porta 2222..."
timeout 3 ssh -p 2222 -o StrictHostKeyChecking=no root@localhost "echo 'OK'" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSH porta 2222 funcionando localmente${NC}"
else
    echo -e "${YELLOW}⚠️ Teste local falhou (pode ser problema de chave)${NC}"
fi

echo ""

#############################################################################
# PASSO 4: VERIFICAR FAIL2BAN
#############################################################################
echo -e "${YELLOW}[PASSO 4] Verificando Fail2Ban${NC}"
echo "----------------------------------------------------------------------"

if systemctl is-active --quiet fail2ban; then
    echo -e "${YELLOW}Fail2Ban está ATIVO${NC}"
    
    echo ""
    echo "IPs banidos no SSH:"
    fail2ban-client status sshd 2>/dev/null | grep "Banned IP list"
    
    echo ""
    echo "IPs banidos no NGINX:"
    fail2ban-client status nginx-http-auth 2>/dev/null | grep "Banned IP list"
    
    echo ""
    echo -e "${YELLOW}Se seu IP estiver banido, execute:${NC}"
    echo "fail2ban-client set sshd unbanip SEU_IP_AQUI"
else
    echo -e "${GREEN}✅ Fail2Ban não está ativo (sem bloqueios)${NC}"
fi

echo ""

#############################################################################
# PASSO 5: CONFIGURAR FIREWALL UFW (OPCIONAL)
#############################################################################
echo -e "${YELLOW}[PASSO 5] Status do Firewall UFW${NC}"
echo "----------------------------------------------------------------------"

UFW_STATUS=$(ufw status | head -1)
echo "Status atual: $UFW_STATUS"

if echo "$UFW_STATUS" | grep -q "inactive"; then
    echo ""
    echo -e "${YELLOW}UFW está DESATIVADO${NC}"
    echo "Se você quiser ATIVAR o firewall, execute:"
    echo ""
    echo "  ufw allow 22/tcp"
    echo "  ufw allow 2222/tcp"
    echo "  ufw allow 80/tcp"
    echo "  ufw allow 443/tcp"
    echo "  ufw --force enable"
    echo ""
    echo "⚠️ ATENÇÃO: Só ative se você tiver certeza!"
else
    echo -e "${GREEN}UFW está ATIVO${NC}"
    echo ""
    ufw status verbose
fi

echo ""

#############################################################################
# RESUMO FINAL
#############################################################################
echo "=========================================================================="
echo -e "${GREEN}✅ CORREÇÃO CONCLUÍDA - RESUMO${NC}"
echo "=========================================================================="
echo ""

echo "📊 STATUS DOS SERVIÇOS:"
echo "  NGINX:       $(systemctl is-active nginx)"
echo "  PHP-FPM 8.3: $(systemctl is-active php8.3-fpm)"
echo "  MySQL:       $(systemctl is-active mysql)"
echo "  SSH:         $(systemctl is-active sshd)"
echo ""

echo "🌐 TESTES DE ACESSO:"
echo ""
echo "1. HTTPS via IP:"
curl -k -I https://72.61.53.222/admin/ 2>/dev/null | head -1
echo ""

echo "2. HTTP via IP:"
curl -I http://72.61.53.222/admin/ 2>/dev/null | head -1
echo ""

echo "3. SSH Porta 2222:"
if ss -tlnp | grep -q ':2222'; then
    echo "   ✅ Porta 2222 ATIVA"
else
    echo "   ❌ Porta 2222 INATIVA"
fi
echo ""

echo "=========================================================================="
echo "🎯 PRÓXIMOS PASSOS:"
echo "=========================================================================="
echo ""
echo "1. Teste o admin panel no navegador:"
echo "   https://72.61.53.222/admin/"
echo ""
echo "2. Teste SSH na porta 2222 da sua máquina:"
echo "   ssh -p 2222 root@72.61.53.222"
echo ""
echo "3. Se SSH falhar, adicione sua chave SSH pública:"
echo "   nano /root/.ssh/authorized_keys"
echo "   (Cole sua chave pública e salve)"
echo ""
echo "4. Se HTTPS ainda retornar 403, execute diagnóstico avançado:"
echo "   nginx -T | grep -A 30 'listen.*443'"
echo "   tail -100 /var/log/nginx/error.log"
echo ""
echo "=========================================================================="
echo "Script concluído em: $(date)"
echo "=========================================================================="
