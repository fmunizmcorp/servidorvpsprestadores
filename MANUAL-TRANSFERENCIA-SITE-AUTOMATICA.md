# 🤖 MANUAL DE TRANSFERÊNCIA AUTOMÁTICA DE SITE

## 🎯 OBJETIVO
Este manual permite que outra sessão de IA transfira um site completo (arquivos + banco de dados) para o servidor VPS 72.61.53.222 de forma totalmente automatizada.

---

## 📋 INFORMAÇÕES DO SERVIDOR DE DESTINO

```yaml
Host: 72.61.53.222
SSH Port: 22 (ou 2222 alternativo)
SSH User: root
SSH Password: Jm@D@KDPnw7Q

Painel Admin: http://72.61.53.222:8080
Painel User: admin@localhost
Painel Pass: (verificar no servidor em /root/admin-panel-credentials.txt)

Estrutura de Sites: /opt/webserver/sites/[nome_site]/
Script de Criação: /opt/webserver/scripts/create-site.sh
```

---

## 🚀 PROCESSO COMPLETO DE TRANSFERÊNCIA

### ETAPA 1: PREPARAR SITE DE ORIGEM

#### 1.1. Coletar Informações do Site Atual

```bash
# No servidor de ORIGEM, coletar:

# A) Informações do site:
SITE_NAME="meusite"  # Nome sem espaços
DOMAIN="meusite.com.br"
PHP_VERSION="8.3"  # ou 8.2, 8.1, 7.4

# B) Localização dos arquivos:
SITE_PATH="/var/www/html"  # ou caminho onde está o site

# C) Informações do banco de dados:
DB_NAME="meusite_db"
DB_USER="meusite_user"
DB_PASS="senha_atual"
DB_HOST="localhost"

# D) Tamanho total:
du -sh $SITE_PATH
mysql -u root -p -e "SELECT SUM(data_length + index_length) / 1024 / 1024 AS 'Size (MB)' FROM information_schema.TABLES WHERE table_schema = '$DB_NAME';"
```

#### 1.2. Fazer Backup dos Arquivos

```bash
# No servidor de ORIGEM:
cd $(dirname $SITE_PATH)
tar -czf site-backup-$(date +%Y%m%d-%H%M%S).tar.gz $(basename $SITE_PATH)

# Resultado: site-backup-20250116-040000.tar.gz
BACKUP_FILE=$(ls -t site-backup-*.tar.gz | head -1)
echo "Backup criado: $BACKUP_FILE"
```

#### 1.3. Fazer Dump do Banco de Dados

```bash
# No servidor de ORIGEM:
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > database-backup-$(date +%Y%m%d-%H%M%S).sql

# Resultado: database-backup-20250116-040000.sql
DB_BACKUP=$(ls -t database-backup-*.sql | head -1)
echo "Database backup: $DB_BACKUP"

# Comprimir para acelerar transferência:
gzip $DB_BACKUP
DB_BACKUP="${DB_BACKUP}.gz"
```

---

### ETAPA 2: CRIAR SITE NO SERVIDOR DE DESTINO

#### 2.1. Conectar ao Servidor de Destino

```bash
# Conectar via SSH:
ssh root@72.61.53.222
# Senha: Jm@D@KDPnw7Q

# OU via porta alternativa (se já configurado):
ssh -p 2222 root@72.61.53.222
```

#### 2.2. Criar Estrutura do Site

```bash
# No servidor de DESTINO (72.61.53.222):

# Definir variáveis:
SITE_NAME="meusite"
DOMAIN="meusite.com.br"
PHP_VERSION="8.3"

# Criar site usando script:
cd /opt/webserver/scripts
./create-site.sh $SITE_NAME $DOMAIN $PHP_VERSION yes

# IMPORTANTE: ANOTAR as credenciais exibidas!
# Output exemplo:
# ==============================================
# Site Created: meusite
# Domain: meusite.com.br
# Database: meusite_db
# DB User: meusite_user
# DB Password: xyz123abc456
# Directory: /opt/webserver/sites/meusite/
# ==============================================

# Salvar credenciais:
NEW_DB_NAME="meusite_db"
NEW_DB_USER="meusite_user"
NEW_DB_PASS="xyz123abc456"  # Substituir pela senha real exibida
```

---

### ETAPA 3: TRANSFERIR ARQUIVOS

