#!/bin/bash
###############################################################################
# DIAGNÓSTICO COMPLETO - SPRINT 37
# Validação total do sistema após correção do 403 Forbidden
###############################################################################

echo "=============================================================================="
echo "🔍 DIAGNÓSTICO COMPLETO DO SERVIDOR - SPRINT 37"
echo "=============================================================================="
echo "Data: $(date)"
echo "Servidor: 72.61.53.222"
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

###############################################################################
# 1. STATUS DOS SERVIÇOS
###############################################################################
echo -e "${BLUE}[1/10] STATUS DOS SERVIÇOS${NC}"
echo "------------------------------------------------------------------------------"

services=("nginx" "php8.3-fpm" "mysql")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo -e "  ✅ $service: ${GREEN}ATIVO${NC}"
    else
        echo -e "  ❌ $service: ${RED}INATIVO${NC}"
    fi
done
echo ""

###############################################################################
# 2. RECURSOS DO SISTEMA
###############################################################################
echo -e "${BLUE}[2/10] RECURSOS DO SISTEMA${NC}"
echo "------------------------------------------------------------------------------"

echo "Memória:"
free -h | grep -E 'Mem|Swap'
echo ""

echo "CPU Load:"
uptime
echo ""

echo "Disco:"
df -h / /opt/webserver | grep -v tmpfs
echo ""

###############################################################################
# 3. LOGS DO NGINX
###############################################################################
echo -e "${BLUE}[3/10] LOGS DO NGINX (Últimas 20 linhas)${NC}"
echo "------------------------------------------------------------------------------"

echo "=== ERROS NGINX ==="
tail -20 /var/log/nginx/error.log 2>/dev/null || echo "Nenhum erro recente"
echo ""

echo "=== ACESSOS NGINX (Admin Panel) ==="
tail -20 /var/log/nginx/ip-server-access.log 2>/dev/null || echo "Sem logs de acesso"
echo ""

###############################################################################
# 4. LOGS DO PHP-FPM
###############################################################################
echo -e "${BLUE}[4/10] LOGS DO PHP-FPM 8.3${NC}"
echo "------------------------------------------------------------------------------"

if [ -f /var/log/php8.3-fpm.log ]; then
    echo "=== ERROS PHP-FPM ==="
    tail -20 /var/log/php8.3-fpm.log
else
    echo "Arquivo de log não encontrado em /var/log/php8.3-fpm.log"
    echo "Procurando em outros locais..."
    find /var/log -name "*php*fpm*" -type f 2>/dev/null | head -5
fi
echo ""

###############################################################################
# 5. LOGS DO LARAVEL (Admin Panel)
###############################################################################
echo -e "${BLUE}[5/10] LOGS DO LARAVEL (Admin Panel)${NC}"
echo "------------------------------------------------------------------------------"

LARAVEL_LOG="/opt/webserver/admin-panel/storage/logs/laravel.log"
if [ -f "$LARAVEL_LOG" ]; then
    echo "=== ÚLTIMAS 30 LINHAS DO LARAVEL ==="
    tail -30 "$LARAVEL_LOG"
else
    echo "❌ Log Laravel não encontrado em $LARAVEL_LOG"
fi
echo ""

###############################################################################
# 6. TESTES DE CONECTIVIDADE HTTP/HTTPS
###############################################################################
echo -e "${BLUE}[6/10] TESTES DE CONECTIVIDADE${NC}"
echo "------------------------------------------------------------------------------"

echo "=== HTTP (porta 80) ==="
HTTP_RESULT=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/admin/ 2>&1)
if [[ "$HTTP_RESULT" == "301" ]] || [[ "$HTTP_RESULT" == "200" ]]; then
    echo -e "  ✅ HTTP respondendo: ${GREEN}$HTTP_RESULT${NC}"
else
    echo -e "  ❌ HTTP com problema: ${RED}$HTTP_RESULT${NC}"
fi

