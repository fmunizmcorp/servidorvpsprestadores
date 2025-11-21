#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "🚀 SPRINT 52 - DEPLOY: FIX LISTAGEM DE SITES"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Problema identificado: Novos sites não aparecem na listagem"
echo "Solução implementada:"
echo "  1. Query direta DB::table() ao invés de Eloquent (evita cache)"
echo "  2. Invalidação explícita de cache após Site::create()"
echo "  3. Headers no-cache em index() e redirect"
echo "  4. Logging detalhado para debug"
echo ""

# SSH credentials
SSH_HOST="72.61.53.222"
SSH_USER="root"
SSH_PASS="Jm@D@KDPnw7Q"

echo "📋 PASSO 1: Backup do controller atual..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "cp /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php \
        /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php.backup-sprint52"

if [ $? -eq 0 ]; then
    echo "✅ Backup criado: SitesController.php.backup-sprint52"
else
    echo "❌ ERRO ao criar backup"
    exit 1
fi

echo ""
echo "📤 PASSO 2: Upload do SitesController corrigido..."
sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no \
    /home/user/webapp/SitesController.php \
    $SSH_USER@$SSH_HOST:/opt/webserver/admin-panel/app/Http/Controllers/SitesController.php

if [ $? -eq 0 ]; then
    echo "✅ SitesController.php deployado com sucesso"
else
    echo "❌ ERRO ao fazer upload do controller"
    exit 1
fi

echo ""
echo "🧹 PASSO 3: Limpar todos os caches do Laravel..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "cd /opt/webserver/admin-panel && \
     php artisan config:clear && \
     php artisan route:clear && \
     php artisan view:clear && \
     php artisan cache:clear"

if [ $? -eq 0 ]; then
    echo "✅ Caches do Laravel limpos"
else
    echo "⚠️  Aviso: Erro ao limpar caches Laravel (pode continuar)"
fi

echo ""
echo "🔄 PASSO 4: Reiniciar PHP-FPM (limpar OPcache)..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "systemctl reload php8.3-fpm"

if [ $? -eq 0 ]; then
    echo "✅ PHP-FPM reiniciado (OPcache limpo)"
else
    echo "❌ ERRO ao reiniciar PHP-FPM"
    exit 1
fi

echo ""
echo "📊 PASSO 5: Verificar total de sites no banco..."
TOTAL_SITES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "mysql -u admin_panel_user -p'Jm@D@KDPnw7Q' admin_panel -s -N -e 'SELECT COUNT(*) FROM sites;'")

echo "✅ Total de sites no banco: $TOTAL_SITES"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ DEPLOY CONCLUÍDO COM SUCESSO!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Alterações implementadas:"
echo "  ✅ getAllSites() agora usa DB::table() direto (sem cache Eloquent)"
echo "  ✅ Cache::flush() após Site::create()"
echo "  ✅ Headers no-cache em index() e redirect"
echo "  ✅ Logging em /opt/webserver/admin-panel/storage/logs/laravel.log"
echo ""
echo "Próximo passo:"
echo "  👉 Testar criação de novo site e verificar se aparece na listagem"
echo ""
echo "Para verificar logs em tempo real:"
echo "  tail -f /opt/webserver/admin-panel/storage/logs/laravel.log | grep SPRINT52"
echo ""
