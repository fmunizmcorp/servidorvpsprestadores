# 📘 GUIA COMPLETO DE USO DO SERVIDOR
## VPS Multi-Tenant + Email Server

**Servidor:** 72.61.53.222 (srv1131556)  
**Data:** 2025-11-15

---

## 🎯 INFORMAÇÕES ESSENCIAIS

### Acesso ao Servidor
```bash
ssh root@72.61.53.222
Senha: Jm@D@KDPnw7Q
```

### Diretórios Principais
```
/opt/webserver/sites/          # Sites hospedados
/opt/webserver/mail/           # Sistema de email
/opt/webserver/scripts/        # Scripts de gerenciamento
/opt/webserver/backups/        # Backups locais
```

---

## 🌐 GERENCIAMENTO DE SITES

### Criar Novo Site

```bash
# Sintaxe
/opt/webserver/scripts/create-site.sh NOME_SITE DOMINIO.COM

# Exemplo
/opt/webserver/scripts/create-site.sh prestadores prestadores.clinfec.com.br
```

**O que o script faz:**
1. ✅ Cria usuário Linux isolado
2. ✅ Cria estrutura de diretórios
3. ✅ Configura PHP-FPM pool dedicado
4. ✅ Cria server block NGINX
5. ✅ Cria banco de dados MySQL
6. ✅ Gera credenciais automaticamente
7. ✅ Recarrega NGINX e PHP-FPM

**Credenciais geradas:**
```
Arquivo: /opt/webserver/sites/NOME_SITE/CREDENTIALS.txt
Contém: DB name, user, password, SSH user
```

### Estrutura do Site Criado
```
/opt/webserver/sites/NOME_SITE/
├── public/              # Document root (arquivos públicos)
├── src/                 # Código-fonte PHP
├── config/              # Arquivos de configuração
├── logs/                # Logs NGINX
│   ├── access.log
│   └── error.log
├── cache/               # Cache da aplicação
└── CREDENTIALS.txt      # Credenciais (chmod 600)
```

### Fazer Upload de Arquivos

**Opção 1: SFTP**
```bash
# No seu computador local
sftp NOME_SITE@72.61.53.222
cd public
put -r ./arquivos_do_site/*
```

**Opção 2: rsync**
```bash
# No seu computador local
rsync -avz -e ssh ./site/ NOME_SITE@72.61.53.222:/opt/webserver/sites/NOME_SITE/public/
```

**Opção 3: Git**
```bash
# No servidor, como usuário do site
su - NOME_SITE
cd /opt/webserver/sites/NOME_SITE/
git clone https://github.com/seu/repositorio.git public
```

### Configurar SSL (Let's Encrypt)

```bash
# Após DNS apontar para o servidor
certbot --nginx -d dominio.com -d www.dominio.com \
    --non-interactive --agree-tos \
    --email admin@dominio.com
```

### Gerenciar Banco de Dados

```bash
# Acessar MySQL
mysql -u user_NOME_SITE -p

# Ver databases
SHOW DATABASES;

# Usar database
USE db_NOME_SITE;

# Importar dump
mysql -u user_NOME_SITE -p db_NOME_SITE < dump.sql

# Exportar dump
mysqldump -u user_NOME_SITE -p db_NOME_SITE > dump.sql
```

### Logs do Site

```bash
# Logs em tempo real
tail -f /opt/webserver/sites/NOME_SITE/logs/access.log
tail -f /opt/webserver/sites/NOME_SITE/logs/error.log

# Erros PHP
tail -f /var/log/php8.3-fpm.log
```

---

## 📧 GERENCIAMENTO DE EMAIL

### 1. Criar Domínio de Email

```bash
# Sintaxe
/opt/webserver/scripts/create-email-domain.sh DOMINIO.COM

# Exemplo
/opt/webserver/scripts/create-email-domain.sh clinfec.com.br
```

**O que o script faz:**
1. ✅ Adiciona domínio virtual ao Postfix
2. ✅ Cria estrutura de mailboxes
3. ✅ Gera chaves DKIM automaticamente
4. ✅ Configura OpenDKIM
5. ✅ **Exibe DNS records necessários**

