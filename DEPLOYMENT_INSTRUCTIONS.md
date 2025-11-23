# 📦 INSTRUÇÕES DE DEPLOYMENT - Sites Controller Fix

**Data:** 22 de Novembro de 2025  
**Arquivo:** SitesController_RECOVERY_FIX.php  
**Servidor:** 72.61.53.222  
**Status:** ✅ **FIX PRONTO PARA DEPLOY**

---

## 🎯 O QUE FOI CORRIGIDO

### Problema Identificado:
- **Sintoma:** Sessão perdida ao tentar criar site
- **Sintoma:** Nenhum dado salvo no banco de dados  
- **Sintoma:** Nenhum diretório criado fisicamente

### Causa Raiz Provável:
1. `shell_exec()` pode estar desabilitado no PHP
2. Função pode estar falhando silenciosamente
3. Exception não sendo capturada corretamente

### Solução Implementada:
✅ **Múltiplos métodos de execução de comandos:**
- Tenta `shell_exec()` primeiro
- Fallback para `exec()` se shell_exec falhar
- Fallback para `proc_open()` se exec falhar
- Log detalhado em cada tentativa

✅ **Lógica corrigida:**
- Fixed: `has_database` agora usa valor boolean direto
- Fixed: `database_name` e `database_user` com lógica correta

✅ **Melhor tratamento de erros:**
- Verifica se script wrapper existe antes de executar
- Mensagens de erro claras para usuários
- Logging comprehensivo em cada etapa
- Não perde sessão em caso de erro

✅ **Validações adicionadas:**
- Checa se funções estão desabilitadas antes de usar
- Valida criação física antes de salvar no banco
- Retorna erros específicos ao invés de redirecionar para login

---

## 🚀 COMO FAZER O DEPLOY

### Opção 1: Deploy Manual (RECOMENDADO)

#### Passo 1: Conectar ao servidor
```bash
ssh root@72.61.53.222
```

#### Passo 2: Fazer backup do controller atual
```bash
cd /opt/webserver/admin-panel/app/Http/Controllers
cp SitesController.php SitesController.backup.$(date +%Y%m%d_%H%M%S).php
```

#### Passo 3: Baixar o fix do repositório
```bash
cd /opt/webserver/admin-panel/app/Http/Controllers
wget https://raw.githubusercontent.com/fmunizmcorp/servidorvpsprestadores/genspark_ai_developer/SitesController_RECOVERY_FIX.php -O SitesController.php
```

**OU** copiar manualmente o conteúdo de `SitesController_RECOVERY_FIX.php` para o servidor.

#### Passo 4: Ajustar permissões
```bash
chown www-data:www-data SitesController.php
chmod 644 SitesController.php
```

#### Passo 5: Limpar caches do Laravel
```bash
cd /opt/webserver/admin-panel
php artisan route:clear
php artisan config:clear
php artisan view:clear
php artisan clear-compiled
```

#### Passo 6: Verificar que o fix foi aplicado
```bash
grep -n "RECOVERY FIX" /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php
```

Se mostrar resultados, o fix foi aplicado corretamente!

---

### Opção 2: Deploy Automático (Script)

Se você tiver acesso SSH configurado, pode usar o script fornecido:

```bash
cd /home/user/webapp
./deploy_sites_controller_fix.sh
```

**Nota:** O script requer:
- SSH key configurada OU password via sshpass
- Permissões de root no servidor

---

## ✅ COMO TESTAR APÓS DEPLOY

### Teste 1: Acessar Admin Panel
```
URL: https://72.61.53.222/admin/
Email: admin@vps.local
Senha: mcorpapp
```

### Teste 2: Criar Site
1. Navegar para "Sites" no menu
2. Clicar em "Create New Site"
3. Preencher formulário:
   - Site Name: `teste_recovery_fix`
   - Domain: `teste-recovery.local`
   - PHP Version: `8.3`
   - Create Database: ✅ (checked)
4. Clicar em "Create Site"

### Resultado Esperado:
✅ **Redirecionado para lista de sites (NÃO para login!)**  
✅ **Mensagem de sucesso aparece**  
✅ **Site aparece na lista**

### Teste 3: Verificar Persistência no Banco
```bash
ssh root@72.61.53.222
mysql -u root -p admin_panel
```

```sql
SELECT * FROM sites WHERE site_name = 'teste_recovery_fix';
```

**Resultado Esperado:**
- ✅ Registro existe no banco
- ✅ `has_database` = 1 (se checkbox foi marcado)
- ✅ `database_name` preenchido
- ✅ `status` = 'active'