#### 3.1. Método A: SCP Direto (Se tem acesso aos dois servidores)

```bash
# Do servidor de ORIGEM para DESTINO:
scp site-backup-*.tar.gz root@72.61.53.222:/tmp/

# Ou do seu computador local:
scp usuario@origem:/path/to/site-backup-*.tar.gz .
scp site-backup-*.tar.gz root@72.61.53.222:/tmp/
```

#### 3.2. Método B: Via Computador Intermediário

```bash
# 1. Baixar do servidor de origem:
scp usuario@origem:/path/to/site-backup-*.tar.gz .
scp usuario@origem:/path/to/database-backup-*.sql.gz .

# 2. Enviar para servidor de destino:
scp site-backup-*.tar.gz root@72.61.53.222:/tmp/
scp database-backup-*.sql.gz root@72.61.53.222:/tmp/
```

#### 3.3. Extrair Arquivos no Destino

```bash
# No servidor de DESTINO (72.61.53.222):

cd /tmp
tar -xzf site-backup-*.tar.gz

# Mover arquivos para o diretório do site:
SITE_DIR="/opt/webserver/sites/$SITE_NAME/public_html"

# Limpar diretório (se necessário):
rm -rf $SITE_DIR/*

# Copiar arquivos:
cp -r $(basename $SITE_PATH)/* $SITE_DIR/

# Ajustar permissões:
chown -R $SITE_NAME:$SITE_NAME $SITE_DIR
find $SITE_DIR -type d -exec chmod 755 {} \;
find $SITE_DIR -type f -exec chmod 644 {} \;

# Se WordPress:
chmod -R 775 $SITE_DIR/wp-content/uploads

# Se Laravel:
chmod -R 775 $SITE_DIR/storage
chmod -R 775 $SITE_DIR/bootstrap/cache
```

---

### ETAPA 4: RESTAURAR BANCO DE DADOS

#### 4.1. Descompactar e Importar

```bash
# No servidor de DESTINO (72.61.53.222):

cd /tmp
gunzip database-backup-*.sql.gz

# Importar para o NOVO banco de dados:
mysql -u $NEW_DB_USER -p$NEW_DB_PASS $NEW_DB_NAME < database-backup-*.sql

# Verificar importação:
mysql -u $NEW_DB_USER -p$NEW_DB_PASS $NEW_DB_NAME -e "SHOW TABLES;"
mysql -u $NEW_DB_USER -p$NEW_DB_PASS $NEW_DB_NAME -e "SELECT COUNT(*) FROM \`wp_posts\`;"  # WordPress
mysql -u $NEW_DB_USER -p$NEW_DB_PASS $NEW_DB_NAME -e "SELECT COUNT(*) FROM \`users\`;"  # Laravel
```

#### 4.2. Limpar Arquivos Temporários

```bash
# Remover backups:
rm -f /tmp/site-backup-*.tar.gz
rm -f /tmp/database-backup-*.sql
rm -rf /tmp/$(basename $SITE_PATH)

echo "✅ Arquivos temporários removidos"
```

---

### ETAPA 5: ATUALIZAR CONFIGURAÇÕES DA APLICAÇÃO

#### 5.1. WordPress

```bash
# Editar wp-config.php:
cd $SITE_DIR
nano wp-config.php

# Atualizar linhas:
define('DB_NAME', '$NEW_DB_NAME');
define('DB_USER', '$NEW_DB_USER');
define('DB_PASSWORD', '$NEW_DB_PASS');
define('DB_HOST', 'localhost');

# Atualizar URLs no banco (se mudou domínio):
mysql -u $NEW_DB_USER -p$NEW_DB_PASS $NEW_DB_NAME <<EOF
UPDATE wp_options SET option_value = 'http://$DOMAIN' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'http://$DOMAIN' WHERE option_name = 'home';
EOF

# Limpar cache:
rm -rf wp-content/cache/*
```

#### 5.2. Laravel

```bash
# Editar .env:
cd $SITE_DIR
nano .env

# Atualizar linhas:
APP_URL=http://$DOMAIN
DB_DATABASE=$NEW_DB_NAME
DB_USERNAME=$NEW_DB_USER
DB_PASSWORD=$NEW_DB_PASS
DB_HOST=localhost

# Executar comandos Laravel:
php artisan key:generate
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
php artisan migrate --force  # Se houver novas migrations

# Recriar caches:
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

#### 5.3. Joomla

```bash
# Editar configuration.php:
cd $SITE_DIR
nano configuration.php