**DNS Records Gerados:**

Após executar, o script mostrará algo assim:

```
=========================================
DNS RECORDS PARA clinfec.com.br
=========================================

MX Record:
clinfec.com.br.    IN    MX    10    mail.clinfec.com.br.

A Record:
mail.clinfec.com.br.    IN    A    72.61.53.222

SPF Record:
clinfec.com.br.    IN    TXT    "v=spf1 mx a ip4:72.61.53.222 ~all"

DKIM Record:
mail._domainkey.clinfec.com.br.    IN    TXT    "v=DKIM1; k=rsa; p=MIGfMA0GCSqGS..."

DMARC Record:
_dmarc.clinfec.com.br.    IN    TXT    "v=DMARC1; p=quarantine; rua=mailto:dmarc@clinfec.com.br"

=========================================
```

**❗ IMPORTANTE:** Você deve adicionar esses records no painel de DNS do seu domínio!

### 2. Configurar DNS do Domínio

Acesse o painel de DNS (GoDaddy, Cloudflare, etc) e adicione:

1. **MX Record:**
   - Type: MX
   - Priority: 10
   - Value: mail.clinfec.com.br

2. **A Record (para mail):**
   - Hostname: mail
   - Type: A
   - Value: 72.61.53.222

3. **TXT Record (SPF):**
   - Hostname: @
   - Type: TXT
   - Value: `v=spf1 mx a ip4:72.61.53.222 ~all`

4. **TXT Record (DKIM):**
   - Hostname: mail._domainkey
   - Type: TXT
   - Value: (copiar do output do script)

5. **TXT Record (DMARC):**
   - Hostname: _dmarc
   - Type: TXT
   - Value: `v=DMARC1; p=quarantine; rua=mailto:dmarc@clinfec.com.br`

**Aguardar:** Propagação DNS pode levar 1-48 horas.

### 3. Criar Contas de Email

```bash
# Sintaxe
/opt/webserver/scripts/create-email.sh DOMINIO USUARIO SENHA [QUOTA_MB]

# Exemplos
/opt/webserver/scripts/create-email.sh clinfec.com.br admin Senha123! 2000
/opt/webserver/scripts/create-email.sh clinfec.com.br suporte OutraSenha456 1000
/opt/webserver/scripts/create-email.sh clinfec.com.br contato EmailSenha789
```

**Parâmetros:**
- DOMINIO: domínio previamente criado
- USUARIO: parte antes do @
- SENHA: senha da conta (mínimo 8 caracteres)
- QUOTA_MB: opcional, default 1000MB (1GB)

**Email criado:**
```
Email: usuario@dominio.com
Senha: (a que você definiu)
Quota: X MB
IMAP: mail.dominio.com:993 (SSL)
SMTP: mail.dominio.com:587 (TLS)
```

### 4. Configurar Cliente de Email

#### Thunderbird / Outlook

**Servidor de Entrada (IMAP):**
```
Servidor: mail.clinfec.com.br (ou mail.SEU_DOMINIO)
Porta: 993
Segurança: SSL/TLS
Autenticação: Senha normal
Nome de usuário: email@completo.com
```

**Servidor de Saída (SMTP):**
```
Servidor: mail.clinfec.com.br
Porta: 587
Segurança: STARTTLS
Autenticação: Sim
Nome de usuário: email@completo.com
Senha: (sua senha)
```

#### Dispositivos Móveis (iOS/Android)

**Tipo de conta:** IMAP
**Email:** seuemail@dominio.com
**Senha:** (sua senha)

**Entrada:**
- Servidor: mail.dominio.com
- Porta: 993
- SSL: Sim

**Saída:**
- Servidor: mail.dominio.com
- Porta: 587
- TLS: Sim
- Autenticação: Sim

### 5. Testar Deliverability

