# Sistema Administrativo Completo - Servidor VPS Multi-Tenant

**Versão**: 2.0  
**Data**: 16 de Novembro de 2025  
**Status**: Produção

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Funcionalidades Implementadas](#funcionalidades-implementadas)
4. [Acesso ao Sistema](#acesso-ao-sistema)
5. [Gerenciamento de Sites](#gerenciamento-de-sites)
6. [Gerenciamento de Backups](#gerenciamento-de-backups)
7. [Gerenciamento de Serviços](#gerenciamento-de-serviços)
8. [Sistema de Segurança](#sistema-de-segurança)
9. [Scripts e Wrappers](#scripts-e-wrappers)
10. [Manutenção e Troubleshooting](#manutenção-e-troubleshooting)

---

## 🎯 Visão Geral

Este documento descreve o sistema administrativo completo implementado no servidor VPS para gerenciamento multi-tenant de sites, serviços e recursos.

### Características Principais

- **Multi-Tenant**: Suporte a múltiplos sites isolados
- **Gerenciamento Web**: Painel administrativo Laravel 11
- **Automação Completa**: Scripts para todas as operações
- **Segurança Reforçada**: Isolamento via PHP-FPM pools e sudoers
- **URL Híbrida**: Suporte a acesso via domínio e IP com path prefix

---

## 🏗️ Arquitetura do Sistema

### Stack Tecnológico

```
┌─────────────────────────────────────────┐
│         NGINX (Reverse Proxy)           │
│  - Roteamento baseado em domínio        │
│  - SSL/TLS (Let's Encrypt + Self-signed)│
│  - HTTP/2 Support                        │
└─────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼──────────┐   ┌───────▼─────────┐
│  Laravel Admin   │   │  Sites Isolados │
│  PHP 8.3-FPM     │   │  PHP 8.3-FPM    │
│  Pool: admin     │   │  Pools isolados │
└──────────────────┘   └─────────────────┘
        │                       │
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │   MySQL 8.0           │
        │   - admin_panel_db    │
        │   - site DBs isolados │
        └───────────────────────┘
```

### Estrutura de Diretórios

```
/opt/webserver/
├── admin-panel/              # Laravel Admin Panel
│   ├── app/
│   │   ├── Http/Controllers/
│   │   └── Services/
│   ├── resources/views/
│   └── public/
├── sites/                    # Sites Multi-Tenant
│   └── [site-name]/
│       ├── public_html/      # Document root
│       ├── src/              # Source code
│       ├── config/           # Configurações
│       ├── logs/             # Logs do site
│       ├── cache/            # Cache
│       ├── temp/             # Arquivos temporários
│       └── CREDENTIALS.txt   # Credenciais do site
├── scripts/                  # Scripts de automação
│   ├── create-site.sh
│   └── wrappers/            # Wrappers seguros
│       ├── service-control.sh
│       ├── create-backup.sh
│       ├── restore-backup.sh
│       ├── site-toggle.sh
│       └── create-site-wrapper.sh
└── backups/                 # Diretório de backups
```

---

## ✨ Funcionalidades Implementadas

### 1. Sistema de URL Híbrida ✅

**Objetivo**: Permitir acesso via domínio ou IP com path prefix

**Implementação**:
- **Via Domínio**: `https://prestadores.clinfec.com.br/page`
- **Via IP**: `https://72.61.53.222/prestadores/page`

**Como Funciona**:
```php
// Detecção automática em index.php
$host = $_SERVER['HTTP_HOST'];
$path_prefix = '';

if (preg_match('/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/', $host)) {
    $path_prefix = '/prestadores';  // Acesso via IP
}

define('BASE_URL', $protocol . '://' . $host . $path_prefix);
```

**NGINX Config**:
```nginx
# Suporte a /prestadores/ via IP
location ^~ /prestadores/ {
    alias /opt/webserver/sites/prestadores/public_html/;
    try_files $uri $uri/ @prestadores_rewrite;
}
```

### 2. Gerenciamento de Sites ✅

**Funcionalidades**:
- ✅ Listar todos os sites
- ✅ Criar novo site (via painel web)
- ✅ Visualizar detalhes do site
- ✅ Ativar/Desativar site
- ✅ Ver logs do site
- ✅ Gerenciar SSL

**Criação Automática de Site**:

O script `create-site.sh` cria automaticamente:
1. Usuário Linux dedicado
2. Estrutura completa de diretórios
3. PHP-FPM pool isolado
4. Configuração NGINX com SSL
5. Banco de dados MySQL (opcional)
6. Certificado SSL self-signed
7. Arquivo de credenciais

**Exemplo de Uso**:
```bash
sudo /opt/webserver/scripts/wrappers/create-site-wrapper.sh \
    meusite \
    meusite.com.br \
    8.3 \
    --template=wordpress
```

**Parâmetros Suportados**:
- `site-name`: Nome do site (alfanumérico)
- `domain`: Domínio principal
- `php-version`: 8.3, 8.2 ou 8.1
- `--no-db`: Não criar banco de dados
- `--template=`: php, laravel, wordpress

### 3. Sistema de Backups ✅

**Tipos de Backup**:
- **Site**: Backup completo de um site específico
- **Database**: Backup de banco de dados
- **Email**: Backup de domínio de email
- **Full**: Backup completo do servidor

**Funcionalidades**:
- ✅ Criar backup manual
- ✅ Listar backups disponíveis
- ✅ Restaurar backup
- ✅ Download de backup
- ✅ Excluir backup antigo
- ✅ Estatísticas de uso

**Exemplo - Criar Backup**:
```bash
sudo /opt/webserver/scripts/wrappers/create-backup.sh site prestadores
```

**Exemplo - Restaurar Backup**:
```bash
sudo /opt/webserver/scripts/wrappers/restore-backup.sh \
    /opt/webserver/backups/site-prestadores-20251116-123456.tar.gz
```

### 4. Gerenciamento de Serviços ✅

**Serviços Monitorados**:
- NGINX (Web Server)
- PHP-FPM 8.3 (FastCGI)
- MySQL (Database)
- Postfix (SMTP)
- Dovecot (IMAP/POP3)
- Fail2Ban (Security)
- ClamAV (Antivirus)

**Ações Disponíveis**:
- ✅ Ver status em tempo real
- ✅ Iniciar serviço
- ✅ Parar serviço
- ✅ Reiniciar serviço
- ✅ Recarregar configuração
- ✅ Ver logs do serviço

**Exemplo**:
```bash
sudo /opt/webserver/scripts/wrappers/service-control.sh nginx restart
```

### 5. Sistema de Segurança ✅

**Mecanismos de Segurança**:

1. **PHP-FPM Pools Isolados**
   - Cada site tem seu próprio pool
   - Usuário Linux dedicado
   - open_basedir restriction
   - disable_functions para funções perigosas

2. **Sudo Wrappers**
   - Scripts com validação de entrada
   - Lista branca de operações
   - Logs de todas as ações
   - Execução via sudoers controlado

3. **Sudoers Configuration**
   ```
   www-data ALL=(root) NOPASSWD: /opt/webserver/scripts/wrappers/*
   ```

4. **NGINX Security Headers**
   ```nginx
   add_header Strict-Transport-Security "max-age=31536000";
   add_header X-Frame-Options "SAMEORIGIN";
   add_header X-Content-Type-Options "nosniff";
   add_header X-XSS-Protection "1; mode=block";
   ```

---

## 🔐 Acesso ao Sistema

### Painel Administrativo

**URL**: 
- Via Domínio: `https://prestadores.clinfec.com.br/admin`
- Via IP: `https://72.61.53.222/admin`

**Credenciais**:
- Verifique o arquivo de credenciais no servidor
- Ou use o script de reset: `/opt/webserver/scripts/reset-admin-password.sh`

### SSH/SFTP

**Servidor**: `72.61.53.222`  
**Porta**: `22` ou `2222`  
**Usuário**: `root` ou usuário específico do site

---

## 🌐 Gerenciamento de Sites

### Criar Novo Site via Painel

1. Acesse: Admin Panel → Sites → Create New Site
2. Preencha:
   - Site Name (sem espaços)
   - Domain (ex: meusite.com.br)
   - PHP Version (8.3 recomendado)
   - Template (PHP, Laravel, WordPress)
3. Marque "Create Database" se necessário
4. Clique em "Create Site"
5. Anote as credenciais geradas

### Estrutura do Site Criado

```
/opt/webserver/sites/meusite/
├── public_html/        # Coloque seus arquivos aqui
├── src/                # Source code (opcional)
├── config/             # Arquivos de configuração
├── logs/               # Logs do Apache/PHP
│   ├── access.log
│   ├── error.log
│   └── php-errors.log
├── cache/              # Cache do aplicativo
├── temp/               # Arquivos temporários
├── uploads/            # Uploads de usuários
└── CREDENTIALS.txt     # ⚠️ IMPORTANTE: Credenciais
```

### Configurar DNS

Após criar o site, configure seu DNS:

```
Type    Name    Value               TTL
A       @       72.61.53.222        3600
A       www     72.61.53.222        3600
```

### Instalar SSL Let's Encrypt

```bash
sudo certbot --nginx -d meusite.com.br -d www.meusite.com.br
```

---

## 💾 Gerenciamento de Backups

### Criar Backup Manual

**Via Painel**:
1. Admin Panel → Backups → Create New Backup
2. Selecione o tipo e alvo
3. Clique em "Create Backup"

**Via CLI**:
```bash
# Backup de site
sudo /opt/webserver/scripts/wrappers/create-backup.sh site meusite

# Backup de banco de dados
sudo /opt/webserver/scripts/wrappers/create-backup.sh database db_meusite

# Backup completo
sudo /opt/webserver/scripts/wrappers/create-backup.sh full servidor
```

### Restaurar Backup

```bash
sudo /opt/webserver/scripts/wrappers/restore-backup.sh \
    /opt/webserver/backups/site-meusite-20251116-143022.tar.gz
```

### Política de Backups Recomendada

| Tipo          | Frequência | Retenção |
|---------------|------------|----------|
| Sites         | Diário     | 7 dias   |
| Databases     | 4x/dia     | 7 dias   |
| Full Server   | Semanal    | 4 semanas|

---

## ⚙️ Gerenciamento de Serviços

### Controlar Serviço

**Via Painel**:
1. Admin Panel → Services
2. Localize o serviço
3. Clique no botão da ação desejada

**Via CLI**:
```bash
sudo /opt/webserver/scripts/wrappers/service-control.sh <service> <action>
```

**Exemplos**:
```bash
# Reiniciar NGINX
sudo /opt/webserver/scripts/wrappers/service-control.sh nginx restart

# Ver status do MySQL
sudo /opt/webserver/scripts/wrappers/service-control.sh mysql status

# Recarregar PHP-FPM
sudo /opt/webserver/scripts/wrappers/service-control.sh php8.3-fpm reload
```

### Serviços Disponíveis

| Serviço         | Descrição                    |
|-----------------|------------------------------|
| nginx           | Web Server                   |
| php8.3-fpm      | PHP FastCGI                  |
| mysql           | Database Server              |
| postfix         | Mail Transfer Agent (SMTP)   |
| dovecot         | IMAP/POP3 Server            |
| fail2ban        | Intrusion Prevention         |
| clamav-daemon   | Antivirus Engine            |

---

## 🔒 Sistema de Segurança

### Configuração PHP-FPM (por site)

```ini
; Isolamento de segurança
php_admin_value[open_basedir] = /opt/webserver/sites/SITE:/tmp:/proc
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen

; Limites de recursos
php_admin_value[memory_limit] = 256M
php_admin_value[upload_max_filesize] = 50M
php_admin_value[max_execution_time] = 60
```

### Fail2Ban

Proteção contra ataques de força bruta:
- SSH
- NGINX (HTTP flood)
- Postfix (SMTP abuse)
- Dovecot (IMAP/POP3)

**Ver IPs banidos**:
```bash
sudo fail2ban-client status sshd
```

### ClamAV

Antivírus para scan de arquivos:

```bash
# Scan de diretório
sudo clamscan -r /opt/webserver/sites/meusite/uploads/

# Atualizar definições de vírus
sudo freshclam
```

---

## 📜 Scripts e Wrappers

### Scripts Principais

| Script                  | Descrição                          |
|-------------------------|-------------------------------------|
| `create-site.sh`        | Criar novo site completo           |
| `delete-site.sh`        | Remover site (TODO)                |

### Wrappers Seguros

| Wrapper                    | Descrição                       |
|----------------------------|---------------------------------|
| `service-control.sh`       | Controlar serviços do sistema   |
| `nginx-test.sh`            | Testar configuração NGINX       |
| `create-backup.sh`         | Criar backups                   |
| `restore-backup.sh`        | Restaurar backups               |
| `site-toggle.sh`           | Ativar/desativar site           |
| `create-site-wrapper.sh`   | Wrapper para criar sites        |

### SystemCommandService (PHP)

Service Laravel para executar comandos do sistema com segurança:

```php
use App\Services\SystemCommandService;

$sysCmd = new SystemCommandService();

// Controlar serviço
$result = $sysCmd->controlService('nginx', 'restart');

// Criar backup
$result = $sysCmd->createBackup('site', 'meusite');

// Ativar site
$result = $sysCmd->toggleSite('meusite', true);
```

---

## 🔧 Manutenção e Troubleshooting

### Logs Importantes

```bash
# NGINX
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/prestadores-error.log

# PHP-FPM
tail -f /var/log/php8.3-fpm.log
tail -f /opt/webserver/sites/SITE/logs/php-errors.log

# MySQL
tail -f /var/log/mysql/error.log

# Admin Panel Laravel
tail -f /opt/webserver/admin-panel/storage/logs/laravel.log
```

### Comandos Úteis

```bash
# Ver todos os sites
ls -la /opt/webserver/sites/

# Ver PHP-FPM pools ativos
ls -la /etc/php/8.3/fpm/pool.d/

# Ver sites NGINX habilitados
ls -la /etc/nginx/sites-enabled/

# Testar configuração NGINX
sudo nginx -t

# Recarregar NGINX após mudanças
sudo systemctl reload nginx

# Ver uso de disco
df -h

# Ver processos PHP-FPM
ps aux | grep php-fpm

# Verificar status de todos os serviços
sudo systemctl status nginx php8.3-fpm mysql postfix dovecot fail2ban
```

### Problemas Comuns

#### 1. Site retorna 502 Bad Gateway

**Causa**: PHP-FPM pool não está rodando

**Solução**:
```bash
sudo systemctl status php8.3-fpm
sudo systemctl restart php8.3-fpm
```

#### 2. Erro 500 no Admin Panel

**Causa**: Permissões ou open_basedir

**Solução**:
```bash
# Verificar permissões
sudo chown -R www-data:www-data /opt/webserver/admin-panel/storage
sudo chmod -R 775 /opt/webserver/admin-panel/storage

# Ver log de erros
tail -100 /opt/webserver/admin-panel/storage/logs/laravel.log
```

#### 3. Site não carrega após criação

**Causa**: DNS ainda não propagou ou SSL não configurado

**Solução**:
```bash
# Testar via hosts local
echo "72.61.53.222 meusite.com.br" >> /etc/hosts

# Verificar SSL
sudo certbot certificates
```

---

## 📊 Métricas e Monitoramento

### Métricas Disponíveis

O painel administrativo mostra:
- CPU Load (1min, 5min, 15min)
- Uso de Memória RAM
- Uso de Disco
- Uptime do servidor
- Status de todos os serviços

### Comandos de Monitoramento

```bash
# CPU e load
uptime
top

# Memória
free -h

# Disco
df -h
du -sh /opt/webserver/sites/*

# Rede
netstat -tuln
ss -tuln
```

---

## 🎓 Boas Práticas

### Segurança

1. ✅ Sempre use SSL/TLS (Let's Encrypt)
2. ✅ Mantenha senhas fortes e únicas por site
3. ✅ Faça backups regulares
4. ✅ Atualize o sistema regularmente
5. ✅ Monitore logs de acesso suspeito
6. ✅ Use Fail2Ban para proteção contra brute force

### Performance

1. ✅ Configure OpCache PHP adequadamente
2. ✅ Use cache de aplicativo (Redis/Memcached)
3. ✅ Otimize queries do banco de dados
4. ✅ Use CDN para assets estáticos
5. ✅ Habilite compressão gzip no NGINX

### Manutenção

1. ✅ Revise logs semanalmente
2. ✅ Teste backups mensalmente
3. ✅ Limpe backups antigos
4. ✅ Monitore uso de disco
5. ✅ Documente mudanças importantes

---

## 📞 Suporte

Para questões técnicas ou problemas:

1. Consulte os logs relevantes
2. Verifique a documentação acima
3. Teste em ambiente de desenvolvimento primeiro
4. Faça backup antes de mudanças críticas

---

## 📝 Changelog

### v2.0 - 16/11/2025
- ✅ Sistema de URL híbrida (IP + domínio)
- ✅ CRUD completo de sites via painel
- ✅ Sistema de sudo wrappers seguros
- ✅ SystemCommandService implementado
- ✅ Gerenciamento completo de backups
- ✅ Gerenciamento de serviços em tempo real
- ✅ Script create-site.sh completo
- ✅ Documentação completa

### v1.0 - 15/11/2025
- ✅ Laravel Admin Panel base
- ✅ Multi-tenant architecture
- ✅ PHP-FPM pools isolados
- ✅ NGINX configurado

---

**Documento mantido por**: Sistema Administrativo  
**Última atualização**: 16 de Novembro de 2025  
**Próxima revisão**: 16 de Dezembro de 2025
