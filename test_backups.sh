#!/bin/bash

COOKIES=$(mktemp)
RESPONSE=$(mktemp)

# Login first
curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" > "$RESPONSE"
CSRF_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' "$RESPONSE" | head -1)

curl -k -b "$COOKIES" -c "$COOKIES" -X POST "https://72.61.53.222/admin/login" \
  -d "_token=$CSRF_TOKEN" -d "email=test@admin.local" -d "password=Test@123456" \
  -L -s -o /dev/null

echo "=== Testing Backups Management page ==="
curl -k -b "$COOKIES" "https://72.61.53.222/admin/backups" -s -w "\nHTTP Status: %{http_code}\n" | grep -E "(Backups|Total Backups|HTTP Status)" | head -10

rm -f "$COOKIES" "$RESPONSE"
