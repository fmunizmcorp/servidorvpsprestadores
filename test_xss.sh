#!/bin/bash

COOKIES=$(mktemp)
RESPONSE=$(mktemp)

# Login as user with XSS payload (ID 1)
curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" > "$RESPONSE"
CSRF_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' "$RESPONSE" | head -1)

curl -k -b "$COOKIES" -c "$COOKIES" -X POST "https://72.61.53.222/admin/login" \
  -d "_token=$CSRF_TOKEN" -d "email=admin@vps.local" -d "password=Test@123456" \
  -L -s -o /dev/null 2>&1

echo "=== Checking if XSS script is escaped in HTML ==="
curl -k -b "$COOKIES" "https://72.61.53.222/admin/dashboard" -s | grep -o '<script>alert.*</script>\|&lt;script&gt;.*&lt;/script&gt;' | head -3

rm -f "$COOKIES" "$RESPONSE"
