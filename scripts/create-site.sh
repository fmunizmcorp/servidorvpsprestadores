#!/bin/bash
# Script completo para criar novo site no servidor multi-tenant
# /opt/webserver/scripts/create-site.sh
# Usage: ./create-site.sh site-name domain.com [php-version] [options]

set -e

# ==================== VALIDAÇÕES INICIAIS ====================

if [ "$#" -lt 2 ]; then
    echo "ERROR: Invalid arguments"
    echo ""
    echo "Usage: $0 <site-name> <domain> [php-version] [--no-db] [--template=TYPE]"
    echo ""
    echo "Arguments:"
    echo "  site-name    : Alphanumeric name for the site (no spaces)"
    echo "  domain       : Primary domain (e.g., example.com)"
    echo "  php-version  : Optional PHP version (8.3, 8.2, 8.1). Default: 8.3"
    echo ""
    echo "Options:"
    echo "  --no-db      : Do not create database"
    echo "  --template=  : Use template (php, laravel, wordpress). Default: php"
    echo ""
    echo "Example:"
    echo "  $0 mysite example.com 8.3 --template=wordpress"
    exit 1
fi

SITE_NAME="$1"
DOMAIN="$2"
PHP_VERSION="${3:-8.3}"
CREATE_DATABASE="yes"
TEMPLATE="php"

# Parse optional arguments
shift 2
shift || true
while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-db)
            CREATE_DATABASE="no"
            shift
            ;;
        --template=*)
            TEMPLATE="${1#*=}"
            shift
            ;;
        8.3|8.2|8.1)
            PHP_VERSION="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validar site name (apenas alfanumérico, hífen e underscore)
if [[ ! "$SITE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "ERROR: Site name must contain only letters, numbers, hyphens and underscores"
    exit 1
fi

# Validar domain
if [[ ! "$DOMAIN" =~ ^[a-z0-9.-]+$ ]]; then
    echo "ERROR: Invalid domain format"
    exit 1
fi

# Validar PHP version
if [[ ! "$PHP_VERSION" =~ ^(8\.3|8\.2|8\.1)$ ]]; then
    echo "ERROR: Invalid PHP version. Supported: 8.3, 8.2, 8.1"
    exit 1
fi

# Verificar se PHP-FPM está instalado
if ! command -v php-fpm${PHP_VERSION} &> /dev/null; then
    echo "ERROR: PHP-FPM ${PHP_VERSION} is not installed"
    exit 1
fi

# Verificar se site já existe
if [ -d "/opt/webserver/sites/$SITE_NAME" ]; then
    echo "ERROR: Site '$SITE_NAME' already exists"
    exit 1
fi

# Verificar se usuário já existe
if id "$SITE_NAME" &>/dev/null; then
    echo "ERROR: User '$SITE_NAME' already exists"
    exit 1
fi

echo "========================================="
echo "Creating new site: $SITE_NAME"
echo "========================================="
echo "Domain: $DOMAIN"
echo "PHP Version: $PHP_VERSION"
echo "Create Database: $CREATE_DATABASE"
echo "Template: $TEMPLATE"
echo "========================================="
echo ""

# ==================== 1. CRIAR USUÁRIO LINUX ====================

echo "[1/9] Creating Linux user..."

useradd -m -s /bin/bash -d "/opt/webserver/sites/$SITE_NAME" "$SITE_NAME"

# Gerar senha para o usuário
USER_PASSWORD=$(openssl rand -base64 24)
echo "$SITE_NAME:$USER_PASSWORD" | chpasswd

echo "✓ User created: $SITE_NAME"

# ==================== 2. CRIAR ESTRUTURA DE DIRETÓRIOS ====================

echo "[2/9] Creating directory structure..."

SITE_PATH="/opt/webserver/sites/$SITE_NAME"

mkdir -p "$SITE_PATH"/{public_html,src,config,logs,cache,temp,uploads,database,backups}

# Criar index.php padrão
case "$TEMPLATE" in
    "php")
        cat > "$SITE_PATH/public_html/index.php" <<'PHPEOF'
<?php
phpinfo();
PHPEOF
        ;;
    
    "laravel")
        # Placeholder para instalação Laravel
        cat > "$SITE_PATH/public_html/index.php" <<'PHPEOF'