# Atualizar variáveis:
public $db = '$NEW_DB_NAME';
public $user = '$NEW_DB_USER';
public $password = '$NEW_DB_PASS';
public $host = 'localhost';
public $live_site = 'http://$DOMAIN';
```

#### 5.4. Drupal

```bash
# Editar sites/default/settings.php:
cd $SITE_DIR
nano sites/default/settings.php

# Atualizar array $databases:
$databases['default']['default'] = array (
  'database' => '$NEW_DB_NAME',
  'username' => '$NEW_DB_USER',
  'password' => '$NEW_DB_PASS',
  'host' => 'localhost',
  'driver' => 'mysql',
);

# Limpar cache:
drush cache-rebuild
```

---

### ETAPA 6: CONFIGURAR DNS

#### 6.1. Atualizar Registros DNS

```bash
# No painel do provedor de domínios (GoDaddy, Registro.br, etc):

# Atualizar registro A:
@ (ou raiz)  →  A  →  72.61.53.222  →  TTL: 3600
www          →  A  →  72.61.53.222  →  TTL: 3600

# Aguardar propagação (15 min - 48h, geralmente 1-2h)
```

#### 6.2. Testar Propagação DNS

```bash
# Do seu computador local:
nslookup $DOMAIN
dig $DOMAIN +short

# Deve retornar: 72.61.53.222

# Verificar propagação global:
# Acessar: https://dnschecker.org
# Digitar: meusite.com.br
# Verificar se maioria dos servidores retorna 72.61.53.222
```

---

### ETAPA 7: GERAR CERTIFICADO SSL (HTTPS)

#### 7.1. Via Painel Admin (Recomendado)

```bash
# DEPOIS que DNS estiver propagado:

1. Acesse: http://72.61.53.222:8080
2. Faça login
3. Vá em "Sites"
4. Localize o site transferido
5. Clique em "SSL" (coluna Actions)
6. Clique em "Generate SSL Certificate"
7. Aguarde 30-60 segundos
8. ✅ Site estará em HTTPS!
```

#### 7.2. Via Linha de Comando (Alternativo)

```bash
# No servidor de DESTINO:
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Testar renovação automática:
certbot renew --dry-run
```

---

### ETAPA 8: VALIDAÇÃO FINAL

#### 8.1. Testes de Funcionamento

```bash
# No servidor de DESTINO:

# 1. Testar NGINX:
nginx -t
systemctl reload nginx

# 2. Testar PHP-FPM:
systemctl status php8.3-fpm | grep "pool $SITE_NAME"

# 3. Testar conexão BD:
mysql -u $NEW_DB_USER -p$NEW_DB_PASS $NEW_DB_NAME -e "SELECT 1;"

# 4. Testar URL:
curl -I http://$DOMAIN
curl -I https://$DOMAIN  # Após SSL

# 5. Ver logs:
tail -f /opt/webserver/sites/$SITE_NAME/logs/error.log
tail -f /opt/webserver/sites/$SITE_NAME/logs/access.log
```

#### 8.2. Checklist Final

```
✅ Site criado no servidor
✅ Arquivos transferidos e com permissões corretas
✅ Banco de dados importado e funcionando
✅ Configurações da aplicação atualizadas
✅ DNS propagado e apontando para 72.61.53.222
✅ SSL gerado (HTTPS funcionando)
✅ Site acessível e funcionando em http://$DOMAIN
✅ Site acessível e funcionando em https://$DOMAIN
✅ Login no admin da aplicação funcionando
✅ Uploads/downloads funcionando
✅ Formulários de contato funcionando
✅ Logs sem erros críticos
```

---

## 🤖 SCRIPT AUTOMATIZADO COMPLETO

### Para IA Executar Automaticamente:

```bash
#!/bin/bash
# Script de Transferência Automática Completa
# Executar no SERVIDOR DE ORIGEM

# ============================================
# CONFIGURAÇÃO (Ajustar conforme necessário)
# ============================================

# Servidor de ORIGEM (atual):
ORIGIN_SITE_PATH="/var/www/html"
ORIGIN_DB_NAME="meusite_db"
ORIGIN_DB_USER="root"
ORIGIN_DB_PASS="senha_origem"

