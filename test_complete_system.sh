#!/bin/bash

# Script de testes completos do sistema VPS Admin Panel
# Sprint 48 - Validação completa pós-correção

BASE_URL="https://72.61.53.222/admin"
COOKIE_FILE="/tmp/admin_cookie.txt"
RESULTS_FILE="/tmp/qa_results.txt"

echo "========================================" > $RESULTS_FILE
echo "RELATÓRIO DE QA - TESTES COMPLETOS" >> $RESULTS_FILE
echo "Data: $(date '+%Y-%m-%d %H:%M:%S')" >> $RESULTS_FILE
echo "========================================" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Função para testar página
test_page() {
    local url=$1
    local name=$2
    local method=${3:-GET}
    
    echo "Testando: $name" >> $RESULTS_FILE
    echo "URL: $url" >> $RESULTS_FILE
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -b $COOKIE_FILE "$url" 2>&1)
    fi
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d':' -f2)
    
    if [ "$http_code" = "200" ]; then
        echo "Status: ✅ SUCESSO (200 OK)" >> $RESULTS_FILE
        
        # Verificar CSRF tokens
        csrf_count=$(echo "$response" | grep -o 'name="_token"' | wc -l)
        if [ $csrf_count -gt 0 ]; then
            echo "CSRF Tokens: $csrf_count encontrado(s)" >> $RESULTS_FILE
        fi
        
        # Verificar título
        title=$(echo "$response" | grep -o '<title>[^<]*</title>' | sed 's/<[^>]*>//g')
        if [ ! -z "$title" ]; then
            echo "Título: $title" >> $RESULTS_FILE
        fi
        
    elif [ "$http_code" = "302" ]; then
        echo "Status: ⚠️  REDIRECIONAMENTO (302)" >> $RESULTS_FILE
    elif [ "$http_code" = "500" ]; then
        echo "Status: ❌ ERRO 500 - ERRO INTERNO DO SERVIDOR" >> $RESULTS_FILE
    elif [ "$http_code" = "404" ]; then
        echo "Status: ❌ ERRO 404 - PÁGINA NÃO ENCONTRADA" >> $RESULTS_FILE
    else
        echo "Status: ❌ ERRO ($http_code)" >> $RESULTS_FILE
    fi
    
    echo "" >> $RESULTS_FILE
}

# 1. Login
echo "=== FASE 1: AUTENTICAÇÃO ===" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

login_response=$(curl -s -c $COOKIE_FILE -w "\nHTTP_CODE:%{http_code}" \
    -X POST "$BASE_URL/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "email=test@admin.local&password=password" 2>&1)

login_code=$(echo "$login_response" | grep "HTTP_CODE:" | cut -d':' -f2)

if [ "$login_code" = "302" ]; then
    echo "Login: ✅ SUCESSO (302 redirect)" >> $RESULTS_FILE
else
    echo "Login: ❌ FALHOU ($login_code)" >> $RESULTS_FILE
fi
echo "" >> $RESULTS_FILE

# 2. Dashboard
echo "=== FASE 2: DASHBOARD ===" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE
test_page "$BASE_URL/dashboard" "Dashboard Principal"

# 3. Email Domains
echo "=== FASE 3: EMAIL DOMAINS ===" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE
test_page "$BASE_URL/email/domains" "Listagem de Domínios"
test_page "$BASE_URL/email/domains/create" "Criar Domínio (SPRINT 48 FIX)"

# 4. Email Accounts
echo "=== FASE 4: EMAIL ACCOUNTS ===" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE
test_page "$BASE_URL/email/accounts" "Listagem de Contas"
test_page "$BASE_URL/email/accounts/create" "Criar Conta de Email"

# 5. Sites
echo "=== FASE 5: SITES ===" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE
test_page "$BASE_URL/sites" "Listagem de Sites"
test_page "$BASE_URL/sites/create" "Criar Site"

# 6. Profile
echo "=== FASE 6: PERFIL ===" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE
test_page "$BASE_URL/profile" "Editar Perfil"

echo "========================================" >> $RESULTS_FILE
echo "FIM DOS TESTES" >> $RESULTS_FILE
echo "========================================" >> $RESULTS_FILE

cat $RESULTS_FILE
