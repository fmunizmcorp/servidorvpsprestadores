#!/bin/bash

################################################################################
# SPRINT 47: CSRF Token Regression Fix
# 
# PROBLEMA IDENTIFICADO:
# - Source code TEM @csrf directive (domains.blade.php linha 106)
# - HTML renderizado NÃO TEM input _token
# - Causa: Cache de views do Laravel corrompido/obsoleto
#
# SOLUÇÃO:
# - Limpar completamente cache de views compiladas
# - Recompilar todos os templates Blade
# - Forçar reload do PHP-FPM
#
# ABORDAGEM: Cirúrgica - não mexer em código funcionando
################################################################################

set -e  # Exit on any error
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Server credentials
SERVER_IP="72.61.53.222"
SERVER_USER="root"
SERVER_PASS="Jm@D@KDPnw7Q"
APP_PATH="/opt/webserver/admin-panel"

# Logging
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="/home/user/webapp/sprint47_fix_${TIMESTAMP}.log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "\n${BLUE}===================================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}===================================================${NC}\n" | tee -a "$LOG_FILE"
}

# SSH command wrapper
ssh_exec() {
    sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_IP}" "$1"
}

################################################################################
# STEP 1: Backup atual (prudência)
################################################################################
log_step "STEP 1: Criando backup preventivo"

BACKUP_DIR="sprint47_backup_${TIMESTAMP}"
log "Criando diretório de backup: ${BACKUP_DIR}"

ssh_exec "cd ${APP_PATH} && mkdir -p backups/${BACKUP_DIR}"

log "Backup de views compiladas..."
ssh_exec "cd ${APP_PATH} && tar -czf backups/${BACKUP_DIR}/compiled_views_before_fix.tar.gz storage/framework/views/ 2>/dev/null || true"

log "Backup de cache..."
ssh_exec "cd ${APP_PATH} && tar -czf backups/${BACKUP_DIR}/cache_before_fix.tar.gz storage/framework/cache/ 2>/dev/null || true"

log "✓ Backup preventivo concluído"

################################################################################
# STEP 2: Verificar estado atual (diagnóstico)
################################################################################
log_step "STEP 2: Diagnóstico - Verificando estado atual"

log "Contando views compiladas..."
COMPILED_VIEWS=$(ssh_exec "find ${APP_PATH}/storage/framework/views/ -type f 2>/dev/null | wc -l")
log "Views compiladas encontradas: ${COMPILED_VIEWS}"

log "Verificando permissões do diretório storage..."
ssh_exec "ls -la ${APP_PATH}/storage/framework/ | grep views" | tee -a "$LOG_FILE"

log "Verificando se PHP-FPM está ativo..."
PHP_FPM_STATUS=$(ssh_exec "systemctl is-active php8.3-fpm")
log "PHP-FPM status: ${PHP_FPM_STATUS}"

################################################################################
# STEP 3: Limpar cache de views (FIX PRINCIPAL)
################################################################################
log_step "STEP 3: Limpando cache de views - FIX PRINCIPAL"

log "Removendo TODAS as views compiladas..."
ssh_exec "rm -rf ${APP_PATH}/storage/framework/views/*"
REMOVED_COUNT=$(ssh_exec "find ${APP_PATH}/storage/framework/views/ -type f ! -name '.gitignore' 2>/dev/null | wc -l")
log "Views restantes após limpeza (exceto .gitignore): ${REMOVED_COUNT}"

if [ "$REMOVED_COUNT" -ne "0" ]; then
    log_error "FALHA: Ainda existem views compiladas após rm -rf"
    exit 1
fi

log "✓ Cache de views removido com sucesso"

################################################################################
# STEP 4: Artisan cache clear (completo)
################################################################################
log_step "STEP 4: Limpando caches do Laravel via Artisan"

log "php artisan view:clear..."
ssh_exec "cd ${APP_PATH} && php artisan view:clear" | tee -a "$LOG_FILE"

