# 🚀 GUIA PASSO A PASSO - IMPLANTAÇÃO DO PRIMEIRO SITE

**Data**: 2025-11-16  
**Servidor**: 72.61.53.222  
**Status**: PRONTO PARA RECEBER SITES

---

## 📋 PRÉ-REQUISITOS

Antes de começar, certifique-se de ter:

- ✅ Acesso SSH ao servidor (root@72.61.53.222)
- ✅ Domínio registrado (exemplo: `meusite.com.br`)
- ✅ Arquivos do site prontos para upload
- ✅ Acesso ao painel de controle do domínio (para configurar DNS)

---

## 🎯 MÉTODO 1: VIA PAINEL ADMINISTRATIVO (RECOMENDADO)

### Passo 1: Acessar o Painel Admin

1. Abra seu navegador
2. Acesse: `http://72.61.53.222:8080`
3. Faça login:
   - **Email**: `admin@localhost`
   - **Senha**: `Admin@2025!`

**⚠️ SE O USUÁRIO NÃO EXISTIR**, crie primeiro via SSH:

```bash
ssh root@72.61.53.222
cd /opt/webserver/admin-panel
php artisan tinker --execute="
    \$user = App\\Models\\User::create([
        'name' => 'Administrator',
        'email' => 'admin@localhost',
        'password' => bcrypt('Admin@2025!')
    ]);
    echo 'User created: ' . \$user->email;
"
```

### Passo 2: Criar o Site

1. No painel, clique em **"Sites"** no menu superior
2. Clique no botão **"Create New Site"** (verde, canto superior direito)
3. Preencha o formulário:

```
Nome do Site: meusite
(Apenas letras minúsculas, números, hífen. Sem espaços ou caracteres especiais)

Domínio: meusite.com.br
(Sem http://, apenas o domínio. Pode adicionar www.meusite.com.br também)

Versão PHP: 8.3
(Recomendado - mais recente e rápido)

Criar Banco de Dados: ☑ Sim
(Marque se o site usa MySQL/MariaDB)
```

4. Clique em **"Create Site"**

### Passo 3: Anotar as Credenciais

Após a criação, você verá uma mensagem com todas as credenciais:

```
✅ Site criado com sucesso!

📁 Informações do Site:
   Nome: meusite
   Domínio: meusite.com.br
   Diretório: /opt/webserver/sites/meusite/public_html/
   PHP Version: 8.3

🔐 Acesso FTP/SFTP:
   Host: 72.61.53.222
   Porta: 22
   Usuário: site_meusite
   Senha: [senha gerada automaticamente]

💾 Banco de Dados:
   Host: localhost
   Porta: 3306
   Database: db_meusite
   Usuário: user_meusite
   Senha: [senha gerada automaticamente]

🌐 URLs:
   HTTP: http://meusite.com.br
   HTTPS: https://meusite.com.br (após configurar SSL)
```

**🔴 IMPORTANTE**: Copie e salve essas credenciais em um local seguro! Você precisará delas.

### Passo 4: Fazer Upload dos Arquivos

Você tem 3 opções:

#### Opção A: Via SFTP (FileZilla, WinSCP, Cyberduck)

1. Abra seu cliente SFTP favorito
2. Configure a conexão:
   - **Host**: `72.61.53.222`
   - **Porta**: `22`
   - **Protocolo**: SFTP
   - **Usuário**: `site_meusite` (o gerado no passo 3)
   - **Senha**: (a gerada no passo 3)

3. Conecte-se
4. Você estará em: `/opt/webserver/sites/meusite/public_html/`
5. Arraste e solte seus arquivos

#### Opção B: Via SCP (Linha de Comando)

```bash
# De seu computador local
scp -r /caminho/local/do/site/* site_meusite@72.61.53.222:/opt/webserver/sites/meusite/public_html/
```

#### Opção C: Via SSH (Upload Manual)

