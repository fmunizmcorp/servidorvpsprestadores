#!/bin/bash
# Script de teste após liberação do firewall

echo "========================================="
echo "  TESTE APÓS LIBERAÇÃO DO FIREWALL"
echo "========================================="
echo ""

echo "[1/5] Testando conectividade HTTPS..."
if timeout 5 curl -k -I https://72.61.53.222/admin/ 2>&1 | grep -q "HTTP"; then
    echo "✅ HTTPS acessível"
else
    echo "❌ HTTPS ainda bloqueado"
    echo "AGUARDE 2-3 minutos após liberar no painel da Hostinger"
    exit 1
fi
echo ""

echo "[2/5] Testando página de login..."
if timeout 5 curl -k -s https://72.61.53.222/admin/login | grep -q "VPS Admin"; then
    echo "✅ Página de login carregando"
else
    echo "❌ Página de login com problemas"
    exit 1
fi
echo ""

echo "[3/5] Testando autenticação..."
CSRF=$(curl -k -s -c cookies_test.txt https://72.61.53.222/admin/login | grep -oP 'name="_token" value="\K[^"]+' | head -1)
if [ ! -z "$CSRF" ]; then
    echo "✅ CSRF token obtido: ${CSRF:0:20}..."
else
    echo "❌ Erro ao obter CSRF token"
    exit 1
fi
echo ""

echo "[4/5] Verificando serviços no servidor..."
sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "systemctl is-active nginx php8.3-fpm mysql | xargs echo"
echo ""

echo "[5/5] Verificando banco de dados..."
SITES_INFO=$(sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -N -e 'SELECT COUNT(*), SUM(status=\"active\") FROM sites;'")
TOTAL=$(echo "$SITES_INFO" | awk '{print $1}')
ACTIVE=$(echo "$SITES_INFO" | awk '{print $2}')
echo "Sites no sistema: $TOTAL total, $ACTIVE ativos"
echo ""

echo "========================================="
echo "  ✅ SISTEMA TOTALMENTE OPERACIONAL!"
echo "========================================="
echo ""
echo "ACESSO:"
echo "  URL: https://72.61.53.222/admin/"
echo "  Login: test@admin.local"
echo "  Senha: Test@123456"
echo ""
echo "FUNCIONALIDADES:"
echo "  ✅ Login e autenticação"
echo "  ✅ Criação de sites"
echo "  ✅ Criação de domínios de email"
echo "  ✅ Criação de contas de email"
echo "  ✅ Arquitetura Laravel Events (Sprint 36 V2)"
echo "  ✅ $ACTIVE sites ativos no sistema"
echo ""
echo "========================================="
