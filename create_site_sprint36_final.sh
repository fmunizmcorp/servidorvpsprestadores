#!/bin/bash

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="cookies_sprint36_test.txt"
SITE_NAME="sprint36final$(date +%s)"
DOMAIN="${SITE_NAME}.local"

echo "========================================="
echo " SPRINT 36 - FINAL SITE CREATION TEST"
echo "========================================="
echo "Site: $SITE_NAME"
echo ""

echo "[1/3] Getting create form CSRF token..."
CSRF_TOKEN=$(curl -k -s -b "$COOKIES" "$ADMIN_URL/sites/create" | grep -oP 'name="_token" value="\K[^"]+' | head -1)
echo "CSRF: ${CSRF_TOKEN:0:30}..."
echo ""

echo "[2/3] Submitting site creation form..."
RESPONSE=$(curl -k -s -b "$COOKIES" -c "$COOKIES" \
    -X POST "$ADMIN_URL/sites" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Referer: $ADMIN_URL/sites/create" \
    -d "_token=$CSRF_TOKEN&site_name=$SITE_NAME&domain=$DOMAIN&php_version=8.3&create_database=1&template=php" \
    -w "\nHTTP_CODE:%{http_code}\n")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Site creation request accepted"
else
    echo "❌ ERROR: HTTP $HTTP_CODE"
    exit 1
fi
echo ""

echo "[3/3] Waiting 35 seconds for background processing..."
sleep 35
echo ""

echo "Checking database status..."
sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e \"SELECT site_name, status, created_at FROM sites WHERE site_name='$SITE_NAME';\""

echo ""
echo "Checking post-creation log..."
sshpass -p 'Jm@D@KDPnw7Q' ssh -o StrictHostKeyChecking=no root@72.61.53.222 \
    "cat /tmp/post-site-${SITE_NAME}.log 2>/dev/null || echo 'Log not found'"

echo ""
echo "========================================="
