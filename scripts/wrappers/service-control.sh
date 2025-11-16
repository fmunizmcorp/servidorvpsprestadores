#!/bin/bash
# Wrapper seguro para controle de serviços
# /opt/webserver/scripts/wrappers/service-control.sh

set -e

# Validar número de argumentos
if [ "$#" -ne 2 ]; then
    echo "ERROR: Invalid arguments"
    echo "Usage: $0 <service> <action>"
    exit 1
fi

SERVICE="$1"
ACTION="$2"

# Lista branca de serviços permitidos
ALLOWED_SERVICES=("nginx" "php8.3-fpm" "mysql" "postfix" "dovecot" "clamav-daemon" "clamav-freshclam" "fail2ban")

# Lista branca de ações permitidas
ALLOWED_ACTIONS=("start" "stop" "restart" "reload" "status")

# Função para verificar se valor está na lista
contains() {
    local value="$1"
    shift
    local array=("$@")
    for item in "${array[@]}"; do
        if [ "$item" = "$value" ]; then
            return 0
        fi
    done
    return 1
}

# Validar serviço
if ! contains "$SERVICE" "${ALLOWED_SERVICES[@]}"; then
    echo "ERROR: Service '$SERVICE' is not allowed"
    exit 1
fi

# Validar ação
if ! contains "$ACTION" "${ALLOWED_ACTIONS[@]}"; then
    echo "ERROR: Action '$ACTION' is not allowed"
    exit 1
fi

# Executar comando
echo "Executing: systemctl $ACTION $SERVICE"
systemctl "$ACTION" "$SERVICE"

# Retornar status
if [ "$ACTION" = "status" ]; then
    exit 0
else
    # Verificar se comando foi bem sucedido
    if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
        echo "SUCCESS: Service $SERVICE is running"
        exit 0
    elif [ "$ACTION" = "stop" ]; then
        echo "SUCCESS: Service $SERVICE stopped"
        exit 0
    else
        echo "WARNING: Service status unknown"
        exit 0
    fi
fi