```bash
# Conectar ao servidor
ssh root@72.61.53.222

# Ir para o diretório
cd /opt/webserver/sites/meusite/public_html/

# Fazer upload (pode usar wget, curl, git clone, etc)
wget https://example.com/meu-site.zip
unzip meu-site.zip

# Ajustar permissões
chown -R site_meusite:site_meusite /opt/webserver/sites/meusite/public_html/
chmod -R 755 /opt/webserver/sites/meusite/public_html/
```

### Passo 5: Configurar o Banco de Dados (se necessário)

Se seu site usa banco de dados, você precisa:

1. **Importar o dump SQL**:

```bash
# Via SSH
ssh root@72.61.53.222

# Importar dump
mysql -u user_meusite -p db_meusite < /caminho/do/dump.sql
# Quando pedir senha, use a senha gerada no Passo 3
```

2. **Ou via phpMyAdmin** (se instalado):
   - Acesse: `http://72.61.53.222/phpmyadmin`
   - Login: `user_meusite` / senha do Passo 3
   - Selecione `db_meusite`
   - Clique em "Importar"
   - Escolha seu arquivo `.sql`

3. **Atualizar config do site** (exemplo WordPress):

```php
// wp-config.php
define('DB_NAME', 'db_meusite');
define('DB_USER', 'user_meusite');
define('DB_PASSWORD', 'SENHA_DO_PASSO_3');
define('DB_HOST', 'localhost');
```

### Passo 6: Configurar DNS do Domínio

No painel de controle do seu provedor de domínio (Registro.br, GoDaddy, Namecheap, etc):

1. Adicione um **registro A**:
   ```
   Tipo: A
   Nome: @  (ou deixe em branco)
   Destino: 72.61.53.222
   TTL: 3600 (1 hora)
   ```

2. Adicione um **registro A para www**:
   ```
   Tipo: A
   Nome: www
   Destino: 72.61.53.222
   TTL: 3600
   ```

3. **Aguarde a propagação DNS** (5 minutos a 48 horas, geralmente 1-2 horas)

4. **Verifique a propagação**:
   ```bash
   # No seu computador
   nslookup meusite.com.br
   # Deve retornar: 72.61.53.222
   ```

### Passo 7: Testar o Site

1. Abra o navegador
2. Acesse: `http://meusite.com.br`
3. Verifique se o site carrega corretamente

**Se não carregar**:
- Verifique se o DNS já propagou (use `nslookup`)
- Verifique os logs: Painel → Sites → meusite → View Logs
- Verifique se os arquivos estão em `public_html/`
- Verifique se há um `index.php` ou `index.html`

### Passo 8: Configurar SSL (HTTPS)

1. No painel admin, vá em: **Sites → meusite → SSL**
2. Clique em **"Generate Let's Encrypt Certificate"**
3. Aguarde 30-60 segundos
4. Você verá: ✅ Certificate generated successfully
5. Acesse: `https://meusite.com.br` (com S)

**Requisitos para SSL funcionar**:
- DNS já propagado (domínio apontando para o servidor)
- Porta 80 aberta (já está)
- Site acessível via HTTP

---

## 🎯 MÉTODO 2: VIA SCRIPT SSH (AVANÇADO)

### Passo 1: Conectar via SSH

```bash
ssh root@72.61.53.222
# Senha: Jm@D@KDPnw7Q
```

### Passo 2: Executar Script de Criação

```bash
cd /opt/webserver/scripts

# Sintaxe:
# ./create-site.sh [nome] [dominio] [php-version] [create-db]

# Exemplo:
./create-site.sh meusite meusite.com.br 8.3 yes
```

O script irá:
1. Criar usuário Linux `site_meusite`
2. Criar diretório `/opt/webserver/sites/meusite/`
3. Criar pool PHP-FPM dedicado
4. Criar virtual host NGINX
5. Criar banco de dados `db_meusite` (se `yes`)
6. Criar usuário MySQL `user_meusite`
7. Configurar permissões
8. Reiniciar NGINX e PHP-FPM

### Passo 3: Anotar as Credenciais

O script exibirá no terminal:

