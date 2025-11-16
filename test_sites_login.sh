#!/bin/bash

# Get CSRF token and login
echo "=== Step 1: Getting login page and CSRF token ==="
COOKIES=$(mktemp)
RESPONSE=$(mktemp)

curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" > "$RESPONSE"
CSRF_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' "$RESPONSE" | head -1)

echo "CSRF Token: ${CSRF_TOKEN:0:20}..."

echo ""
echo "=== Step 2: Logging in ==="
curl -k -b "$COOKIES" -c "$COOKIES" \
  -X POST "https://72.61.53.222/admin/login" \
  -d "_token=$CSRF_TOKEN" \
  -d "email=test@admin.local" \
  -d "password=Test@123456" \
  -L -s -o /dev/null -w "HTTP Status: %{http_code}\n"

echo ""
echo "=== Step 3: Accessing Sites Management page ==="
curl -k -b "$COOKIES" \
  "https://72.61.53.222/admin/sites" \
  -s -w "\nHTTP Status: %{http_code}\n" | head -50

rm -f "$COOKIES" "$RESPONSE"
