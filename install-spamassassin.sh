#!/bin/bash
# Script: Integração SpamAssassin com Postfix
# Sprint 8: SpamAssassin Integration
# Tempo estimado: 30 minutos

set -e

echo "=================================================="
echo "🎯 SPRINT 8: SPAMASSASSIN INTEGRATION"
echo "=================================================="
echo ""
echo "📋 Este script irá:"
echo "   1. Configurar SpamAssassin daemon"
echo "   2. Integrar com Postfix via content_filter"
echo "   3. Ativar Bayes learning"
echo "   4. Configurar score threshold"
echo "   5. Ativar auto-learning"
echo "   6. Testar detecção de spam"
echo ""
read -p "🚀 Pressione ENTER para iniciar configuração..."

# Passo 1: Configurar SpamAssassin
echo ""
echo "⚙️  [1/6] Configurando SpamAssassin..."

# Editar /etc/default/spamassassin
cat > /etc/default/spamassassin << 'EOF'
# SpamAssassin Configuration

# Enable SpamAssassin daemon
ENABLED=1

# Options
OPTIONS="--create-prefs --max-children 5 --helper-home-dir"

# Run as user
SPAMD_USER=debian-spamd

# Listen address
SPAMD_HOST=127.0.0.1

# Pid file
PIDFILE="/var/run/spamd.pid"

# Nice level
NICE="--nicelevel 15"
EOF

echo "✅ /etc/default/spamassassin configurado"

# Configurar local.cf
cat > /etc/spamassassin/local.cf << 'EOF'
# SpamAssassin Local Configuration

# Rewrite subject of spam messages
rewrite_header Subject [***SPAM***]

# Spam threshold (messages with score >= 5.0 are marked as spam)
required_score 5.0

# Use Bayesian classifier
use_bayes 1
bayes_auto_learn 1
bayes_auto_learn_threshold_nonspam 0.1
bayes_auto_learn_threshold_spam 12.0

# Store Bayes data in SQL (optional, usar se quiser)
# bayes_store_module Mail::SpamAssassin::BayesStore::MySQL
# bayes_sql_dsn DBI:mysql:spamassassin:localhost
# bayes_sql_username spamassassin
# bayes_sql_password password

# Network tests
skip_rbl_checks 0
use_razor2 0
use_dcc 0
use_pyzor 0

# Auto-whitelist (AWL)
use_auto_whitelist 1

# Language
ok_languages pt en
ok_locales pt_BR en_US

# Report safe (0 = add full spam report, 1 = add minimal report, 2 = add only headers)
report_safe 0

# Add spam score to headers
add_header all Status _YESNO_, score=_SCORE_ required=_REQD_ tests=_TESTS_ autolearn=_AUTOLEARN_ version=_VERSION_
add_header all Level _STARS(*)_
add_header all Checker-Version SpamAssassin _VERSION_ (_SUBVERSION_) on _HOSTNAME_

# Custom rules
score URIBL_BLOCKED 0
score RCVD_IN_BRBL_LASTEXT 0

# Trusted networks (adicionar IPs confiáveis)
# trusted_networks 192.168.1.0/24

# DNS timeout
dns_query_restriction allow localhost
EOF

echo "✅ /etc/spamassassin/local.cf configurado"

# Criar diretório Bayes
mkdir -p /var/lib/spamassassin/bayes
chown -R debian-spamd:debian-spamd /var/lib/spamassassin
chmod 700 /var/lib/spamassassin/bayes

echo "✅ Diretório Bayes criado"

# Passo 2: Integrar com Postfix
echo ""
echo "📮 [2/6] Integrando SpamAssassin com Postfix..."

# Backup master.cf
cp /etc/postfix/master.cf /etc/postfix/master.cf.bak.$(date +%Y%m%d%H%M%S)

# Verificar se já existe spamassassin no master.cf
if grep -q "^spamassassin" /etc/postfix/master.cf; then
    echo "⚠️  SpamAssassin já configurado no master.cf, pulando..."
else
    # Adicionar filtro SpamAssassin ao master.cf
    cat >> /etc/postfix/master.cf << 'EOF'

# SpamAssassin filter
spamassassin unix -     n       n       -       -       pipe
  user=debian-spamd argv=/usr/bin/spamc -f -e /usr/sbin/sendmail -oi -f ${sender} ${recipient}
EOF
    echo "✅ SpamAssassin adicionado ao master.cf"
