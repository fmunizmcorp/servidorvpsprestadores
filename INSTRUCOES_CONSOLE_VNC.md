# 🚨 INSTRUÇÕES PASSO-A-PASSO - CONSOLE VNC HOSTINGER

## SITUAÇÃO ATUAL
- ✅ Servidor operacional internamente (NGINX, PHP-FPM, MySQL funcionando)
- ❌ HTTPS retorna **403 Forbidden** quando acessado via IP externo
- ❌ SSH porta 2222 não aceita conexões (autenticação falhando)
- ✅ Firewall local (UFW) está **DESATIVADO** - não há bloqueio de firewall

---

## COMO ACESSAR O CONSOLE VNC

1. Acesse o painel da Hostinger: **https://hpanel.hostinger.com/**
2. Faça login com suas credenciais
3. Vá em **"VPS"** no menu lateral
4. Selecione o servidor **72.61.53.222**
5. Procure por botão **"Console"**, **"VNC Console"** ou **"Browser Console"**
6. Clique para abrir o console no navegador
7. Faça login:
   - **Usuário:** `root`
   - **Senha:** `Jm@D@KDPnw7Q`

---

## OPÇÃO 1: EXECUTAR SCRIPT AUTOMÁTICO (RECOMENDADO)

Após acessar o console VNC, execute estes comandos:

```bash
# 1. Baixar o script de correção
cd /tmp
wget https://raw.githubusercontent.com/SEU_REPO/CORRECAO_RAPIDA_VNC.sh

# OU criar o arquivo manualmente:
cat > /tmp/correcao_rapida.sh << 'EOF'
# (Copie todo o conteúdo do arquivo CORRECAO_RAPIDA_VNC.sh aqui)
EOF

# 2. Dar permissão de execução
chmod +x /tmp/correcao_rapida.sh

# 3. Executar o script
/tmp/correcao_rapida.sh
```

O script irá:
- ✅ Verificar status de todos os serviços
- ✅ Corrigir permissões do DocumentRoot (solução para 403)
- ✅ Recarregar NGINX
- ✅ Reiniciar SSH para ativar porta 2222
- ✅ Verificar fail2ban
- ✅ Mostrar resumo completo

---

## OPÇÃO 2: CORREÇÃO MANUAL (COMANDOS INDIVIDUAIS)

### PASSO 1: Corrigir o 403 Forbidden

```bash
# 1. Ver o erro nos logs
tail -50 /var/log/nginx/error.log | grep -i "403\|forbidden"

# 2. Corrigir permissões (CAUSA MAIS PROVÁVEL)
chown -R www-data:www-data /opt/webserver/admin-panel/public/
chmod -R 755 /opt/webserver/admin-panel/public/

# 3. Recarregar NGINX
systemctl reload nginx

# 4. Testar
curl -k https://72.61.53.222/admin/
```

**Resultado esperado:** HTTP 200 ou 301, NÃO 403

---

### PASSO 2: Ativar SSH Porta 2222

```bash
# 1. Verificar configuração
grep -E '^Port' /etc/ssh/sshd_config

# Deve mostrar:
# Port 22
# Port 2222

# 2. Reiniciar SSH
systemctl restart sshd

# 3. Confirmar que está escutando
ss -tlnp | grep :2222

# Deve mostrar algo como:
# LISTEN  0  128  *:2222  *:*  users:(("sshd",pid=...))
```

---

### PASSO 3: Adicionar Chave SSH (se necessário)

Se a porta 2222 estiver ativa mas você não conseguir conectar da sua máquina:

```bash
# 1. Abrir arquivo de chaves autorizadas
nano /root/.ssh/authorized_keys

# 2. Colar sua chave SSH pública no final do arquivo
# (A chave pública geralmente está em ~/.ssh/id_rsa.pub na SUA máquina)
# Formato: ssh-rsa AAAAB3NzaC1yc2E... seu_email@example.com

# 3. Salvar e sair (Ctrl+O, Enter, Ctrl+X)

# 4. Garantir permissões corretas
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh
```

---

### PASSO 4: Verificar Fail2Ban (se estiver bloqueando)

```bash
# 1. Verificar se fail2ban está ativo
systemctl status fail2ban

# 2. Ver IPs banidos
fail2ban-client status sshd

# 3. Se seu IP estiver banido, desbloquear:
# fail2ban-client set sshd unbanip SEU_IP_AQUI
```

---

## TESTES DE VALIDAÇÃO

### Teste 1: HTTPS Funcionando

```bash
# No console VNC:
curl -k https://72.61.53.222/admin/

# Deve retornar HTML ou redirect 301, NÃO 403
```

**No navegador da sua máquina:**
- Acesse: https://72.61.53.222/admin/
- Deve mostrar a tela de login do admin panel

---

### Teste 2: SSH Porta 2222 Funcionando

```bash
# No console VNC:
ss -tlnp | grep :2222

# Deve mostrar: LISTEN ... *:2222
```

**Na sua máquina local:**
```bash
ssh -p 2222 root@72.61.53.222 "echo 'SSH porta 2222 OK'"
```

---

## DIAGNÓSTICO AVANÇADO (Se nada funcionar)

### Ver configuração completa NGINX:

```bash
nginx -T | less
# Procure por: listen 443 ssl
# Verifique: root /opt/webserver/admin-panel/public;
```

### Ver logs detalhados NGINX:

```bash
tail -100 /var/log/nginx/error.log
tail -100 /var/log/nginx/access.log
```

### Ver configuração completa SSH:

```bash
cat /etc/ssh/sshd_config | grep -v "^#" | grep -v "^$"
```

### Ver logs SSH:

```bash
tail -100 /var/log/auth.log | grep sshd
```

---

## ⚠️ ATENÇÃO - NÃO ATIVE UFW SEM LIBERAR PORTAS!

Se você quiser ativar o firewall UFW, **PRIMEIRO** libere as portas:

```bash
# APENAS se você quiser ativar o firewall:
ufw allow 22/tcp
ufw allow 2222/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

**Atualmente UFW está DESATIVADO** e não é necessário ativá-lo.

---

## 📞 SE NADA FUNCIONAR

Envie as seguintes informações:

```bash
# 1. Status dos serviços
systemctl status nginx php8.3-fpm mysql sshd

# 2. Logs NGINX
tail -50 /var/log/nginx/error.log

# 3. Teste HTTPS local
curl -vk https://127.0.0.1/admin/ 2>&1 | head -30

# 4. Configuração NGINX SSL
nginx -T | grep -A 30 "listen.*443"

# 5. Portas escutando
ss -tlnp | grep -E '(80|443|22|2222)'
```

---

## ✅ SUCESSO - COMO CONFIRMAR

Após executar as correções:

1. ✅ **HTTPS funciona:** https://72.61.53.222/admin/ carrega no navegador
2. ✅ **SSH porta 2222 aceita conexões:** `ssh -p 2222 root@72.61.53.222`
3. ✅ **Admin panel acessível:** Login com test@admin.local / Test@123456

---

**Preparado por:** GenSpark AI Developer  
**Data:** 20/11/2025  
**Versão:** 1.0