```
===============================================
   SITE CRIADO COM SUCESSO!
===============================================

Site Name: meusite
Domain: meusite.com.br
Directory: /opt/webserver/sites/meusite/public_html/

FTP/SFTP User: site_meusite
FTP/SFTP Password: [gerada automaticamente]

Database: db_meusite
DB User: user_meusite
DB Password: [gerada automaticamente]

NGINX Config: /etc/nginx/sites-available/meusite.conf
PHP-FPM Pool: /etc/php/8.3/fpm/pool.d/meusite.conf

Next Steps:
1. Upload your files to public_html/
2. Configure your DNS
3. Generate SSL certificate
===============================================
```

**Copie e salve essas informações!**

### Passo 4: Upload dos Arquivos

```bash
# Ainda conectado via SSH
cd /opt/webserver/sites/meusite/public_html/

# Opção A: Git clone
git clone https://github.com/usuario/meu-site.git .

# Opção B: Download zip
wget https://example.com/meu-site.zip
unzip meu-site.zip
rm meu-site.zip

# Opção C: SCP de outra máquina
# (executar de outro terminal)
scp -r /caminho/local/* root@72.61.53.222:/opt/webserver/sites/meusite/public_html/
```

### Passo 5: Ajustar Permissões

```bash
# Dar ownership para o usuário do site
chown -R site_meusite:site_meusite /opt/webserver/sites/meusite/public_html/

# Permissões corretas
find /opt/webserver/sites/meusite/public_html/ -type d -exec chmod 755 {} \;
find /opt/webserver/sites/meusite/public_html/ -type f -exec chmod 644 {} \;

# Se tiver pastas que precisam ser writeable (uploads, cache)
chmod -R 775 /opt/webserver/sites/meusite/public_html/wp-content/uploads/
```

### Passo 6: Configurar DNS

(Mesmo processo do Método 1, Passo 6)

### Passo 7: Gerar SSL

```bash
# Instalar certbot se não estiver
apt-get install -y certbot python3-certbot-nginx

# Gerar certificado
certbot --nginx -d meusite.com.br -d www.meusite.com.br --non-interactive --agree-tos --email admin@meusite.com.br
```

---

## 📊 ESTRUTURA FINAL DO SITE

Após a implantação, seu site terá esta estrutura:

```
/opt/webserver/sites/meusite/
│
├── public_html/              # Arquivos públicos (DocumentRoot)
│   ├── index.php
│   ├── wp-config.php        # (se WordPress)
│   ├── .htaccess
│   ├── assets/
│   │   ├── css/
│   │   ├── js/
│   │   └── images/
│   └── uploads/
│
├── logs/                     # Logs do NGINX
│   ├── access.log
│   └── error.log
│
├── ssl/                      # Certificados SSL
│   ├── cert.pem
│   ├── key.pem
│   └── chain.pem
│
└── backup/                   # Backups locais
    └── [backups automáticos]
```

---

## 🔐 ARQUIVOS DE CONFIGURAÇÃO GERADOS

### NGINX Virtual Host

Arquivo: `/etc/nginx/sites-available/meusite.conf`

```nginx
server {
    listen 80;
    server_name meusite.com.br www.meusite.com.br;
    
    root /opt/webserver/sites/meusite/public_html;
    index index.php index.html index.htm;
    
    access_log /opt/webserver/sites/meusite/logs/access.log;
    error_log /opt/webserver/sites/meusite/logs/error.log;
    
    # PHP-FPM
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm-meusite.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
```

### PHP-FPM Pool

Arquivo: `/etc/php/8.3/fpm/pool.d/meusite.conf`

```ini
[meusite]
user = site_meusite
group = site_meusite
listen = /run/php/php8.3-fpm-meusite.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

php_admin_value[error_log] = /opt/webserver/sites/meusite/logs/php-error.log
php_admin_flag[log_errors] = on

php_admin_value[open_basedir] = /opt/webserver/sites/meusite:/tmp
php_admin_value[upload_tmp_dir] = /opt/webserver/sites/meusite/tmp
php_admin_value[session.save_path] = /opt/webserver/sites/meusite/tmp

php_admin_value[memory_limit] = 256M
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
php_admin_value[max_execution_time] = 300
```

