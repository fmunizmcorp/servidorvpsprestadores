#!/bin/bash
set -e

echo "========================================="
echo "DEPLOY SPRINT 21 - EmailController Fix"
echo "========================================="
echo ""

VPS_IP="72.61.53.222"
VPS_USER="root"
VPS_PASSWORD="Estrela@2025*"
TARGET_PATH="/opt/webserver/admin-panel/app/Http/Controllers/"

echo "📁 Preparando arquivo para deploy..."
if [ ! -f "EmailController.php" ]; then
    echo "❌ ERRO: EmailController.php não encontrado!"
    exit 1
fi

echo "✅ EmailController.php encontrado"
echo ""

echo "🚀 Fazendo backup do arquivo atual no VPS..."
sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP \
    "cp $TARGET_PATH/EmailController.php $TARGET_PATH/EmailController.php.backup_sprint21_$(date +%Y%m%d_%H%M%S) 2>&1" || true

echo ""
echo "📤 Enviando EmailController.php corrigido para VPS..."
sshpass -p "$VPS_PASSWORD" scp -o StrictHostKeyChecking=no \
    EmailController.php $VPS_USER@$VPS_IP:$TARGET_PATH/EmailController.php

echo ""
echo "🔍 Verificando arquivo deployed..."
sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP \
    "grep -n 'sudo bash' $TARGET_PATH/EmailController.php | head -5"

echo ""
echo "🔄 Limpando cache do Laravel..."
sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP << 'ENDSSH'
cd /opt/webserver/admin-panel
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
echo "✅ Cache limpo"
ENDSSH

echo ""
echo "🔧 Verificando permissões sudo para www-data..."
sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP << 'ENDSSH'
echo "Verificando /etc/sudoers.d/ para www-data..."
if grep -q "www-data.*create-email" /etc/sudoers.d/* 2>/dev/null; then
    echo "✅ Permissões sudo para scripts de email ENCONTRADAS"
    grep "www-data.*create-email" /etc/sudoers.d/* 2>/dev/null | head -5
else
    echo "⚠️  AVISO: Permissões sudo podem precisar ser configuradas"
    echo "Verificando sudoers principal..."
    grep "www-data" /etc/sudoers 2>/dev/null || echo "Nenhuma regra www-data em /etc/sudoers"
fi
ENDSSH

echo ""
echo "========================================="
echo "✅ DEPLOY SPRINT 21 COMPLETO!"
echo "========================================="
echo ""
echo "📋 Próximos passos:"
echo "1. Testar formulário Create Email Domain"
echo "2. Testar formulário Create Email Account"
echo "3. Verificar dados em /etc/postfix/virtual_domains"
echo "4. Verificar dados em /etc/postfix/virtual_mailbox_maps"
echo ""
echo "🔗 Pull Request: https://github.com/fmunizmcorp/servidorvpsprestadores/pull/1"
echo ""
