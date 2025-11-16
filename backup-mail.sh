#!/bin/bash
# Backup de Email - Mailboxes e Configurações
# Autor: VPS Admin System
# Data: 2025-11-16

set -e

BACKUP_BASE="/opt/webserver/backups/mail"
LOG_FILE="/var/log/backup-mail.log"
RESTIC_PASSWORD="Jm@D@KDPnw7Q"
export RESTIC_PASSWORD

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Starting Email Backup ==="

mkdir -p "$BACKUP_BASE"/{mailboxes,config}

# Backup de Mailboxes
log "Backing up mailboxes..."
if [ -d "/opt/webserver/mail/mailboxes" ]; then
    REPO="$BACKUP_BASE/mailboxes"
    
    if [ ! -d "$REPO" ]; then
        restic init --repo "$REPO" 2>/dev/null || true
    fi
    
    restic backup /opt/webserver/mail/mailboxes --repo "$REPO" --quiet
    restic forget --repo "$REPO" --keep-daily 30 --prune --quiet
    
    log "  - Mailboxes backed up successfully"
fi

# Backup de configurações de email
log "Backing up email config..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar -czf "$BACKUP_BASE/config/mail-config-${TIMESTAMP}.tar.gz" \
    /opt/webserver/mail/config \
    /etc/postfix \
    /etc/dovecot \
    /etc/opendkim \
    /etc/opendmarc \
    2>/dev/null || true

# Manter apenas últimas 7 configs
cd "$BACKUP_BASE/config"
ls -t mail-config-*.tar.gz | tail -n +8 | xargs -r rm

log "=== Email Backup Completed Successfully ==="
