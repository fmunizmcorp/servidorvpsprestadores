#!/bin/bash
COOKIES=$(mktemp)

# Login
curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" > /dev/null
CSRF=$(curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" | grep -oP 'name="_token" value="\K[^"]+' | head -1)
curl -k -b "$COOKIES" -c "$COOKIES" -X POST "https://72.61.53.222/admin/login" \
  -d "_token=$CSRF" -d "email=test@admin.local" -d "password=Test@123456" -L -s > /dev/null

# Get fresh CSRF
CSRF=$(curl -k -b "$COOKIES" -s "https://72.61.53.222/admin/email/domains" | grep -oP 'name="_token" value="\K[^"]+' | tail -1)

# Submit with explicit Content-Type
echo "=== Testing with proper headers ==="
curl -k -b "$COOKIES" -c "$COOKIES" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "X-CSRF-TOKEN: $CSRF" \
  --data-urlencode "_token=$CSRF" \
  --data-urlencode "domain=proper$(date +%s).test.com" \
  "https://72.61.53.222/admin/email/domains" \
  -L -s -w "\nHTTP: %{http_code}\nURL: %{url_effective}\n" -o /tmp/response.html

echo ""
echo "=== Response preview ==="
head -20 /tmp/response.html | grep -E "success|error|Domain" || echo "No clear success/error message"

rm -f "$COOKIES"
