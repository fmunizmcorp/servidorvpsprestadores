#!/bin/bash
# Script auxiliar para executar comandos no servidor VPS remoto
# Uso: ./remote-exec.sh "comando"

HOST="72.61.53.222"
USER="root"
PASS="Jm@D@KDPnw7Q"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30 "$USER@$HOST" "$@"
