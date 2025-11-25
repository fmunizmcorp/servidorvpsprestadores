#!/bin/bash
################################################################################
# Script de Limpeza Completa de Cache - Sistema VPS Admin
# Deve ser executado após cada deploy ou quando sites não aparecerem na UI
################################################################################

set -e

echo "=========================================="
echo "LIMPEZA COMPLETA DE CACHE"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar se estamos no diretório correto
if [ ! -f "artisan" ]; then
    echo "❌ Erro: Este script deve ser executado no diretório raiz do Laravel"
    echo "   Diretório esperado: /opt/webserver/admin-panel"
    exit 1
fi

echo "📦 FASE 1: Limpeza Laravel Artisan"
echo "-----------------------------------"
php artisan optimize:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
php artisan clear-compiled
echo -e "${GREEN}✅ Caches Laravel limpos${NC}"
echo ""

echo "📁 FASE 2: Limpeza Manual de Arquivos"
echo "---------------------------------------"
rm -rf storage/framework/views/* 2>/dev/null && echo "✓ Views compiladas removidas" || echo "⚠ Views já limpas"
rm -rf storage/framework/cache/* 2>/dev/null && echo "✓ Cache application removido" || echo "⚠ Cache já limpo"
rm -rf bootstrap/cache/*.php 2>/dev/null && echo "✓ Bootstrap cache removido" || echo "⚠ Bootstrap já limpo"
echo -e "${GREEN}✅ Arquivos de cache removidos${NC}"
echo ""

echo "🔄 FASE 3: Reiniciar Serviços"
echo "-------------------------------"

# Detectar versão PHP automaticamente
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
PHP_SERVICE="php${PHP_VERSION}-fpm"

echo "Reiniciando $PHP_SERVICE..."
systemctl restart "$PHP_SERVICE" && echo "✓ PHP-FPM reiniciado" || echo "❌ Falha ao reiniciar PHP-FPM"

echo "Recarregando NGINX..."
nginx -s reload && echo "✓ NGINX recarregado" || echo "❌ Falha ao recarregar NGINX"

echo -e "${GREEN}✅ Serviços reiniciados${NC}"
echo ""

echo "🧪 FASE 4: Verificação"
echo "-----------------------"

# Verificar se artisan funciona
php artisan --version > /dev/null 2>&1 && echo "✓ Laravel artisan OK" || echo "❌ Laravel artisan com erro"

# Verificar sites no banco (se tabela existir)
SITE_COUNT=$(php artisan tinker --execute='echo App\Models\Site::count();' 2>/dev/null | tail -1)
if [ ! -z "$SITE_COUNT" ]; then
    echo "✓ Sites no banco de dados: $SITE_COUNT"
else
    echo "⚠ Não foi possível verificar sites (model pode não existir)"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ LIMPEZA COMPLETA FINALIZADA!${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}📝 PRÓXIMOS PASSOS:${NC}"
echo "1. Acesse o admin panel no navegador"
echo "2. Pressione CTRL+F5 (force reload)"
echo "3. Verifique se todas as listagens aparecem corretamente"
echo ""
echo "💡 DICA: Execute este script sempre que:"
echo "   - Fizer deploy de código novo"
echo "   - Sites não aparecerem na listagem"
echo "   - Encontrar dados antigos/obsoletos na UI"
echo ""
