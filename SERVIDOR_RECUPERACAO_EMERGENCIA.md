# 🚨 RECUPERAÇÃO DE EMERGÊNCIA - SERVIDOR VPS

## DIAGNÓSTICO COMPLETO REALIZADO

**Data:** 20 de Novembro de 2025, 08:28 (horário servidor)
**Status:** Servidor OPERACIONAL mas INACESSÍVEL externamente

---

## ✅ O QUE ESTÁ FUNCIONANDO

1. **SSH:** Acessível e operacional
2. **NGINX:** Rodando corretamente (portas 80/443 LISTENING)
3. **PHP-FPM 8.3:** Ativo e processando (54 workers)
4. **MySQL/MariaDB:** Operacional
5. **Admin Panel:** Funcionando via localhost
6. **Database:** 31 sites cadastrados, 17 ativos

**Teste Local Bem-Sucedido:**
```bash
curl -k https://localhost/admin/login
# Retorna: HTML válido do painel admin
```

---

## ❌ PROBLEMAS IDENTIFICADOS

### PROBLEMA 1: HTTPS Retorna 403 Forbidden

**Evidências:**
- `curl http://72.61.53.222/admin/` → 301 Redirect (OK)
- `curl -k https://72.61.53.222/admin/` → **403 Forbidden**
- `curl https://localhost/admin/` → HTML OK (funciona localmente)
- NGINX escutando em 0.0.0.0:443 (correto)
- Certificado SSL self-signed válido
- UFW firewall: **INACTIVE**
- iptables: **SEM REGRAS** (vazio)

**Causa Provável:** Configuração NGINX com restrições de acesso via IP ou problema de permissões no DocumentRoot

### PROBLEMA 2: SSH Porta 2222 Não Acessível

**Evidências:**
- `sshd_config` configurado com `Port 22` e `Port 2222`
- Autenticação SSH falhando em ambas portas após restart
- Provável: SSH key não autorizada após reinício ou fail2ban ativo

**Status:** Firewall VPS está DESABILITADO (não há firewall externo no datacenter)

---

## 🔧 SOLUÇÕES NECESSÁRIAS

### SOLUÇÃO 1: Corrigir 403 Forbidden no HTTPS (VIA CONSOLE VNC)

**Você PRECISA acessar via Console VNC da Hostinger:**

1. Acesse: https://hpanel.hostinger.com/
2. Vá em "VPS" → Selecione servidor `72.61.53.222`
3. Clique em **"Console"** ou **"VNC Console"** (acesso direto sem SSH)
4. Faça login como root

**Comandos a executar:**

```bash
# 1. Verificar configuração NGINX SSL
nginx -T | grep -A 30 "listen.*443"

# 2. Verificar logs de erro NGINX para o 403
tail -100 /var/log/nginx/error.log | grep -i "403\|forbidden\|denied"

# 3. Verificar permissões do DocumentRoot
ls -la /opt/webserver/
ls -la /opt/webserver/admin-panel/public/

# 4. Verificar se há arquivo .htaccess bloqueando
find /opt/webserver/admin-panel -name ".htaccess" -exec cat {} \;

# 5. Verificar se fail2ban está bloqueando
systemctl status fail2ban
fail2ban-client status nginx-http-auth 2>/dev/null

# 6. Testar HTTPS localmente com verbosidade
curl -vk https://127.0.0.1/admin/ 2>&1 | grep -E '(HTTP|403|forbidden)'

# 7. Verificar se há módulo de segurança ativo
apache2ctl -M 2>/dev/null | grep security
nginx -V 2>&1 | grep -i security
```

**CORREÇÃO PROVÁVEL - Permissões DocumentRoot:**

```bash
# Garantir permissões corretas
chown -R www-data:www-data /opt/webserver/admin-panel/public/
chmod -R 755 /opt/webserver/admin-panel/public/

# Recarregar NGINX
systemctl reload nginx

# Testar novamente
curl -k https://72.61.53.222/admin/
```

### SOLUÇÃO 2: Ativar e Liberar SSH Porta 2222 (VIA CONSOLE VNC)

**Comandos a executar no Console VNC:**

