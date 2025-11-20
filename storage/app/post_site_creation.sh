#!/bin/bash
# Post-site-creation script to update database status
# Usage: post_site_creation.sh <site_name>
# SPRINT 34 FIX: Added error handling and logging
# SPRINT 36 FIX: Enhanced logging and execution verification

SITE_NAME="$1"
LOG_FILE="/tmp/post-site-${SITE_NAME}.log"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== SPRINT 36: POST-SITE-CREATION SCRIPT STARTED ==="
log "Executed by: $(whoami)"
log "Current user ID: $(id)"
log "Script path: $0"
log "Site name: $SITE_NAME"

if [ -z "$SITE_NAME" ]; then
    log "ERROR: Site name required"
    exit 1
fi

log "Starting post-site-creation for: $SITE_NAME"

# SPRINT 35 FIX: Wait longer for wrapper script to complete site creation
# SPRINT 36: Enhanced with progress logging
log "Waiting for wrapper script to complete site creation..."
sleep 15
log "Waited 15 seconds for filesystem operations"

# Verify site directory was created
if [ -d "/opt/webserver/sites/$SITE_NAME" ] || [ -d "/var/www/$SITE_NAME" ]; then
    log "Site directory exists - filesystem creation confirmed"
else
    log "WARNING: Site directory not found yet, waiting additional 10 seconds..."
    sleep 10
fi

# Check if site exists in database
SITE_EXISTS=$(mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -N -e "SELECT COUNT(*) FROM sites WHERE site_name='$SITE_NAME';")
log "Site exists in database: $SITE_EXISTS"

if [ "$SITE_EXISTS" = "0" ]; then
    log "ERROR: Site $SITE_NAME not found in database. Cannot update status."
    exit 1
fi

# Update database status to 'active' using mysql directly (no sudo needed)
log "SPRINT 36: Attempting to update site status to active..."
log "Database: admin_panel, Table: sites, Site: $SITE_NAME"

UPDATE_RESULT=$(mysql -u root -p'Jm@D@KDPnw7Q' admin_panel << SQL
UPDATE sites SET status='active', ssl_enabled=1 WHERE site_name='$SITE_NAME';
SELECT ROW_COUNT();
SQL
)

log "Database update result: $UPDATE_RESULT"
log "Rows affected: $(echo "$UPDATE_RESULT" | tail -n 1)"

# Verify update was successful
UPDATED_STATUS=$(mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -N -e "SELECT status FROM sites WHERE site_name='$SITE_NAME';")
log "Current site status after update: $UPDATED_STATUS"

if [ "$UPDATED_STATUS" = "active" ]; then
    log "=== SPRINT 36: SUCCESS - Site $SITE_NAME status updated to active ==="
    log "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    exit 0
else
    log "=== SPRINT 36: ERROR - Failed to update site $SITE_NAME status ==="
    log "Expected: active, Got: $UPDATED_STATUS"
    exit 1
fi
