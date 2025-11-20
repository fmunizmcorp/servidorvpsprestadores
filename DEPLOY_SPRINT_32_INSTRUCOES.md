# 🚀 INSTRUÇÕES DE DEPLOY - SPRINT 32

**CORREÇÃO CRÍTICA**: Scripts de criação de site agora são copiados corretamente para `/tmp/`

---

## ⚡ DEPLOY RÁPIDO (5 MINUTOS)

```bash
# === PASSO 1: SSH no servidor ===
ssh root@72.61.53.222
# Senha: Jm@D@KDPnw7Q

# === PASSO 2: Backup e Deploy ===
cd /opt/webserver/admin-panel
cp -r storage/app storage/app.backup.$(date +%Y%m%d)
git fetch origin genspark_ai_developer
git checkout genspark_ai_developer
git pull origin genspark_ai_developer

# === PASSO 3: Permissões CRÍTICAS ===
chmod 755 storage/app/*.sh
chown www-data:www-data storage/app/*.sh
chown -R www-data:www-data storage bootstrap/cache

# === PASSO 4: Cache e Restart ===
php artisan config:cache
php artisan route:cache
systemctl restart php8.3-fpm
systemctl reload nginx

# === PASSO 5: Verificar Deploy ===
grep -n "SPRINT 32 FIX" app/Http/Controllers/SitesController.php | wc -l
# Deve mostrar: 2
```

---

## ✅ TESTE RÁPIDO (2 MINUTOS)

```bash
# Via web interface:
# 1. Acessar: https://72.61.53.222/admin
# 2. Login: admin@example.com / Admin@123
# 3. Sites → Create New
# 4. Criar: testfinal_<timestamp>
# 5. Aguardar 30 segundos
# 6. Verificar aparece na listagem ✅
```

**OU via CLI:**

```bash
ssh root@72.61.53.222

# Criar timestamp
TS=$(date +%s)

# Testar via artisan tinker
cd /opt/webserver/admin-panel
php artisan tinker << TINKER
\$ts = ${TS};
\$site = new App\Models\Site(['site_name' => 'testfinal' . \$ts, 'domain_name' => 'testfinal' . \$ts . '.com', 'description' => 'Teste final', 'php_version' => '8.3', 'status' => 'inactive', 'ssl_enabled' => false]);
\$site->save();
echo "Site ID: " . \$site->id . "\n";
exit
TINKER

# Aguardar 30 segundos
sleep 30

# Verificar resultado
mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e "SELECT site_name, status, ssl_enabled FROM sites WHERE site_name LIKE 'testfinal%';"

# Esperado: status='active', ssl_enabled=1
```

---

## 🔍 TROUBLESHOOTING

### Se site ficar 'inactive'

```bash
# 1. Verificar logs Laravel
tail -100 /opt/webserver/admin-panel/storage/logs/laravel.log

# 2. Verificar logs criação
ls -la /tmp/site-creation-*.log | tail -1
tail -100 /tmp/site-creation-testfinal*.log

# 3. Verificar scripts em /tmp foram copiados
ls -la /tmp/*.sh

# 4. Verificar script principal existe
ls -la /root/create-site.sh
# DEVE EXISTIR e ser executável
```

### Script /root/create-site.sh não existe

**Se `/root/create-site.sh` não existir no servidor:**

```bash
# Copiar do repositório
cd /opt/webserver/admin-panel
cp scripts/create-site.sh /root/
chmod 755 /root/create-site.sh

# Testar execução
/root/create-site.sh testemergencia testemergencia.com 8.3
```

### Permissões Incorretas

```bash
# Corrigir todas permissões
cd /opt/webserver/admin-panel
chown -R www-data:www-data .
chmod -R 755 storage bootstrap/cache
chmod 755 storage/app/*.sh
```

---

## 📊 VALIDAÇÃO COMPLETA (10 MINUTOS)

```bash
# === Teste 1: Criar site ===
# (via web interface ou CLI conforme acima)

# === Teste 2: Verificar DB ===
mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e \
  "SELECT id, site_name, status, ssl_enabled, created_at FROM sites ORDER BY id DESC LIMIT 5;"

# === Teste 3: Verificar filesystem ===
ls -la /var/www/ | tail -10
ls -la /etc/nginx/sites-available/ | tail -10

# === Teste 4: Verificar logs sem erros ===
tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log
tail -50 /tmp/site-creation-*.log | tail -50
```

**Critério de Sucesso:**
- ✅ Site aparece na listagem web
- ✅ Database: `status='active'` e `ssl_enabled=1`
- ✅ Diretório `/var/www/<site>` criado
- ✅ Config `/etc/nginx/sites-available/<site>.conf` criado
- ✅ Logs sem erros

---

## ⚠️ IMPORTANTE

### O que mudou no Sprint 32?

**ANTES:**
```php
// Scripts nunca eram copiados para /tmp/
$wrapper = "/tmp/create-site-wrapper.sh";  // ❌ Não existia
$postScript = "/tmp/post_site_creation.sh"; // ❌ Não existia
exec($command); // ❌ Falhava silenciosamente
```

**DEPOIS:**
```php
// Scripts agora são copiados ANTES de executar
copy(storage_path('app/create-site-wrapper.sh'), '/tmp/create-site-wrapper.sh');
copy(storage_path('app/post_site_creation.sh'), '/tmp/post_site_creation.sh');
chmod('/tmp/create-site-wrapper.sh', 0755);
chmod('/tmp/post_site_creation.sh', 0755);
exec($command); // ✅ Funciona!
```

### Por que isso corrige o problema?

1. **Antes**: Comando tentava executar scripts que não existiam → falha silenciosa
2. **Depois**: Scripts são copiados primeiro → comando executa com sucesso
3. **Resultado**: Sites agora ficam com `status='active'` corretamente

---

## 📞 SUPORTE

**Se encontrar problemas:**

1. Verificar `/root/create-site.sh` existe
2. Verificar permissões (`storage/app/*.sh` deve ser 755)
3. Verificar logs Laravel (`storage/logs/laravel.log`)
4. Verificar logs criação (`/tmp/site-creation-*.log`)

**Pull Request com mais detalhes:**
https://github.com/fmunizmcorp/servidorvpsprestadores/pull/1

---

**Deploy criado por**: IA Developer (Sprint 32)  
**Data**: 2025-11-19  
**Commit**: aba8351  
**Tempo estimado**: 5-10 minutos