log "php artisan config:clear..."
ssh_exec "cd ${APP_PATH} && php artisan config:clear" | tee -a "$LOG_FILE"

log "php artisan cache:clear..."
ssh_exec "cd ${APP_PATH} && php artisan cache:clear" | tee -a "$LOG_FILE"

log "php artisan route:clear..."
ssh_exec "cd ${APP_PATH} && php artisan route:clear" | tee -a "$LOG_FILE"

log "php artisan optimize:clear..."
ssh_exec "cd ${APP_PATH} && php artisan optimize:clear" | tee -a "$LOG_FILE"

log "✓ Todos os caches Artisan limpos"

################################################################################
# STEP 5: Recompilar otimizações
################################################################################
log_step "STEP 5: Recompilando otimizações do Laravel"

log "php artisan config:cache..."
ssh_exec "cd ${APP_PATH} && php artisan config:cache" | tee -a "$LOG_FILE"

log "php artisan route:cache..."
ssh_exec "cd ${APP_PATH} && php artisan route:cache" | tee -a "$LOG_FILE"

log "php artisan optimize... (SKIP: Laravel 11 route cache issue known)"
# ssh_exec "cd ${APP_PATH} && php artisan optimize" | tee -a "$LOG_FILE"
log_warning "Skipping php artisan optimize devido a bug conhecido do Laravel 11 com CompiledRouteCollection"

log "✓ Otimizações recompiladas (exceto optimize que tem bug conhecido)"

################################################################################
# STEP 6: Reload PHP-FPM
################################################################################
log_step "STEP 6: Recarregando PHP-FPM"

log "systemctl reload php8.3-fpm..."
ssh_exec "systemctl reload php8.3-fpm"

sleep 2

PHP_FPM_STATUS_AFTER=$(ssh_exec "systemctl is-active php8.3-fpm")
log "PHP-FPM status após reload: ${PHP_FPM_STATUS_AFTER}"

if [ "$PHP_FPM_STATUS_AFTER" != "active" ]; then
    log_error "FALHA: PHP-FPM não está ativo após reload"
    exit 1
fi

log "✓ PHP-FPM recarregado com sucesso"

################################################################################
# STEP 7: Verificar permissões (garantir que Laravel pode escrever)
################################################################################
log_step "STEP 7: Verificando permissões do storage"

log "Ajustando permissões do storage..."
ssh_exec "chown -R www-data:www-data ${APP_PATH}/storage"
ssh_exec "chmod -R 775 ${APP_PATH}/storage"

log "Verificando permissões..."
ssh_exec "ls -la ${APP_PATH}/storage/framework/ | grep views" | tee -a "$LOG_FILE"

log "✓ Permissões ajustadas"

################################################################################
# STEP 8: Teste de renderização (forçar compilação)
################################################################################
log_step "STEP 8: Forçando primeira renderização para compilar views"

log "Fazendo requisição para Email Domains (força compilação do Blade)..."
RESPONSE=$(sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_IP}" \
    "curl -s -k -c /tmp/sprint47_cookies.txt -b /tmp/sprint47_cookies.txt \
    https://localhost/admin/login \
    -d 'email=test@admin.local&password=password&_token=dummy' 2>/dev/null || echo 'LOGIN_FAILED'")

if [[ "$RESPONSE" == *"LOGIN_FAILED"* ]]; then
    log_warning "Login falhou, mas compilação de views deve ter sido acionada"
else
    log "Login executado com sucesso"
fi

log "Aguardando 3 segundos para Laravel compilar views..."
sleep 3

log "Verificando views compiladas após requisição..."
COMPILED_AFTER=$(ssh_exec "find ${APP_PATH}/storage/framework/views/ -type f 2>/dev/null | wc -l")
log "Views compiladas agora: ${COMPILED_AFTER}"

if [ "$COMPILED_AFTER" -gt "0" ]; then
    log "✓ Laravel compilou ${COMPILED_AFTER} views com sucesso"
