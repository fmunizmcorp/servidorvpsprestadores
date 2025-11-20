# 🚨 COMANDOS PARA EXECUTAR VIA CONSOLE VNC - SPRINT 37

## SITUAÇÃO ATUAL
- ✅ Servidor ONLINE (corrigimos o 403 Forbidden)
- ✅ NGINX, PHP-FPM, MySQL funcionando
- ✅ SSH porta 2222 ativa
- ❌ Chave SSH não autorizada (precisa adicionar manualmente)
- ❓ Relatório de testes menciona problemas que precisam ser validados

## OBJETIVO
Executar diagnóstico completo e validar TODAS as funcionalidades mencionadas no relatório de testes.

---

## PASSO 1: EXECUTAR DIAGNÓSTICO COMPLETO

Acesse o Console VNC da Hostinger e execute:

```bash
cat > /tmp/diagnostico_sprint37.sh << 'EOFDIAG'
#!/bin/bash
echo "=============================================================================="
echo "🔍 DIAGNÓSTICO COMPLETO DO SERVIDOR - SPRINT 37"
echo "=============================================================================="
echo "Data: $(date)"
echo ""

# 1. STATUS DOS SERVIÇOS
echo "[1/10] STATUS DOS SERVIÇOS"
echo "------------------------------------------------------------------------------"
for service in nginx php8.3-fpm mysql; do
    if systemctl is-active --quiet "$service"; then
        echo "  ✅ $service: ATIVO"
    else
        echo "  ❌ $service: INATIVO"
    fi
done
echo ""

# 2. RECURSOS DO SISTEMA
echo "[2/10] RECURSOS DO SISTEMA"
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

# 3. LOGS DO NGINX (últimas 20 linhas)
echo "[3/10] LOGS DO NGINX"
echo "------------------------------------------------------------------------------"
echo "=== ERROS NGINX ==="
tail -20 /var/log/nginx/error.log 2>/dev/null || echo "Nenhum erro recente"
echo ""

# 4. LOGS DO PHP-FPM
echo "[4/10] LOGS DO PHP-FPM 8.3"
echo "------------------------------------------------------------------------------"
if [ -f /var/log/php8.3-fpm.log ]; then
    tail -20 /var/log/php8.3-fpm.log
else
    echo "Log PHP-FPM não encontrado. Procurando..."
    find /var/log -name "*php*fpm*" -type f 2>/dev/null | head -3
fi
echo ""

# 5. LOGS DO LARAVEL
echo "[5/10] LOGS DO LARAVEL (Admin Panel)"
echo "------------------------------------------------------------------------------"
if [ -f /opt/webserver/admin-panel/storage/logs/laravel.log ]; then
    echo "=== ÚLTIMAS 30 LINHAS ==="
    tail -30 /opt/webserver/admin-panel/storage/logs/laravel.log
else
    echo "❌ Log Laravel não encontrado"
fi
echo ""

# 6. TESTES DE CONECTIVIDADE
echo "[6/10] TESTES DE CONECTIVIDADE"
echo "------------------------------------------------------------------------------"
echo "HTTP (porta 80):"
curl -s -o /dev/null -w "  Status: %{http_code}\n" http://127.0.0.1/admin/

echo "HTTPS (porta 443 local):"
curl -k -s -o /dev/null -w "  Status: %{http_code}\n" https://127.0.0.1/admin/

echo "HTTPS (via IP externo):"
curl -k -s -o /dev/null -w "  Status: %{http_code}\n" https://72.61.53.222/admin/
echo ""

# 7. PORTAS ESCUTANDO
echo "[7/10] PORTAS ESCUTANDO"
echo "------------------------------------------------------------------------------"
echo "NGINX (80, 443):"
ss -tlnp | grep nginx | grep -E '(:80|:443)'
echo ""
echo "SSH (22, 2222):"
ss -tlnp | grep sshd | grep -E '(:22|:2222)'
echo ""
echo "MySQL (3306):"
ss -tlnp | grep mysql
echo ""

# 8. PERMISSÕES DO ADMIN PANEL
echo "[8/10] PERMISSÕES DO ADMIN PANEL"
echo "------------------------------------------------------------------------------"
ls -la /opt/webserver/admin-panel/public/ | head -10
echo ""

# 9. BANCO DE DADOS - SITES
echo "[9/10] BANCO DE DADOS - SITES"
echo "------------------------------------------------------------------------------"
mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e "
SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN status='active' THEN 1 ELSE 0 END) as active,
    SUM(CASE WHEN status='inactive' THEN 1 ELSE 0 END) as inactive
FROM sites;
"
echo ""
echo "=== Últimos 5 sites criados ==="
mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e "
SELECT id, site_name, status, ssl_enabled, created_at 
FROM sites 
ORDER BY created_at DESC 
LIMIT 5;
"
echo ""

# 10. PROCESSOS PHP-FPM
echo "[10/10] PROCESSOS PHP-FPM"
echo "------------------------------------------------------------------------------"
ps aux | grep php8.3-fpm-admin-panel | grep -v grep | head -5
echo ""

echo "=============================================================================="
echo "✅ DIAGNÓSTICO COMPLETO CONCLUÍDO"
echo "=============================================================================="
EOFDIAG

chmod +x /tmp/diagnostico_sprint37.sh
/tmp/diagnostico_sprint37.sh | tee /tmp/resultado_diagnostico_sprint37.txt

echo ""
echo "=========================================="
echo "Resultado salvo em: /tmp/resultado_diagnostico_sprint37.txt"
echo "Para ver novamente: cat /tmp/resultado_diagnostico_sprint37.txt"
echo "=========================================="
```

