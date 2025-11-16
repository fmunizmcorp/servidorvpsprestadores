# 🌐 GUIA COMPLETO: Adicionar Novos Domínios/Subdomínios

**Sistema:** VPS Multi-Tenant com isolamento PHP-FPM  
**Servidor:** 72.61.53.222  
**Data:** 2025-11-16

---

## 📋 VISÃO GERAL

Este guia ensina como adicionar novos sites/domínios ao servidor multi-tenant, com isolamento completo e segurança.

### Arquitetura Atual

```
prestadores.clinfec.com.br/        → Sistema Prestadores (PHP custom)
prestadores.clinfec.com.br/admin/  → Laravel Admin Panel
futuro-site.com/                   → Novo site (seguir este guia)
```

---

## 🚀 PASSO A PASSO: Adicionar Novo Site

### Pré-requisitos

1. Acesso root ao VPS (72.61.53.222)
2. DNS do domínio apontando para o IP do servidor
3. Decisão sobre tecnologia (PHP, Laravel, Node.js, etc.)

### Passo 1: Criar Usuário Linux (Isolamento)

```bash
# Conectar ao VPS
ssh root@72.61.53.222

# Criar usuário para o novo site (substitua NOMEDOSITE)
SITE_NAME="novosite"
useradd -m -s /bin/bash $SITE_NAME
usermod -aG www-data $SITE_NAME

# Criar estrutura de diretórios
mkdir -p /opt/webserver/sites/$SITE_NAME/{public_html,logs,temp,backups}
chown -R $SITE_NAME:www-data /opt/webserver/sites/$SITE_NAME
chmod 755 /opt/webserver/sites/$SITE_NAME/public_html
```

### Passo 2: Criar PHP-FPM Pool (Para sites PHP)

```bash
# Criar arquivo de configuração do pool
cat > /etc/php/8.3/fpm/pool.d/$SITE_NAME.conf << 'EOF'
[NOMEDOSITE]
user = NOMEDOSITE
group = www-data
listen = /run/php/php8.3-fpm-NOMEDOSITE.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

; Isolamento de segurança
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen
php_admin_value[open_basedir] = /opt/webserver/sites/NOMEDOSITE:/tmp:/proc
php_admin_flag[allow_url_fopen] = on

; Logs
php_admin_value[error_log] = /opt/webserver/sites/NOMEDOSITE/logs/php-error.log
php_admin_flag[log_errors] = on

; Sessões
php_value[session.save_handler] = files
php_value[session.save_path] = /opt/webserver/sites/NOMEDOSITE/temp

; Upload
php_admin_value[upload_max_filesize] = 32M
php_admin_value[post_max_size] = 32M
php_admin_value[memory_limit] = 128M

chdir = /opt/webserver/sites/NOMEDOSITE
EOF

# Substituir NOMEDOSITE pelo nome real
sed -i "s/NOMEDOSITE/$SITE_NAME/g" /etc/php/8.3/fpm/pool.d/$SITE_NAME.conf

# Reiniciar PHP-FPM
systemctl restart php8.3-fpm
```

### Passo 3: Configurar NGINX

```bash
# Criar configuração NGINX (substitua DOMINIO.COM)
DOMAIN="novosite.com.br"
cat > /etc/nginx/sites-available/$DOMAIN.conf << 'EOF'
# HTTP - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name DOMINIO.COM www.DOMINIO.COM;
    
    # Let's Encrypt validation
    location ^~ /.well-known/acme-challenge/ {
        alias /var/www/html/.well-known/acme-challenge/;
        default_type "text/plain";
        allow all;
    }
    
    # Redirect to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name DOMINIO.COM www.DOMINIO.COM;
    
    # SSL Configuration (auto-detect)
    ssl_certificate /etc/letsencrypt/live/DOMINIO.COM/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMINIO.COM/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Document root
    root /opt/webserver/sites/NOMEDOSITE/public_html;
    index index.php index.html index.htm;
    
    # Logs
    access_log /var/log/nginx/NOMEDOSITE-access.log;
    error_log /var/log/nginx/NOMEDOSITE-error.log;
    
    # PHP processing
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm-NOMEDOSITE.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param SERVER_NAME $server_name;
        fastcgi_param HTTP_HOST $host;
        fastcgi_param HTTPS on;
    }
    
    # Hide hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

# Substituir placeholders
sed -i "s/DOMINIO.COM/$DOMAIN/g" /etc/nginx/sites-available/$DOMAIN.conf
sed -i "s/NOMEDOSITE/$SITE_NAME/g" /etc/nginx/sites-available/$DOMAIN.conf

# Ativar site
ln -s /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/

# Testar e recarregar NGINX
nginx -t && systemctl reload nginx
```

### Passo 4: Gerar Certificado SSL (Let's Encrypt)

