#!/bin/bash

echo "=============================================="
echo "VERIFICAÇÃO DE PERSISTÊNCIA NO BANCO DE DADOS"
echo "=============================================="
echo ""

# Using sshpass for password authentication
export SSHPASS='mcorpapp'

echo "📋 Conectando ao servidor de produção..."
echo ""

sshpass -e ssh -o StrictHostKeyChecking=no root@72.61.53.222 << 'ENDSSH'
cd /opt/webserver/admin-panel

echo "=== SITES CRIADOS RECENTEMENTE ==="
php artisan tinker --execute="
    \$sites = \App\Models\Site::latest()->take(5)->get(['id', 'site_name', 'domain', 'created_at']);
    echo 'Total de sites: ' . \App\Models\Site::count() . PHP_EOL;
    echo PHP_EOL;
    echo 'Últimos 5 sites criados:' . PHP_EOL;
    foreach (\$sites as \$site) {
        echo '  ID: ' . \$site->id . ' | Nome: ' . \$site->site_name . ' | Domínio: ' . \$site->domain . ' | Criado: ' . \$site->created_at . PHP_EOL;
    }
"

echo ""
echo "=== DOMÍNIOS DE EMAIL CRIADOS RECENTEMENTE ==="
php artisan tinker --execute="
    \$domains = \App\Models\EmailDomain::latest()->take(5)->get(['id', 'domain', 'status', 'created_at']);
    echo 'Total de domínios: ' . \App\Models\EmailDomain::count() . PHP_EOL;
    echo PHP_EOL;
    echo 'Últimos 5 domínios criados:' . PHP_EOL;
    foreach (\$domains as \$domain) {
        echo '  ID: ' . \$domain->id . ' | Domínio: ' . \$domain->domain . ' | Status: ' . \$domain->status . ' | Criado: ' . \$domain->created_at . PHP_EOL;
    }
"

echo ""
echo "=== VERIFICAR SE OS TESTES FORAM SALVOS ==="
php artisan tinker --execute="
    \$testSite = \App\Models\Site::where('site_name', 'LIKE', 'teste_validacao_%')->latest()->first();
    if (\$testSite) {
        echo '✅ SITE DE TESTE ENCONTRADO NO BANCO:' . PHP_EOL;
        echo '   ID: ' . \$testSite->id . PHP_EOL;
        echo '   Nome: ' . \$testSite->site_name . PHP_EOL;
        echo '   Domínio: ' . \$testSite->domain . PHP_EOL;
        echo '   Criado em: ' . \$testSite->created_at . PHP_EOL;
    } else {
        echo '❌ Site de teste não encontrado no banco' . PHP_EOL;
    }
"

echo ""
php artisan tinker --execute="
    \$testDomain = \App\Models\EmailDomain::where('domain', 'LIKE', 'email-test-%')->latest()->first();
    if (\$testDomain) {
        echo '✅ DOMÍNIO DE TESTE ENCONTRADO NO BANCO:' . PHP_EOL;
        echo '   ID: ' . \$testDomain->id . PHP_EOL;
        echo '   Domínio: ' . \$testDomain->domain . PHP_EOL;
        echo '   Status: ' . \$testDomain->status . PHP_EOL;
        echo '   Criado em: ' . \$testDomain->created_at . PHP_EOL;
    } else {
        echo '❌ Domínio de teste não encontrado no banco' . PHP_EOL;
    }
"

ENDSSH

echo ""
echo "=============================================="
echo "VERIFICAÇÃO COMPLETA"
echo "=============================================="

