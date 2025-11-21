#!/bin/bash

echo "=================================="
echo "TESTE E2E: CRIAR EMAIL ACCOUNT"
echo "=================================="

# 1. Login
echo "[1/4] Fazendo login..."
COOKIE_FILE="/tmp/test_account_cookies.txt"
BASE_URL="https://72.61.53.222/admin"

# Get CSRF token
LOGIN_PAGE=$(curl -k -s -c $COOKIE_FILE "$BASE_URL/login")
CSRF_TOKEN=$(echo "$LOGIN_PAGE" | grep -o 'name="_token" value="[^"]*"' | cut -d'"' -f4 | head -1)

# Login
curl -k -s -b $COOKIE_FILE -c $COOKIE_FILE -X POST "$BASE_URL/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=$CSRF_TOKEN&email=test@admin.local&password=password" > /dev/null 2>&1

echo "✅ Login efetuado"

# 2. Get create form
echo "[2/4] Obtendo formulário de criação..."
CREATE_PAGE=$(curl -k -s -b $COOKIE_FILE "$BASE_URL/email/accounts/create")
FORM_CSRF=$(echo "$CREATE_PAGE" | grep -o 'name="_token" value="[^"]*"' | cut -d'"' -f4 | head -1)

if [ -z "$FORM_CSRF" ]; then
    echo "❌ ERRO: CSRF token não encontrado na página"
    exit 1
fi

echo "✅ CSRF token obtido: ${FORM_CSRF:0:20}..."

# 3. Verificar se há domínios disponíveis
DOMAINS=$(echo "$CREATE_PAGE" | grep -o '<option value="[^"]*"' | cut -d'"' -f2 | grep -v "^$" | head -1)

if [ -z "$DOMAINS" ]; then
    echo "❌ ERRO: Nenhum domínio disponível"
    echo "Criando domínio de teste primeiro..."
    
    # Criar domínio
    DOMAIN_PAGE=$(curl -k -s -b $COOKIE_FILE "$BASE_URL/email/domains/create")
    DOMAIN_CSRF=$(echo "$DOMAIN_PAGE" | grep -o 'name="_token" value="[^"]*"' | cut -d'"' -f4 | head -1)
    
    curl -k -s -b $COOKIE_FILE -X POST "$BASE_URL/email/domains" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "_token=$DOMAIN_CSRF&domain=sprint50test.local" > /dev/null 2>&1
    
    echo "✅ Domínio sprint50test.local criado"
    DOMAINS="sprint50test.local"
fi

echo "✅ Domínio disponível: $DOMAINS"

# 4. Criar conta de email
echo "[3/4] Criando conta de email..."
TIMESTAMP=$(date +%s)
USERNAME="testuser$TIMESTAMP"
EMAIL="$USERNAME@$DOMAINS"

echo "Criando: $EMAIL"

RESPONSE=$(curl -k -s -w "\nHTTP_CODE:%{http_code}\nREDIRECT:%{redirect_url}" \
  -b $COOKIE_FILE -X POST "$BASE_URL/email/accounts" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_token=$FORM_CSRF&domain=$DOMAINS&username=$USERNAME&password=Test@123456&quota=1024")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
REDIRECT=$(echo "$RESPONSE" | grep "REDIRECT:" | cut -d':' -f2-)

echo ""
echo "HTTP Code: $HTTP_CODE"
echo "Redirect: $REDIRECT"

if [ "$HTTP_CODE" = "500" ]; then
    echo ""
    echo "❌ ERRO 500 DETECTADO!"
    echo "Resposta do servidor:"
    echo "$RESPONSE" | head -50
elif [ "$HTTP_CODE" = "302" ]; then
    echo "✅ Redirecionamento (provável sucesso)"
    
    # 5. Verificar se foi criado
    echo "[4/4] Verificando se conta foi criada..."
    
    ACCOUNTS_PAGE=$(curl -k -s -b $COOKIE_FILE "$BASE_URL/email/accounts?domain=$DOMAINS")
    
    if echo "$ACCOUNTS_PAGE" | grep -q "$EMAIL"; then
        echo "✅ SUCESSO! Conta $EMAIL encontrada na listagem"
    else
        echo "❌ FALHA! Conta $EMAIL NÃO encontrada na listagem"
    fi
else
    echo "⚠️  HTTP $HTTP_CODE (inesperado)"
    echo "$RESPONSE" | head -30
fi