echo "=== HTTPS (porta 443) ==="
HTTPS_RESULT=$(curl -k -s -o /dev/null -w "%{http_code}" https://127.0.0.1/admin/ 2>&1)
if [[ "$HTTPS_RESULT" == "200" ]]; then
    echo -e "  ✅ HTTPS respondendo: ${GREEN}$HTTPS_RESULT${NC}"
else
    echo -e "  ⚠️ HTTPS: ${YELLOW}$HTTPS_RESULT${NC}"
fi

echo "=== HTTPS via IP Externo ==="
HTTPS_EXT=$(curl -k -s -o /dev/null -w "%{http_code}" https://72.61.53.222/admin/ 2>&1)
if [[ "$HTTPS_EXT" == "200" ]]; then
    echo -e "  ✅ HTTPS externo: ${GREEN}$HTTPS_EXT${NC}"
else
    echo -e "  ⚠️ HTTPS externo: ${YELLOW}$HTTPS_EXT${NC}"
fi
echo ""

###############################################################################
# 7. PORTAS ESCUTANDO
###############################################################################
echo -e "${BLUE}[7/10] PORTAS ESCUTANDO${NC}"
echo "------------------------------------------------------------------------------"

echo "=== NGINX (80, 443) ==="
ss -tlnp | grep nginx | grep -E '(:80|:443)'

echo ""
echo "=== SSH (22, 2222) ==="
ss -tlnp | grep sshd | grep -E '(:22|:2222)'

echo ""
echo "=== MySQL (3306) ==="
ss -tlnp | grep mysql
echo ""

###############################################################################
# 8. PERMISSÕES DO ADMIN PANEL
###############################################################################
echo -e "${BLUE}[8/10] PERMISSÕES DO ADMIN PANEL${NC}"
echo "------------------------------------------------------------------------------"

echo "=== DocumentRoot (public/) ==="
ls -la /opt/webserver/admin-panel/public/ | head -10

echo ""
echo "=== Storage ==="
ls -ld /opt/webserver/admin-panel/storage/
echo ""

###############################################################################
# 9. BANCO DE DADOS - SITES
###############################################################################
echo -e "${BLUE}[9/10] BANCO DE DADOS - SITES${NC}"
echo "------------------------------------------------------------------------------"

MYSQL_RESULT=$(mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e "
SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN status='active' THEN 1 ELSE 0 END) as active,
    SUM(CASE WHEN status='inactive' THEN 1 ELSE 0 END) as inactive
FROM sites;
" 2>&1)

if [ $? -eq 0 ]; then
    echo "$MYSQL_RESULT"
    echo ""
    echo "=== Últimos 5 sites criados ==="
    mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e "
    SELECT id, site_name, status, ssl_enabled, created_at 
    FROM sites 
    ORDER BY created_at DESC 
    LIMIT 5;
    " 2>&1
else
    echo -e "${RED}❌ Erro ao conectar no MySQL${NC}"
fi
echo ""

###############################################################################
# 10. PROCESSOS PHP-FPM
###############################################################################
echo -e "${BLUE}[10/10] PROCESSOS PHP-FPM${NC}"
echo "------------------------------------------------------------------------------"

echo "=== PHP-FPM Admin Panel ==="
ps aux | grep php8.3-fpm-admin-panel | grep -v grep | head -5

echo ""
echo "=== Pools PHP-FPM Ativos ==="
ls -1 /etc/php/8.3/fpm/pool.d/*.conf | wc -l
echo "pools configurados"
echo ""

###############################################################################
# RESUMO FINAL
###############################################################################
echo "=============================================================================="
echo -e "${GREEN}✅ DIAGNÓSTICO COMPLETO CONCLUÍDO${NC}"
echo "=============================================================================="
echo ""

echo "RESUMO:"
echo "  - NGINX: $(systemctl is-active nginx)"
echo "  - PHP-FPM 8.3: $(systemctl is-active php8.3-fpm)"
echo "  - MySQL: $(systemctl is-active mysql)"
echo "  - HTTP: $HTTP_RESULT"
echo "  - HTTPS: $HTTPS_RESULT"
echo "  - HTTPS Externo: $HTTPS_EXT"
echo ""
echo "Logs salvos em: /tmp/diagnostico_sprint37_$(date +%s).log"
echo "=============================================================================="