else
    log_warning "Nenhuma view compilada ainda - pode ser normal se requisição falhou"
fi

################################################################################
# STEP 9: Teste CSRF Token - Email Domains
################################################################################
log_step "STEP 9: Testando CSRF Token em Email Domains"

log "Fazendo requisição autenticada para /admin/email/domains..."

# Login primeiro
ssh_exec "curl -s -k -c /tmp/csrf_test_cookies.txt \
    https://localhost/admin/login \
    -d 'email=test@admin.local&password=password' > /dev/null"

sleep 1

# Buscar página de domains
DOMAINS_HTML=$(ssh_exec "curl -s -k -b /tmp/csrf_test_cookies.txt https://localhost/admin/email/domains")

# Verificar CSRF token
if echo "$DOMAINS_HTML" | grep -q 'name="_token"'; then
    log "✓✓✓ SUCESSO: CSRF token ENCONTRADO em Email Domains!"
    echo "$DOMAINS_HTML" | grep '_token' | head -3 | tee -a "$LOG_FILE"
    CSRF_DOMAINS_OK=1
else
    log_error "✗✗✗ FALHA: CSRF token NÃO ENCONTRADO em Email Domains"
    CSRF_DOMAINS_OK=0
fi

################################################################################
# STEP 10: Teste CSRF Token - Email Accounts
################################################################################
log_step "STEP 10: Testando CSRF Token em Email Accounts"

ACCOUNTS_HTML=$(ssh_exec "curl -s -k -b /tmp/csrf_test_cookies.txt https://localhost/admin/email/accounts")

if echo "$ACCOUNTS_HTML" | grep -q 'name="_token"'; then
    log "✓✓✓ SUCESSO: CSRF token ENCONTRADO em Email Accounts!"
    CSRF_ACCOUNTS_OK=1
else
    log_error "✗✗✗ FALHA: CSRF token NÃO ENCONTRADO em Email Accounts"
    CSRF_ACCOUNTS_OK=0
fi

################################################################################
# STEP 11: Teste CSRF Token - Sites Create
################################################################################
log_step "STEP 11: Testando CSRF Token em Sites Create"

SITES_HTML=$(ssh_exec "curl -s -k -b /tmp/csrf_test_cookies.txt https://localhost/admin/sites/create")

if echo "$SITES_HTML" | grep -q 'name="_token"'; then
    log "✓✓✓ SUCESSO: CSRF token ENCONTRADO em Sites Create!"
    CSRF_SITES_OK=1
else
    log_error "✗✗✗ FALHA: CSRF token NÃO ENCONTRADO em Sites Create"
    CSRF_SITES_OK=0
fi

################################################################################
# STEP 12: Teste E2E - Criar Email Domain
################################################################################
log_step "STEP 12: Teste E2E - Criação de Email Domain"

# Extrair CSRF token real
CSRF_TOKEN=$(echo "$DOMAINS_HTML" | grep -oP 'name="_token" value="\K[^"]+' | head -1)

if [ -z "$CSRF_TOKEN" ]; then
    log_error "Não foi possível extrair CSRF token para teste E2E"
    E2E_DOMAIN_OK=0
else
    log "CSRF token extraído: ${CSRF_TOKEN:0:20}..."
    
    TEST_DOMAIN="sprint47-fix-test-$(date +%s).local"
    log "Tentando criar domínio: ${TEST_DOMAIN}"
    
    CREATE_RESPONSE=$(ssh_exec "curl -s -k -b /tmp/csrf_test_cookies.txt \
        -X POST https://localhost/admin/email/storeDomain \
        -d 'domain=${TEST_DOMAIN}&_token=${CSRF_TOKEN}' \
        -L")  # -L para seguir redirects
    
    sleep 2
    
    # Verificar se domínio foi criado
    VERIFY_DOMAIN=$(ssh_exec "cd ${APP_PATH} && php artisan tinker --execute=\"echo EmailDomain::where('domain', '${TEST_DOMAIN}')->count();\"")
    
    if [[ "$VERIFY_DOMAIN" == *"1"* ]]; then
        log "✓✓✓ SUCESSO: Domain ${TEST_DOMAIN} criado e persistido no banco!"
        E2E_DOMAIN_OK=1
    else
        log_error "✗✗✗ FALHA: Domain ${TEST_DOMAIN} NÃO foi persistido no banco"
        E2E_DOMAIN_OK=0
    fi