fi

# Adicionar content_filter ao main.cf
if grep -q "^content_filter.*spamassassin" /etc/postfix/main.cf; then
    echo "⚠️  content_filter já configurado no main.cf, pulando..."
else
    echo "" >> /etc/postfix/main.cf
    echo "# SpamAssassin content filter" >> /etc/postfix/main.cf
    echo "content_filter = spamassassin" >> /etc/postfix/main.cf
    echo "✅ content_filter adicionado ao main.cf"
fi

# Passo 3: Instalar cliente SpamAssassin
echo ""
echo "📦 [3/6] Verificando cliente spamc..."

if ! command -v spamc &> /dev/null; then
    apt-get install -y -qq spamc
    echo "✅ spamc instalado"
else
    echo "✅ spamc já instalado"
fi

# Passo 4: Iniciar serviços
echo ""
echo "🚀 [4/6] Iniciando serviços..."

# Habilitar e iniciar SpamAssassin
systemctl enable spamassassin
systemctl restart spamassassin

# Aguardar inicialização
sleep 3

# Verificar status
if systemctl is-active --quiet spamassassin; then
    echo "✅ SpamAssassin rodando"
else
    echo "❌ SpamAssassin não iniciou"
    systemctl status spamassassin --no-pager
    exit 1
fi

# Recarregar Postfix
postfix check
if [ $? -eq 0 ]; then
    systemctl reload postfix
    echo "✅ Postfix recarregado"
else
    echo "❌ Erro na configuração Postfix"
    exit 1
fi

# Passo 5: Testar SpamAssassin
echo ""
echo "🧪 [5/6] Testando SpamAssassin..."

# Teste básico
echo "Testing SpamAssassin" | spamassassin -t > /tmp/sa-test.txt 2>&1

if grep -q "X-Spam-Status: No" /tmp/sa-test.txt; then
    echo "✅ SpamAssassin processando corretamente (mensagem limpa)"
elif grep -q "X-Spam-Status: Yes" /tmp/sa-test.txt; then
    echo "✅ SpamAssassin processando corretamente (detectou spam)"
else
    echo "⚠️  Teste inconclusivo, verificar /tmp/sa-test.txt"
fi

# Teste com GTUBE (padrão de teste spam)
echo 'XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X' | spamassassin -t > /tmp/sa-gtube-test.txt 2>&1

if grep -q "X-Spam-Status: Yes" /tmp/sa-gtube-test.txt; then
    SPAM_SCORE=$(grep "X-Spam-Status: Yes" /tmp/sa-gtube-test.txt | grep -oP 'score=\K[0-9.]+')
    echo "✅ GTUBE detectado como spam (score: $SPAM_SCORE)"
else
    echo "❌ GTUBE não detectado como spam (problema!)"
    cat /tmp/sa-gtube-test.txt
fi

rm -f /tmp/sa-test.txt /tmp/sa-gtube-test.txt

# Passo 6: Criar script de treinamento Bayes
echo ""
echo "📚 [6/6] Criando script de treinamento Bayes..."

cat > /opt/webserver/scripts/train-spamassassin.sh << 'SCRIPT'
#!/bin/bash
# Script: Treinar SpamAssassin Bayes com emails existentes
# Uso: ./train-spamassassin.sh [spam_folder] [ham_folder]

SPAM_FOLDER=${1:-/var/mail/spam}
HAM_FOLDER=${2:-/var/mail/ham}

echo "Treinando SpamAssassin Bayes..."
echo "Spam folder: $SPAM_FOLDER"
echo "Ham folder: $HAM_FOLDER"

# Treinar com SPAM
if [ -d "$SPAM_FOLDER" ]; then
    SPAM_COUNT=$(find "$SPAM_FOLDER" -type f | wc -l)
    echo "Treinando com $SPAM_COUNT emails de spam..."
    sa-learn --spam "$SPAM_FOLDER"
else
    echo "⚠️  Pasta de spam não encontrada: $SPAM_FOLDER"
fi

# Treinar com HAM (emails legítimos)
if [ -d "$HAM_FOLDER" ]; then
    HAM_COUNT=$(find "$HAM_FOLDER" -type f | wc -l)
    echo "Treinando com $HAM_COUNT emails legítimos..."
    sa-learn --ham "$HAM_FOLDER"
else
    echo "⚠️  Pasta de ham não encontrada: $HAM_FOLDER"
fi

