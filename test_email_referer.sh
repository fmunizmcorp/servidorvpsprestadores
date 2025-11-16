#!/bin/bash
COOKIES=$(mktemp)

curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" > /dev/null
CSRF=$(curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" | grep -oP 'name="_token" value="\K[^"]+' | head -1)
curl -k -b "$COOKIES" -c "$COOKIES" -X POST "https://72.61.53.222/admin/login" \
  -d "_token=$CSRF" -d "email=test@admin.local" -d "password=Test@123456" -L -s > /dev/null

CSRF=$(curl -k -b "$COOKIES" -s "https://72.61.53.222/admin/email/domains" | grep -oP 'name="_token" value="\K[^"]+' | tail -1)

echo "Testing with Referer header..."
curl -k -b "$COOKIES" -c "$COOKIES" \
  -X POST \
  -H "Referer: https://72.61.53.222/admin/email/domains" \
  -d "_token=$CSRF" \
  -d "domain=referer$(date +%s).test.com" \
  "https://72.61.53.222/admin/email/domains" \
  -L -s -w "\nHTTP: %{http_code}\nFinal URL: %{url_effective}\n" | grep -E "HTTP:|Final URL:|success|created|Error"

rm -f "$COOKIES"
