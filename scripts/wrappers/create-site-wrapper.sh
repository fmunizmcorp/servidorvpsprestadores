#!/bin/bash
# Wrapper seguro para criação de sites
# /opt/webserver/scripts/wrappers/create-site-wrapper.sh

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

# Verificar se site já existe
if [ -d "/opt/webserver/sites/$SITE_NAME" ]; then
    echo "ERROR: Site already exists"
    exit 1
fi

# Executar script principal
/opt/webserver/scripts/create-site.sh "$@"

exit $?