<?php
echo "<h1>Laravel Installation Required</h1>";
echo "<p>Install Laravel manually in this directory.</p>";
PHPEOF
        ;;
    
    "wordpress")
        # Placeholder para instalação WordPress
        cat > "$SITE_PATH/public_html/index.php" <<'PHPEOF'
<?php
echo "<h1>WordPress Installation Required</h1>";
echo "<p>Install WordPress manually in this directory.</p>";
PHPEOF
        ;;
esac

# Ajustar permissões
chown -R "$SITE_NAME:www-data" "$SITE_PATH"
chmod 750 "$SITE_PATH"
chmod 755 "$SITE_PATH/public_html"
chmod 775 "$SITE_PATH/"{cache,temp,uploads,logs}

echo "✓ Directory structure created"

# ==================== 3. CRIAR PHP-FPM POOL ====================

echo "[3/9] Creating PHP-FPM pool..."

POOL_FILE="/etc/php/$PHP_VERSION/fpm/pool.d/$SITE_NAME.conf"

cat > "$POOL_FILE" <<POOLEOF
; PHP-FPM Pool for $SITE_NAME
[$SITE_NAME]
user = $SITE_NAME
group = www-data

; Listen on Unix socket
listen = /run/php/php${PHP_VERSION}-fpm-${SITE_NAME}.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

; Process Management
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

; PHP Settings
php_admin_value[open_basedir] = /opt/webserver/sites/$SITE_NAME:/tmp:/proc
php_admin_value[upload_max_filesize] = 50M
php_admin_value[post_max_size] = 50M
php_admin_value[max_execution_time] = 60
php_admin_value[max_input_time] = 60
php_admin_value[memory_limit] = 256M

; Error Logging
php_admin_value[error_log] = /opt/webserver/sites/$SITE_NAME/logs/php-errors.log
php_admin_flag[log_errors] = on
php_admin_value[display_errors] = off

; Security
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source

; Opcache
php_value[opcache.enable] = 1
php_value[opcache.memory_consumption] = 128
php_value[opcache.interned_strings_buffer] = 8
php_value[opcache.max_accelerated_files] = 10000

; Session
php_value[session.save_handler] = files
php_value[session.save_path] = /opt/webserver/sites/$SITE_NAME/temp
POOLEOF

echo "✓ PHP-FPM pool created: $POOL_FILE"

# ==================== 4. CRIAR NGINX SERVER BLOCK ====================

echo "[4/9] Creating NGINX configuration..."

NGINX_CONF="/etc/nginx/sites-available/$SITE_NAME.conf"

cat > "$NGINX_CONF" <<'NGINXEOF'
# HTTP server - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN www.DOMAIN;
    
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

# HTTPS server (self-signed initially)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name DOMAIN www.DOMAIN;
    
    # SSL Configuration (self-signed - replace with Let's Encrypt)
    ssl_certificate /etc/ssl/certs/SITE_NAME-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/SITE_NAME-selfsigned.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    root SITE_PATH/public_html;
    index index.php index.html index.htm;
    
    access_log SITE_PATH/logs/access.log;
    error_log SITE_PATH/logs/error.log;
    
    # Main location
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/phpPHP_VERSION-fpm-SITE_NAME.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Deny access to sensitive files
    location ~* \.(log|sql|txt)$ {
        deny all;
    }
}
NGINXEOF

# Substituir placeholders
sed -i "s|DOMAIN|$DOMAIN|g" "$NGINX_CONF"
sed -i "s|SITE_NAME|$SITE_NAME|g" "$NGINX_CONF"
sed -i "s|SITE_PATH|$SITE_PATH|g" "$NGINX_CONF"
sed -i "s|PHP_VERSION|$PHP_VERSION|g" "$NGINX_CONF"

echo "✓ NGINX configuration created: $NGINX_CONF"

# ==================== 5. CRIAR CERTIFICADO SSL AUTO-ASSINADO ====================

echo "[5/9] Creating self-signed SSL certificate..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "/etc/ssl/private/$SITE_NAME-selfsigned.key" \
    -out "/etc/ssl/certs/$SITE_NAME-selfsigned.crt" \
    -subj "/C=BR/ST=State/L=City/O=Organization/CN=$DOMAIN" \
    2>/dev/null

