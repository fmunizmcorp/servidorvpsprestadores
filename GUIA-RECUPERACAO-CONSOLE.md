# 🚨 GUIA DE RECUPERAÇÃO DE EMERGÊNCIA - SERVIDOR INACESSÍVEL

## ⚠️ SITUAÇÃO ATUAL

**PROBLEMA:** Servidor **72.61.53.222** completamente inacessível

- ❌ Ping não responde
- ❌ SSH não funciona (portas 22 e 2222)
- ❌ Painel admin não carrega (portas 8080 e 8443)
- ❌ Nenhuma porta responde

**CAUSA PROVÁVEL:** UFW Firewall bloqueou tudo ou serviços travaram durante o script anterior

---

## 🔧 SOLUÇÃO: VIA CONSOLE DO PROVEDOR VPS

**⚠️ IMPORTANTE:** Como SSH não funciona, você **DEVE** usar o **CONSOLE** do provedor VPS.

---

## 📋 PASSO A PASSO DETALHADO

### **PASSO 1: Acessar Console do Provedor VPS**

**Onde encontrar o console:**

- **Se seu provedor é Contabo:** Painel → Servers → [Seu servidor] → Botão **"VNC Console"** ou **"noVNC"**
- **Se é DigitalOcean:** Dashboard → Droplets → [Seu droplet] → Botão **"Console"** (canto superior direito)
- **Se é Vultr:** Dashboard → Instances → [Sua instância] → Tab **"Console"**
- **Se é OVH:** Manager → VPS → [Seu VPS] → Tab **"Console KVM"**
- **Se é AWS/Lightsail:** Dashboard → Instances → [Sua instância] → Botão **"Connect"** → **"Browser-based SSH"**
- **Se é Hetzner Cloud:** Console → Servers → [Seu servidor] → Botão **"Console"**

**O que procurar:**
- Botão chamado: "Console", "VNC", "noVNC", "Terminal", "KVM Console"
- Geralmente abre uma nova janela/aba com terminal

---

### **PASSO 2: Fazer Login no Console**

Quando o console abrir, você verá uma tela de login:

```
Ubuntu 22.04 LTS servidor-hostname tty1

servidor-hostname login: _
```

**Digite:**

```
root
```

**Pressione ENTER**

```
Password: _
```

**Digite a senha (NÃO vai aparecer na tela):**

```
Jm@D@KDPnw7Q
```

**Pressione ENTER**

Você deve ver algo como:

```
root@servidor-hostname:~#
```

✅ **Você está logado!**

---

### **PASSO 3: Executar Script de Recuperação**

**MÉTODO A: Copiar e Colar (RECOMENDADO se o console permite)**

1. Abra este arquivo no GitHub:
   ```
   https://github.com/fmunizmcorp/servidorvpsprestadores/blob/main/SCRIPT-RECUPERACAO-EMERGENCIA.sh
   ```

2. Clique em "Raw" (canto superior direito)

3. Copie **TODO** o conteúdo (Ctrl+A, Ctrl+C)

4. No console do servidor, cole o conteúdo:
   ```bash
   cat > /root/recuperacao.sh << 'EOFSCRIPT'
   # Cole AQUI todo o conteúdo do script (Ctrl+Shift+V ou botão direito)
   EOFSCRIPT
   ```

5. Torne executável e execute:
   ```bash
   chmod +x /root/recuperacao.sh
   bash /root/recuperacao.sh
   ```

---

**MÉTODO B: Comandos Diretos (se copiar/colar não funciona)**

Execute os comandos abaixo **UM POR UM** no console:

#### **1. Desabilitar UFW imediatamente**

```bash
ufw --force disable
```

**Você deve ver:**
```
Firewall stopped and disabled on system startup
```

✅ **CRÍTICO:** Se o servidor estava bloqueado pelo UFW, ele já deve estar acessível agora!

---

#### **2. Verificar e reiniciar SSH**

```bash
# Verificar se SSH está rodando
systemctl status sshd

# Se não estiver ativo, reiniciar
systemctl restart sshd

# Verificar portas SSH
ss -tlnp | grep sshd
```

**Você deve ver portas 22 e/ou 2222 escutando**

---

#### **3. Verificar e reiniciar NGINX**

```bash
# Testar configuração
nginx -t

# Se OK, reiniciar
systemctl restart nginx

# Verificar status
systemctl status nginx

# Verificar portas
ss -tlnp | grep nginx
```

**Você deve ver portas 80, 443, 8080, 8443 escutando**

---

#### **4. Reconfigurar UFW corretamente**

```bash
# Resetar UFW
ufw --force reset

# Configurar política padrão
ufw default deny incoming
ufw default allow outgoing

# Liberar TODAS as portas necessárias
ufw allow 22/tcp
ufw allow 2222/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
ufw allow 8443/tcp
ufw allow 25/tcp
ufw allow 587/tcp
ufw allow 993/tcp
ufw allow 995/tcp

# Permitir ping
ufw allow proto icmp

# Habilitar UFW
ufw --force enable

# Verificar regras
ufw status verbose
```

**Você deve ver todas as portas como "ALLOW"**

---

#### **5. Verificar serviços críticos**

```bash
# Verificar todos os serviços
systemctl status sshd nginx php8.3-fpm mariadb redis-server

# Se algum não estiver ativo, iniciar
systemctl start sshd
systemctl start nginx
systemctl start php8.3-fpm
systemctl start mariadb
systemctl start redis-server
```

---

#### **6. Testar conectividade**

