#!/bin/bash
COOKIES=$(mktemp)
curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" > /dev/null
CSRF=$(curl -k -c "$COOKIES" -s "https://72.61.53.222/admin/login" | grep -oP 'name="_token" value="\K[^"]+' | head -1)
curl -k -b "$COOKIES" -c "$COOKIES" -X POST "https://72.61.53.222/admin/login" \
  -d "_token=$CSRF" -d "email=test@admin.local" -d "password=Test@123456" -L -s > /dev/null

curl -k -b "$COOKIES" -s "https://72.61.53.222/admin/email/domains" | grep -A 30 "Add Email Domain"
rm -f "$COOKIES"