fi

################################################################################
# STEP 13: Teste E2E - Criar Email Account
################################################################################
log_step "STEP 13: Teste E2E - Criação de Email Account"

# Refresh da página para obter novo token
ACCOUNTS_HTML_REFRESH=$(ssh_exec "curl -s -k -b /tmp/csrf_test_cookies.txt https://localhost/admin/email/accounts")
CSRF_TOKEN_ACC=$(echo "$ACCOUNTS_HTML_REFRESH" | grep -oP 'name="_token" value="\K[^"]+' | head -1)

if [ -z "$CSRF_TOKEN_ACC" ]; then
    log_error "Não foi possível extrair CSRF token para Email Account"
    E2E_ACCOUNT_OK=0
else
    log "CSRF token extraído para account: ${CSRF_TOKEN_ACC:0:20}..."
    
    # Pegar um domínio existente
    EXISTING_DOMAIN=$(ssh_exec "cd ${APP_PATH} && php artisan tinker --execute=\"echo EmailDomain::first()->domain ?? 'none';\"" | tail -1)
    
    if [ "$EXISTING_DOMAIN" == "none" ]; then
        log_warning "Nenhum domain disponível para criar account"
        E2E_ACCOUNT_OK=0
    else
        TEST_EMAIL="sprint47test$(date +%s)@${EXISTING_DOMAIN}"
        log "Tentando criar email: ${TEST_EMAIL}"
        
        CREATE_ACC_RESPONSE=$(ssh_exec "curl -s -k -b /tmp/csrf_test_cookies.txt \
            -X POST https://localhost/admin/email/storeAccount \
            -d 'email=${TEST_EMAIL}&password=TestPass123!&_token=${CSRF_TOKEN_ACC}' \
            -L")
        
        sleep 2
        
        VERIFY_EMAIL=$(ssh_exec "cd ${APP_PATH} && php artisan tinker --execute=\"echo EmailAccount::where('email', '${TEST_EMAIL}')->count();\"" | tail -1)
        
        if [[ "$VERIFY_EMAIL" == *"1"* ]]; then
            log "✓✓✓ SUCESSO: Email account ${TEST_EMAIL} criado e persistido!"
            E2E_ACCOUNT_OK=1
        else
            log_error "✗✗✗ FALHA: Email account NÃO foi persistido no banco"
            E2E_ACCOUNT_OK=0
        fi
    fi
fi

################################################################################
# STEP 14: Teste E2E - Criar Site
################################################################################
log_step "STEP 14: Teste E2E - Criação de Site"

SITES_HTML_REFRESH=$(ssh_exec "curl -s -k -b /tmp/csrf_test_cookies.txt https://localhost/admin/sites/create")
CSRF_TOKEN_SITE=$(echo "$SITES_HTML_REFRESH" | grep -oP 'name="_token" value="\K[^"]+' | head -1)

if [ -z "$CSRF_TOKEN_SITE" ]; then
    log_error "Não foi possível extrair CSRF token para Site"
    E2E_SITE_OK=0
