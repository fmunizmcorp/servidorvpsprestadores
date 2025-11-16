# 🔐 INSTRUÇÕES PARA RESETAR CREDENCIAIS DO ADMIN

## ⚠️ SITUAÇÃO ATUAL

- **Problema**: As credenciais do painel admin não estão funcionando
- **Causa**: Possível mudança de senha SSH impediu acesso remoto
- **Solução**: Executar script via console do VPS

---

## 📋 PASSO A PASSO

### **Passo 1: Acessar Console do VPS**

1. Acesse o painel da Hostinger: https://hpanel.hostinger.com/
2. Login com suas credenciais da Hostinger
3. No menu lateral, clique em **VPS**
4. Selecione seu servidor: **srv1131556**
5. Clique no botão **"Browser terminal"** ou **"Console"**
6. Aguarde o console carregar

### **Passo 2: Login no Console**

Quando aparecer o prompt de login:
```
srv1131556 login: _
```

Digite:
- **Usuário**: `root`
- **Senha**: `S0lid@2025VPS!` (ou a senha atual do root)

### **Passo 3: Baixar e Executar o Script**

No console do VPS, execute os comandos abaixo:

```bash
# Baixar o script
cd /root
cat > /root/reset_admin.sh << 'EOFSCRIPT'
#!/bin/bash
cd /opt/webserver/admin-panel || exit 1

# Criar script PHP
cat > /tmp/create_admin.php << 'EOFPHP'
<?php
require_once "/opt/webserver/admin-panel/vendor/autoload.php";
$app = require_once "/opt/webserver/admin-panel/bootstrap/app.php";
$kernel = $app->make("Illuminate\Contracts\Console\Kernel");
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

echo "\n🗑️  Deletando usuários admin antigos...\n";
User::where("email", "LIKE", "%admin%")->delete();

$newEmail = "admin@vps.local";
$newPassword = "VpsAdmin2024!@#$";

echo "\n👤 Criando novo usuário admin...\n";
$user = User::create([
    "name" => "Administrador VPS",
    "email" => $newEmail,
    "password" => Hash::make($newPassword),
    "email_verified_at" => now(),
]);

echo "\n✅ USUÁRIO CRIADO!\n";
echo "📧 EMAIL: " . $user->email . "\n";
echo "🔑 SENHA: " . $newPassword . "\n";
echo "🆔 ID: " . $user->id . "\n";

if (Hash::check($newPassword, $user->password)) {
    echo "✅ Hash validado!\n";
}
EOFPHP

# Executar
php /tmp/create_admin.php

# Limpar caches
php artisan cache:clear
php artisan config:clear

# Reiniciar PHP-FPM
systemctl restart php8.2-fpm

# Salvar credenciais
cat > /root/CREDENCIAIS_ADMIN.txt << 'EOFCRED'
URL:   https://72.61.53.222:8443/login
Email: admin@vps.local
Senha: VpsAdmin2024!@#$
EOFCRED

echo ""
echo "════════════════════════════════════════"
echo "✅ CONCLUÍDO!"
echo "════════════════════════════════════════"
echo ""
cat /root/CREDENCIAIS_ADMIN.txt
echo ""
echo "════════════════════════════════════════"

# Cleanup
rm -f /tmp/create_admin.php
EOFSCRIPT

# Tornar executável
chmod +x /root/reset_admin.sh

# Executar
/root/reset_admin.sh
```

### **Passo 4: Copiar as Credenciais**

Após a execução, você verá algo como:

```
════════════════════════════════════════
✅ CONCLUÍDO!
════════════════════════════════════════

URL:   https://72.61.53.222:8443/login
Email: admin@vps.local
Senha: VpsAdmin2024!@#$

════════════════════════════════════════
```

---

## 🌐 ACESSAR O PAINEL ADMIN

### **URL de Acesso**:
```
https://72.61.53.222:8443/login
```

### **Novas Credenciais**:
- **Email**: `admin@vps.local`
- **Senha**: `VpsAdmin2024!@#$`

