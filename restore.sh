#!/bin/bash
# Script de Restore - Sites e Databases
# Autor: VPS Admin System
# Data: 2025-11-16

set -e

BACKUP_BASE="/opt/webserver/backups"
RESTIC_PASSWORD="Jm@D@KDPnw7Q"
export RESTIC_PASSWORD

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <type> <name> [snapshot_id]"
    echo ""
    echo "Types:"
    echo "  site <site_name> [snapshot_id]  - Restore site"
    echo "  db <database_name>              - Restore latest database"
    echo ""
    echo "Examples:"
    echo "  $0 site prestadores"
    echo "  $0 site prestadores abc123"
    echo "  $0 db admin_panel"
    exit 1
fi

TYPE=$1
NAME=$2
SNAPSHOT=${3:-latest}

case $TYPE in
    site)
        echo "Restoring site: $NAME (snapshot: $SNAPSHOT)"
        REPO="$BACKUP_BASE/sites/$NAME"
        
        if [ ! -d "$REPO" ]; then
            echo "ERROR: No backup found for site $NAME"
            exit 1
        fi
        
        echo "Available snapshots:"
        restic snapshots --repo "$REPO"
        echo ""
        
        read -p "Confirm restore? This will OVERWRITE current files! (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Restore cancelled"
            exit 0
        fi
        
        restic restore $SNAPSHOT --repo "$REPO" --target /opt/webserver/sites/$NAME
        chown -R www-data:www-data /opt/webserver/sites/$NAME
        echo "Site restored successfully!"
        ;;
        
    db)
        echo "Restoring database: $NAME"
        LATEST=$(ls -t "$BACKUP_BASE/databases/daily/${NAME}_"*.sql.gz 2>/dev/null | head -1)
        
        if [ -z "$LATEST" ]; then
            echo "ERROR: No backup found for database $NAME"
            exit 1
        fi
        
        echo "Found backup: $(basename $LATEST)"
        echo ""
        
        read -p "Confirm restore? This will OVERWRITE current database! (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Restore cancelled"
            exit 0
        fi
        
        zcat "$LATEST" | mysql "$NAME"
        echo "Database restored successfully!"
        ;;
        
    *)
        echo "ERROR: Unknown type: $TYPE"
        exit 1
        ;;
esac
