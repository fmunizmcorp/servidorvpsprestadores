#!/bin/bash
# Wrapper seguro para criação de sites
# SPRINT 32: Simplified wrapper - calls /root/create-site.sh

set -e

if [ "$#" -lt 2 ]; then
    echo "ERROR: Invalid arguments"
    echo "Usage: $0 <site-name> <domain> [php-version] [--no-db] [--template=TYPE]"
    exit 1
fi

SITE_NAME="$1"
DOMAIN="$2"

# Validações de segurança
if [[ ! "$SITE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "ERROR: Invalid site name format"
    exit 1
fi

if [[ ! "$DOMAIN" =~ ^[a-z0-9.-]+$ ]]; then
    echo "ERROR: Invalid domain format"
    exit 1
fi

# Verificar se site já existe no path /var/www (conforme documentação)
if [ -d "/var/www/$SITE_NAME" ]; then
    echo "ERROR: Site already exists"
    exit 1
fi

# Executar script principal no servidor (path real conforme documentação)
# O script /root/create-site.sh deve existir no servidor de produção
if [ -f "/root/create-site.sh" ]; then
    /root/create-site.sh "$@"
else
    echo "ERROR: Main creation script not found at /root/create-site.sh"
    echo "Please ensure the server is properly configured"
    exit 1
fi

exit $?