### Teste 4: Verificar Criação Física
```bash
ls -la /opt/webserver/sites/teste_recovery_fix/
```

**Resultado Esperado:**
- ✅ Diretório existe
- ✅ Contém `public_html/`
- ✅ Contém `CREDENTIALS.txt` (se database foi criado)

### Teste 5: Verificar Logs
```bash
tail -50 /opt/webserver/admin-panel/storage/logs/laravel.log
```

**Procurar por:**
- ✅ `RECOVERY: Site creation started`
- ✅ `RECOVERY: Command executed`
- ✅ `RECOVERY: Site physically created`
- ✅ `RECOVERY: Site persisted to database`

**NÃO deve aparecer:**
- ❌ Erros de "shell_exec disabled"
- ❌ Erros de "Site directory not created"
- ❌ Exception traces

---

## 🔍 TROUBLESHOOTING

### Se ainda redireciona para login:

**Verificar:** Funções PHP desabilitadas
```bash
php -r "echo ini_get('disable_functions');"
```

Se `shell_exec`, `exec`, E `proc_open` estiverem todos desabilitados:
1. Editar `/etc/php/8.3/fpm/php.ini`
2. Remover essas funções de `disable_functions`
3. Reiniciar PHP-FPM: `systemctl restart php8.3-fpm`

### Se script wrapper não existe:

**Verificar:**
```bash
ls -la /opt/webserver/scripts/wrappers/create-site-wrapper.sh
```

Se não existir:
1. Restaurar scripts do repositório
2. OU criar script manualmente
3. OU modificar controller para não usar script

### Se sudo não funciona:

**Verificar:**
```bash
sudo -u www-data sudo -n whoami
```

Se falhar, adicionar em `/etc/sudoers.d/webserver`:
```
www-data ALL=(ALL) NOPASSWD: /opt/webserver/scripts/
```

---

## 📊 DIAGNÓSTICO ADICIONAL

Se ainda houver problemas após o deploy, executar script de diagnóstico:

```bash
cd /opt/webserver/admin-panel
php /path/to/diagnose_real_problem.php
```

Este script verificará:
- ✅ Funções PHP disponíveis
- ✅ Permissões sudo
- ✅ Existência de scripts
- ✅ Permissões de diretórios
- ✅ Logs do Laravel
- ✅ Conexão com banco de dados

---

## 📝 CHECKLIST DE DEPLOYMENT

- [ ] Backup do controller atual criado
- [ ] Novo controller copiado para servidor
- [ ] Permissões ajustadas (www-data:www-data 644)
- [ ] Caches do Laravel limpos
- [ ] Teste de criação de site realizado
- [ ] Persistência no banco verificada
- [ ] Criação física de diretório verificada
- [ ] Logs do Laravel verificados
- [ ] Sistema funcionando sem redirecionar para login

---

## 🎯 RESULTADO ESPERADO

### Antes do Fix:
- ❌ Criar site → Sessão perdida → Redirect para login
- ❌ Nenhum dado no banco
- ❌ Nenhum diretório criado

### Depois do Fix:
- ✅ Criar site → Sucesso → Volta para lista
- ✅ Dados salvos no banco
- ✅ Diretório criado fisicamente
- ✅ Credenciais disponíveis (se database criado)

---

## 📞 SUPORTE

Se após o deployment o problema persistir:

1. **Verificar logs detalhados:**
   ```bash
   tail -100 /opt/webserver/admin-panel/storage/logs/laravel.log | grep RECOVERY
   ```

2. **Executar diagnóstico completo:**
   ```bash
   php diagnose_real_problem.php > diagnostic_results.txt
   ```

3. **Compartilhar resultados:**
   - Output do diagnóstico
   - Últimas 50 linhas do laravel.log
   - Resultado da tentativa de criar site

---

**ARQUIVOS IMPORTANTES:**
- `SitesController_RECOVERY_FIX.php` - Controller corrigido
- `deploy_sites_controller_fix.sh` - Script de deployment automático
- `diagnose_real_problem.php` - Script de diagnóstico
- `HONEST_ANALYSIS.md` - Análise dos erros anteriores
- `RECOVERY_SPRINT_56_HONEST_REPORT.md` - Relatório completo

**STATUS:** ✅ **PRONTO PARA DEPLOYMENT**

**PRÓXIMO PASSO:** Fazer deploy seguindo as instruções acima e testar!