```bash
# Enviar email de teste
echo "Teste" | mail -s "Assunto Teste" destino@gmail.com

# Ver fila de email
postqueue -p

# Ver logs
tail -f /var/log/mail.log

# Testar DKIM
# Enviar email para check-auth@verifier.port25.com
# Você receberá resposta com análise completa
```

**Sites para testar:**
- https://www.mail-tester.com (score de deliverability)
- https://mxtoolbox.com/dkim.aspx (testar DKIM)
- https://mxtoolbox.com/spf.aspx (testar SPF)

### 6. Gerenciar Email

```bash
# Ver emails na fila
postqueue -p

# Limpar fila
postqueue -f

# Deletar todos emails da fila
postsuper -d ALL

# Ver logs em tempo real
tail -f /var/log/mail.log

# Verificar mailbox de usuário
ls -lah /opt/webserver/mail/mailboxes/DOMINIO/USUARIO/Maildir/new/

# Estatísticas Postfix
pflogsumm /var/log/mail.log
```

---

## 🔐 SEGURANÇA

### Firewall (UFW)

```bash
# Ver status
ufw status verbose

# Ver regras numeradas
ufw status numbered

# Abrir porta adicional
ufw allow 8080/tcp comment 'Aplicacao Custom'

# Deletar regra
ufw delete [numero]

# Desabilitar (cuidado!)
ufw disable
```

### Fail2Ban

```bash
# Status geral
fail2ban-client status

# Status de jail específico
fail2ban-client status sshd
fail2ban-client status postfix

# Ver IPs banidos
fail2ban-client status sshd

# Desbanir IP
fail2ban-client set sshd unbanip 1.2.3.4

# Ver logs
tail -f /var/log/fail2ban.log
```

### Certificados SSL

```bash
# Renovar certificados
certbot renew

# Renovar forçado
certbot renew --force-renewal

# Listar certificados
certbot certificates

# Status de renovação automática
systemctl status certbot.timer
```

### Antivírus (ClamAV)

```bash
# Atualizar banco de vírus
freshclam

# Scan de diretório
clamscan -r /opt/webserver/sites/

# Scan com remoção
clamscan -r --remove /path

# Scan com quarentena
clamscan -r --move=/quarantine /path

# Ver status do daemon
systemctl status clamav-daemon
```

---

## 🔧 MANUTENÇÃO

### Reiniciar Serviços

```bash
# NGINX
systemctl restart nginx

# PHP-FPM
systemctl restart php8.3-fpm

# MariaDB
systemctl restart mariadb

# Redis
systemctl restart redis-server

# Postfix (email)
systemctl restart postfix

# Dovecot (email)
systemctl restart dovecot

# Todos de uma vez
systemctl restart nginx php8.3-fpm postfix dovecot
```

### Ver Status dos Serviços

```bash
# Status individual
systemctl status nginx
systemctl status postfix

# Status múltiplos
systemctl status nginx php8.3-fpm mariadb redis postfix dovecot opendkim

# Ver serviços falhados
systemctl --failed
```

### Monitoramento de Recursos

```bash
# CPU e RAM em tempo real
htop

# Uso de disco
df -h
ncdu /opt/webserver/

# Uso de disco por diretório
du -sh /opt/webserver/*

# I/O de disco
iotop

# Network
nethogs

# Processos
ps aux | grep -E 'nginx|php|mysql|postfix|dovecot'
```

### Logs do Sistema

```bash
# Logs gerais
tail -f /var/log/syslog

# Logs de autenticação
tail -f /var/log/auth.log

# Logs NGINX
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Logs PHP
tail -f /var/log/php8.3-fpm.log

# Logs MySQL
tail -f /var/log/mysql/error.log

# Logs Email
tail -f /var/log/mail.log

# Logs Fail2Ban
tail -f /var/log/fail2ban.log

# Pesquisar em logs
grep "erro" /var/log/syslog
grep "NOQUEUE" /var/log/mail.log
```

---

## ⚠️ RESOLUÇÃO DE PROBLEMAS

### Site não carrega

1. Verificar NGINX:
```bash
nginx -t
systemctl status nginx
tail -f /var/log/nginx/error.log
```

