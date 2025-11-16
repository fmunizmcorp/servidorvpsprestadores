#!/bin/bash
# Wrapper seguro para restaurar backups
# /opt/webserver/scripts/wrappers/restore-backup.sh

set -e

if [ "$#" -ne 1 ]; then
    echo "ERROR: Invalid arguments"
    echo "Usage: $0 <backup-file>"
    exit 1
fi

BACKUP_FILE="$1"
BACKUP_DIR="/opt/webserver/backups"

# Validar que o arquivo está no diretório de backups
if [[ ! "$BACKUP_FILE" =~ ^${BACKUP_DIR}/.+ ]]; then
    echo "ERROR: Backup file must be in $BACKUP_DIR"
    exit 1
fi

# Verificar se arquivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Determinar tipo de backup pelo nome do arquivo
FILENAME=$(basename "$BACKUP_FILE")

if [[ "$FILENAME" =~ ^site-(.+)-[0-9]{8}-[0-9]{6}\.tar\.gz$ ]]; then
    # Backup de site
    SITE_NAME="${BASH_REMATCH[1]}"
    SITE_PATH="/opt/webserver/sites/$SITE_NAME"
    
    echo "Restoring site backup: $SITE_NAME"
    echo "WARNING: This will overwrite existing files!"
    
    # Criar diretório se não existir
    mkdir -p "$SITE_PATH"
    
    # Extrair backup
    tar -xzf "$BACKUP_FILE" -C "$SITE_PATH"
    
    # Ajustar permissões
    chown -R "$SITE_NAME:www-data" "$SITE_PATH"
    
    echo "SUCCESS: Site restored to $SITE_PATH"
    exit 0
    
elif [[ "$FILENAME" =~ ^db-(.+)-[0-9]{8}-[0-9]{6}\.sql\.gz$ ]]; then
    # Backup de banco de dados
    DB_NAME="${BASH_REMATCH[1]}"
    
    echo "Restoring database backup: $DB_NAME"
    echo "WARNING: This will overwrite existing database!"
    
    # Restaurar banco
    if [ -f /root/.my.cnf ]; then
        gunzip < "$BACKUP_FILE" | mysql "$DB_NAME"
    else
        echo "ERROR: MySQL credentials not found"
        exit 1
    fi
    
    echo "SUCCESS: Database restored: $DB_NAME"
    exit 0
    
elif [[ "$FILENAME" =~ ^email-(.+)-[0-9]{8}-[0-9]{6}\.tar\.gz$ ]]; then
    # Backup de email
    DOMAIN="${BASH_REMATCH[1]}"
    MAIL_DIR="/var/mail/vhosts/$DOMAIN"
    
    echo "Restoring email backup: $DOMAIN"
    echo "WARNING: This will overwrite existing emails!"
    
    # Criar diretório se não existir
    mkdir -p "$MAIL_DIR"
    
    # Extrair backup
    tar -xzf "$BACKUP_FILE" -C "$MAIL_DIR"
    
    # Ajustar permissões
    chown -R vmail:vmail "$MAIL_DIR"
    
    echo "SUCCESS: Emails restored to $MAIL_DIR"
    exit 0
    
else
    echo "ERROR: Unknown backup type"
    exit 1
fi