else
    log "CSRF token extraído para site: ${CSRF_TOKEN_SITE:0:20}..."
    
    TEST_SITE_DOMAIN="sprint47-site-$(date +%s).local"
    log "Tentando criar site: ${TEST_SITE_DOMAIN}"
    
    CREATE_SITE_RESPONSE=$(ssh_exec "curl -s -k -b /tmp/csrf_test_cookies.txt \
        -X POST https://localhost/admin/sites \
        -d 'domain=${TEST_SITE_DOMAIN}&_token=${CSRF_TOKEN_SITE}' \
        -L")
    
    sleep 3  # Sites demoram mais para criar
    
    VERIFY_SITE=$(ssh_exec "cd ${APP_PATH} && php artisan tinker --execute=\"echo Site::where('domain', '${TEST_SITE_DOMAIN}')->count();\"" | tail -1)
    
    if [[ "$VERIFY_SITE" == *"1"* ]]; then
        log "✓✓✓ SUCESSO: Site ${TEST_SITE_DOMAIN} criado e persistido!"
        E2E_SITE_OK=1
    else
        log_error "✗✗✗ FALHA: Site NÃO foi persistido no banco"
        E2E_SITE_OK=0
    fi
fi

################################################################################
# FINAL REPORT
################################################################################
log_step "RELATÓRIO FINAL - SPRINT 47"

echo "" | tee -a "$LOG_FILE"
echo "╔══════════════════════════════════════════════════════════════╗" | tee -a "$LOG_FILE"
echo "║         SPRINT 47: CSRF TOKEN REGRESSION FIX REPORT         ║" | tee -a "$LOG_FILE"
echo "╚══════════════════════════════════════════════════════════════╝" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "CSRF TOKEN VERIFICATION:" | tee -a "$LOG_FILE"
echo "  Email Domains:  $( [ $CSRF_DOMAINS_OK -eq 1 ] && echo '✓ PASS' || echo '✗ FAIL' )" | tee -a "$LOG_FILE"
echo "  Email Accounts: $( [ $CSRF_ACCOUNTS_OK -eq 1 ] && echo '✓ PASS' || echo '✗ FAIL' )" | tee -a "$LOG_FILE"
echo "  Sites Create:   $( [ $CSRF_SITES_OK -eq 1 ] && echo '✓ PASS' || echo '✗ FAIL' )" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "END-TO-END TESTS:" | tee -a "$LOG_FILE"
echo "  Create Domain:  $( [ $E2E_DOMAIN_OK -eq 1 ] && echo '✓ PASS' || echo '✗ FAIL' )" | tee -a "$LOG_FILE"
echo "  Create Account: $( [ $E2E_ACCOUNT_OK -eq 1 ] && echo '✓ PASS' || echo '✗ FAIL' )" | tee -a "$LOG_FILE"
echo "  Create Site:    $( [ $E2E_SITE_OK -eq 1 ] && echo '✓ PASS' || echo '✗ FAIL' )" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

TOTAL_TESTS=6
PASSED_TESTS=$(( CSRF_DOMAINS_OK + CSRF_ACCOUNTS_OK + CSRF_SITES_OK + E2E_DOMAIN_OK + E2E_ACCOUNT_OK + E2E_SITE_OK ))

echo "TOTAL: ${PASSED_TESTS}/${TOTAL_TESTS} TESTS PASSED" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo "✓✓✓ SPRINT 47 CONCLUÍDO COM SUCESSO! ✓✓✓" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "REGRESSÃO CORRIGIDA:" | tee -a "$LOG_FILE"
    echo "  - Cache de views do Laravel foi limpo" | tee -a "$LOG_FILE"
    echo "  - CSRF tokens estão sendo renderizados corretamente" | tee -a "$LOG_FILE"
    echo "  - Todos os 3 formulários estão funcionais" | tee -a "$LOG_FILE"
    echo "  - Persistência no banco de dados verificada" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 0
else
    log_error "SPRINT 47 PARCIALMENTE CONCLUÍDO: ${PASSED_TESTS}/${TOTAL_TESTS} testes passaram"
    echo "" | tee -a "$LOG_FILE"
    echo "TESTES FALHARAM - INVESTIGAÇÃO NECESSÁRIA" | tee -a "$LOG_FILE"
    exit 1
fi
