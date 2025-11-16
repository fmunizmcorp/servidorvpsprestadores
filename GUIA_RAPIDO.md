# 🚀 Guia Rápido - Sistema Administrativo VPS

## Acesso Rápido

### Painel Admin
- **URL**: https://prestadores.clinfec.com.br/admin
- **IP**: https://72.61.53.222/admin

### SSH
```bash
ssh root@72.61.53.222
```

---

## ⚡ Comandos Rápidos

### Criar Novo Site
```bash
sudo /opt/webserver/scripts/wrappers/create-site-wrapper.sh \
    nome-site \
    dominio.com.br \
    8.3 \
    --template=php
```

### Fazer Backup
```bash
# Site
sudo /opt/webserver/scripts/wrappers/create-backup.sh site nome-site

# Database
sudo /opt/webserver/scripts/wrappers/create-backup.sh database db_nome

# Full
sudo /opt/webserver/scripts/wrappers/create-backup.sh full servidor
```

### Controlar Serviço
```bash
sudo /opt/webserver/scripts/wrappers/service-control.sh <serviço> <ação>

# Exemplos:
sudo /opt/webserver/scripts/wrappers/service-control.sh nginx restart
sudo /opt/webserver/scripts/wrappers/service-control.sh php8.3-fpm reload
sudo /opt/webserver/scripts/wrappers/service-control.sh mysql status
```

### Ativar/Desativar Site
```bash
# Ativar
sudo /opt/webserver/scripts/wrappers/site-toggle.sh nome-site enable

# Desativar
sudo /opt/webserver/scripts/wrappers/site-toggle.sh nome-site disable
```

---

## 📁 Localizações Importantes

```
/opt/webserver/admin-panel/     → Laravel Admin Panel
/opt/webserver/sites/           → Sites Multi-Tenant
/opt/webserver/scripts/         → Scripts de automação
/opt/webserver/backups/         → Backups
/etc/nginx/sites-available/     → Configs NGINX
/etc/php/8.3/fpm/pool.d/       → PHP-FPM Pools
```

---

## 🔍 Logs Importantes

```bash
# NGINX
tail -f /var/log/nginx/error.log

# PHP-FPM
tail -f /var/log/php8.3-fpm.log

# Laravel Admin
tail -f /opt/webserver/admin-panel/storage/logs/laravel.log

# Site específico
tail -f /opt/webserver/sites/SITE/logs/error.log
```

---

## 🆘 Troubleshooting Rápido

### Site não carrega (502)
```bash
sudo systemctl restart php8.3-fpm
sudo systemctl restart nginx
```

### Admin Panel erro 500
```bash
cd /opt/webserver/admin-panel
sudo chown -R www-data:www-data storage/
sudo chmod -R 775 storage/
tail -100 storage/logs/laravel.log
```

### SSL não funciona
```bash
sudo certbot --nginx -d dominio.com.br -d www.dominio.com.br
```

### Verificar todos os serviços
```bash
sudo systemctl status nginx php8.3-fpm mysql postfix dovecot fail2ban
```

---

## 📊 Monitoramento Rápido

```bash
# CPU/Memória
top
free -h

# Disco
df -h
du -sh /opt/webserver/sites/*

# Processos PHP-FPM
ps aux | grep php-fpm

# Conexões ativas
netstat -tuln | grep LISTEN
```

---

## ✅ Checklist Pós-Criação de Site

- [ ] DNS configurado (A record)
- [ ] Site acessível via domínio
- [ ] SSL instalado (certbot)
- [ ] Banco de dados funcionando
- [ ] Backup inicial criado
- [ ] Credenciais salvas em local seguro
- [ ] Permissões corretas (arquivos/pastas)
- [ ] Logs sendo gerados corretamente

---

## 🔐 Segurança

### Verificar IPs banidos
```bash
sudo fail2ban-client status sshd
```

### Scan antivírus
```bash
sudo clamscan -r /opt/webserver/sites/SITE/uploads/
```

### Atualizar sistema
```bash
sudo apt update && sudo apt upgrade -y
```

---

## 🎯 Fluxo de Trabalho Típico

### 1. Criar Site
```bash
# Via painel admin ou CLI
sudo /opt/webserver/scripts/wrappers/create-site-wrapper.sh \
    meusite dominio.com.br 8.3
```

### 2. Configurar DNS
```
A    @    72.61.53.222
A    www  72.61.53.222
```

### 3. Instalar SSL
```bash
sudo certbot --nginx -d dominio.com.br -d www.dominio.com.br
```

### 4. Fazer Upload
```bash
# Via SFTP para:
/opt/webserver/sites/meusite/public_html/
```

### 5. Backup
```bash
sudo /opt/webserver/scripts/wrappers/create-backup.sh site meusite
```

---

Para documentação completa, consulte: `SISTEMA_ADMINISTRATIVO_COMPLETO.md`
