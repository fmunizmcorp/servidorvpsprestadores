# 🚀 Servidor VPS Prestadores - Documentação Completa

![Status](https://img.shields.io/badge/status-production%20ready-brightgreen)
![Server](https://img.shields.io/badge/server-ubuntu%2024.04-orange)
![Stack](https://img.shields.io/badge/stack-NGINX%20%7C%20PHP%20%7C%20MariaDB-blue)
![Email](https://img.shields.io/badge/email-Postfix%20%7C%20Dovecot-red)

Documentação completa da implantação do servidor VPS para hospedagem multi-tenant e email corporativo.

## 📋 Índice

- [🎯 Sobre o Projeto](#-sobre-o-projeto)
- [✨ Características](#-características)
- [📚 Documentação](#-documentação)
- [🚀 Quick Start](#-quick-start)
- [📊 Componentes](#-componentes)
- [🔐 Segurança](#-segurança)
- [📧 Contato](#-contato)

## 🎯 Sobre o Projeto

Servidor VPS Ubuntu 24.04 LTS completamente configurado para:
- **Hospedagem Web Multi-Tenant**: Sites PHP ilimitados com isolamento total
- **Email Corporativo**: Servidor SMTP/IMAP/POP3 completo com anti-spam e anti-vírus
- **Segurança Enterprise**: Firewall, IDS/IPS, anti-vírus, hardening
- **Alta Performance**: Cache multicamadas, otimizações de kernel

**Servidor:** 72.61.53.222  
**Status:** ✅ Operacional  
**Data:** 2025-11-15

## ✨ Características

### 🌐 Hospedagem Web
- ✅ NGINX 1.24.0 (otimizado)
- ✅ PHP 8.3.6-FPM (OPcache)
- ✅ MariaDB 10.11.13 (4GB buffer)
- ✅ Redis 7.0.15 (cache)
- ✅ SSL automático (Let's Encrypt)
- ✅ Scripts de criação de sites

### 📧 Email Corporativo
- ✅ Postfix 3.8.6 (SMTP)
- ✅ Dovecot 2.3.21 (IMAP/POP3)
- ✅ OpenDKIM + OpenDMARC
- ✅ ClamAV (anti-vírus)
- ✅ SpamAssassin (anti-spam)
- ✅ Scripts de criação de emails

### 🔐 Segurança
- ✅ UFW Firewall
- ✅ Fail2Ban (6 jails)
- ✅ ClamAV daemon
- ✅ SSH hardening
- ✅ SSL/TLS everywhere
- ✅ Rate limiting

## 📚 Documentação

### 📖 Principais Documentos

| Documento | Descrição | Link |
|-----------|-----------|------|
| **INDEX.md** | Índice de navegação | [Ver](INDEX.md) |
| **GUIA-COMPLETO-USO.md** | Manual passo-a-passo | [Ver](GUIA-COMPLETO-USO.md) ⭐ |
| **RESUMO-EXECUTIVO.md** | Visão geral rápida | [Ver](RESUMO-EXECUTIVO.md) |
| **ENTREGA-FINAL.md** | Checklist de entrega | [Ver](ENTREGA-FINAL.md) |
| **PROGRESSO-GERAL.md** | Status do projeto | [Ver](PROGRESSO-GERAL.md) |

### 📊 Relatórios Técnicos

- [Sprint 2 Report](sprint2-report.md) - Web Stack
- [Sprint 3 Report](sprint3-report.md) - Email Stack  
- [Sprint 4 Report](sprint4-report.md) - Segurança

## 🚀 Quick Start

### 1. Criar um Site

```bash
# Conectar ao servidor
ssh root@72.61.53.222

# Criar site
/opt/webserver/scripts/create-site.sh meusite dominio.com

# Ver credenciais
cat /opt/webserver/sites/meusite/CREDENTIALS.txt
```

### 2. Configurar Email

```bash
# Criar domínio de email
/opt/webserver/scripts/create-email-domain.sh dominio.com

# Configurar DNS (copiar records exibidos)

# Criar conta
/opt/webserver/scripts/create-email.sh dominio.com admin SenhaForte123
```

### 3. Gerar SSL

```bash
certbot --nginx -d dominio.com -d www.dominio.com \
    --email admin@dominio.com
```

## 📊 Componentes

### Stack Completo

```
┌─────────────────────────────────────┐
│     NGINX 1.24.0 (Web Server)       │
├─────────────────────────────────────┤
│     PHP 8.3.6-FPM (Application)     │
├─────────────────────────────────────┤
│   MariaDB 10.11.13 (Database)       │
├─────────────────────────────────────┤
│     Redis 7.0.15 (Cache)            │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│    Postfix 3.8.6 (SMTP)             │
├─────────────────────────────────────┤
│   Dovecot 2.3.21 (IMAP/POP3)        │
├─────────────────────────────────────┤
│  OpenDKIM + OpenDMARC               │
├─────────────────────────────────────┤
│  ClamAV + SpamAssassin              │
└─────────────────────────────────────┘
```

### Serviços Ativos

- ✅ NGINX (Web Server)
- ✅ PHP-FPM (Application)
- ✅ MariaDB (Database)
- ✅ Redis (Cache)
- ✅ Postfix (SMTP)
- ✅ Dovecot (IMAP/POP3)
- ✅ OpenDKIM (DKIM Signing)
- ✅ OpenDMARC (DMARC)
- ✅ ClamAV (Antivirus)
- ✅ Fail2Ban (IDS/IPS)
- ✅ UFW (Firewall)

## 🔐 Segurança

### Camadas de Proteção

1. **Firewall (UFW)** - Network layer
2. **IDS/IPS (Fail2Ban)** - Application layer
3. **Anti-Virus (ClamAV)** - File/Email scanning
4. **Email Auth** - SPF, DKIM, DMARC
5. **SSL/TLS** - Encryption everywhere
6. **Hardening** - System level

### Portas Configuradas

| Porta | Serviço | Proteção |
|-------|---------|----------|
| 22 | SSH | Fail2Ban |
| 25 | SMTP | Rate limit |
| 80 | HTTP | Firewall |
| 443 | HTTPS | SSL/TLS |
| 465 | SMTPS | SSL |
| 587 | Submission | TLS |
| 993 | IMAPS | SSL |
| 995 | POP3S | SSL |

### Fail2Ban Jails

- ✅ sshd (SSH brute-force)
- ✅ nginx-http-auth
- ✅ nginx-noscript
- ✅ nginx-badbots
- ✅ postfix (SMTP abuse)
- ✅ dovecot (IMAP/POP3)

## 📁 Estrutura

```
/opt/webserver/
├── sites/              # Sites hospedados
│   └── [site]/
│       ├── public/     # Document root
│       ├── logs/       # Logs NGINX
│       └── CREDENTIALS.txt
├── mail/               # Sistema de email
│   ├── mailboxes/      # Emails storage
│   └── config/         # Configs email
├── scripts/            # Scripts automação
│   ├── create-site.sh
│   ├── create-email-domain.sh
│   └── create-email.sh
└── backups/            # Backups locais
```

## 🎯 Capacidades

### Hospedagem
- ✅ Sites PHP ilimitados
- ✅ Isolamento por site
- ✅ SSL automático
- ✅ Cache inteligente
- ✅ Database dedicado

### Email
- ✅ Domínios ilimitados
- ✅ Contas ilimitadas
- ✅ SMTP completo
- ✅ IMAP + POP3
- ✅ Anti-spam + Anti-vírus
- ✅ DKIM + SPF + DMARC

### Performance
- ✅ FastCGI Cache
- ✅ OPcache PHP
- ✅ Redis Cache
- ✅ Gzip/Brotli
- ✅ HTTP/2
- ✅ Database optimized

## 🛠️ Manutenção

### Comandos Úteis

```bash
# Ver status dos serviços
systemctl status nginx php8.3-fpm mariadb postfix dovecot

# Reiniciar serviços
systemctl restart nginx php8.3-fpm

# Ver logs
tail -f /var/log/nginx/error.log
tail -f /var/log/mail.log

# Fail2Ban status
fail2ban-client status

# Ver sites
ls /opt/webserver/sites/

# Ver emails
ls /opt/webserver/mail/mailboxes/
```

## 📈 Métricas

- **Componentes:** 15 instalados
- **Scripts:** 3 automatizados
- **Documentação:** 11 arquivos
- **Serviços:** 11/11 ativos ✅
- **Segurança:** 6 jails ativos
- **Performance:** Otimizado ✅
- **Status:** Production Ready 🚀

## ⚠️ Avisos

### Credenciais Temporárias
```
Host: 72.61.53.222
User: root
Pass: Jm@D@KDPnw7Q
```
⚠️ **Mudar senhas após primeiro acesso!**

### DNS Email
⚠️ Configurar DNS records (MX, SPF, DKIM, DMARC) após criar domínio de email.

### SSL
⚠️ Gerar certificados Let's Encrypt após DNS configurado.

## 📧 Contato

Para suporte ou dúvidas, consulte:
- 📘 [GUIA-COMPLETO-USO.md](GUIA-COMPLETO-USO.md)
- 📊 [PROGRESSO-GERAL.md](PROGRESSO-GERAL.md)

## 📄 Licença

Documentação e configuração do servidor VPS Prestadores.

---

**Status:** ✅ Operacional  
**Versão:** 1.0  
**Última atualização:** 2025-11-15

---

**🎉 Servidor configurado com sucesso e pronto para produção!**
