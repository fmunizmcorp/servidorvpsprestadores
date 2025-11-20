# 🚀 INSTRUÇÕES DE DEPLOY MANUAL - SPRINT 21

## ✅ CORREÇÃO APLICADA
**EmailController.php** - Adicionado `sudo` aos comandos bash

## 📋 PASSOS PARA DEPLOY

### 1. Fazer Backup do Arquivo Atual
```bash
ssh root@72.61.53.222
cd /opt/webserver/admin-panel/app/Http/Controllers/
cp EmailController.php EmailController.php.backup_sprint21
```

### 2. Atualizar Arquivo no VPS
**Opção A - Via SCP (se SSH funcionar):**
```bash
scp EmailController.php root@72.61.53.222:/opt/webserver/admin-panel/app/Http/Controllers/
```

**Opção B - Via Editor Manual:**
1. Acesse o VPS: `ssh root@72.61.53.222`
2. Edite o arquivo: `nano /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php`
3. Localize linha 60 e altere:
   ```php
   // ANTES:
   $command = "bash $script $domain 2>&1";
   
   // DEPOIS:
   $command = "sudo bash $script $domain 2>&1";
   ```
4. Localize linha 135 e altere:
   ```php
   // ANTES:
   $command = "bash $script " . escapeshellarg($domain) . " " . 
   
   // DEPOIS:
   $command = "sudo bash $script " . escapeshellarg($domain) . " " .
   ```
5. Salve: `Ctrl+O`, `Enter`, `Ctrl+X`

### 3. Verificar Correções Aplicadas
```bash
grep -n "sudo bash" /opt/webserver/admin-panel/app/Http/Controllers/EmailController.php
```
**Saída esperada:**
```
60:            $command = "sudo bash $script $domain 2>&1";
135:            $command = "sudo bash $script " . escapeshellarg($domain) . " " .
```

### 4. Limpar Cache do Laravel
```bash
cd /opt/webserver/admin-panel
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
```

### 5. Verificar Permissões Sudo
```bash
# Verificar se www-data tem permissão para executar scripts
grep -r "www-data" /etc/sudoers /etc/sudoers.d/ 2>/dev/null
```

**Se não houver regras, adicionar:**
```bash
echo "www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email-domain.sh" >> /etc/sudoers.d/webserver-scripts
echo "www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/create-email.sh" >> /etc/sudoers.d/webserver-scripts
chmod 440 /etc/sudoers.d/webserver-scripts
```

## 🧪 TESTAR CORREÇÕES

### Teste 1: Email Domain
1. Acesse: http://72.61.53.222/admin/email/domains
2. Login: test@admin.local / Test@123456
3. Clique "Create Domain"
4. Insira: `sprint21test.local`
5. Submit

**Verificar persistência:**
```bash
grep sprint21test.local /etc/postfix/virtual_domains
```

### Teste 2: Email Account
1. Acesse: http://72.61.53.222/admin/email/accounts
2. Selecione domínio criado
3. Clique "Create Account"
4. Username: testuser
5. Password: Test@123456
6. Submit

**Verificar persistência:**
```bash
grep testuser@sprint21test.local /etc/postfix/virtual_mailbox_maps
```

## 📊 RESULTADO ESPERADO
✅ HTTP 302 redirect após submit
✅ Dados aparecem em /etc/postfix/virtual_domains
✅ Dados aparecem em /etc/postfix/virtual_mailbox_maps
✅ Mensagem de sucesso no admin panel

## 🔗 LINKS
- Pull Request: https://github.com/fmunizmcorp/servidorvpsprestadores/pull/1
- Documentação: SPRINT_21_PLANO.md