---

## 🛡️ VERIFICAÇÃO DE ISOLAMENTO

Para garantir que seu site está isolado dos demais:

### Teste 1: Verificar Usuário do Processo

```bash
ps aux | grep php-fpm | grep meusite
# Deve mostrar: site_meusite
```

### Teste 2: Verificar open_basedir

```php
// Criar /opt/webserver/sites/meusite/public_html/test.php
<?php
echo "open_basedir: " . ini_get('open_basedir') . "\n";

// Tentar acessar outro site (deve falhar)
try {
    $content = file_get_contents('/opt/webserver/sites/outrosite/config.php');
    echo "❌ ERRO: Conseguiu acessar outro site!";
} catch (Exception $e) {
    echo "✅ OK: Não consegue acessar outros sites (isolado)";
}
?>
```

Acesse: `http://meusite.com.br/test.php`

Resultado esperado:
```
open_basedir: /opt/webserver/sites/meusite:/tmp
✅ OK: Não consegue acessar outros sites (isolado)
```

### Teste 3: Verificar Banco de Dados

```bash
# Conectar com usuário do site
mysql -u user_meusite -p db_meusite
# Senha: [do Passo 3]

# Tentar acessar outro banco (deve falhar)
mysql> USE db_outrosite;
# Erro: Access denied for user 'user_meusite'@'localhost' to database 'db_outrosite'

mysql> exit
```

---

## 📈 MONITORAMENTO DO SITE

### Via Painel Administrativo

1. **Ver Logs em Tempo Real**:
   ```
   Sites → meusite → View Logs
   Selecionar: Access Log ou Error Log
   ```

2. **Ver Métricas**:
   ```
   Monitoring → Processes
   Filtrar por: site_meusite
   Ver: CPU, Memória, Uptime
   ```

### Via SSH

```bash
# Logs de acesso
tail -f /opt/webserver/sites/meusite/logs/access.log

# Logs de erro
tail -f /opt/webserver/sites/meusite/logs/error.log

# Logs de erro PHP
tail -f /opt/webserver/sites/meusite/logs/php-error.log

# Processos PHP-FPM
watch -n 2 'ps aux | grep meusite'

# Uso de disco
du -sh /opt/webserver/sites/meusite/
```

---

## 🔧 MANUTENÇÃO DO SITE

### Reiniciar PHP-FPM Pool

```bash
# Via SSH
systemctl restart php8.3-fpm

# Ou apenas o pool do site
systemctl reload php8.3-fpm
```

### Reiniciar NGINX

```bash
# Testar configuração
nginx -t

# Reload (sem downtime)
systemctl reload nginx

# Restart completo
systemctl restart nginx
```

### Atualizar Arquivos

```bash
# Via SFTP: simplesmente sobrescrever arquivos

# Via SSH:
cd /opt/webserver/sites/meusite/public_html/
# [fazer alterações]

# Limpar cache (se framework moderno)
php artisan cache:clear    # Laravel
wp cache flush              # WordPress
```

### Backup Manual

```bash
# Via painel:
Backups → Trigger Manual Backup → Select "meusite"

# Via SSH:
/opt/webserver/scripts/backup.sh meusite
```

---

## 🚨 TROUBLESHOOTING COMUM

### Site Retorna 404

**Causa**: Arquivo index não encontrado

**Solução**:
```bash
cd /opt/webserver/sites/meusite/public_html/
ls -la
# Verificar se existe index.php ou index.html
```

### Site Retorna 502 Bad Gateway

**Causa**: PHP-FPM pool não está rodando

**Solução**:
```bash
# Verificar status
systemctl status php8.3-fpm

# Ver logs
tail -50 /var/log/php8.3-fpm.log

# Reiniciar
systemctl restart php8.3-fpm
```

