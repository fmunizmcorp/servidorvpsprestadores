#!/bin/bash
################################################################################
# SCRIPT PARA RESETAR CREDENCIAIS DO PAINEL ADMIN
# Execute este script via console do VPS (Hostinger hpanel)
################################################################################

echo "════════════════════════════════════════════════════════════"
echo "🔐 RESET DE CREDENCIAIS DO PAINEL ADMIN"
echo "════════════════════════════════════════════════════════════"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se está executando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Este script precisa ser executado como root${NC}"
   exit 1
fi

echo -e "${YELLOW}📍 Passo 1: Navegando para diretório do Laravel...${NC}"
cd /opt/webserver/admin-panel || exit 1
echo -e "${GREEN}✅ Diretório: $(pwd)${NC}"
echo ""

echo -e "${YELLOW}📍 Passo 2: Criando script PHP temporário...${NC}"
cat > /tmp/create_admin.php << 'EOFPHP'
<?php
require_once "/opt/webserver/admin-panel/vendor/autoload.php";

$app = require_once "/opt/webserver/admin-panel/bootstrap/app.php";
$kernel = $app->make("Illuminate\Contracts\Console\Kernel");
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

echo "\n🔍 Verificando usuários existentes...\n";
$existingUsers = User::all();
echo "Total de usuários: " . $existingUsers->count() . "\n";

foreach ($existingUsers as $user) {
    echo "  - " . $user->email . " (ID: " . $user->id . ")\n";
}

echo "\n🗑️  Deletando usuários admin antigos...\n";
$deleted = User::where("email", "LIKE", "%admin%")->delete();
echo "Deletados: $deleted usuário(s)\n";

$newEmail = "admin@vps.local";
$newPassword = "VpsAdmin2024!@#$";

echo "\n👤 Criando novo usuário admin...\n";
$user = User::create([
    "name" => "Administrador VPS",
    "email" => $newEmail,
    "password" => Hash::make($newPassword),
    "email_verified_at" => now(),
]);

echo "\n✅ USUÁRIO CRIADO COM SUCESSO!\n\n";
echo "═══════════════════════════════════════════════════════════\n";
echo "📧 EMAIL:    " . $user->email . "\n";
echo "🔑 SENHA:    " . $newPassword . "\n";
echo "📛 NOME:     " . $user->name . "\n";
echo "🆔 ID:       " . $user->id . "\n";
echo "═══════════════════════════════════════════════════════════\n";

// Verificar hash
echo "\n🔐 Verificando hash da senha...\n";
if (Hash::check($newPassword, $user->password)) {
    echo "✅ Hash validado corretamente!\n";
} else {
    echo "❌ ERRO: Hash não valida!\n";
}

echo "\n✨ PROCESSO CONCLUÍDO!\n\n";
EOFPHP

echo -e "${GREEN}✅ Script criado em /tmp/create_admin.php${NC}"
echo ""

echo -e "${YELLOW}📍 Passo 3: Executando script PHP...${NC}"
php /tmp/create_admin.php
RESULT=$?
echo ""

if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Script executado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro ao executar script (código: $RESULT)${NC}"
    echo ""
    echo -e "${YELLOW}Tentando método alternativo com Artisan Tinker...${NC}"
    
    php artisan tinker << 'TINKER'
\App\Models\User::where("email", "LIKE", "%admin%")->delete();
$user = \App\Models\User::create([
    "name" => "Administrador VPS",
    "email" => "admin@vps.local",
    "password" => \Illuminate\Support\Facades\Hash::make("VpsAdmin2024!@#$"),
    "email_verified_at" => now(),
]);
echo "✅ Usuário criado: " . $user->email . " (ID: " . $user->id . ")\n";
exit
TINKER
fi

echo ""
echo -e "${YELLOW}📍 Passo 4: Limpando caches do Laravel...${NC}"
php artisan cache:clear
php artisan config:clear
php artisan view:clear
php artisan route:clear
echo -e "${GREEN}✅ Caches limpos!${NC}"
echo ""

echo -e "${YELLOW}📍 Passo 5: Reiniciando PHP-FPM...${NC}"
systemctl restart php8.2-fpm
echo -e "${GREEN}✅ PHP-FPM reiniciado!${NC}"
echo ""

echo -e "${YELLOW}📍 Passo 6: Salvando credenciais em arquivo...${NC}"
cat > /root/NOVAS-CREDENCIAIS-ADMIN.txt << 'EOFCRED'
════════════════════════════════════════════════════════════
🔐 CREDENCIAIS DO PAINEL ADMIN - VPS
════════════════════════════════════════════════════════════

🌐 URL DE ACESSO:
   https://72.61.53.222:8443/login
   (Aceitar o aviso de certificado autoassinado)

👤 CREDENCIAIS:
   Email:    admin@vps.local
   Senha:    VpsAdmin2024!@#$

📝 NOTAS:
   - Certificado SSL é autoassinado (aviso no navegador é normal)
   - Para Let's Encrypt, é necessário um domínio válido
   - Porta HTTPS: 8443
   - Porta HTTP: 8080 (redireciona para HTTPS)

📅 Data de Criação: $(date '+%Y-%m-%d %H:%M:%S')
════════════════════════════════════════════════════════════
EOFCRED

chmod 600 /root/NOVAS-CREDENCIAIS-ADMIN.txt
echo -e "${GREEN}✅ Credenciais salvas em: /root/NOVAS-CREDENCIAIS-ADMIN.txt${NC}"
echo ""

echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ PROCESSO CONCLUÍDO COM SUCESSO!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 SUAS NOVAS CREDENCIAIS:"
echo ""
echo "🌐 URL:    https://72.61.53.222:8443/login"
echo "📧 Email:  admin@vps.local"
echo "🔑 Senha:  VpsAdmin2024!@#$"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Cleanup
rm -f /tmp/create_admin.php

exit 0