```bash
# Instalar certbot se não estiver instalado
apt install certbot python3-certbot-nginx -y

# Gerar certificado
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Verificar renovação automática
certbot renew --dry-run
```

### Passo 5: Configurar Aplicação PHP para Usar Domínio Correto

**IMPORTANTE:** Sua aplicação PHP deve detectar o domínio corretamente.

#### Para Aplicações PHP Custom:

```php
<?php
// No início do index.php ou arquivo de configuração

// Detectar protocolo
$protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') 
    || $_SERVER['SERVER_PORT'] == 443 ? 'https' : 'http';

// IMPORTANTE: Use SERVER_NAME, não HTTP_HOST
// SERVER_NAME vem da configuração do NGINX e é confiável
$host = $_SERVER['SERVER_NAME'] ?? $_SERVER['HTTP_HOST'] ?? 'dominio-padrao.com';

// Definir BASE_URL
define('BASE_URL', $protocol . '://' . $host);

// Usar em toda a aplicação
echo '<a href="' . BASE_URL . '/pagina">Link</a>';
?>
```

#### Para Laravel:

```env
# .env
APP_URL=https://novosite.com.br
FORCE_HTTPS=true
```

```php
// app/Providers/AppServiceProvider.php
public function boot(): void
{
    if (env('FORCE_HTTPS', false)) {
        \URL::forceScheme('https');
    }
}
```

#### Para WordPress:

```php
// wp-config.php (adicionar antes de "That's all, stop editing!")
define('WP_HOME', 'https://novosite.com.br');
define('WP_SITEURL', 'https://novosite.com.br');
define('FORCE_SSL_ADMIN', true);

// Fix para domínio atrás de proxy/CDN
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && 
    $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
```

### Passo 6: Criar Banco de Dados (Se necessário)

