# SPRINT 21 - Investigação e Correção de Persistência de Dados

## Data: 2025-11-17

## OBJETIVO SPRINT 21
Resolver TODOS os 3 problemas de persistência de dados:
1. 🔴 Email Domain form não salva dados em /etc/postfix/virtual_domains
2. 🔴 Email Account form não salva dados em /etc/postfix/virtual_mailbox_maps
3. 🔴 Site Creation form não cria diretório em /opt/webserver/sites/

## METODOLOGIA: SCRUM + PDCA

### BACKLOG SPRINT 21
- [ ] Task 1.1: Verificar logs Laravel durante submissão de formulários
- [ ] Task 1.2: Testar execução shell_exec() no PHP
- [ ] Task 1.3: Adicionar debug logging em EmailController e SitesController
- [ ] Task 2.1: Verificar permissões sudo para www-data
- [ ] Task 2.2: Testar scripts manualmente com bash direto
- [ ] Task 3.1: Corrigir problemas encontrados em EmailController
- [ ] Task 3.2: Corrigir problemas encontrados em SitesController
- [ ] Task 4.1: Testar correções com formulários reais
- [ ] Task 4.2: Verificar dados persistidos em arquivos Postfix
- [ ] Task 4.3: Verificar site criado em /opt/webserver/sites/
- [ ] Task 5.1: Commit completo Sprint 21
- [ ] Task 5.2: Criar/Atualizar Pull Request
- [ ] Task 5.3: Deploy em produção
- [ ] Task 5.4: Teste final end-to-end

## PDCA CYCLE 1 - INVESTIGAÇÃO

### PLAN (Planejar)
**Problema:** Formulários redirecionam (HTTP 302) mas dados não persistem
**Hipótese:** Controllers executam mas shell_exec() falha silenciosamente
**Meta:** Identificar causa raiz da falha de execução dos scripts

**Ações Planejadas:**
1. Verificar Laravel logs (últimas 100 linhas)
2. Testar se shell_exec() funciona no PHP
3. Verificar se bash está disponível para www-data
4. Adicionar logging detalhado nos Controllers

### DO (Executar)
Iniciando investigação...


### CHECK (Verificar) - Cycle 1

✅ **Causa Raiz Identificada:**

**EmailController.php (linhas 60 e 135-139):**
- ❌ Usa `bash $script` SEM sudo
- ❌ www-data não tem permissão para escrever em `/etc/postfix/`
- ❌ Scripts precisam de root para modificar arquivos do sistema

**Comparação:**
- ✅ **SitesController.php (linha 81)**: `sudo $wrapper` - CORRETO
- ❌ **EmailController::storeDomain()**: `bash $script` - ERRADO
- ❌ **EmailController::storeAccount()**: `bash $script` - ERRADO

**Impacto:**
1. Formulários executam e redirecionam corretamente (HTTP 302)
2. Scripts NÃO executam porque falta permissão
3. Dados NÃO são gravados em /etc/postfix/
4. Nenhum erro visível porque shell_exec() falha silenciosamente

### ACT (Agir) - Cycle 1

**Correções Necessárias:**
1. Adicionar `sudo` antes dos comandos bash em EmailController
2. Verificar se www-data tem permissão sudo para esses scripts
3. Testar correções com formulários reais

## PDCA CYCLE 2 - CORREÇÃO

### PLAN (Planejar)
**Meta:** Corrigir EmailController para usar sudo nos comandos bash
**Ações:**
1. Adicionar `sudo` em storeDomain() linha 60
2. Adicionar `sudo` em storeAccount() linha 135
3. Testar permissões sudo para www-data
4. Executar testes completos


### DO (Executar) - Cycle 2

✅ **Correções Aplicadas:**

**EmailController.php:**
```php
// LINHA 60 - storeDomain()
// ANTES:
$command = "bash $script $domain 2>&1";

// DEPOIS:
$command = "sudo bash $script $domain 2>&1";

// LINHA 135 - storeAccount()
// ANTES:
$command = "bash $script " . escapeshellarg($domain) . " " . ...

// DEPOIS:
$command = "sudo bash $script " . escapeshellarg($domain) . " " . ...
```

**Verificação:**
```bash
$ grep -n "sudo bash" EmailController.php
60:            $command = "sudo bash $script $domain 2>&1";
135:            $command = "sudo bash $script " . escapeshellarg($domain) . " " .
```

✅ **Status:** 2 correções aplicadas com sucesso

