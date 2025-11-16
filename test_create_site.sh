#!/bin/bash

COOKIES=$(mktemp)
RESPONSE=$(mktemp)

echo "=== Step 1: Login ==="
curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" > "$RESPONSE"
CSRF_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' "$RESPONSE" | head -1)

curl -k -b "$COOKIES" -c "$COOKIES" -X POST "https://72.61.53.222/admin/login" \
  -d "_token=$CSRF_TOKEN" -d "email=test@admin.local" -d "password=Test@123456" \
  -L -s -o /dev/null

echo "=== Step 2: Get Create Site Form ==="
curl -k -b "$COOKIES" -s "https://72.61.53.222/admin/sites/create" > "$RESPONSE"
CSRF_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' "$RESPONSE" | head -1)

echo "CSRF Token: ${CSRF_TOKEN:0:20}..."

echo ""
echo "=== Step 3: Submit Create Site Form ==="
curl -k -b "$COOKIES" -c "$COOKIES" -L \
  -X POST "https://72.61.53.222/admin/sites" \
  -d "_token=$CSRF_TOKEN" \
  -d "site_name=testsite$(date +%s)" \
  -d "domain=test$(date +%s).example.com" \
  -d "php_version=8.3" \
  -d "create_database=1" \
  -s -w "\nFinal URL: %{url_effective}\nHTTP Status: %{http_code}\n" \
  -o /dev/null

rm -f "$COOKIES" "$RESPONSE"
