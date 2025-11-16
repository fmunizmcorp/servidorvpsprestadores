#!/bin/bash
#############################################################################
# COMPLETE SSL INSTALLATION SCRIPT - Let's Encrypt for prestadores.clinfec.com.br
# Ubuntu 24.04.3 LTS + NGINX
# ZERO MANUAL INTERVENTION - Fully automated
#############################################################################

set -e  # Exit on any error

echo "=============================================="
echo "  SSL LET'S ENCRYPT INSTALLATION"
echo "  Domain: prestadores.clinfec.com.br"
echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOMAIN="prestadores.clinfec.com.br"
BACKUP_DIR="/opt/webserver/ssl-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Step 1: Update system and install Certbot
echo -e "${YELLOW}Step 1: Installing Certbot...${NC}"
apt update -qq
apt install -y certbot > /dev/null 2>&1
echo -e "${GREEN}✓ Certbot installed${NC}"
echo ""

# Step 2: Create backup directory
echo -e "${YELLOW}Step 2: Creating backup directory...${NC}"
mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}✓ Backup directory created: $BACKUP_DIR${NC}"
echo ""

# Step 3: Backup current NGINX configs
echo -e "${YELLOW}Step 3: Backing up NGINX configurations...${NC}"
cp /etc/nginx/sites-available/prestadores-domain-only.conf "$BACKUP_DIR/prestadores-domain-only.conf.backup-$TIMESTAMP"
echo -e "${GREEN}✓ Backup saved: $BACKUP_DIR/prestadores-domain-only.conf.backup-$TIMESTAMP${NC}"
echo ""

# Step 4: Test NGINX config before stopping
echo -e "${YELLOW}Step 4: Testing current NGINX configuration...${NC}"
nginx -t
echo -e "${GREEN}✓ NGINX configuration valid${NC}"
echo ""

# Step 5: Stop NGINX temporarily (Certbot needs port 80 free)
echo -e "${YELLOW}Step 5: Stopping NGINX temporarily...${NC}"
systemctl stop nginx
echo -e "${GREEN}✓ NGINX stopped${NC}"
echo ""

# Step 6: Generate SSL certificate
echo -e "${YELLOW}Step 6: Generating Let's Encrypt SSL certificate...${NC}"
echo "This may take a few moments..."
certbot certonly --standalone \
    -d "$DOMAIN" \
    --non-interactive \
    --agree-tos \
    --email admin@clinfec.com.br \
    --preferred-challenges http

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSL certificate generated successfully!${NC}"
else
    echo -e "${RED}✗ SSL certificate generation FAILED${NC}"
    systemctl start nginx
    exit 1
fi
echo ""

# Step 7: Verify certificate files exist
echo -e "${YELLOW}Step 7: Verifying certificate files...${NC}"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    echo -e "${GREEN}✓ Certificate file exists: $CERT_PATH${NC}"
    echo -e "${GREEN}✓ Private key exists: $KEY_PATH${NC}"
else
    echo -e "${RED}✗ Certificate files NOT found!${NC}"
    systemctl start nginx
    exit 1
fi
echo ""

# Step 8: Display certificate information
echo -e "${YELLOW}Step 8: Certificate Information:${NC}"
openssl x509 -in "$CERT_PATH" -noout -text | grep -A 2 "Validity"
openssl x509 -in "$CERT_PATH" -noout -text | grep "Subject:"
echo ""

# Step 9: Update NGINX configuration with valid SSL
echo -e "${YELLOW}Step 9: Updating NGINX configuration with Let's Encrypt certificates...${NC}"

cat > /etc/nginx/sites-available/prestadores-domain-only.conf << 'EOFNGINX'
# ========================================
# PRESTADORES.CLINFEC.COM.BR - APENAS PRESTADORES
# Admin panel NÃO disponível neste domínio
# SSL: Let's Encrypt válido
# ========================================

# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name prestadores.clinfec.com.br www.prestadores.clinfec.com.br;
    
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

# HTTPS - Prestadores APENAS com SSL Let's Encrypt
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name prestadores.clinfec.com.br www.prestadores.clinfec.com.br;
    
    # SSL Configuration - Let's Encrypt
    ssl_certificate /etc/letsencrypt/live/prestadores.clinfec.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/prestadores.clinfec.com.br/privkey.pem;
    
    # SSL Protocols and Ciphers
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    
    # SSL Session
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/prestadores.clinfec.com.br/chain.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Prestadores site root
    root /opt/webserver/sites/prestadores/public_html;
    index index.php index.html;
    
    access_log /var/log/nginx/prestadores-domain-access.log;
    error_log /var/log/nginx/prestadores-domain-error.log;
    
    # BLOQUEAR /admin completamente neste domínio
    location ^~ /admin {
        return 404;
    }
    
    # Main location
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm-prestadores.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
        fastcgi_param PHP_VALUE "open_basedir=/opt/webserver/sites/prestadores:/tmp:/proc";
    }
    
    # Hide hidden files
    location ~ /\. {
        deny all;
    }
}
EOFNGINX

