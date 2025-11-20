# ARQUITETURA VISUAL DO SISTEMA

## 🏗️ STACK TECNOLÓGICO

```
┌─────────────────────────────────────────────────────────────┐
│                      USER BROWSER                            │
│                  https://72.61.53.222/admin                  │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    NGINX WEB SERVER                          │
│                  Reverse Proxy + SSL                         │
│              /etc/nginx/sites-available/                     │
└──────────────────────────┬──────────────────────────────────┘
                           │ FastCGI
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     PHP-FPM 8.3                              │
│              /etc/php/8.3/fpm/pool.d/www.conf               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  LARAVEL 11 APPLICATION                      │
│               /opt/webserver/admin-panel/                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Controllers (SitesController.php - CRÍTICO)       │    │
│  │  Models (Site, EmailDomain, EmailAccount)          │    │
│  │  Views (Blade Templates)                           │    │
│  │  Routes (web.php)                                  │    │
│  └────────────────────────────────────────────────────┘    │
└──────────────────────────┬──────────────────────────────────┘
                           │ Eloquent ORM
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      MySQL 8.x                               │
│                   Database: admin_panel                      │
│  Tables: sites, email_domains, email_accounts               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 FLUXO DE CRIAÇÃO DE SITE (DETALHADO)

### Fase 1: Request HTTP (Síncrono)

```
┌──────────┐
│  USER    │
│ (Browser)│
└────┬─────┘
     │
     │ POST /admin/sites
     │ {site_name, domain_name, description}
     ▼
┌─────────────────────────────────────┐
│  SitesController@store              │
│  Line ~60-170                       │
│                                     │
│  1. Validação Input                 │
│     - site_name: unique             │
│     - domain_name: unique           │
│                                     │
│  2. Criar Registro DB               │
│     INSERT INTO sites               │
│     status='inactive' ←─────────────┼─── IMPORTANTE: Começa INATIVO
│     ssl_enabled=0                   │
│                                     │
│  3. Copiar Scripts para /tmp/       │
│     - create-site-wrapper.sh        │
│     - post_site_creation.sh         │
│     chmod 0755                      │
│                                     │
│  4. Executar Comando Assíncrono     │ ┐
│     (nohup sudo wrapper.sh          │ │
│      && post_script.sh)             │ │ CRÍTICO: Sprint 30 removeu
│      > log 2>&1 & echo $!           │ │ 'sudo' antes post_script.sh
│                                     │ ┘
│  5. Return Redirect (IMEDIATO)      │
│     → /admin/sites                  │
│     with success message            │
└─────────────────────────────────────┘
     │
     │ Redirect 302
     ▼
┌─────────────────────────────────────┐
│  User vê mensagem:                  │
│  "Site creation started (PID: XXX)" │
└─────────────────────────────────────┘
```

### Fase 2: Background Processing (Assíncrono)

```
┌─────────────────────────────────────────────────────────────┐
│  PROCESSO BACKGROUND (nohup)                                │
│  PID capturado e retornado ao user                          │
└────┬────────────────────────────────────────────────────────┘
     │
     │ Fork & Execute
     ▼
┌─────────────────────────────────────┐
│  /tmp/create-site-wrapper.sh        │
│  (com SUDO)                          │
│                                     │
│  Chama: /root/create-site.sh        │
└────┬────────────────────────────────┘
     │
     │ Execute as root
     ▼
