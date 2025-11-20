# 🚀 INSTRUÇÕES DE DEPLOY MANUAL - SPRINT 22

## ⚠️ IMPORTANTE: LEIA ANTES DE COMEÇAR

O relatório de validação confirmou que **AS CORREÇÕES DO SPRINT 21 NÃO FORAM DEPLOYADAS**.

Este documento contém instruções **PASSO A PASSO** para fazer o deploy completo.

---

## OPÇÃO 1: DEPLOY AUTOMÁTICO (RECOMENDADO)

### Passo 1: Copiar Script para o VPS

```bash
# No seu computador local
scp DEPLOY_COMPLETO_SPRINT22.sh root@72.61.53.222:/root/
```

###Passo 2: Executar no VPS

```bash
ssh root@72.61.53.222
cd /root
bash DEPLOY_COMPLETO_SPRINT22.sh
```

O script vai:
1. ✅ Fazer backup dos arquivos atuais
2. ✅ Deploy do EmailController.php com sudo
3. ✅ Configurar permissões sudo para www-data
4. ✅ Limpar cache do Laravel
5. ✅ Verificar se tudo está correto

---

## OPÇÃO 2: DEPLOY MANUAL (SE OPÇÃO 1 FALHAR)

### Passo 1: Acessar o VPS

```bash
ssh root@72.61.53.222
# Senha: Estrela@2025*
```

### Passo 2: Fazer Backup

```bash
mkdir -p /opt/webserver/backups/sprint22_manual
cp /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php \
   /opt/webserver/backups/sprint22_manual/
```

### Passo 3: Editar EmailController.php

```bash
nano /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php
```

**Alterações necessárias:**

**LINHA 60** - Método `storeDomain()`:
```php
// ANTES:
$command = "bash $script $domain 2>&1";

// DEPOIS:
$command = "sudo bash $script $domain 2>&1";
```

**LINHA 135** - Método `storeAccount()`:
```php
// ANTES:
$command = "bash $script " . escapeshellarg($domain) . " " .

// DEPOIS:
$command = "sudo bash $script " . escapeshellarg($domain) . " " .
```

**Salvar:** `Ctrl+O`, `Enter`, `Ctrl+X`

### Passo 4: Configurar Permissões Sudo

```bash
cat > /etc/sudoers.d/webserver-scripts << 'EOFSUDOERS'
# Permissões para www-data executar scripts
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email-domain.sh
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email.sh
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/wrappers/create-site-wrapper.sh
EOFSUDOERS

chmod 440 /etc/sudoers.d/webserver-scripts
```

### Passo 5: Limpar Cache Laravel

```bash
cd /opt/webserver/admin-panel
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
```

### Passo 6: Verificar Deploy

```bash
# Verificar se 'sudo bash' está presente:
grep -n "sudo bash" /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php

# Deve mostrar:
# 60:            $command = "sudo bash $script $domain 2>&1";
# 135:            $command = "sudo bash $script " . escapeshellarg($domain) . " " .
```

```bash
# Verificar permissões sudo:
cat /etc/sudoers.d/webserver-scripts

# Deve mostrar:
# www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email-domain.sh
# www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email.sh
# ...
```

---

## PASSO 7: TESTAR APÓS DEPLOY

### Teste 1: Email Domain Creation

1. Acesse: http://72.61.53.222/admin/email/domains
2. Login: test@admin.local / Test@123456
3. Click "Create Domain"
4. Domain: `sprint22validacao.local`
5. Submit

**Verificar no VPS:**
```bash
grep sprint22validacao.local /etc/postfix/virtual_domains
# Esperado: sprint22validacao.local OK
```

### Teste 2: Email Account Creation

1. Acesse: http://72.61.53.222/admin/email/accounts
2. Selecione: sprint22validacao.local
3. Click "Create Account"
4. Username: testuser
5. Password: Test@123456
6. Submit

**Verificar no VPS:**
```bash
grep testuser@sprint22validacao.local /etc/postfix/virtual_mailbox_maps
# Esperado: testuser@sprint22validacao.local sprint22validacao.local/testuser/
```

### Teste 3: Site Creation

1. Acesse: http://72.61.53.222/admin/sites/create
2. Name: sprint22site
3. Domain: sprint22site.local
4. PHP: 8.3
5. Database: Yes
6. Submit
7. **Aguardar 2-3 minutos** (processo em background)

**Verificar no VPS:**
```bash
ls -la /opt/webserver/sites/ | grep sprint22site
# Esperado: drwxr-xr-x ... sprint22site
```

---

## TROUBLESHOOTING

### Problema 1: "sudo bash" não funciona

**Verificar:**
```bash
sudo -u www-data sudo -l
```

**Deve mostrar:**
```
User www-data may run the following commands:
    (ALL) NOPASSWD: /opt/webserver/scripts/create-email-domain.sh
    (ALL) NOPASSWD: /opt/webserver/scripts/create-email.sh
    ...
```

**Se não aparecer:**
```bash
# Recriar arquivo sudoers
cat > /etc/sudoers.d/webserver-scripts << 'EOF'
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email-domain.sh
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email.sh
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/wrappers/create-site-wrapper.sh