# Mostrar estatísticas
echo ""
echo "Estatísticas Bayes:"
sa-learn --dump magic

echo ""
echo "✅ Treinamento concluído!"
SCRIPT

chmod +x /opt/webserver/scripts/train-spamassassin.sh
echo "✅ Script de treinamento criado: /opt/webserver/scripts/train-spamassassin.sh"

# Salvar configuração
cat > /root/spamassassin-config.txt << EOF
==============================================
SPAMASSASSIN - CONFIGURAÇÃO
==============================================

Status: ✅ Ativo e integrado com Postfix

Configurações:
- Config: /etc/spamassassin/local.cf
- Default: /etc/default/spamassassin
- Postfix Integration: /etc/postfix/master.cf

Score Threshold:
- Spam Score: >= 5.0
- Auto-learn Spam: >= 12.0
- Auto-learn Ham: <= 0.1

Bayes Classifier:
- Status: Ativo
- Auto-learning: Sim
- Data Dir: /var/lib/spamassassin/bayes

Headers Adicionados:
- X-Spam-Status
- X-Spam-Level
- X-Spam-Checker-Version

Daemon:
- Service: spamassassin
- User: debian-spamd
- Listen: 127.0.0.1
- Max Children: 5

Postfix Integration:
- Content Filter: spamassassin
- Pipe: /usr/bin/spamc

==============================================
COMANDOS ÚTEIS:
==============================================

# Ver status
systemctl status spamassassin

# Reiniciar
systemctl restart spamassassin

# Testar com arquivo
spamassassin -t < /path/to/email.txt

# Teste GTUBE (deve marcar como spam)
echo 'XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X' | spamassassin -t

# Ver estatísticas Bayes
sa-learn --dump magic

# Treinar com spam
sa-learn --spam /path/to/spam/folder

# Treinar com ham (legítimos)
sa-learn --ham /path/to/ham/folder

# Limpar banco Bayes
sa-learn --clear

# Ver regras aplicadas
spamassassin -D -t < email.txt 2>&1 | grep "score="

# Ver logs
tail -f /var/log/mail.log | grep spam

==============================================
TREINAMENTO BAYES:
==============================================

O SpamAssassin aprende automaticamente (auto-learn), mas
você pode treinar manualmente:

1. Crie pastas para exemplos:
   mkdir -p /var/mail/spam /var/mail/ham

2. Coloque emails de spam em /var/mail/spam/
   Coloque emails legítimos em /var/mail/ham/

3. Execute o script de treinamento:
   /opt/webserver/scripts/train-spamassassin.sh

4. Quanto mais emails de exemplo, melhor a detecção!

==============================================
INTEGRAÇÃO COM ROUNDCUBE:
==============================================

O plugin "markasjunk" já está ativo no Roundcube.
Quando usuário marcar email como spam/ham:
- Email é movido para pasta Junk
- SpamAssassin pode aprender (se configurado)

==============================================
MONITORAMENTO:
==============================================

# Ver quantos emails foram marcados como spam hoje:
grep "X-Spam-Status: Yes" /var/log/mail.log | grep "$(date +%b\ %d)" | wc -l

# Ver score médio de spam:
grep "X-Spam-Status: Yes" /var/log/mail.log | grep -oP 'score=\K[0-9.]+' | awk '{sum+=$1; count++} END {print sum/count}'

# Email com maior score:
grep "X-Spam-Status: Yes" /var/log/mail.log | grep -oP 'score=\K[0-9.]+' | sort -n | tail -1

==============================================
INSTALADO EM: $(date '+%Y-%m-%d %H:%M:%S')
==============================================
EOF

echo ""
echo "=================================================="
echo "✅ SPRINT 8 COMPLETO: SPAMASSASSIN INTEGRADO!"
echo "=================================================="
echo ""
echo "📊 Status:"
echo "   - Daemon: $(systemctl is-active spamassassin)"
echo "   - Postfix: $(systemctl is-active postfix)"
echo ""
echo "📍 Configurações salvas em:"
echo "   /root/spamassassin-config.txt"
echo ""
echo "🧪 Testar:"
echo '   echo "GTUBE" | spamassassin -t'
echo ""
echo "📚 Treinar Bayes:"
echo "   /opt/webserver/scripts/train-spamassassin.sh"
echo ""
echo "📋 Próximo Sprint:"
echo "   Sprint 14: End-to-End Testing (2h)"
echo "=================================================="
