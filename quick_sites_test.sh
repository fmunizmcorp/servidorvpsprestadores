#!/bin/bash
COOKIE_FILE="/tmp/quick_test_cookies.txt"
rm -f "$COOKIE_FILE"

# Get CSRF and login
CSRF=$(curl -k -c "$COOKIE_FILE" -s "https://72.61.53.222/admin/login" | grep -oP 'name="_token"\s+value="\K[^"]+' | head -1)
curl -k -b "$COOKIE_FILE" -c "$COOKIE_FILE" -X POST -s -d "_token=$CSRF" -d "email=admin@vps.local" -d "password=Admin2024VPS" "https://72.61.53.222/admin/login" > /dev/null

# Test Sites
HTTP_CODE=$(curl -k -b "$COOKIE_FILE" -s -w "%{http_code}" -o /dev/null "https://72.61.53.222/admin/sites")
echo "Sites Management HTTP Code: $HTTP_CODE"
rm -f "$COOKIE_FILE"
