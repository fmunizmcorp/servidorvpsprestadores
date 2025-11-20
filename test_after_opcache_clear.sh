#!/bin/bash

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="cookies_sprint36_test.txt"
SITE_NAME="sprint36v2$(date +%s)"
DOMAIN="${SITE_NAME}.local"

echo "Testing after OPcache clear..."
echo "Site: $SITE_NAME"

# Get CSRF
CSRF=$(curl -k -s -b "$COOKIES" "$ADMIN_URL/sites/create" | grep -oP 'name="_token" value="\K[^"]+' | head -1)

# Submit
curl -k -s -b "$COOKIES" -X POST "$ADMIN_URL/sites" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "_token=$CSRF&site_name=$SITE_NAME&domain=$DOMAIN&php_version=8.3&create_database=1&template=php" \
    -w "HTTP:%{http_code}\n" > /dev/null

echo "Waiting 35 seconds..."
sleep 35

echo ""
echo "=== DATABASE CHECK ==="
sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e \"SELECT site_name, status FROM sites WHERE site_name='$SITE_NAME';\""

echo ""
echo "=== LARAVEL LOG (last 20 Sprint 36 lines) ==="
sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "tail -100 /opt/webserver/admin-panel/storage/logs/laravel.log | grep 'SPRINT 36' | tail -20"

echo ""
echo "=== POST-CREATION LOG ==="
sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "cat /tmp/post-site-${SITE_NAME}.log 2>/dev/null || echo 'NOT FOUND'"