2. Verificar PHP-FPM:
```bash
systemctl status php8.3-fpm
tail -f /var/log/php8.3-fpm.log
```

3. Verificar permissões:
```bash
ls -la /opt/webserver/sites/NOME_SITE/public/
```

### Erro 502 Bad Gateway

```bash
# Verificar se socket PHP existe
ls -la /var/run/php/

# Reiniciar PHP-FPM
systemctl restart php8.3-fpm

# Ver logs
tail -f /var/log/nginx/error.log
tail -f /var/log/php8.3-fpm.log
```

### Email não envia

1. Verificar fila:
```bash
postqueue -p
```

2. Ver logs:
```bash
tail -f /var/log/mail.log
```

3. Testar conexão SMTP:
```bash
telnet localhost 25
```

4. Verificar DNS:
```bash
dig MX clinfec.com.br
dig TXT mail._domainkey.clinfec.com.br
```

### Email não recebe

1. Verificar Dovecot:
```bash
systemctl status dovecot
tail -f /var/log/mail.log
```

2. Testar IMAP:
```bash
openssl s_client -connect localhost:993
```

3. Verificar mailbox:
```bash
ls /opt/webserver/mail/mailboxes/DOMINIO/USUARIO/Maildir/new/
```

### Banco de dados lento

```bash
# Ver processos MySQL
mysqladmin -p processlist

# Ver queries lentas
tail -f /var/log/mysql/slow-query.log

# Otimizar tabelas
mysqlcheck -o --all-databases -p
```

---

## 📊 COMANDOS ÚTEIS

### Listar sites ativos

```bash
ls /opt/webserver/sites/
ls /etc/nginx/sites-enabled/
```

### Listar domínios de email

```bash
cat /etc/postfix/virtual_domains
ls /opt/webserver/mail/mailboxes/
```

### Listar contas de email

```bash
cat /etc/dovecot/users
cat /etc/postfix/virtual_mailbox_maps
```

### Ver espaço usado por site

```bash
du -sh /opt/webserver/sites/NOME_SITE/
```

### Ver espaço usado por mailboxes

```bash
du -sh /opt/webserver/mail/mailboxes/*
```

### Backup manual

```bash
# Site completo
tar -czf backup-site-$(date +%Y%m%d).tar.gz /opt/webserver/sites/NOME_SITE/

# Database
mysqldump -p db_NOME_SITE > backup-db-$(date +%Y%m%d).sql

# Mailboxes
tar -czf backup-mail-$(date +%Y%m%d).tar.gz /opt/webserver/mail/mailboxes/DOMINIO/
```

---

## 📞 INFORMAÇÕES TÉCNICAS

### Versões Instaladas
```
OS: Ubuntu 24.04.3 LTS
NGINX: 1.24.0
PHP: 8.3.6
MariaDB: 10.11.13
Redis: 7.0.15
Postfix: 3.8.6
Dovecot: 2.3.21
OpenDKIM: 2.11.0
ClamAV: 1.4.3
```

### Limites Configurados
```
Max upload: 25MB
PHP memory: 256MB per script
PHP execution time: 60s
MySQL connections: 200
Redis memory: 256MB
Email message size: 25MB
Mailbox quota: configurável por conta
```

### Localização de Arquivos
```
Sites: /opt/webserver/sites/
Email: /opt/webserver/mail/
Scripts: /opt/webserver/scripts/
Configs NGINX: /etc/nginx/
Configs PHP: /etc/php/8.3/
Configs MySQL: /etc/mysql/
Configs Postfix: /etc/postfix/
Configs Dovecot: /etc/dovecot/
```

---

## 🆘 SUPORTE

### Contatos
- **Email Técnico:** (configurar)
- **Documentação:** Este arquivo
- **Logs:** /var/log/

### Recursos Online
- Ubuntu: https://ubuntu.com/server/docs
- NGINX: https://nginx.org/en/docs/
- Postfix: http://www.postfix.org/documentation.html
- Dovecot: https://doc.dovecot.org/

---

**Última atualização:** 2025-11-15  
**Versão:** 1.0
