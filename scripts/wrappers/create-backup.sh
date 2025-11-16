#!/bin/bash
# Wrapper seguro para criar backups
# /opt/webserver/scripts/wrappers/create-backup.sh

set -e

if [ "$#" -lt 2 ]; then
    echo "ERROR: Invalid arguments"
    echo "Usage: $0 <type> <target> [options]"
    echo "Types: site, database, email, full"
    exit 1
fi

BACKUP_TYPE="$1"
TARGET="$2"
BACKUP_DIR="/opt/webserver/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Criar diretório de backups se não existir
mkdir -p "$BACKUP_DIR"

case "$BACKUP_TYPE" in
    "site")
        # Backup de site
        SITE_PATH="/opt/webserver/sites/$TARGET"
        
        if [ ! -d "$SITE_PATH" ]; then
            echo "ERROR: Site '$TARGET' not found"
            exit 1
        fi
        
        BACKUP_FILE="$BACKUP_DIR/site-${TARGET}-${TIMESTAMP}.tar.gz"
        
        echo "Creating backup of site: $TARGET"
        tar -czf "$BACKUP_FILE" -C "$SITE_PATH" .
        
        echo "SUCCESS: Backup created at $BACKUP_FILE"
        echo "SIZE: $(du -h "$BACKUP_FILE" | cut -f1)"
        exit 0
        ;;
        
    "database")
        # Backup de banco de dados
        DB_NAME="$TARGET"
        BACKUP_FILE="$BACKUP_DIR/db-${DB_NAME}-${TIMESTAMP}.sql.gz"
        
        echo "Creating backup of database: $DB_NAME"
        
        # Usar credenciais do root MySQL
        if [ -f /root/.my.cnf ]; then
            mysqldump "$DB_NAME" | gzip > "$BACKUP_FILE"
        else
            echo "ERROR: MySQL credentials not found"
            exit 1
        fi
        
        echo "SUCCESS: Backup created at $BACKUP_FILE"
        echo "SIZE: $(du -h "$BACKUP_FILE" | cut -f1)"
        exit 0
        ;;
        
    "email")
        # Backup de emails
        DOMAIN="$TARGET"
        MAIL_DIR="/var/mail/vhosts/$DOMAIN"
        
        if [ ! -d "$MAIL_DIR" ]; then
            echo "ERROR: Email domain '$DOMAIN' not found"
            exit 1
        fi
        
        BACKUP_FILE="$BACKUP_DIR/email-${DOMAIN}-${TIMESTAMP}.tar.gz"
        
        echo "Creating backup of email domain: $DOMAIN"
        tar -czf "$BACKUP_FILE" -C "$MAIL_DIR" .
        
        echo "SUCCESS: Backup created at $BACKUP_FILE"
        echo "SIZE: $(du -h "$BACKUP_FILE" | cut -f1)"
        exit 0
        ;;
        
    "full")
        # Backup completo do servidor
        BACKUP_FILE="$BACKUP_DIR/full-backup-${TIMESTAMP}.tar.gz"
        
        echo "Creating full server backup..."
        tar -czf "$BACKUP_FILE" \
            --exclude='/opt/webserver/backups' \
            --exclude='/proc' \
            --exclude='/sys' \
            --exclude='/dev' \
            --exclude='/tmp' \
            /opt/webserver \
            /etc/nginx \
            /etc/php \
            /etc/mysql \
            /etc/postfix \
            /var/mail
        
        echo "SUCCESS: Full backup created at $BACKUP_FILE"
        echo "SIZE: $(du -h "$BACKUP_FILE" | cut -f1)"
        exit 0
        ;;
        
    *)
        echo "ERROR: Invalid backup type '$BACKUP_TYPE'"
        exit 1
        ;;
esac