# Servidor de DESTINO (72.61.53.222):
DEST_HOST="72.61.53.222"
DEST_SSH_PORT="22"
DEST_SSH_USER="root"
DEST_SSH_PASS="Jm@D@KDPnw7Q"
DEST_SITE_NAME="meusite"
DEST_DOMAIN="meusite.com.br"
DEST_PHP_VERSION="8.3"

# ============================================
# EXECUÇÃO AUTOMÁTICA
# ============================================

echo "🚀 Iniciando transferência automática..."

# 1. Backup dos arquivos
echo "📦 Criando backup dos arquivos..."
cd $(dirname $ORIGIN_SITE_PATH)
BACKUP_FILE="site-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf /tmp/$BACKUP_FILE $(basename $ORIGIN_SITE_PATH)

# 2. Dump do banco de dados
echo "💾 Criando dump do banco de dados..."
DB_BACKUP="database-backup-$(date +%Y%m%d-%H%M%S).sql"
mysqldump -u $ORIGIN_DB_USER -p$ORIGIN_DB_PASS $ORIGIN_DB_NAME > /tmp/$DB_BACKUP
gzip /tmp/$DB_BACKUP
DB_BACKUP="${DB_BACKUP}.gz"

# 3. Criar site no destino
echo "🏗️  Criando site no servidor de destino..."
sshpass -p "$DEST_SSH_PASS" ssh -p $DEST_SSH_PORT $DEST_SSH_USER@$DEST_HOST \
  "cd /opt/webserver/scripts && ./create-site.sh $DEST_SITE_NAME $DEST_DOMAIN $DEST_PHP_VERSION yes" \
  > /tmp/create-output.txt

# Extrair credenciais do output:
DEST_DB_NAME=$(grep "Database:" /tmp/create-output.txt | awk '{print $2}')
DEST_DB_USER=$(grep "DB User:" /tmp/create-output.txt | awk '{print $3}')
DEST_DB_PASS=$(grep "DB Password:" /tmp/create-output.txt | awk '{print $3}')

echo "✅ Site criado. Credenciais:"
echo "   DB: $DEST_DB_NAME"
echo "   User: $DEST_DB_USER"
echo "   Pass: $DEST_DB_PASS"

# 4. Transferir arquivos
echo "📤 Transferindo arquivos..."
sshpass -p "$DEST_SSH_PASS" scp -P $DEST_SSH_PORT /tmp/$BACKUP_FILE $DEST_SSH_USER@$DEST_HOST:/tmp/
sshpass -p "$DEST_SSH_PASS" scp -P $DEST_SSH_PORT /tmp/$DB_BACKUP $DEST_SSH_USER@$DEST_HOST:/tmp/

# 5. Extrair e configurar no destino
echo "📂 Extraindo arquivos no destino..."
sshpass -p "$DEST_SSH_PASS" ssh -p $DEST_SSH_PORT $DEST_SSH_USER@$DEST_HOST << REMOTESCRIPT
cd /tmp
tar -xzf $BACKUP_FILE

# Mover arquivos
SITE_DIR="/opt/webserver/sites/$DEST_SITE_NAME/public_html"
rm -rf \$SITE_DIR/*
cp -r $(basename $ORIGIN_SITE_PATH)/* \$SITE_DIR/

# Ajustar permissões
chown -R $DEST_SITE_NAME:$DEST_SITE_NAME \$SITE_DIR
find \$SITE_DIR -type d -exec chmod 755 {} \;
find \$SITE_DIR -type f -exec chmod 644 {} \;

# Importar banco de dados
gunzip /tmp/$DB_BACKUP
mysql -u $DEST_DB_USER -p$DEST_DB_PASS $DEST_DB_NAME < /tmp/$(basename $DB_BACKUP .gz)

# Atualizar wp-config.php (se WordPress)
if [ -f \$SITE_DIR/wp-config.php ]; then
  sed -i "s/define('DB_NAME'.*/define('DB_NAME', '$DEST_DB_NAME');/" \$SITE_DIR/wp-config.php
  sed -i "s/define('DB_USER'.*/define('DB_USER', '$DEST_DB_USER');/" \$SITE_DIR/wp-config.php
  sed -i "s/define('DB_PASSWORD'.*/define('DB_PASSWORD', '$DEST_DB_PASS');/" \$SITE_DIR/wp-config.php
  
  # Atualizar URLs no BD
  mysql -u $DEST_DB_USER -p$DEST_DB_PASS $DEST_DB_NAME -e "UPDATE wp_options SET option_value = 'http://$DEST_DOMAIN' WHERE option_name IN ('siteurl', 'home');"
