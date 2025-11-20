#!/bin/bash

ADMIN_URL="https://72.61.53.222/admin"
LOGIN_URL="$ADMIN_URL/login"
COOKIES_FILE="cookies_sprint36_test.txt"

echo "Fetching login page..."
curl -k -s -c "$COOKIES_FILE" "$LOGIN_URL" > /dev/null

echo "Getting CSRF token..."
CSRF_TOKEN=$(curl -k -s -b "$COOKIES_FILE" "$LOGIN_URL" | grep -oP 'name="_token" value="\K[^"]+' | head -1)
echo "CSRF: ${CSRF_TOKEN:0:30}..."

echo ""
echo "Attempting login..."
curl -k -v -b "$COOKIES_FILE" -c "$COOKIES_FILE" \
    -X POST "$LOGIN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "_token=$CSRF_TOKEN&email=test@admin.local&password=Test@123456" \
    2>&1 | grep -E "(< HTTP|< Location)"

echo ""
echo "Cookies after login:"
cat "$COOKIES_FILE"
