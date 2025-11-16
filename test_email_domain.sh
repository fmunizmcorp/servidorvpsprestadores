#!/bin/bash

COOKIES=$(mktemp)
RESPONSE=$(mktemp)

echo "=== Login ==="
curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" > "$RESPONSE"
CSRF_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' "$RESPONSE" | head -1)

curl -k -b "$COOKIES" -c "$COOKIES" -X POST "https://72.61.53.222/admin/login" \
  -d "_token=$CSRF_TOKEN" -d "email=test@admin.local" -d "password=Test@123456" \
  -L -s -o /dev/null

echo "=== Get Email Domains Page ==="
curl -k -b "$COOKIES" -s "https://72.61.53.222/admin/email/domains" > "$RESPONSE"
CSRF_TOKEN=$(grep -oP 'name="_token" value="\K[^"]+' "$RESPONSE" | head -1)

echo "=== Submit Create Domain Form ==="
curl -k -b "$COOKIES" -c "$COOKIES" -L \
  -X POST "https://72.61.53.222/admin/email/storeDomain" \
  -d "_token=$CSRF_TOKEN" \
  -d "domain=test$(date +%s).example.com" \
  -s -w "\nFinal URL: %{url_effective}\nHTTP Status: %{http_code}\n" \
  -o /dev/null

rm -f "$COOKIES" "$RESPONSE"