```bash
# Testar ping local
ping -c 3 127.0.0.1

# Testar portas localmente
curl http://localhost
curl -k https://localhost:8443

# Verificar todas as portas escutando
ss -tlnp | grep -E ':(22|80|443|8080|8443)'
```

---

### **PASSO 4: Testar Acesso Externo**

**Do seu computador, teste:**

#### **A. Teste SSH**

```bash
ssh root@72.61.53.222
# Senha: Jm@D@KDPnw7Q
```

**Ou porta alternativa:**

```bash
ssh -p 2222 root@72.61.53.222
```

✅ **Se conectar:** SSH funcionando!

---

#### **B. Teste Ping**

```bash
ping 72.61.53.222
```

✅ **Se responder:** Rede funcionando!

---

#### **C. Teste Painel Admin**

**No navegador:**

```
https://72.61.53.222:8443
```

**Login:**
```
admin@localhost
Admin123!@#
```

✅ **Se carregar:** Painel funcionando!

---

#### **D. Teste HTTP**

```bash
curl http://72.61.53.222
```

✅ **Se retornar HTML:** NGINX funcionando!

---

## 🔍 DIAGNÓSTICO ADICIONAL

Se **AINDA** não funcionar após os passos acima:

### **Verificar logs de erro**

No console do servidor:

```bash
# Ver últimas mensagens do sistema
tail -100 /var/log/syslog

# Ver logs de serviços
journalctl -xe

# Ver logs específicos
tail -50 /var/log/nginx/error.log
tail -50 /var/log/auth.log
```

---

### **Verificar interface de rede**

```bash
# Ver interfaces
ip addr show

# Ver rotas
ip route show

# Ver se interface principal está UP
ip link show

# Se interface está DOWN, levantar
ip link set eth0 up
# ou
ip link set ens3 up
```

---

### **Verificar firewall do provedor**

**⚠️ IMPORTANTE:** Alguns provedores VPS têm **firewall próprio** FORA do servidor!

**Onde verificar:**

- **DigitalOcean:** Cloud Firewalls (no dashboard)
- **Vultr:** Firewall Groups
- **AWS:** Security Groups
- **Hetzner:** Firewall Rules
- **Contabo:** Normalmente não tem
- **OVH:** Firewall no painel

**Configure para permitir:**
- Todas as portas: 22, 2222, 80, 443, 8080, 8443, 25, 587, 993, 995
- Protocolo ICMP (ping)

---

### **Verificar se servidor reiniciou**

```bash
# Ver uptime
uptime

# Ver quando sistema iniciou
who -b

# Ver logs de boot
journalctl -b
```

Se uptime for muito baixo (poucos minutos), servidor reiniciou recentemente.

---

## 🆘 PLANO B: RESTAURAR BACKUP

Se **NADA** funcionar, você pode restaurar de backup:

### **No console do servidor:**

```bash
# Listar backups disponíveis
ls -lh /opt/webserver/backups/

# Ou verificar backups Restic
restic -r /opt/webserver/backups/repo snapshots
```

---

## 📊 CHECKLIST DE VERIFICAÇÃO

Após executar a recuperação, verifique:

- [ ] UFW está com status "active"
- [ ] Todas as portas aparecem como "ALLOW" no `ufw status`
- [ ] SSH está "active (running)"
- [ ] NGINX está "active (running)"
- [ ] Portas 22, 80, 443, 8080, 8443 aparecem no `ss -tlnp`
- [ ] `ping 72.61.53.222` responde (do seu PC)
- [ ] `ssh root@72.61.53.222` conecta (do seu PC)
- [ ] `https://72.61.53.222:8443` carrega no navegador

---

## 📞 SUPORTE ADICIONAL

### **Se o problema persistir:**

1. **Verifique com o provedor VPS:**
   - Há manutenção programada?
   - Há problemas de rede no datacenter?
   - Firewall do provedor está bloqueando?

2. **Verifique hardware/recursos:**
   ```bash
   # Uso de disco
   df -h
   
   # Uso de memória
   free -h
   
   # Carga do sistema
   uptime
   ```

3. **Considere reboot (ÚLTIMO RECURSO):**
   ```bash
   reboot
   ```
   
   Aguarde 2-3 minutos e teste acesso novamente.

---

## 📄 DOCUMENTAÇÃO GERADA

Após executar o script de recuperação, o servidor criará:

```
/root/RECUPERACAO-STATUS.txt
```

Para ver:

```bash
cat /root/RECUPERACAO-STATUS.txt
```

Este arquivo contém o relatório completo da recuperação.

---

## ✅ CONCLUSÃO

Após seguir este guia:

1. ✅ UFW reconfigurado corretamente
2. ✅ Todas as portas liberadas
3. ✅ Serviços críticos verificados e reiniciados
4. ✅ SSH acessível
5. ✅ Painel admin acessível
6. ✅ Servidor totalmente operacional

---

## 🎯 PRÓXIMOS PASSOS

Após recuperar o acesso:

1. **Revisar o que causou o problema**
   ```bash
   tail -500 /var/log/syslog | grep -i error
   ```

2. **Não executar scripts não testados**
   - Sempre fazer backup antes
   - Testar em ambiente de desenvolvimento primeiro

3. **Monitorar logs regularmente**
   ```bash
   tail -f /var/log/syslog
   ```

4. **Considerar snapshot/backup imediato**
   - Fazer backup do servidor funcional
   - Via painel do provedor ou Restic

---

**Data:** 2025-11-16  
**Versão:** 1.0 - Recuperação de Emergência  
**Status:** 🚨 CRÍTICO - Requer ação imediata via console VPS
