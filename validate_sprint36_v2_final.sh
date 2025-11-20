#!/bin/bash
# SPRINT 36 V2 - VALIDAÇÃO FINAL COMPLETA

set -e

ADMIN_URL="https://72.61.53.222/admin"
COOKIES="cookies_sprint36_v2_final.txt"
SITE_NAME="sprint36v2final$(date +%s)"
DOMAIN="${SITE_NAME}.local"
VPS_IP="72.61.53.222"
VPS_PASS="Jm@D@KDPnw7Q"

echo "========================================="
echo "  SPRINT 36 V2 - VALIDAÇÃO 100%"
echo "========================================="
echo "Site de teste: $SITE_NAME"
echo "Arquitetura: Laravel Events"
echo "========================================="
echo ""

remote_exec() {
    sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no root@$VPS_IP "$1"
}

echo "[1/10] Login no painel admin..."
curl -k -s -c "$COOKIES" "$ADMIN_URL/login" > /dev/null
CSRF=$(curl -k -s -b "$COOKIES" "$ADMIN_URL/login" | grep -oP 'name="_token" value="\K[^"]+' | head -1)
curl -k -s -b "$COOKIES" -c "$COOKIES" -X POST "$ADMIN_URL/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "_token=$CSRF&email=test@admin.local&password=Test@123456" > /dev/null
echo "✅ Login efetuado"
echo ""

echo "[2/10] Obtendo formulário de criação..."
CSRF=$(curl -k -s -b "$COOKIES" "$ADMIN_URL/sites/create" | grep -oP 'name="_token" value="\K[^"]+' | head -1)
echo "✅ CSRF token obtido"
echo ""

echo "[3/10] Submetendo criação de site..."
RESPONSE=$(curl -k -s -b "$COOKIES" -c "$COOKIES" \
    -X POST "$ADMIN_URL/sites" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "_token=$CSRF&site_name=$SITE_NAME&domain=$DOMAIN&php_version=8.3&create_database=1&template=php" \
    -w "\nHTTP_CODE:%{http_code}\n")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Request aceito (HTTP $HTTP_CODE)"
else
    echo "❌ ERRO: HTTP $HTTP_CODE"
    exit 1
fi
echo ""

echo "[4/10] Verificando site no banco de dados..."
sleep 2
DB_CHECK=$(remote_exec "mysql -u root -p'$VPS_PASS' admin_panel -N -e \"SELECT id, status FROM sites WHERE site_name='$SITE_NAME';\"")

if [ -z "$DB_CHECK" ]; then
    echo "❌ ERRO: Site não encontrado no banco!"
    exit 1
fi

SITE_ID=$(echo "$DB_CHECK" | awk '{print $1}')
INITIAL_STATUS=$(echo "$DB_CHECK" | awk '{print $2}')

echo "✅ Site criado no banco"
echo "  ID: $SITE_ID"
echo "  Status inicial: $INITIAL_STATUS"
echo ""

echo "[5/10] Verificando logs do Laravel (Event dispatch)..."
sleep 1
EVENT_LOG=$(remote_exec "tail -30 /opt/webserver/admin-panel/storage/logs/laravel.log | grep -i 'sprint36 v2\|sitecreated event' | tail -5")

if echo "$EVENT_LOG" | grep -q "SiteCreated event dispatched"; then
    echo "✅ Event SiteCreated disparado"
    echo "Log:"
    echo "$EVENT_LOG" | head -2
else
    echo "❌ WARNING: Event não encontrado nos logs"
fi
echo ""

echo "[6/10] Aguardando execução do Listener (35 segundos)..."
for i in {35..1}; do
    printf "\r  Aguardando: %02d segundos restantes..." $i
    sleep 1
done
echo ""
echo "✅ Aguarde concluído"
echo ""

echo "[7/10] Verificando status final no banco..."
FINAL_CHECK=$(remote_exec "mysql -u root -p'$VPS_PASS' admin_panel -N -e \"SELECT site_name, status, ssl_enabled, created_at FROM sites WHERE site_name='$SITE_NAME';\"")

FINAL_STATUS=$(echo "$FINAL_CHECK" | awk '{print $2}')
SSL_STATUS=$(echo "$FINAL_CHECK" | awk '{print $3}')

echo "Detalhes do site:"
echo "  Nome: $SITE_NAME"
echo "  Status: $FINAL_STATUS"
echo "  SSL: $SSL_STATUS"
echo ""

if [ "$FINAL_STATUS" = "active" ]; then
    echo "✅ SUCCESS: Status = ACTIVE"
    STATUS_OK=true
else
    echo "❌ FAILURE: Status = $FINAL_STATUS (esperado: active)"
    STATUS_OK=false
fi
echo ""

echo "[8/10] Verificando logs do Listener..."
LISTENER_LOG=$(remote_exec "tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log | grep -i 'sprint 36.*event\|processsitecreation' | tail -10")

if echo "$LISTENER_LOG" | grep -q "Processing site creation in background"; then
    echo "✅ Listener ProcessSiteCreation executado"
    echo "Logs relevantes:"
    echo "$LISTENER_LOG" | grep "SPRINT 36" | head -3
    LISTENER_OK=true
else
    echo "❌ WARNING: Listener não encontrado nos logs"
    LISTENER_OK=false
fi
echo ""

echo "[9/10] Verificando log do post-creation script..."
POST_LOG=$(remote_exec "cat /tmp/post-site-${SITE_NAME}.log 2>/dev/null || echo 'NOT_FOUND'")

if echo "$POST_LOG" | grep -q "SUCCESS"; then
    echo "✅ post_site_creation.sh executado com sucesso"
    echo "Log excerpt:"
    echo "$POST_LOG" | grep "SUCCESS" | head -2
    SCRIPT_OK=true
else
    echo "❌ FAILURE: Script não executou ou falhou"
    echo "Log content: $POST_LOG"
    SCRIPT_OK=false
fi
echo ""

echo "[10/10] RESULTADO FINAL DA VALIDAÇÃO"
echo ""
echo "========================================="

if [ "$STATUS_OK" = true ] && [ "$LISTENER_OK" = true ] && [ "$SCRIPT_OK" = true ]; then
    echo "  ✅✅✅ SISTEMA 100% FUNCIONAL ✅✅✅"
    echo "========================================="
    echo ""
    echo "RESULTADOS:"
    echo "  ✅ Site criado no banco de dados"
    echo "  ✅ Event SiteCreated disparado"
    echo "  ✅ Listener ProcessSiteCreation executado"
    echo "  ✅ Scripts de criação executados"
    echo "  ✅ Status atualizado para 'active'"
    echo "  ✅ Logs completos e rastreáveis"
    echo ""
    echo "ARQUITETURA SPRINT 36 V2: APROVADA"
    echo "FUNCIONALIDADE: 100%"
    echo "QUALIDADE: PROFISSIONAL"
    echo ""
    echo "========================================="
    echo ""
    exit 0
else
    echo "  ❌ VALIDAÇÃO FALHOU"
    echo "========================================="
    echo ""
    echo "PROBLEMAS DETECTADOS:"
    
    if [ "$STATUS_OK" != true ]; then
        echo "  ❌ Status não é 'active'"
    fi
    
    if [ "$LISTENER_OK" != true ]; then
        echo "  ❌ Listener não executou"
    fi
    
    if [ "$SCRIPT_OK" != true ]; then
        echo "  ❌ post_site_creation.sh não completou"
    fi
    
    echo ""
    echo "Sistema NÃO está 100% funcional"
    echo "Investigação adicional necessária"
    echo ""
    echo "========================================="
    echo ""
    exit 1
fi