### Site Retorna 403 Forbidden

**Causa**: Permissões incorretas

**Solução**:
```bash
chown -R site_meusite:site_meusite /opt/webserver/sites/meusite/public_html/
chmod -R 755 /opt/webserver/sites/meusite/public_html/
```

### Banco de Dados Não Conecta

**Causa 1**: Credenciais erradas no config
```php
// Verificar config do site
nano /opt/webserver/sites/meusite/public_html/wp-config.php
// ou
nano /opt/webserver/sites/meusite/public_html/.env
```

**Causa 2**: Usuário MySQL não tem permissão
```bash
mysql -u root -pJm@D@KDPnw7Q
mysql> SHOW GRANTS FOR 'user_meusite'@'localhost';
mysql> GRANT ALL ON db_meusite.* TO 'user_meusite'@'localhost';
mysql> FLUSH PRIVILEGES;
```

### SSL Não Funciona

**Causa**: DNS não propagou ou porta 80 não acessível

**Solução**:
```bash
# Verificar DNS
nslookup meusite.com.br
# Deve retornar: 72.61.53.222

# Verificar se site HTTP funciona primeiro
curl -I http://meusite.com.br

# Tentar gerar SSL novamente
certbot --nginx -d meusite.com.br -d www.meusite.com.br --force-renewal
```

### Site Lento

**Solução 1**: Aumentar recursos do pool PHP-FPM
```bash
nano /etc/php/8.3/fpm/pool.d/meusite.conf
# Aumentar:
pm.max_children = 10        # De 5 para 10
pm.start_servers = 4        # De 2 para 4
systemctl restart php8.3-fpm
```

**Solução 2**: Habilitar cache
```bash
# No NGINX config
nano /etc/nginx/sites-available/meusite.conf
# Adicionar:
fastcgi_cache_path /var/cache/nginx/meusite levels=1:2 keys_zone=meusite:10m;
nginx -t && systemctl reload nginx
```

---

## ✅ CHECKLIST FINAL

Antes de considerar o site 100% implantado:

- [ ] Site criado via painel ou script
- [ ] Arquivos enviados para `public_html/`
- [ ] Permissões ajustadas (`site_meusite:site_meusite`, 755/644)
- [ ] Banco de dados importado (se necessário)
- [ ] Config do site atualizado com credenciais corretas
- [ ] DNS configurado (A record → 72.61.53.222)
- [ ] DNS propagado (verificado com `nslookup`)
- [ ] Site HTTP acessível (`http://meusite.com.br`)
- [ ] SSL gerado e funcionando (`https://meusite.com.br`)
- [ ] Logs verificados (sem erros críticos)
- [ ] Testes de isolamento realizados
- [ ] Backup manual executado
- [ ] Credenciais salvas em local seguro

---

## 🎉 PRÓXIMOS SITES

Para adicionar o **segundo site**, **terceiro site**, etc:

1. Repita TODO o processo acima com um novo nome
2. **IMPORTANTE**: Cada site terá:
   - Seu próprio usuário Linux (`site_site2`, `site_site3`, etc)
   - Seu próprio pool PHP-FPM isolado
   - Seu próprio banco de dados (`db_site2`, `db_site3`, etc)
   - Suas próprias permissões e restrições
   - Isolamento TOTAL dos demais sites

**Não há limite** de sites. O servidor suporta quantos você precisar!

---

## 📞 SUPORTE

Se encontrar problemas:

1. **Verificar logs primeiro**:
   ```
   Painel → Sites → [seu-site] → View Logs
   ```

2. **Consultar documentação**:
   ```
   /home/user/webapp/ACESSO-COMPLETO-SERVIDOR.md
   /home/user/webapp/GUIA-COMPLETO-USO.md
   ```

3. **Verificar GitHub**:
   ```
   https://github.com/fmunizmcorp/servidorvpsprestadores
   ```

---

**Criado em**: 2025-11-16  
**Versão**: 1.0  
**Autor**: Sistema Automatizado VPS Multi-Tenant
