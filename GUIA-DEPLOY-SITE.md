# 🚀 GUIA PRÁTICO: DEPLOY DO SEU PRIMEIRO SITE

## 📋 PRÉ-REQUISITOS

- ✅ Servidor configurado (72.61.53.222)
- ✅ Acesso ao painel admin (http://72.61.53.222:8080)
- ✅ Credenciais de login
- ✅ Domínio próprio (opcional, mas recomendado)
- ✅ Arquivos do site preparados localmente

---

## 🎯 MÉTODO 1: VIA PAINEL ADMIN (RECOMENDADO)

### Passo 1: Login no Painel

```
1. Abra navegador
2. Acesse: http://72.61.53.222:8080/login
3. Digite email e senha (ver ACESSO-COMPLETO.md)
4. Clique em "Login"
```

### Passo 2: Criar Novo Site

```
1. No menu lateral, clique em "Sites"
2. Clique no botão "Create New Site" (canto superior direito)
3. Preencha o formulário:

   📝 Site Name: meusite
      - Apenas letras minúsculas, números e hífens
      - Sem espaços, sem caracteres especiais
      - Exemplo: blog, loja, portfolio

   🌐 Domain: meusite.com.br
      - Seu domínio completo
      - Exemplo: exemplo.com.br, blog.exemplo.com
      - Pode ser alterado depois

   🐘 PHP Version: 8.3
      - Recomendado: 8.3 (mais recente)
      - Disponível: 8.3, 8.2, 8.1, 7.4

   💾 Create Database: ☑️ Yes
      - Marque se precisar de MySQL/MariaDB
      - WordPress, Laravel, Joomla: precisa
      - Site estático HTML: não precisa

4. Clique em "Create Site"
```

### Passo 3: Anotar Informações Criadas

```
✅ Após criação, o painel exibirá:

┌─────────────────────────────────────────────┐
│ Site Created Successfully!                  │
├─────────────────────────────────────────────┤
│ Site Name: meusite                          │
│ Domain: meusite.com.br                      │
│ Directory: /opt/webserver/sites/meusite     │
│                                             │
│ Database:                                   │
│   Name: meusite_db                          │
│   User: meusite_user                        │
│   Password: xyz123abc456def                 │
│   Host: localhost                           │
│                                             │
│ PHP-FPM Pool: meusite.conf                  │
│ NGINX Config: meusite.conf                  │
└─────────────────────────────────────────────┘

⚠️ COPIE E SALVE ESSAS INFORMAÇÕES!
   Você precisará delas para configurar seu site.
```

### Passo 4: Upload dos Arquivos

#### Opção A: Via SCP (Terminal Linux/Mac)

```bash
# Do seu computador local, execute:
scp -r /caminho/para/seus/arquivos/* root@72.61.53.222:/opt/webserver/sites/meusite/public_html/

# Exemplo prático:
scp -r ~/Desktop/meu-site/* root@72.61.53.222:/opt/webserver/sites/meusite/public_html/

# Será solicitada a senha: Jm@D@KDPnw7Q
```

#### Opção B: Via FileZilla (Interface Gráfica)

```
1. Abra FileZilla
2. Configure nova conexão:
   - Host: 72.61.53.222
   - Porta: 22
   - Protocolo: SFTP
   - Usuário: root
   - Senha: Jm@D@KDPnw7Q

3. Conecte

4. Navegue até (lado direito):
   /opt/webserver/sites/meusite/public_html/

5. Arraste seus arquivos do computador (lado esquerdo)
   para o servidor (lado direito)
```

#### Opção C: Via WinSCP (Windows)

```
1. Abra WinSCP
2. Nova Sessão:
   - File Protocol: SFTP
   - Host: 72.61.53.222
   - Port: 22
   - User: root
   - Password: Jm@D@KDPnw7Q

3. Login

4. Navegue até:
   /opt/webserver/sites/meusite/public_html/

5. Copie seus arquivos para lá
```

### Passo 5: Ajustar Permissões

```bash
# Conecte via SSH:
ssh root@72.61.53.222

# Execute os comandos:
cd /opt/webserver/sites/meusite

# Definir dono correto:
chown -R meusite:meusite public_html/

# Permissões de diretórios:
find public_html/ -type d -exec chmod 755 {} \;

# Permissões de arquivos:
find public_html/ -type f -exec chmod 644 {} \;

# Se tiver cache/uploads/storage, permitir escrita:
chmod -R 775 public_html/wp-content/uploads/  # WordPress
chmod -R 775 public_html/storage/             # Laravel
chmod -R 775 public_html/cache/               # Geral
```

### Passo 6: Configurar Aplicação (Se Necessário)

#### Para WordPress:

```bash
cd /opt/webserver/sites/meusite/public_html
cp wp-config-sample.php wp-config.php
nano wp-config.php

# Edite as linhas:
define('DB_NAME', 'meusite_db');           # Nome do BD (visto no passo 3)
define('DB_USER', 'meusite_user');         # Usuário do BD
define('DB_PASSWORD', 'xyz123abc456def');  # Senha do BD
define('DB_HOST', 'localhost');

# Salve: Ctrl+O, Enter, Ctrl+X
```

#### Para Laravel:

```bash
cd /opt/webserver/sites/meusite/public_html
cp .env.example .env
nano .env

# Edite as linhas:
DB_DATABASE=meusite_db
DB_USERNAME=meusite_user
DB_PASSWORD=xyz123abc456def

# Execute:
php artisan key:generate
php artisan migrate
php artisan config:cache
```

### Passo 7: Configurar DNS

```
⚠️ OBRIGATÓRIO para domínio próprio funcionar!

1. Acesse o painel do seu provedor de domínios
   (Registro.br, GoDaddy, Hostgator, etc)

2. Encontre a seção "Gerenciar DNS" ou "DNS Zone"

3. Adicione/Edite os registros:

   Registro A (principal):
   ┌──────────┬──────┬─────────────┬──────┐
   │ Nome     │ Tipo │ Valor       │ TTL  │
   ├──────────┼──────┼─────────────┼──────┤
   │ @        │ A    │ 72.61.53.222│ 3600 │
   └──────────┴──────┴─────────────┴──────┘

   Registro A (www):
   ┌──────────┬──────┬─────────────┬──────┐
   │ Nome     │ Tipo │ Valor       │ TTL  │
   ├──────────┼──────┼─────────────┼──────┤
   │ www      │ A    │ 72.61.53.222│ 3600 │
   └──────────┴──────┴─────────────┴──────┘

4. Salve as alterações

5. ⏱️ Aguarde propagação: 15min a 48h
   (Geralmente funciona em 1-2 horas)
```

### Passo 8: Testar Antes da Propagação DNS

```bash
# NO SEU COMPUTADOR (não no servidor!)

# Linux/Mac:
sudo nano /etc/hosts

# Windows:
# Abra como Admin: C:\Windows\System32\drivers\etc\hosts

# Adicione a linha:
72.61.53.222  meusite.com.br www.meusite.com.br

# Salve e feche

# Agora abra navegador:
http://meusite.com.br
✅ Deve funcionar APENAS no seu computador!

# Quando DNS propagar, remova essa linha do hosts
```

### Passo 9: Gerar Certificado SSL (HTTPS)

```
⚠️ Só faça APÓS DNS estar propagado!

1. No painel admin, vá em "Sites"
2. Localize seu site na lista
3. Clique no botão "SSL" na coluna Actions
4. Clique em "Generate SSL Certificate"
5. Aguarde processamento (30-60 segundos)
6. Certificado Let's Encrypt será criado
7. Site ficará acessível via HTTPS

✅ Renovação automática a cada 90 dias!
```

### Passo 10: Verificar Funcionamento

```
1. Abra navegador
2. Acesse: http://meusite.com.br
3. Se SSL gerado: https://meusite.com.br

✅ Site deve estar ONLINE e funcionando!

🔍 Se não funcionar:
   - Verifique DNS propagou (use https://dnschecker.org)
   - Veja logs: http://72.61.53.222:8080/sites → Logs
   - Confira permissões dos arquivos
```

---

## 🔧 MÉTODO 2: VIA LINHA DE COMANDO (AVANÇADO)

```bash
# 1. Conectar ao servidor
ssh root@72.61.53.222

# 2. Executar script de criação
cd /opt/webserver/scripts
./create-site.sh meusite meusite.com.br 8.3 yes

# Parâmetros:
# - meusite: nome do site (sem espaços)
# - meusite.com.br: domínio
# - 8.3: versão PHP
# - yes: criar banco de dados (ou 'no')

# 3. Anotar credenciais exibidas no output

# 4. Upload dos arquivos
# (usar método SCP/FileZilla do Método 1)

# 5. Ajustar permissões
chown -R meusite:meusite /opt/webserver/sites/meusite/public_html
find /opt/webserver/sites/meusite/public_html -type d -exec chmod 755 {} \;
find /opt/webserver/sites/meusite/public_html -type f -exec chmod 644 {} \;

# 6. Configurar aplicação (WordPress, Laravel, etc)
# (ver Passo 6 do Método 1)

# 7. Configurar DNS
# (ver Passo 7 do Método 1)

# 8. Gerar SSL
cd /opt/webserver/scripts
certbot --nginx -d meusite.com.br -d www.meusite.com.br
```

---

## 🐛 TROUBLESHOOTING

### Problema: Site mostra erro 404

```bash
# Verificar se arquivos estão no lugar certo:
ls -la /opt/webserver/sites/meusite/public_html/

# Deve ter index.php ou index.html

# Se vazio, fazer upload dos arquivos
```

### Problema: Site mostra erro 500

```bash
# Ver logs de erro:
tail -50 /opt/webserver/sites/meusite/logs/error.log

# Verificar permissões:
ls -la /opt/webserver/sites/meusite/public_html/

# Deve mostrar: meusite meusite (dono)

# Ajustar se necessário:
chown -R meusite:meusite /opt/webserver/sites/meusite/public_html/
```

### Problema: "Connection refused" ao acessar site

```bash
# Verificar se NGINX está rodando:
systemctl status nginx

# Se parado, iniciar:
systemctl start nginx

# Verificar configuração do vhost:
nginx -t

# Ver logs NGINX:
tail -50 /var/log/nginx/error.log
```

### Problema: Site não encontra banco de dados

```bash
# Verificar se BD foi criado:
mysql -e "SHOW DATABASES LIKE 'meusite%';"

# Verificar usuário do BD:
mysql -e "SELECT User, Host FROM mysql.user WHERE User LIKE 'meusite%';"

# Testar conexão:
mysql -u meusite_user -p meusite_db
# Digite a senha quando solicitado

# Se erro de conexão:
# - Verifique credenciais no config do site (wp-config.php, .env, etc)
# - Verifique se senha está correta (ver anotações do Passo 3)
```

### Problema: DNS não resolve

```bash
# Testar DNS:
nslookup meusite.com.br

# Ou:
dig meusite.com.br +short

# Deve retornar: 72.61.53.222

# Se não retornar:
# - Aguardar mais tempo (até 48h)
# - Verificar se salvou registros no painel DNS
# - Verificar se está no domínio correto
```

### Problema: SSL não gera

```bash
# Verificar se DNS está propagado primeiro:
nslookup meusite.com.br
# Deve retornar 72.61.53.222

# Verificar se porta 80 está aberta:
ufw status | grep 80

# Tentar manualmente:
certbot --nginx -d meusite.com.br -d www.meusite.com.br

# Ver logs do Certbot:
tail -50 /var/log/letsencrypt/letsencrypt.log
```

---

## 📊 ESTRUTURA APÓS DEPLOY

```
/opt/webserver/sites/meusite/
├── public_html/              ← SEUS ARQUIVOS AQUI
│   ├── index.php
│   ├── wp-admin/            (WordPress)
│   ├── wp-content/          (WordPress)
│   ├── app/                 (Laravel)
│   ├── assets/              (Geral)
│   └── ...
│
├── logs/
│   ├── access.log           ← Acessos ao site
│   └── error.log            ← Erros PHP/NGINX
│
└── ssl/                      ← Certificados SSL (se gerado)
    ├── cert.pem
    ├── privkey.pem
    └── fullchain.pem
```

---

## 🎯 CHECKLIST FINAL

Antes de considerar deploy concluído, verifique:

- [ ] ✅ Site criado via painel admin
- [ ] ✅ Credenciais de BD anotadas
- [ ] ✅ Arquivos enviados para public_html/
- [ ] ✅ Permissões ajustadas (chown + chmod)
- [ ] ✅ Aplicação configurada (wp-config.php, .env, etc)
- [ ] ✅ DNS configurado no provedor
- [ ] ✅ DNS propagado (testado com nslookup)
- [ ] ✅ Site acessível via HTTP
- [ ] ✅ SSL gerado (se desejado)
- [ ] ✅ Site acessível via HTTPS (se SSL gerado)
- [ ] ✅ Funcionalidades testadas (login, upload, BD, etc)

---

## 📞 EXEMPLOS PRÁTICOS

### Deploy WordPress Completo

```bash
# 1. Criar site via painel admin
# Nome: blog, Domínio: blog.exemplo.com.br, PHP: 8.3, DB: Yes

# 2. SSH no servidor
ssh root@72.61.53.222

# 3. Baixar WordPress
cd /opt/webserver/sites/blog/public_html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz --strip-components=1
rm latest.tar.gz

# 4. Configurar
cp wp-config-sample.php wp-config.php
nano wp-config.php
# (editar credenciais conforme Passo 6)

# 5. Ajustar permissões
chown -R blog:blog /opt/webserver/sites/blog/public_html
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod -R 775 wp-content/uploads

# 6. Configurar DNS (no provedor)
# blog.exemplo.com.br A 72.61.53.222

# 7. Aguardar propagação (1-2h)

# 8. Acessar:
# http://blog.exemplo.com.br/wp-admin/install.php

# 9. Gerar SSL via painel

# 10. ✅ Pronto!
# https://blog.exemplo.com.br
```

### Deploy Laravel Completo

```bash
# 1. Criar site via painel admin
# Nome: app, Domínio: app.exemplo.com.br, PHP: 8.3, DB: Yes

# 2. No seu computador, preparar projeto:
cd ~/meu-projeto-laravel
composer install --no-dev --optimize-autoloader
npm run build
php artisan config:clear
php artisan route:clear

# 3. Upload via SCP:
scp -r ~/meu-projeto-laravel/* root@72.61.53.222:/opt/webserver/sites/app/public_html/

# 4. SSH no servidor:
ssh root@72.61.53.222
cd /opt/webserver/sites/app/public_html

# 5. Configurar .env:
cp .env.example .env
nano .env
# (editar credenciais BD)

# 6. Finalizar setup:
php artisan key:generate
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 7. Ajustar permissões:
chown -R app:app /opt/webserver/sites/app/public_html
chmod -R 775 storage bootstrap/cache

# 8. Ajustar NGINX para Laravel:
nano /etc/nginx/sites-available/app.conf
# root /opt/webserver/sites/app/public_html/public;
# (adicionar /public no final)
systemctl reload nginx

# 9. Configurar DNS e SSL (como WordPress)

# 10. ✅ Pronto!
# https://app.exemplo.com.br
```

---

## 🎓 DICAS PROFISSIONAIS

### Segurança

```bash
# Sempre use senhas fortes para BD
# Nunca deixe arquivos .env ou wp-config.php com permissão 777
# Gere SSL para todos os sites em produção
# Mantenha backups regulares
```

### Performance

```bash
# Use PHP 8.3 (mais rápido)
# Ative cache da aplicação (Laravel: config:cache, route:cache)
# Use Redis para cache (já instalado no servidor)
# Otimize imagens antes do upload
# Minifique CSS/JS
```

### Monitoramento

```bash
# Acesse logs regularmente:
tail -f /opt/webserver/sites/meusite/logs/error.log

# Use painel admin para monitorar:
http://72.61.53.222:8080/monitoring
```

---

**📅 Última Atualização**: 2025-11-16  
**🎯 Status**: Servidor 100% pronto para receber sites  
**📖 Mais Info**: Veja ACESSO-COMPLETO.md para detalhes adicionais