echo -e "${GREEN}✓ NGINX configuration updated with Let's Encrypt SSL${NC}"
echo ""

# Step 10: Test new NGINX configuration
echo -e "${YELLOW}Step 10: Testing new NGINX configuration...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ NGINX configuration is valid${NC}"
else
    echo -e "${RED}✗ NGINX configuration has errors!${NC}"
    echo "Restoring backup..."
    cp "$BACKUP_DIR/prestadores-domain-only.conf.backup-$TIMESTAMP" /etc/nginx/sites-available/prestadores-domain-only.conf
    systemctl start nginx
    exit 1
fi
echo ""

# Step 11: Start NGINX
echo -e "${YELLOW}Step 11: Starting NGINX...${NC}"
systemctl start nginx
systemctl status nginx --no-pager | head -5
echo -e "${GREEN}✓ NGINX started successfully${NC}"
echo ""

# Step 12: Setup automatic SSL renewal
echo -e "${YELLOW}Step 12: Setting up automatic SSL renewal...${NC}"

# Create renewal script
cat > /opt/webserver/scripts/renew-ssl.sh << 'EOFRENEWAL'
#!/bin/bash
# Automatic SSL renewal script
certbot renew --quiet --post-hook "systemctl reload nginx"
EOFRENEWAL

chmod +x /opt/webserver/scripts/renew-ssl.sh

# Add to crontab (check twice daily at 3am and 3pm)
CRON_JOB="0 3,15 * * * /opt/webserver/scripts/renew-ssl.sh >> /var/log/letsencrypt-renewal.log 2>&1"

# Check if cron job already exists
if ! crontab -l 2>/dev/null | grep -q "renew-ssl.sh"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo -e "${GREEN}✓ Automatic renewal configured (runs at 3am and 3pm daily)${NC}"
else
    echo -e "${YELLOW}⚠ Cron job already exists, skipping${NC}"
fi
echo ""

# Step 13: Test SSL certificate renewal (dry run)
echo -e "${YELLOW}Step 13: Testing SSL renewal (dry run)...${NC}"
certbot renew --dry-run --quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSL renewal test successful${NC}"
else
    echo -e "${RED}✗ SSL renewal test failed${NC}"
fi
echo ""

# Step 14: Create certificate information file
echo -e "${YELLOW}Step 14: Creating certificate information file...${NC}"

cat > /opt/webserver/ssl-backups/CERTIFICATE-INFO-$TIMESTAMP.txt << EOFINFO
SSL CERTIFICATE INFORMATION
============================
Date: $(date '+%Y-%m-%d %H:%M:%S')
Domain: $DOMAIN

Certificate Paths:
- Full Chain: /etc/letsencrypt/live/$DOMAIN/fullchain.pem
- Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem
- Chain: /etc/letsencrypt/live/$DOMAIN/chain.pem
- Certificate: /etc/letsencrypt/live/$DOMAIN/cert.pem

Certificate Details:
$(openssl x509 -in "$CERT_PATH" -noout -text | grep -A 2 "Validity")
$(openssl x509 -in "$CERT_PATH" -noout -text | grep "Subject:")
$(openssl x509 -in "$CERT_PATH" -noout -text | grep "Issuer:")

Renewal:
- Automatic renewal configured via cron
- Runs twice daily at 3am and 3pm
- Log file: /var/log/letsencrypt-renewal.log

NGINX Configuration:
- File: /etc/nginx/sites-available/prestadores-domain-only.conf
- Backup: $BACKUP_DIR/prestadores-domain-only.conf.backup-$TIMESTAMP

Status: ACTIVE ✓
EOFINFO

echo -e "${GREEN}✓ Certificate info saved: /opt/webserver/ssl-backups/CERTIFICATE-INFO-$TIMESTAMP.txt${NC}"
echo ""

# Step 15: Display final summary
echo ""
echo "=============================================="
echo -e "${GREEN}  SSL INSTALLATION COMPLETED SUCCESSFULLY!${NC}"
echo "=============================================="
echo ""
echo "Certificate Details:"
echo "  - Domain: $DOMAIN"
echo "  - Issuer: Let's Encrypt"
echo "  - Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "  - Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo ""
echo "Configuration:"
echo "  - NGINX Config: /etc/nginx/sites-available/prestadores-domain-only.conf"
echo "  - Backup: $BACKUP_DIR/prestadores-domain-only.conf.backup-$TIMESTAMP"
echo ""
echo "Automatic Renewal:"
echo "  - Enabled: YES"
echo "  - Schedule: Twice daily (3am and 3pm)"
echo "  - Log: /var/log/letsencrypt-renewal.log"
echo ""
echo "Next Steps:"
echo "  1. Test HTTPS: https://$DOMAIN"
echo "  2. Verify redirect: http://$DOMAIN (should redirect to HTTPS)"
echo "  3. Check SSL rating: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
echo ""
echo -e "${GREEN}Status: OPERATIONAL ✓${NC}"
echo "=============================================="