```bash
# Conectar ao MySQL/MariaDB
mysql -u root -p

# Criar banco e usuário
CREATE DATABASE novosite_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'novosite_user'@'localhost' IDENTIFIED BY 'SENHA_FORTE_AQUI';
GRANT ALL PRIVILEGES ON novosite_db.* TO 'novosite_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Passo 7: Deploy da Aplicação

```bash
# Fazer upload dos arquivos (via SCP, FTP, Git, etc.)
# Exemplo com SCP:
scp -r /caminho/local/site/* root@72.61.53.222:/opt/webserver/sites/$SITE_NAME/public_html/

# Ajustar permissões
chown -R $SITE_NAME:www-data /opt/webserver/sites/$SITE_NAME/public_html
find /opt/webserver/sites/$SITE_NAME/public_html -type d -exec chmod 755 {} \;
find /opt/webserver/sites/$SITE_NAME/public_html -type f -exec chmod 644 {} \;
```

### Passo 8: Testar!

```bash
# Testar via curl
curl -I https://novosite.com.br

# Verificar logs em caso de erro
tail -f /var/log/nginx/novosite-error.log
tail -f /opt/webserver/sites/novosite/logs/php-error.log
```

---

## 🔧 CONFIGURAÇÕES ESPECIAIS

### Para Subdomínios

Use o mesmo processo, mas ajuste o `server_name`:

```nginx
server_name sub.dominio.com;
```

### Para Sites Node.js

1. **Não crie pool PHP-FPM**
2. Configure NGINX como proxy reverso:

```nginx
location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}
```

3. Use PM2 para gerenciar a aplicação Node.js

### Para Sites Estáticos (HTML/CSS/JS)

1. **Não precisa de PHP-FPM pool**
2. NGINX serve diretamente:

```nginx
location / {
    try_files $uri $uri/ =404;
}
```

---

## 🛡️ SEGURANÇA: Open_basedir

Se sua aplicação precisar acessar diretórios específicos fora do site, ajuste o `open_basedir`:

```bash
# Editar pool PHP-FPM
nano /etc/php/8.3/fpm/pool.d/$SITE_NAME.conf

# Modificar linha:
php_admin_value[open_basedir] = /opt/webserver/sites/NOMEDOSITE:/tmp:/proc:/outro/path/necessario

# Reiniciar PHP-FPM
systemctl restart php8.3-fpm
```

**Caminhos comuns que podem ser necessários:**
- `/var/log` - Para aplicações que leem logs do sistema
- `/etc/postfix` - Para aplicações que gerenciam email
- `/var/mail` - Para aplicações de email
- `/etc/nginx/sites-available` - Para painéis de controle

---

## 📊 MONITORAMENTO

### Verificar Status dos Pools PHP-FPM

```bash
# Listar todos os pools ativos
systemctl status php8.3-fpm | grep -A2 "pool"

# Ver processos de um pool específico
ps aux | grep php-fpm | grep novosite
```

### Verificar Uso de Recursos

```bash
# Uso de memória por pool
ps aux | grep php-fpm-novosite | awk '{sum+=$6} END {print "Memory: " sum/1024 " MB"}'

# Uso de CPU
top -u novosite
```

### Logs para Troubleshooting

```bash
# NGINX
tail -f /var/log/nginx/novosite-error.log
tail -f /var/log/nginx/novosite-access.log

# PHP-FPM
tail -f /var/log/php8.3-fpm.log
tail -f /opt/webserver/sites/novosite/logs/php-error.log

# Sistema
journalctl -u nginx -f
journalctl -u php8.3-fpm -f
```

---

## 🔥 TROUBLESHOOTING COMUM

### Problema: URLs usando IP ao invés do domínio

**Solução:** Verificar código da aplicação

```php
// ERRADO
$host = $_SERVER['HTTP_HOST'] ?? '72.61.53.222';

// CORRETO
$host = $_SERVER['SERVER_NAME'] ?? $_SERVER['HTTP_HOST'] ?? 'dominio.com';
```

### Problema: Erro 502 Bad Gateway

**Causas comuns:**
1. Pool PHP-FPM não está rodando
2. Socket path incorreto no NGINX
3. Permissões do socket incorretas

**Solução:**
```bash
# Verificar se pool está ativo
systemctl status php8.3-fpm

# Verificar socket
ls -la /run/php/php8.3-fpm-novosite.sock

# Reiniciar PHP-FPM
systemctl restart php8.3-fpm
```

### Problema: open_basedir restriction

**Solução:** Adicionar path necessário ao pool:
```bash
nano /etc/php/8.3/fpm/pool.d/novosite.conf
# Adicionar path à linha open_basedir
systemctl restart php8.3-fpm
```

### Problema: Permissões de arquivo

**Solução:**
```bash
# Corrigir ownership
chown -R novosite:www-data /opt/webserver/sites/novosite/public_html

# Corrigir permissões
find /opt/webserver/sites/novosite/public_html -type d -exec chmod 755 {} \;
find /opt/webserver/sites/novosite/public_html -type f -exec chmod 644 {} \;

# Para diretórios de upload/cache (se necessário)
chmod -R 775 /opt/webserver/sites/novosite/public_html/uploads
chmod -R 775 /opt/webserver/sites/novosite/public_html/cache
```

---

## ✅ CHECKLIST DE VALIDAÇÃO

Antes de considerar o site pronto:

- [ ] DNS apontando para o servidor (A record)
- [ ] Certificado SSL configurado e válido
- [ ] Site acessível via HTTPS
- [ ] URLs usando domínio correto (não IP)
- [ ] PHP-FPM pool rodando e acessível
- [ ] Permissões de arquivo corretas
- [ ] Logs sendo escritos corretamente
- [ ] Backup configurado (se aplicável)
- [ ] Monitoramento configurado (se aplicável)

---

## 📚 EXEMPLOS PRÁTICOS

### Exemplo 1: Site WordPress

```bash
SITE_NAME="blogcliente"
DOMAIN="blog.cliente.com.br"

# Seguir passos 1-3
# ... (criar usuário, pool, nginx)

# Download WordPress
cd /opt/webserver/sites/$SITE_NAME/public_html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
mv wordpress/* .
rm -rf wordpress latest.tar.gz

# Criar banco
mysql -u root -p << EOF
CREATE DATABASE ${SITE_NAME}_wp;
CREATE USER '${SITE_NAME}'@'localhost' IDENTIFIED BY 'senha123';
GRANT ALL ON ${SITE_NAME}_wp.* TO '${SITE_NAME}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Configurar permissões
chown -R $SITE_NAME:www-data .
chmod 755 wp-content/uploads
```

### Exemplo 2: Laravel Application

```bash
SITE_NAME="appaplicacao"
DOMAIN="app.cliente.com.br"

# Após criar estrutura básica
cd /opt/webserver/sites/$SITE_NAME

# Deploy Laravel
git clone https://github.com/cliente/aplicacao.git public_html
cd public_html
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate

# Configurar storage
php artisan storage:link
chmod -R 775 storage bootstrap/cache
chown -R $SITE_NAME:www-data storage bootstrap/cache

# Configurar .env
nano .env
# APP_URL=https://app.cliente.com.br
# DB_*=...
```

---

## 🎓 BOAS PRÁTICAS

1. **Sempre use HTTPS** - Configure SSL antes de fazer deploy
2. **Isolamento por usuário** - Cada site com seu próprio usuário Linux
3. **Logs separados** - Facilita troubleshooting
4. **Backup regular** - Configure backups automáticos
5. **Monitoramento** - Configure alertas para downtime
6. **Documentação** - Documente configurações específicas de cada site
7. **Versionamento** - Use Git para controle de código
8. **Testes** - Teste em ambiente de staging antes de produção

---

**Autor:** Sistema Multi-Tenant VPS  
**Última atualização:** 2025-11-16  
**Versão:** 1.0