┌─────────────────────────────────────────────────────────────┐
│  /root/create-site.sh {site} {domain} {description}        │
│  ════════════════════════════════════════════════════════   │
│                                                              │
│  1. Criar diretório site:                                   │
│     mkdir -p /var/www/{site_name}                           │
│     chown www-data:www-data                                 │
│                                                              │
│  2. Criar NGINX config:                                     │
│     /etc/nginx/sites-available/{site_name}.conf             │
│     - server_name {domain_name}                             │
│     - root /var/www/{site_name}                             │
│                                                              │
│  3. Criar symlink:                                          │
│     ln -s sites-available/{site}.conf sites-enabled/        │
│                                                              │
│  4. Configurar SSL:                                         │
│     certbot --nginx -d {domain_name}                        │
│     (Let's Encrypt)                                         │
│                                                              │
│  5. Recarregar NGINX:                                       │
│     systemctl reload nginx                                  │
│                                                              │
│  6. Log resultado:                                          │
│     >> /tmp/site-creation-{site}.log                        │
│                                                              │
└────┬────────────────────────────────────────────────────────┘
     │
     │ Success (exit 0)
     │ Operações filesystem completas
     ▼
┌─────────────────────────────────────────────────────────────┐
│  /tmp/post_site_creation.sh {site_name}                     │
│  (SEM SUDO - Sprint 30 Fix)                                 │
│  ════════════════════════════════════════════════════════   │
│                                                              │
│  1. Aguardar filesystem:                                    │
│     sleep 3                                                 │
│                                                              │
│  2. Atualizar Database:                                     │
│     mysql -u root -p'...' admin_panel << SQL                │
│     UPDATE sites                                            │
│     SET status='active', ←───────────────────────────────   MUDANÇA
│         ssl_enabled=1                                       │ CRÍTICA
│     WHERE site_name='{site_name}';                          │
│     SQL                                                     │
│                                                              │
│  3. Log resultado:                                          │
│     echo "Site {site} updated to active"                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
     │
     │ Background process termina
     ▼
┌─────────────────────────────────────────────────────────────┐
│  RESULTADO FINAL                                             │
│  ════════════════════════════════════════════════════════   │
│                                                              │
│  Database (sites table):                                    │
│    - status: 'active' ✅                                     │
│    - ssl_enabled: 1 ✅                                       │
│                                                              │
│  Filesystem:                                                │
│    - /var/www/{site_name}/ ✅                               │
│    - /etc/nginx/sites-available/{site}.conf ✅              │
│    - /etc/nginx/sites-enabled/{site}.conf ✅                │
│                                                              │
│  SSL:                                                       │
│    - Let's Encrypt certificate ✅                           │
│    - HTTPS habilitado ✅                                    │
│                                                              │
│  NGINX:                                                     │
│    - Virtual host configurado ✅                            │
│    - Servidor respondendo ✅                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🐛 BUG SPRINT 30 (VISUALIZADO)

### ANTES (Sprint 29 - BUGADO):

```
┌─────────────────────────────────────┐
│  SitesController.php linha ~121     │
│                                     │
│  $command = "(nohup sudo " .        │
│    $wrapper . " " . $args .         │
│    " && sudo " . $postScript .      │ ← ERRO: sudo aqui causa problema!
│    " {$siteName}) > log 2>&1 &";   │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│  PROBLEMA:                                                   │
│  ════════════════════════════════════════════════════════   │
│                                                              │
│  sudo /tmp/post_site_creation.sh {site}                     │
│       ↑                                                      │
│       └─ Tenta executar como root                           │
│          Mas script está em background (nohup)              │
│          Terminal não está disponível                       │
│          Erro: "a terminal is required to read password"    │
│                                                              │
│  RESULTADO:                                                 │
│    ❌ post_site_creation.sh NÃO executa                     │
│    ❌ UPDATE do banco NÃO acontece                          │
│    ❌ Site fica com status='inactive' FOREVER               │
│    ❌ ssl_enabled fica 0 FOREVER                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### DEPOIS (Sprint 30 - CORRIGIDO):

```
┌─────────────────────────────────────┐
│  SitesController.php linha ~121     │
│                                     │
│  $command = "(nohup sudo " .        │
│    $wrapper . " " . $args .         │
│    " && " . $postScript .           │ ← CORRETO: SEM sudo aqui!
│    " {$siteName}) > log 2>&1 &";   │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│  SOLUÇÃO:                                                    │
│  ════════════════════════════════════════════════════════   │
│                                                              │
│  /tmp/post_site_creation.sh {site}                          │
│       ↑                                                      │
│       └─ Executa como usuário atual (www-data)              │
│          Script usa mysql com credenciais embarcadas        │
│          NÃO precisa de sudo                                │
│                                                              │
│  RESULTADO:                                                 │
│    ✅ post_site_creation.sh executa com sucesso             │
│    ✅ UPDATE do banco acontece                              │
│    ✅ Site atualizado: status='active'                      │
│    ✅ SSL habilitado: ssl_enabled=1                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📂 ESTRUTURA DE ARQUIVOS (TREE)

```
SERVER: 72.61.53.222
════════════════════════════════════════════════════════════════

/opt/webserver/admin-panel/               ← Laravel Application Root
├── app/
│   ├── Http/
│   │   └── Controllers/
│   │       ├── SitesController.php       ← CRÍTICO (linha 121)
│   │       ├── EmailDomainsController.php
│   │       └── EmailAccountsController.php
│   └── Models/
│       ├── Site.php
│       ├── EmailDomain.php
│       └── EmailAccount.php
├── resources/
│   └── views/
│       ├── sites/
│       │   ├── index.blade.php
│       │   ├── create.blade.php
│       │   └── edit.blade.php
│       ├── email-domains/
│       └── email-accounts/
├── routes/
│   └── web.php                           ← Route definitions
├── storage/
│   ├── app/
│   │   ├── create-site-wrapper.sh        ← Copiado para /tmp runtime
│   │   └── post_site_creation.sh         ← Copiado para /tmp runtime
│   └── logs/
│       └── laravel.log                   ← Application logs
├── database/
│   └── migrations/
│       └── *_create_sites_table.php
├── .env                                  ← CRÍTICO: SESSION_PATH=/admin
├── composer.json
└── artisan

/root/
└── create-site.sh                        ← Script principal (SUDO)
                                           Cria NGINX, SSL, filesystem

/tmp/                                     ← Runtime scripts (copiados)
├── create-site-wrapper.sh                ← Wrapper para create-site.sh
├── post_site_creation.sh                 ← Atualiza DB status
└── site-creation-{sitename}.log          ← Logs de cada criação

/var/www/                                 ← Document roots dos sites
├── sprint26test1763481293/
├── sprint28cli1763491543/
├── sprint29success1763506146/
├── sprint30test1763510124/
├── sprint31final1763516724/
└── ...                                   ← Cada site tem seu diretório

/etc/nginx/
├── sites-available/                      ← Configs NGINX
│   ├── admin-panel.conf                  ← Admin panel principal
│   ├── sprint26test1763481293.conf
│   ├── sprint28cli1763491543.conf
│   └── ...                               ← Um .conf por site
├── sites-enabled/                        ← Symlinks ativos
│   └── {site}.conf -> ../sites-available/{site}.conf
└── nginx.conf                            ← Config principal

/etc/php/8.3/fpm/
├── php-fpm.conf
└── pool.d/
    └── www.conf                          ← Pool PHP-FPM

/etc/letsencrypt/live/                    ← SSL Certificates
└── {domain}/
    ├── fullchain.pem
    └── privkey.pem
```

---

## 🔐 FLUXO DE AUTENTICAÇÃO E SESSÃO

```
┌──────────┐
│  USER    │
└────┬─────┘
     │
     │ GET /admin/login
     ▼
┌─────────────────────────────────────┐
│  Laravel Auth                       │
│  Gera CSRF token                    │
│  Session: path=/admin ←──────────── CRÍTICO: Sprint 29 fix
│           secure=true                │
│           domain=null                │
└────┬────────────────────────────────┘
     │
     │ POST /admin/login
     │ {email, password, _token}
     ▼
┌─────────────────────────────────────┐
│  Validate Credentials               │
│  Check: admin@example.com           │
│         Admin@123                   │
└────┬────────────────────────────────┘
     │
     │ Success
     ▼
┌─────────────────────────────────────┐
│  Create Session                     │
│  Set Cookie:                        │
│    - laravel_session={token}        │
│    - Path=/admin                    │ ← Importante: não /
│    - Secure=true                    │
│    - HttpOnly=true                  │
└────┬────────────────────────────────┘
     │
     │ Redirect
     ▼
┌─────────────────────────────────────┐
│  Dashboard /admin                   │
│  User authenticated ✅              │
└─────────────────────────────────────┘
```

---

## 💾 DATABASE SCHEMA

```
DATABASE: admin_panel
════════════════════════════════════════════════════════════════

┌──────────────────────────────────────────────────────────────┐
│  TABLE: sites                                                 │
├────────────────┬───────────────┬────────────┬────────────────┤
│  Column        │  Type         │  Nullable  │  Default       │
├────────────────┼───────────────┼────────────┼────────────────┤
│  id            │  BIGINT (PK)  │  NO        │  AUTO_INCREMENT│
│  site_name     │  VARCHAR(255) │  NO        │  -             │ ← UNIQUE
│  domain_name   │  VARCHAR(255) │  NO        │  -             │ ← UNIQUE
│  description   │  TEXT         │  YES       │  NULL          │
│  status        │  ENUM(...)    │  NO        │  'inactive'    │ ← IMPORTANTE
│                │  ('active',   │            │                │
│                │   'inactive', │            │                │
│                │   'suspended')│            │                │
│  ssl_enabled   │  TINYINT(1)   │  NO        │  0             │ ← BOOLEAN
│  created_at    │  TIMESTAMP    │  YES       │  NULL          │
│  updated_at    │  TIMESTAMP    │  YES       │  NULL          │
└────────────────┴───────────────┴────────────┴────────────────┘

INDEXES:
  - PRIMARY KEY (id)
  - UNIQUE KEY sites_site_name_unique (site_name)
  - UNIQUE KEY sites_domain_name_unique (domain_name)

RELATIONSHIPS:
  - None (self-contained table)

STATUS ENUM VALUES:
  ┌──────────┬─────────────────────────────────────────────┐
  │  Value   │  Meaning                                    │
  ├──────────┼─────────────────────────────────────────────┤
  │ inactive │  Site criado mas bash script não completou  │ ← DEFAULT
  │ active   │  Site funcionando (NGINX + SSL OK)          │ ← GOAL
  │ suspended│  Site suspenso manualmente                  │
  └──────────┴─────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  TABLE: email_domains                                         │
├────────────────┬───────────────┬────────────┬────────────────┤
│  Column        │  Type         │  Nullable  │  Default       │
├────────────────┼───────────────┼────────────┼────────────────┤
│  id            │  BIGINT (PK)  │  NO        │  AUTO_INCREMENT│
│  domain_name   │  VARCHAR(255) │  NO        │  -             │
│  status        │  ENUM(...)    │  NO        │  'active'      │
│  created_at    │  TIMESTAMP    │  YES       │  NULL          │
│  updated_at    │  TIMESTAMP    │  YES       │  NULL          │
└────────────────┴───────────────┴────────────┴────────────────┘

STATUS: Funcional desde Sprint 25 ✅

┌──────────────────────────────────────────────────────────────┐
│  TABLE: email_accounts                                        │
├────────────────┬───────────────┬────────────┬────────────────┤
│  Column        │  Type         │  Nullable  │  Default       │
├────────────────┼───────────────┼────────────┼────────────────┤
│  id            │  BIGINT (PK)  │  NO        │  AUTO_INCREMENT│
│  email         │  VARCHAR(255) │  NO        │  -             │
│  password      │  VARCHAR(255) │  NO        │  -             │
│  domain_id     │  BIGINT (FK)  │  NO        │  -             │
│  status        │  ENUM(...)    │  NO        │  'active'      │
│  created_at    │  TIMESTAMP    │  YES       │  NULL          │
│  updated_at    │  TIMESTAMP    │  YES       │  NULL          │
└────────────────┴───────────────┴────────────┴────────────────┘

FOREIGN KEY:
  - domain_id REFERENCES email_domains(id)

STATUS: Funcional desde Sprint 28 ✅
```

---

## 🔍 PONTOS DE VERIFICAÇÃO (CHECKPOINTS)

```
CHECKPOINT 1: Código em Produção
════════════════════════════════════════════════════════════════
Comando:
  ssh root@72.61.53.222 "grep -n 'postScript' /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php | head -5"

Resultado ESPERADO (Sprint 30):
  121:  " && " . $postScript . " " . escapeshellarg($siteName) .
       ↑ SEM 'sudo' antes

Resultado ERRADO (Sprint 29 ou anterior):
  121:  " && sudo " . $postScript . " " . escapeshellarg($siteName) .
       ↑ COM 'sudo' = bug não corrigido

════════════════════════════════════════════════════════════════

CHECKPOINT 2: Database Status
════════════════════════════════════════════════════════════════
Comando:
  ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e 'SELECT status, COUNT(*) as total FROM sites GROUP BY status;'"

Resultado ESPERADO:
  +--------+-------+
  | status | total |
  +--------+-------+
  | active |     9 |
  +--------+-------+
       ↑ Todos sites ativos

Resultado ERRADO:
  +----------+-------+
  | status   | total |
  +----------+-------+
  | active   |     X |
  | inactive |     Y | ← Tem sites inativos = bug ainda existe
  +----------+-------+

════════════════════════════════════════════════════════════════

CHECKPOINT 3: Filesystem
════════════════════════════════════════════════════════════════
Comando:
  ssh root@72.61.53.222 "ls /var/www/ | wc -l && ls /etc/nginx/sites-available/*.conf | wc -l"

Resultado ESPERADO:
  9  ← 9 diretórios em /var/www/
  9  ← 9 configs em sites-available/
       (ou N sites no DB = N diretórios = N configs)

════════════════════════════════════════════════════════════════

CHECKPOINT 4: Logs Sem Erros
════════════════════════════════════════════════════════════════
Comando:
  ssh root@72.61.53.222 "tail -50 /tmp/site-creation-sprint31final1763516724.log | grep -i error"

Resultado ESPERADO:
  (vazio) ← Sem erros

Resultado ERRADO:
  sudo: a terminal is required to read the password
  Error: ...
       ↑ Erros indicam bug

════════════════════════════════════════════════════════════════

CHECKPOINT 5: Git Sync
════════════════════════════════════════════════════════════════
Comando Local:
  cd /home/user/webapp && git log --oneline -1

Comando Produção:
  ssh root@72.61.53.222 "cd /opt/webserver/admin-panel && git log --oneline -1"

Resultado ESPERADO:
  Local:    5c71f52 fix(sprints-30-31): Sistema 100% Funcional
  Produção: 5c71f52 fix(sprints-30-31): Sistema 100% Funcional
            ↑ MESMO commit SHA

Resultado ERRADO:
  Local:    5c71f52
  Produção: ff5b6c0 ← Diferente = deploy não feito
```

---

## 🚨 TROUBLESHOOTING VISUAL

```
PROBLEMA: Site fica 'inactive' forever
════════════════════════════════════════════════════════════════

Diagnóstico:

1. Verificar log criação:
   tail /tmp/site-creation-{site}.log
   
   Se contém: "sudo: a terminal is required"
   → Bug Sprint 30 não corrigido
   → Solução: Deploy correção Sprint 30

2. Verificar script existe:
   ls -la /tmp/post_site_creation.sh
   
   Se NÃO existe:
   → Scripts não foram copiados
   → Solução: Verificar storage/app/ no Laravel

3. Verificar permissões:
   ls -la /tmp/*.sh
   
   Se NÃO tem permissão executável:
   → chmod falhou
   → Solução: Verificar controller linha ~115

4. Verificar MySQL access:
   mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e "SELECT 1;"
   
   Se falha:
   → Credenciais erradas
   → Solução: Verificar .env ou post_site_creation.sh

════════════════════════════════════════════════════════════════

PROBLEMA: CSRF Token Mismatch (419)
════════════════════════════════════════════════════════════════

Diagnóstico:

1. Verificar session path:
   grep SESSION_PATH /opt/webserver/admin-panel/.env
   
   Deve ser: SESSION_PATH=/admin
   Se for:   SESSION_PATH=/  ← ERRADO
   → Solução: Corrigir .env + php artisan config:cache

2. Verificar cookies:
   Browser DevTools → Application → Cookies
   
   laravel_session deve ter:
     Path: /admin  ← CORRETO
   Se tiver:
     Path: /       ← ERRADO (Sprint 29 bug)

3. Verificar tempo sessão:
   grep SESSION_LIFETIME /opt/webserver/admin-panel/.env
   
   Padrão: 120 (minutos)
   Se página aberta > 120min → token expira
   → Solução: Refresh página

════════════════════════════════════════════════════════════════

PROBLEMA: NGINX 502 Bad Gateway
════════════════════════════════════════════════════════════════

Diagnóstico:

1. PHP-FPM rodando?
   systemctl status php8.3-fpm
   
   Se parado:
   → systemctl start php8.3-fpm

2. Socket existe?
   ls -la /var/run/php/php8.3-fpm.sock
   
   Se NÃO existe:
   → PHP-FPM não iniciou corretamente
   → Ver logs: /var/log/php8.3-fpm.log

3. Permissões socket:
   ls -la /var/run/php/php8.3-fpm.sock
   
   Deve ser: www-data:www-data
   Se diferente:
   → Corrigir pool.d/www.conf

════════════════════════════════════════════════════════════════
```

---

## ✅ FLUXO DE VALIDAÇÃO END-TO-END

```
START
  │
  ├─► 1. Verificar deploy em produção (grep SitesController)
  │     ├─ SEM sudo? → OK, continuar
  │     └─ COM sudo? → Deploy Sprint 30 primeiro
  │
  ├─► 2. Verificar banco de dados atual (SELECT * FROM sites)
  │     ├─ Sites existem? → OK
  │     ├─ Status active? → OK
  │     └─ SSL enabled? → OK
  │
  ├─► 3. Criar novo site teste (testevalida{timestamp})
  │     ├─ Via web interface
  │     └─ Aguardar 30 segundos
  │
  ├─► 4. Verificar DB após criação
  │     ├─ Site existe? → OK
  │     ├─ Status active? → OK (bug corrigido)
  │     └─ Status inactive? → FAIL (bug ainda existe)
  │
  ├─► 5. Verificar filesystem
  │     ├─ /var/www/{site} existe? → OK
  │     ├─ /etc/nginx/sites-available/{site}.conf existe? → OK
  │     └─ Arquivos faltando? → FAIL
  │
  ├─► 6. Verificar logs
  │     ├─ /tmp/site-creation-{site}.log sem erros? → OK
  │     └─ Contém erros? → FAIL (investigar causa)
  │
  ├─► 7. Teste HTTP
  │     ├─ curl https://{domain} retorna 200? → OK
  │     └─ Erro SSL ou conexão? → FAIL
  │
  ├─► 8. Repetir teste (criar 2 sites adicionais)
  │     ├─ Todos passam? → Sistema 100% funcional ✅
  │     └─ Algum falha? → Bug intermitente
  │
  └─► 9. Documentar resultado
        ├─ Commit changes
        ├─ Update PR
        └─ Fornecer evidências
          │
          └─► END ✅
```

---

**FIM ARQUITETURA VISUAL**
