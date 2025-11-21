#!/bin/bash

BASE_URL="https://72.61.53.222/admin"
COOKIE_FILE="/tmp/admin_cookie.txt"
RESULTS_FILE="/tmp/qa_results.txt"

echo "========================================" > $RESULTS_FILE
echo "RELATÓRIO DE QA - TESTES COMPLETOS" >> $RESULTS_FILE
echo "Data: $(date '+%Y-%m-%d %H:%M:%S')" >> $RESULTS_FILE
echo "Sistema: VPS Admin Panel Laravel 11.x" >> $RESULTS_FILE
echo "========================================" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Função para testar página
test_page() {
    local url=$1
    local name=$2
    
    echo "Testando: $name" >> $RESULTS_FILE
    echo "URL: $url" >> $RESULTS_FILE
    
    response=$(curl -k -s -w "\nHTTP_CODE:%{http_code}" -b $COOKIE_FILE "$url" 2>&1)
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d':' -f2)
    
    if [ "$http_code" = "200" ]; then
        echo "Status: ✅ SUCESSO (200 OK)" >> $RESULTS_FILE
        
        # Verificar CSRF tokens
        csrf_count=$(echo "$response" | grep -o 'name="_token"' | wc -l)
        if [ $csrf_count -gt 0 ]; then
            echo "CSRF Tokens: $csrf_count encontrado(s)" >> $RESULTS_FILE
        fi
        
        # Verificar título
        title=$(echo "$response" | grep -o '<title>[^<]*</title>' | sed 's/<[^>]*>//g' | head -1)
        if [ ! -z "$title" ]; then
            echo "Título: $title" >> $RESULTS_FILE
        fi
        
        # Verificar se tem form
        has_form=$(echo "$response" | grep -c '<form')
        if [ $has_form -gt 0 ]; then
            echo "Formulário: Encontrado" >> $RESULTS_FILE
        fi
        
    elif [ "$http_code" = "302" ]; then
        echo "Status: ⚠️  REDIRECIONAMENTO (302)" >> $RESULTS_FILE
    elif [ "$http_code" = "500" ]; then
        echo "Status: ❌ ERRO 500 - ERRO INTERNO DO SERVIDOR" >> $RESULTS_FILE
    elif [ "$http_code" = "404" ]; then
        echo "Status: ❌ ERRO 404 - PÁGINA NÃO ENCONTRADA" >> $RESULTS_FILE
    elif [ "$http_code" = "419" ]; then
        echo "Status: ❌ ERRO 419 - CSRF TOKEN EXPIRADO" >> $RESULTS_FILE
    else
        echo "Status: ❌ ERRO ($http_code)" >> $RESULTS_FILE
    fi
    
    echo "" >> $RESULTS_FILE
}

# 1. Login
echo "=== FASE 1: AUTENTICAÇÃO ===" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Primeiro pegar o CSRF token
echo "Obtendo CSRF token..." >> $RESULTS_FILE
login_page=$(curl -k -s -c $COOKIE_FILE "$BASE_URL/login")
csrf_token=$(echo "$login_page" | grep -o 'name="_token" value="[^"]*"' | cut -d'"' -f4 | head -1)

if [ ! -z "$csrf_token" ]; then
    echo "CSRF Token obtido: ${csrf_token:0:20}..." >> $RESULTS_FILE
    
    # Fazer login com CSRF
    login_response=$(curl -k -s -b $COOKIE_FILE -c $COOKIE_FILE -w "\nHTTP_CODE:%{http_code}" \
        -X POST "$BASE_URL/login" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "_token=$csrf_token&email=test@admin.local&password=password" 2>&1)
    
    login_code=$(echo "$login_response" | grep "HTTP_CODE:" | cut -d':' -f2)
    
    if [ "$login_code" = "302" ]; then
        echo "Login: ✅ SUCESSO (302 redirect)" >> $RESULTS_FILE
    else
        echo "Login: ❌ FALHOU (HTTP $login_code)" >> $RESULTS_FILE
    fi
else
    echo "Login: ❌ FALHOU (Não conseguiu obter CSRF token)" >> $RESULTS_FILE
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

# Resumo
echo "========================================" >> $RESULTS_FILE
echo "RESUMO DOS TESTES" >> $RESULTS_FILE
echo "========================================" >> $RESULTS_FILE

total=$(grep -c "Testando:" $RESULTS_FILE)
success=$(grep -c "✅ SUCESSO" $RESULTS_FILE)
errors=$(grep -c "❌ ERRO" $RESULTS_FILE)
warnings=$(grep -c "⚠️" $RESULTS_FILE)

echo "Total de testes: $total" >> $RESULTS_FILE
echo "Sucessos: $success" >> $RESULTS_FILE
echo "Erros: $errors" >> $RESULTS_FILE
echo "Avisos: $warnings" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

if [ $errors -gt 0 ]; then
    echo "STATUS GERAL: ❌ FALHOU" >> $RESULTS_FILE
else
    echo "STATUS GERAL: ✅ TODOS OS TESTES PASSARAM" >> $RESULTS_FILE
fi

echo "========================================" >> $RESULTS_FILE

cat $RESULTS_FILE