### **⚠️ Aviso do Navegador**:
Você verá um aviso sobre certificado SSL não confiável. Isso é normal porque estamos usando certificado autoassinado.

**Para prosseguir**:
- **Chrome/Edge**: Clique em "Avançado" → "Continuar para 72.61.53.222 (não seguro)"
- **Firefox**: Clique em "Avançado" → "Aceitar o risco e continuar"
- **Safari**: Clique em "Mostrar detalhes" → "visitar este site"

---

## 🔐 SOBRE O LET'S ENCRYPT (SSL GRATUITO)

### **Status Atual**:
- ✅ Certbot instalado no servidor
- ⚠️ Certificado autoassinado em uso (causa aviso no navegador)
- ❌ Impossível obter Let's Encrypt com IP

### **Por que não funciona com IP?**
Let's Encrypt requer um **domínio válido** (ex: `meusite.com`). Não funciona com endereço IP (`72.61.53.222`).

### **Para Habilitar Let's Encrypt**:

**Você precisa**:
1. Ter um domínio registrado (ex: `meusite.com`)
2. Apontar o domínio para o IP do VPS: `72.61.53.222`
3. Aguardar propagação DNS (até 48h)

**Depois execute no servidor**:
```bash
# Para domínio principal
certbot --nginx -d meusite.com -d www.meusite.com

# Para admin panel (subdomínio)
certbot --nginx -d admin.meusite.com
```

O certbot irá:
- Validar que você controla o domínio
- Obter certificado SSL gratuito
- Configurar NGINX automaticamente
- Renovar certificado automaticamente (a cada 90 dias)

---

## 🆘 ALTERNATIVA: MÉTODO MANUAL (Se o script falhar)

Se o script automático não funcionar, execute manualmente:

```bash
# 1. Entrar no diretório do Laravel
cd /opt/webserver/admin-panel

# 2. Usar Laravel Tinker
php artisan tinker

# 3. No tinker, execute os comandos abaixo:
\App\Models\User::where("email", "LIKE", "%admin%")->delete();

$user = \App\Models\User::create([
    "name" => "Administrador VPS",
    "email" => "admin@vps.local",
    "password" => \Illuminate\Support\Facades\Hash::make("VpsAdmin2024!@#$"),
    "email_verified_at" => now(),
]);

echo $user->email;

exit

# 4. Limpar caches
php artisan cache:clear
php artisan config:clear

# 5. Reiniciar PHP-FPM
systemctl restart php8.2-fpm
```

---

## 📞 SUPORTE

Se encontrar problemas:

1. **Verificar se PHP-FPM está rodando**:
   ```bash
   systemctl status php8.2-fpm
   ```

2. **Verificar se NGINX está rodando**:
   ```bash
   systemctl status nginx
   ```

3. **Ver logs do Laravel**:
   ```bash
   tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log
   ```

4. **Verificar usuários no banco**:
   ```bash
   cd /opt/webserver/admin-panel
   php artisan tinker
   \App\Models\User::all();
   exit
   ```

---

## ✅ CHECKLIST DE VERIFICAÇÃO

- [ ] Conseguiu acessar o console do VPS
- [ ] Login como root funcionou
- [ ] Script executado sem erros
- [ ] Credenciais exibidas na tela
- [ ] Conseguiu acessar https://72.61.53.222:8443/login
- [ ] Login com admin@vps.local / VpsAdmin2024!@#$ funcionou
- [ ] Painel admin carregou corretamente

---

## 🎯 PRÓXIMOS PASSOS (OPCIONAL)

### **Para SSL sem avisos (Let's Encrypt)**:
1. Registrar um domínio
2. Apontar DNS para 72.61.53.222
3. Executar: `certbot --nginx -d seudominio.com`

### **Para aumentar segurança**:
1. Alterar a senha do admin pelo painel
2. Configurar autenticação de dois fatores (2FA)
3. Restringir acesso ao painel por IP (firewall)

---

**Data**: 2025-11-16
**VPS**: srv1131556.hostinger.com (72.61.53.222)
**Servidor Web**: NGINX + PHP 8.2-FPM
**Framework**: Laravel 11.x