chmod 600 "/etc/ssl/private/$SITE_NAME-selfsigned.key"

echo "✓ Self-signed SSL certificate created"
echo "  (You can replace with Let's Encrypt certificate later)"

# ==================== 6. HABILITAR SITE ====================

echo "[6/9] Enabling site..."

ln -s "$NGINX_CONF" "/etc/nginx/sites-enabled/$SITE_NAME.conf"

echo "✓ Site enabled"

# ==================== 7. CRIAR BANCO DE DADOS ====================

if [ "$CREATE_DATABASE" = "yes" ]; then
    echo "[7/9] Creating database..."
    
    DB_NAME="db_${SITE_NAME//-/_}"
    DB_USER="user_${SITE_NAME//-/_}"
    DB_PASS=$(openssl rand -base64 24)
    
    # Criar banco e usuário
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    
    echo "✓ Database created: $DB_NAME"
else
    echo "[7/9] Skipping database creation (--no-db flag)"
    DB_NAME="N/A"
    DB_USER="N/A"
    DB_PASS="N/A"
fi

# ==================== 8. CRIAR ARQUIVO DE CREDENCIAIS ====================

echo "[8/9] Creating credentials file..."

cat > "$SITE_PATH/CREDENTIALS.txt" <<CREDEOF
========================================
Site Configuration: $SITE_NAME
========================================

Created: $(date)
Template: $TEMPLATE

DOMAIN INFORMATION
------------------
Primary Domain: $DOMAIN
Alternative: www.$DOMAIN

PATHS
-----
Site Root: $SITE_PATH
Document Root: $SITE_PATH/public_html
Logs: $SITE_PATH/logs
Config: $SITE_PATH/config

SSH/SFTP ACCESS
---------------
Username: $SITE_NAME
Password: $USER_PASSWORD
Host: $(hostname -f)
Port: 22

DATABASE
--------
Database Name: $DB_NAME
Database User: $DB_USER
Database Password: $DB_PASS
Database Host: localhost
Port: 3306

PHP CONFIGURATION
-----------------
PHP Version: $PHP_VERSION
FPM Socket: /run/php/php${PHP_VERSION}-fpm-${SITE_NAME}.sock
Memory Limit: 256M
Upload Max: 50M
Execution Time: 60s

WEB SERVER
----------
NGINX Config: $NGINX_CONF
Access Log: $SITE_PATH/logs/access.log
Error Log: $SITE_PATH/logs/error.log

SSL CERTIFICATE
---------------
Type: Self-signed (temporary)
Certificate: /etc/ssl/certs/$SITE_NAME-selfsigned.crt
Key: /etc/ssl/private/$SITE_NAME-selfsigned.key

Note: Replace with Let's Encrypt certificate:
  certbot --nginx -d $DOMAIN -d www.$DOMAIN

========================================
CREDEOF

chmod 600 "$SITE_PATH/CREDENTIALS.txt"
chown "$SITE_NAME:$SITE_NAME" "$SITE_PATH/CREDENTIALS.txt"

echo "✓ Credentials saved to: $SITE_PATH/CREDENTIALS.txt"

# ==================== 9. RECARREGAR SERVIÇOS ====================

echo "[9/9] Reloading services..."

# Testar configuração NGINX
if ! nginx -t 2>&1; then
    echo "ERROR: NGINX configuration test failed!"
    echo "Rolling back..."
    rm -f "/etc/nginx/sites-enabled/$SITE_NAME.conf"
    exit 1
fi

# Recarregar serviços
systemctl reload php${PHP_VERSION}-fpm
systemctl reload nginx

echo "✓ Services reloaded"

# ==================== FINALIZAÇÃO ====================

echo ""
echo "========================================="
echo "✅ Site created successfully!"
echo "========================================="
echo ""
echo "Site: $SITE_NAME"
echo "Domain: https://$DOMAIN"
echo "IP Access: https://$(hostname -I | awk '{print $1}')/$SITE_NAME"
echo ""
echo "Credentials: $SITE_PATH/CREDENTIALS.txt"
echo ""
echo "NEXT STEPS:"
echo "  1. Update DNS records to point to this server"
echo "  2. Replace self-signed SSL with Let's Encrypt:"
echo "     certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo "  3. Upload your site files to: $SITE_PATH/public_html"
echo ""

exit 0
