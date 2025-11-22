#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "🔨 SPRINT 53 - RECONSTRUÇÃO COMPLETA DO MÓDULO SITES"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🔴 RECONHECIMENTO: Sprint 52 falhou completamente"
echo "✅ SOLUÇÃO: Reconstruir como EmailController (que FUNCIONA!)"
echo ""
echo "Mudanças implementadas:"
echo "  1. index() reconstruído - query Eloquent inline (como EmailController)"
echo "  2. store() simplificado - sem cache, sem logs, sem headers extras"
echo "  3. getAllSites() REMOVIDO - query direta em index()"
echo "  4. Imports simplificados - apenas Model, Request, Validator"
echo ""

# SSH credentials
SSH_HOST="72.61.53.222"
SSH_USER="root"
SSH_PASS="Jm@D@KDPnw7Q"

echo "📋 PASSO 1: Backup do controller atual..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "cp /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php \
        /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php.backup-sprint53"

if [ $? -eq 0 ]; then
    echo "✅ Backup criado: SitesController.php.backup-sprint53"
else
    echo "❌ ERRO ao criar backup"
    exit 1
fi

echo ""
echo "📤 PASSO 2: Upload do SitesController reconstruído..."
sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no \
    /home/user/webapp/SitesController.php \
    $SSH_USER@$SSH_HOST:/opt/webserver/admin-panel/app/Http/Controllers/SitesController.php

if [ $? -eq 0 ]; then
    echo "✅ SitesController.php reconstruído deployado com sucesso"
else
    echo "❌ ERRO ao fazer upload do controller"
    exit 1
fi

echo ""
echo "🧹 PASSO 3: Limpar TODOS os caches..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "cd /opt/webserver/admin-panel && \
     php artisan config:clear && \
     php artisan route:clear && \
     php artisan view:clear && \
     php artisan cache:clear && \
     php artisan clear-compiled"

if [ $? -eq 0 ]; then
    echo "✅ Todos os caches Laravel limpos"
else
    echo "⚠️  Aviso: Erro ao limpar caches (continuando...)"
fi

echo ""
echo "🔄 PASSO 4: Reiniciar PHP-FPM (OPcache)..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "systemctl restart php8.3-fpm"

if [ $? -eq 0 ]; then
    echo "✅ PHP-FPM reiniciado (OPcache completamente limpo)"
else
    echo "❌ ERRO ao reiniciar PHP-FPM"
    exit 1
fi

echo ""
echo "📊 PASSO 5: Validação - contar sites no banco..."
TOTAL_SITES=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "mysql -u admin_panel_user -p'Jm@D@KDPnw7Q' admin_panel -s -N -e 'SELECT COUNT(*) FROM sites;'")

echo "✅ Total de sites no banco: $TOTAL_SITES"

echo ""
echo "📊 PASSO 6: Validação - últimos 3 sites criados..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST \
    "mysql -u admin_panel_user -p'Jm@D@KDPnw7Q' admin_panel -e 'SELECT id, site_name, created_at FROM sites ORDER BY created_at DESC LIMIT 3;'"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ DEPLOY DA RECONSTRUÇÃO CONCLUÍDO!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🔨 Reconstrução completa realizada:"
echo "  ✅ index() agora usa Site::orderBy()->get()->map() direto"
echo "  ✅ store() simplificado (sem cache flush, sem headers)"
echo "  ✅ getAllSites() removido completamente"
echo "  ✅ Código igual ao EmailController que FUNCIONA"
echo ""
echo "📋 Comparação com EmailController:"
echo "  ✅ Mesmo padrão de imports"
echo "  ✅ Mesmo padrão de query (Eloquent direto)"
echo "  ✅ Mesmo padrão de map()->toArray()"
echo "  ✅ Mesmo padrão de return view()"
echo ""
echo "🧪 PRÓXIMO PASSO: Teste E2E"
echo "  1. Criar novo site via formulário"
echo "  2. Verificar se site persiste no banco"
echo "  3. Verificar se site APARECE na listagem"
echo ""