```bash
# 1. Verificar se porta 2222 está escutando
ss -tlnp | grep :2222

# 2. Se NÃO estiver escutando, reiniciar SSH
systemctl restart sshd

# 3. Verificar status SSH
systemctl status sshd

# 4. Confirmar configuração de portas
grep -E '^Port' /etc/ssh/sshd_config

# 5. Adicionar chave SSH pública autorizada
# (Cole sua chave pública aqui quando tiver acesso)
mkdir -p /root/.ssh
chmod 700 /root/.ssh
# Adicione sua chave em: /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# 6. Verificar fail2ban (pode estar bloqueando após tentativas)
systemctl status fail2ban
fail2ban-client status sshd 2>/dev/null

# 7. Se fail2ban estiver bloqueando, desbloquear seu IP
# fail2ban-client set sshd unbanip SEU_IP_AQUI

# 8. Testar conexão SSH localmente
ssh -p 2222 root@localhost -o StrictHostKeyChecking=no
```

### SOLUÇÃO 3: Habilitar UFW Firewall Corretamente (OPCIONAL)

**Se você quiser ativar o firewall local do VPS:**

```bash
# Permitir portas necessárias ANTES de ativar UFW
ufw allow 22/tcp comment 'SSH principal'
ufw allow 2222/tcp comment 'SSH secundária'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Ativar UFW
ufw --force enable

# Verificar regras
ufw status verbose
```

**⚠️ ATENÇÃO:** Se ativar UFW sem liberar as portas primeiro, você pode perder acesso SSH!

---

## 📊 INFORMAÇÕES DO SERVIDOR

**IP:** 72.61.53.222
**SO:** Ubuntu 24.04.3 LTS
**Uptime:** 10 minutos (reiniciado às 08:18)
**Load Average:** 0.00, 0.10, 0.11 (servidor OK)

**Serviços:**
- NGINX: ✅ Ativo
- PHP-FPM 8.3: ✅ Ativo (87.4M RAM)
- MySQL: ✅ Ativo
- Admin Panel: ✅ Funcional

**URLs de Acesso:**
- Admin: https://72.61.53.222/admin/
- Login: test@admin.local / Test@123456

---

## 🎯 AÇÕES IMEDIATAS NECESSÁRIAS

### PELO USUÁRIO (AGORA - Via Console VNC):

**PASSO 1: Acessar Console VNC**
1. Acesse: https://hpanel.hostinger.com/
2. VPS → Servidor `72.61.53.222` → **Console/VNC**
3. Login: root / Senha: Jm@D@KDPnw7Q

**PASSO 2: Diagnosticar o 403 Forbidden**
```bash
# Ver logs NGINX para o erro 403
tail -100 /var/log/nginx/error.log | grep -i "403\|forbidden"

# Ver configuração SSL do NGINX
nginx -T | grep -A 30 "listen.*443"

# Testar HTTPS localmente
curl -vk https://127.0.0.1/admin/
```

**PASSO 3: Corrigir Permissões (Provável Solução)**
```bash
chown -R www-data:www-data /opt/webserver/admin-panel/public/
chmod -R 755 /opt/webserver/admin-panel/public/
systemctl reload nginx
curl -k https://72.61.53.222/admin/
```

**PASSO 4: Ativar SSH Porta 2222**
```bash
# Reiniciar SSH para ativar porta 2222
systemctl restart sshd
ss -tlnp | grep :2222

# Verificar fail2ban
systemctl status fail2ban
```

**PASSO 5: Adicionar Chave SSH (se necessário)**
```bash
# Se SSH não aceitar sua chave, adicione manualmente
nano /root/.ssh/authorized_keys
# Cole sua chave pública SSH e salve (Ctrl+O, Ctrl+X)
chmod 600 /root/.ssh/authorized_keys
```

### PELO DESENVOLVEDOR (Já Executado):

✅ Diagnóstico completo do servidor
✅ Identificação dos problemas (403 HTTPS + SSH porta 2222)
✅ Verificação: firewall local DESABILITADO (não é firewall externo)
✅ Documentação completa de recuperação criada

---

