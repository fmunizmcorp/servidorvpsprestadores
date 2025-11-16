#!/bin/bash
# Sistema de Backup Completo - Sites e Databases
# Autor: VPS Admin System
# Data: 2025-11-16

set -e

BACKUP_BASE="/opt/webserver/backups"
LOG_FILE="/var/log/backup.log"
RESTIC_PASSWORD="Jm@D@KDPnw7Q"
export RESTIC_PASSWORD

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Starting Backup ==="

# Criar diretórios se não existirem
mkdir -p "$BACKUP_BASE"/{sites,databases,mail}

# Backup de Sites
log "Backing up sites..."
if [ -d "/opt/webserver/sites" ]; then
    for site in /opt/webserver/sites/*/ ; do
        if [ -d "$site" ]; then
            site_name=$(basename "$site")
            REPO="$BACKUP_BASE/sites/$site_name"
            
            log "  - Site: $site_name"
            
            if [ ! -d "$REPO" ]; then
                restic init --repo "$REPO" 2>/dev/null || true
            fi
            
            restic backup "$site" --repo "$REPO" --exclude cache --exclude logs --quiet
            restic forget --repo "$REPO" --keep-daily 7 --prune --quiet
        fi
    done
fi

# Backup de Databases
log "Backing up databases..."
mkdir -p "$BACKUP_BASE/databases/daily"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

for db in $(mysql -e "SHOW DATABASES;" | grep -Ev "^(Database|information_schema|performance_schema|mysql|sys)$"); do
    log "  - Database: $db"
    mysqldump "$db" 2>/dev/null | gzip > "$BACKUP_BASE/databases/daily/${db}_${TIMESTAMP}.sql.gz"
    md5sum "$BACKUP_BASE/databases/daily/${db}_${TIMESTAMP}.sql.gz" > "$BACKUP_BASE/databases/daily/${db}_${TIMESTAMP}.sql.gz.md5"
done

# Rotacionar backups de database (manter 7 dias)
find "$BACKUP_BASE/databases/daily" -name "*.sql.gz" -mtime +7 -delete

# Backup de configurações do sistema
log "Backing up system config..."
tar -czf "$BACKUP_BASE/system-config-$(date +%Y%m%d).tar.gz" \
    /opt/webserver/config \
    /etc/nginx/sites-available \
    /etc/php/8.3/fpm/pool.d \
    2>/dev/null || true

# Limpar configs antigas (manter 30 dias)
find "$BACKUP_BASE" -name "system-config-*.tar.gz" -mtime +30 -delete

log "=== Backup Completed Successfully ==="
