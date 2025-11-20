#!/bin/bash
# Script de diagnóstico para 403 Forbidden

echo "=========================================================================="
echo "🔍 DIAGNÓSTICO DO ERRO 403 FORBIDDEN"
echo "=========================================================================="
echo ""

echo "=== 1. ÚLTIMOS ERROS 403 NO LOG DO NGINX ==="
tail -100 /var/log/nginx/error.log | grep -i "403\|forbidden\|denied" | tail -10
echo ""

echo "=== 2. CONFIGURAÇÃO SSL DO NGINX ==="
nginx -T 2>&1 | grep -A 50 "listen.*443" | grep -A 50 "server_name" | head -60
echo ""

echo "=== 3. PERMISSÕES DO DOCUMENTROOT ==="
ls -la /opt/webserver/admin-panel/public/ | head -20
echo ""

echo "=== 4. DONO DOS ARQUIVOS ==="
stat /opt/webserver/admin-panel/public/index.php 2>/dev/null || echo "index.php não encontrado"
echo ""

echo "=== 5. TESTAR HTTPS COM VERBOSIDADE ==="
curl -k -v https://127.0.0.1/admin/ 2>&1 | grep -E '(< HTTP|< Server|403|forbidden|denied|Location)' | head -20
echo ""

echo "=== 6. VERIFICAR SE HÁ RESTRIÇÕES DE IP NO NGINX ==="
grep -r "allow\|deny" /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "#"
echo ""

echo "=== 7. VERIFICAR INDEX FILES NA CONFIGURAÇÃO ==="
nginx -T 2>&1 | grep -i "index " | grep -v "#"
echo ""

echo "=========================================================================="