fi

# Atualizar .env (se Laravel)
if [ -f \$SITE_DIR/.env ]; then
  sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DEST_DB_NAME/" \$SITE_DIR/.env
  sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DEST_DB_USER/" \$SITE_DIR/.env
  sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DEST_DB_PASS/" \$SITE_DIR/.env
  
  cd \$SITE_DIR
  php artisan config:clear
  php artisan cache:clear
  php artisan config:cache
fi

# Limpar temporários
rm -rf /tmp/$BACKUP_FILE /tmp/$DB_BACKUP /tmp/$(basename $ORIGIN_SITE_PATH)

echo "✅ Arquivos e banco de dados restaurados!"
REMOTESCRIPT

# 6. Instruções finais
echo ""
echo "=========================================="
echo "✅ TRANSFERÊNCIA CONCLUÍDA!"
echo "=========================================="
echo ""
echo "📋 Próximos passos MANUAIS:"
echo ""
echo "1. Configure DNS:"
echo "   No provedor de domínio, criar registro A:"
echo "   $DEST_DOMAIN → 72.61.53.222"
echo ""
echo "2. Aguarde propagação DNS (1-2 horas)"
echo ""
echo "3. Gere certificado SSL:"
echo "   Via painel: http://72.61.53.222:8080"
echo "   Ou via SSH: certbot --nginx -d $DEST_DOMAIN -d www.$DEST_DOMAIN"
echo ""
echo "4. Acesse o site:"
echo "   http://$DEST_DOMAIN"
echo "   https://$DEST_DOMAIN (após SSL)"
echo ""
echo "=========================================="
```

---

## 📞 INFORMAÇÕES PARA OUTRA IA

### Contexto do Servidor:

```yaml
Servidor: VPS Multi-Tenant
IP: 72.61.53.222
OS: Ubuntu
Web Server: NGINX
PHP: 8.3 (pools isolados por site)
Database: MariaDB
Painel: Laravel Admin (porta 8080)

Isolamento:
- 7 camadas de isolamento implementadas
- Cada site = usuário Linux próprio
- Cada site = pool PHP-FPM próprio
- Cada site = banco de dados próprio
- open_basedir restrictions ativas

Estrutura:
/opt/webserver/
  ├── sites/
  │   └── [nome_site]/
  │       ├── public_html/  ← Arquivos do site aqui
  │       ├── logs/
  │       └── ssl/
  ├── scripts/
  │   └── create-site.sh    ← Script de criação
  └── admin-panel/          ← Painel Laravel
```

### Comandos Úteis:

```bash
# Listar sites existentes:
ls -la /opt/webserver/sites/

# Ver configuração NGINX de um site:
cat /etc/nginx/sites-available/[nome_site].conf

# Ver pool PHP-FPM de um site:
cat /etc/php/8.3/fpm/pool.d/[nome_site].conf

# Ver logs de um site:
tail -f /opt/webserver/sites/[nome_site]/logs/error.log

# Verificar bancos de dados:
mysql -e "SHOW DATABASES;"

# Testar site:
curl -I http://[dominio]
```

---

## 🎯 RESUMO PARA IA

Para transferir um site para 72.61.53.222:

1. **Coletar**: Arquivos + Banco de dados do site atual
2. **Backup**: `tar.gz` dos arquivos + `mysqldump` do BD
3. **Criar**: Execute `/opt/webserver/scripts/create-site.sh`
4. **Transferir**: `scp` dos backups para `/tmp/` no servidor
5. **Extrair**: Descompactar em `/opt/webserver/sites/[nome]/public_html/`
6. **Importar BD**: `mysql` import no novo banco criado
7. **Configurar**: Atualizar `wp-config.php` ou `.env` com novas credenciais
8. **Permissões**: `chown` + `chmod` adequados
9. **DNS**: Apontar domínio para 72.61.53.222
10. **SSL**: Gerar via Certbot ou painel admin

**Tempo total**: 15-30 minutos (depende do tamanho)

---

**📅 Criado em**: 2025-11-16  
**🎯 Propósito**: Transferência automatizada de sites  
**👥 Público**: Outras sessões de IA  
**📊 Status**: Pronto para uso imediato
