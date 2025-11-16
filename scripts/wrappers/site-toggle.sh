#!/bin/bash
# Wrapper seguro para ativar/desativar sites
# /opt/webserver/scripts/wrappers/site-toggle.sh

set -e

if [ "$#" -ne 2 ]; then
    echo "ERROR: Invalid arguments"
    echo "Usage: $0 <site-name> <enable|disable>"
    exit 1
fi

SITE_NAME="$1"
ACTION="$2"

# Validar site name (apenas alfanumérico, hífen, underscore e ponto)
if [[ ! "$SITE_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "ERROR: Invalid site name"
    exit 1
fi

AVAILABLE="/etc/nginx/sites-available/$SITE_NAME"
ENABLED="/etc/nginx/sites-enabled/$SITE_NAME"

# Procurar por arquivo .conf se o arquivo direto não existir
if [ ! -f "$AVAILABLE" ] && [ -f "${AVAILABLE}.conf" ]; then
    AVAILABLE="${AVAILABLE}.conf"
    ENABLED="${ENABLED}.conf"
fi

# Procurar por padrão no diretório
if [ ! -f "$AVAILABLE" ]; then
    FOUND=$(find /etc/nginx/sites-available -name "${SITE_NAME}*" -type f | head -1)
    if [ -n "$FOUND" ]; then
        AVAILABLE="$FOUND"
        ENABLED="/etc/nginx/sites-enabled/$(basename "$FOUND")"
    fi
fi

# Verificar se site existe
if [ ! -f "$AVAILABLE" ]; then
    echo "ERROR: Site configuration not found: $SITE_NAME"
    exit 1
fi

case "$ACTION" in
    "enable")
        if [ -L "$ENABLED" ]; then
            echo "INFO: Site is already enabled"
            exit 0
        fi
        
        echo "Enabling site: $SITE_NAME"
        ln -s "$AVAILABLE" "$ENABLED"
        
        # Testar configuração NGINX
        if nginx -t 2>&1; then
            # Recarregar NGINX
            systemctl reload nginx
            echo "SUCCESS: Site enabled and NGINX reloaded"
            exit 0
        else
            # Remover symlink se teste falhar
            rm -f "$ENABLED"
            echo "ERROR: NGINX configuration test failed, site not enabled"
            exit 1
        fi
        ;;
        
    "disable")
        if [ ! -L "$ENABLED" ] && [ ! -f "$ENABLED" ]; then
            echo "INFO: Site is already disabled"
            exit 0
        fi
        
        echo "Disabling site: $SITE_NAME"
        rm -f "$ENABLED"
        
        # Recarregar NGINX
        if systemctl reload nginx; then
            echo "SUCCESS: Site disabled and NGINX reloaded"
            exit 0
        else
            echo "ERROR: Failed to reload NGINX"
            exit 1
        fi
        ;;
        
    *)
        echo "ERROR: Invalid action. Use 'enable' or 'disable'"
        exit 1
        ;;
esac
