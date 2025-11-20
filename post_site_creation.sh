#!/bin/bash
# Post-site-creation script to update database status
# Usage: post_site_creation.sh <site_name>

SITE_NAME="$1"

if [ -z "$SITE_NAME" ]; then
    echo "Error: Site name required"
    exit 1
fi

# Wait for filesystem operations to complete
sleep 3

# Update database status to 'active' using mysql directly (no sudo needed)
mysql -u root -p'Jm@D@KDPnw7Q' admin_panel << SQL
UPDATE sites SET status='active', ssl_enabled=1 WHERE site_name='$SITE_NAME';
SQL

echo "Site $SITE_NAME status updated to active"
