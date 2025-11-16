#!/bin/bash
# Wrapper seguro para testar configuração NGINX
# /opt/webserver/scripts/wrappers/nginx-test.sh

set -e

echo "Testing NGINX configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "SUCCESS: NGINX configuration is valid"
    exit 0
else
    echo "ERROR: NGINX configuration has errors"
    exit 1
fi