---

## PASSO 2: TESTAR LOGIN NO ADMIN PANEL

```bash
# Testar login via curl
curl -k -X POST https://127.0.0.1/admin/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=test@admin.local&password=Test@123456" \
  -c /tmp/cookies_sprint37.txt \
  -L -v 2>&1 | grep -E '(HTTP|Location|Set-Cookie)'
```

---

## PASSO 3: TESTAR ACESSO ÀS PÁGINAS DO ADMIN

```bash
# Dashboard
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/dashboard -s -o /dev/null -w "Dashboard: %{http_code}\n"

# Sites
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/sites -s -o /dev/null -w "Sites: %{http_code}\n"
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/sites/create -s -o /dev/null -w "Sites Create: %{http_code}\n"

# Email Domains
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/email/domains -s -o /dev/null -w "Email Domains: %{http_code}\n"
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/email/domains/create -s -o /dev/null -w "Email Domains Create: %{http_code}\n"

# Email Accounts
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/email/accounts -s -o /dev/null -w "Email Accounts: %{http_code}\n"
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/email/accounts/create -s -o /dev/null -w "Email Accounts Create: %{http_code}\n"

# DNS
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/dns -s -o /dev/null -w "DNS: %{http_code}\n"

# Users
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/users -s -o /dev/null -w "Users: %{http_code}\n"

# Settings
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/settings -s -o /dev/null -w "Settings: %{http_code}\n"

# Logs
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/logs -s -o /dev/null -w "Logs: %{http_code}\n"

# Services
curl -k -b /tmp/cookies_sprint37.txt https://127.0.0.1/admin/services -s -o /dev/null -w "Services: %{http_code}\n"
```

---

## PASSO 4: TESTAR CRIAÇÃO DE SITE (FUNCIONALIDADE PRINCIPAL)

```bash
# Criar site de teste
curl -k -X POST https://127.0.0.1/admin/sites \
  -b /tmp/cookies_sprint37.txt \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "site_name=testsprint37validacao&domain=testsprint37validacao.local&template=html&create_database=on" \
  -L -v 2>&1 | tee /tmp/test_site_creation.log

echo ""
echo "Aguardando 30 segundos para scripts em background..."
sleep 30

echo ""
echo "Verificando se o site foi criado com status 'active':"
mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e "
SELECT id, site_name, status, ssl_enabled, created_at 
FROM sites 
WHERE site_name='testsprint37validacao';
"
```

---

## PASSO 5: ENVIAR RESULTADOS

Após executar todos os comandos acima, envie os resultados:

```bash
# Consolidar todos os resultados
cat > /tmp/resultados_completos_sprint37.txt << 'EOF'
========== RESULTADOS SPRINT 37 - VALIDAÇÃO COMPLETA ==========

=== 1. DIAGNÓSTICO DO SERVIDOR ===
EOF

cat /tmp/resultado_diagnostico_sprint37.txt >> /tmp/resultados_completos_sprint37.txt

echo "" >> /tmp/resultados_completos_sprint37.txt
echo "=== 2. LOG DE CRIAÇÃO DE SITE ===" >> /tmp/resultados_completos_sprint37.txt
cat /tmp/test_site_creation.log >> /tmp/resultados_completos_sprint37.txt

echo "" >> /tmp/resultados_completos_sprint37.txt
echo "========== FIM DOS RESULTADOS ==========" >> /tmp/resultados_completos_sprint37.txt

# Mostrar arquivo final
cat /tmp/resultados_completos_sprint37.txt

echo ""
echo "=========================================="
echo "✅ Resultados consolidados salvos em:"
echo "/tmp/resultados_completos_sprint37.txt"
echo ""
echo "Para copiar o arquivo, execute:"
echo "cat /tmp/resultados_completos_sprint37.txt"
echo "=========================================="
```

---

## INFORMAÇÕES IMPORTANTES

**Credenciais de Login:**
- Email: test@admin.local
- Senha: Test@123456

**Caminhos Corretos:**
- Admin Panel: `/opt/webserver/admin-panel`
- PHP-FPM: `php8.3-fpm` (NÃO php8.2)
- Logs Laravel: `/opt/webserver/admin-panel/storage/logs/laravel.log`

**Portas:**
- HTTP: 80
- HTTPS: 443
- SSH: 22 e 2222
- MySQL: 3306

---

**Preparado por:** GenSpark AI Developer - Sprint 37  
**Data:** 20/11/2025  
**Objetivo:** Validação 100% de todas as funcionalidades
