#!/bin/bash

echo "================================================================================"
echo "                  TESTE END-TO-END - SPRINT 18 - TODAS FUNÇÕES"
echo "================================================================================"
echo ""
echo "Data: $(date)"
echo "VPS: 72.61.53.222"
echo ""

# Test 1: HTTP 500 /admin/email/accounts (FIXED)
echo "================================================================================"
echo "TESTE 1: HTTP 500 /admin/email/accounts (Sprint 18.1)"
echo "================================================================================"
echo ""

RESPONSE=$(sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
  "cd /opt/webserver/admin-panel && php artisan tinker --execute='
    \\\$controller = new \\\\App\\\\Http\\\\Controllers\\\\EmailController();
    \\\$accounts = [];
    \\\$reflection = new ReflectionClass(\\\$controller);
    \\\$method = \\\$reflection->getMethod(\"getAccountsForDomain\");
    \\\$method->setAccessible(true);
    try {
        \\\$accounts = \\\$method->invoke(\\\$controller, \"testefinal16email.local\");
        echo \"SUCCESS: \" . count(\\\$accounts) . \" accounts retrieved\";
    } catch (Exception \\\$e) {
        echo \"ERROR: \" . \\\$e->getMessage();
    }
  '" 2>&1)

if echo "$RESPONSE" | grep -q "SUCCESS"; then
    echo "✅ TESTE 1 PASSOU! Email accounts funciona corretamente"
    echo "   $RESPONSE"
else
    echo "🔴 TESTE 1 FALHOU!"
    echo "   $RESPONSE"
fi

# Test 2: Create Site (Sprint 18.2)
echo ""
echo "================================================================================"
echo "TESTE 2: Create Site (Sprint 18.2)"
echo "================================================================================"
echo ""
echo "Criando site via CLI: testsprint182..."

SITE_CREATE=$(sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
  "bash /opt/webserver/scripts/wrappers/create-site-wrapper.sh testsprint182 testsprint182.local 8.3 --template=php 2>&1")

if echo "$SITE_CREATE" | grep -q "successfully"; then
    echo "✅ TESTE 2 PASSOU! Site criado com sucesso"
    echo ""
    echo "Verificando filesystem..."
    sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 "ls -la /opt/webserver/sites/ | grep testsprint182"
    
    echo ""
    echo "Verificando NGINX config..."
    sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 "ls -la /etc/nginx/sites-enabled/ | grep testsprint182"
else
    echo "🔴 TESTE 2 FALHOU!"
    echo "$SITE_CREATE"
fi

# Test 3: Create Email Domain (Sprint 18.3)
echo ""
echo "================================================================================"
echo "TESTE 3: Create Email Domain (Sprint 18.3)"
echo "================================================================================"
echo ""
echo "Criando domínio email via CLI: testsprint183.local..."

DOMAIN_CREATE=$(sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
  "bash /opt/webserver/scripts/create-email-domain.sh testsprint183.local 2>&1")

if echo "$DOMAIN_CREATE" | grep -q "DNS RECORDS"; then
    echo "✅ TESTE 3 PASSOU! Domínio email criado"
    echo ""
    echo "Verificando arquivo virtual_domains..."
    sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 "grep testsprint183.local /etc/postfix/virtual_domains"
else
    echo "🔴 TESTE 3 FALHOU!"
    echo "$DOMAIN_CREATE"
fi

echo ""
echo "================================================================================"
echo "                          RESUMO DOS TESTES"
echo "================================================================================"
echo ""
echo "Sprint 18.1 (Email Accounts):  $(echo "$RESPONSE" | grep -q "SUCCESS" && echo "✅ PASSOU" || echo "🔴 FALHOU")"
echo "Sprint 18.2 (Create Site):     $(echo "$SITE_CREATE" | grep -q "successfully" && echo "✅ PASSOU" || echo "🔴 FALHOU")"
echo "Sprint 18.3 (Email Domain):    $(echo "$DOMAIN_CREATE" | grep -q "DNS RECORDS" && echo "✅ PASSOU" || echo "🔴 FALHOU")"
echo ""
echo "================================================================================"