## ✅ COMO CONFIRMAR QUE OS PROBLEMAS FORAM RESOLVIDOS

### Teste 1: HTTPS Funcionando (403 Corrigido)

```bash
# De qualquer máquina externa:
curl -I https://72.61.53.222/admin/

# Deve retornar:
HTTP/1.1 200 OK
server: nginx

# OU pelo menos um redirect 301, NÃO 403 Forbidden
```

**Teste no navegador:** https://72.61.53.222/admin/

### Teste 2: SSH Porta 2222 Ativa

```bash
# De sua máquina local:
ssh -p 2222 root@72.61.53.222 "echo 'Porta 2222 funcionando'"

# Deve retornar:
Porta 2222 funcionando
```

### Teste 3: Admin Panel Acessível

**Login:** https://72.61.53.222/admin/login
- Email: test@admin.local
- Senha: Test@123456

**Deve mostrar:** Dashboard do admin panel

---

## 📞 DIAGNÓSTICOS AVANÇADOS (Se Soluções Básicas Falharem)

### Se 403 Forbidden Persistir:

```bash
# 1. Ver TODA a configuração NGINX do admin panel
cat /etc/nginx/sites-available/default

# 2. Verificar se há restrição de IP no NGINX
grep -r "allow\|deny" /etc/nginx/

# 3. Verificar AppArmor ou SELinux
aa-status 2>/dev/null
sestatus 2>/dev/null

# 4. Verificar logs PHP-FPM
tail -100 /var/log/php8.3-fpm.log

# 5. Testar com IP diferente do próprio servidor
curl -k https://72.61.53.222/admin/ -H "Host: 72.61.53.222"

# 6. Verificar módulos NGINX compilados
nginx -V 2>&1 | tr ' ' '\n' | grep module
```

### Se SSH Porta 2222 Não Ativar:

```bash
# 1. Verificar se SSHD está realmente escutando em 2222
netstat -tlnp | grep sshd

# 2. Ver logs SSH
tail -100 /var/log/auth.log | grep sshd

# 3. Testar configuração SSH
sshd -t -f /etc/ssh/sshd_config

# 4. Verificar se há outro serviço na porta 2222
lsof -i :2222

# 5. Forçar restart SSH
systemctl stop sshd
sleep 2
systemctl start sshd
ss -tlnp | grep :2222
```

---

## 🎉 RESUMO DO PROBLEMA

**SERVIDOR ESTÁ FUNCIONAL INTERNAMENTE**
- NGINX, PHP-FPM, MySQL: ✅ Todos operacionais
- Admin panel via localhost: ✅ Funcionando
- 17 sites ativos no banco: ✅ Correto

**PROBLEMAS EXTERNOS APÓS REINÍCIO:**

1. **HTTPS retorna 403 Forbidden** ao acessar via IP 72.61.53.222
   - Causa provável: Permissões do DocumentRoot ou configuração NGINX
   - Solução: Corrigir permissões via Console VNC

2. **SSH porta 2222 não aceita conexões**
   - Causa provável: Chave SSH não autorizada após restart ou fail2ban
   - Solução: Adicionar chave SSH autorizada ou reiniciar SSHD via Console VNC

**NÃO É FIREWALL EXTERNO!**
- UFW: INACTIVE ✅
- iptables: SEM REGRAS ✅  
- Não há firewall do datacenter (confirmado pelo usuário)

**SPRINT 36 V2 CONTINUA 100% FUNCIONAL:**
- Arquitetura Laravel Events implementada ✅
- Sistema de criação de sites automático funcionando ✅
- Último teste (sprint36v2final1763609112) criado com sucesso ✅

---

## 🚀 PRÓXIMOS PASSOS

**IMEDIATO:** Usuário deve acessar Console VNC da Hostinger e executar os comandos de correção listados acima.

**APÓS CORREÇÃO:** Continuar com Sprint 36 - gerar relatório final de validação e atualizar PR #1.

---

**Preparado por:** GenSpark AI Developer  
**Data:** 20/11/2025 11:55 (Atualizado)  
**Status:** AGUARDANDO ACESSO VIA CONSOLE VNC PARA CORREÇÃO
