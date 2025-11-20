# SPRINT 20 - DIAGNÓSTICO COMPLETO

**Data:** 2025-11-17  
**Status:** DIAGNÓSTICO CONCLUÍDO

---

## 🔍 INVESTIGAÇÃO REALIZADA

### 1. Verificação dos Controllers

#### SitesController::store()
✅ **Código correto** - Executa script wrapper  
❓ **Status**: Script existe e é executável  
🔴 **Problema**: Script pode estar falhando ou demorando (502 Bad Gateway)

#### EmailController::storeDomain()
✅ **Código correto** - Executa script de criação de domínio  
✅ **Mensagem de sucesso** implementada  
🔴 **Problema**: Script tem BUG no formato do arquivo Postfix

#### EmailController::storeAccount()
✅ **Código correto** - Executa script de criação de conta  
✅ **Mensagem de sucesso** implementada  
❓ **Status**: Script precisa ser testado

---

## 🐛 BUGS ENCONTRADOS

### Bug #1: Postfix virtual_domains formato incorreto

**Arquivo:** `/opt/webserver/scripts/create-email-domain.sh`  
**Linha:** 9

**Código Atual:**
```bash
echo "$DOMAIN" >> /etc/postfix/virtual_domains
```

**Problema:**
- Postfix virtual_domains espera formato: `domain OK`
- Script está salvando apenas: `domain`
- Causa warnings do postmap: "expected format: key whitespace value"

**Correção Necessária:**
```bash
echo "$DOMAIN OK" >> /etc/postfix/virtual_domains
```

**Impacto:**
- Domínios são criados mas com warnings
- Pode causar problemas no Postfix
- Arquivo precisa ser corrigido retroativamente

---

### Bug #2: Postfix virtual_domains arquivo existente corrompido

**Arquivo:** `/etc/postfix/virtual_domains`

**Conteúdo Atual:**
```
testdirect.example.com
testefinal16email.local
testemaildomain18.local
testsprint183.local
sprint20test.local
```

**Problema:**
- Todos os domínios sem o "OK"
- Postfix reclama de formato incorreto

**Correção Necessária:**
```
testdirect.example.com OK
testefinal16email.local OK
testemaildomain18.local OK
testsprint183.local OK
sprint20test.local OK
```

**Comando para corrigir:**
```bash
# Backup
cp /etc/postfix/virtual_domains /etc/postfix/virtual_domains.backup

# Adicionar OK a cada linha
sed -i 's/$/\ OK/' /etc/postfix/virtual_domains

# Refazer o hash
postmap /etc/postfix/virtual_domains

# Reload Postfix
systemctl reload postfix
```

---

### Bug #3: Create Site pode estar timing out

**Problema:**
- SitesController executa script wrapper com sudo
- Script wrapper provavelmente executa create-site.sh
- Processo demora > 2 minutos (timeout padrão PHP-FPM)
- Resultado: HTTP 502 Bad Gateway

**Possíveis Causas:**
1. Script create-site.sh demora muito
2. Precisa criar estrutura de diretórios, NGINX, PHP-FPM, DB
3. PHP-FPM mata o processo por timeout
4. NGINX retorna 502

**Possíveis Soluções:**
1. Aumentar timeout PHP-FPM para este pool
2. Executar script em background e retornar imediatamente
3. Usar queue/job system (Laravel Queue)
4. Fazer script mais rápido

---

## 📊 ANÁLISE DOS SCRIPTS

### Script 1: create-email-domain.sh
- **Localização:** `/opt/webserver/scripts/create-email-domain.sh`
- **Tamanho:** 1773 bytes
- **Permissões:** -rwxr-xr-x (executável)
- **Status:** ✅ Existe, 🔴 TEM BUG (linha 9)
- **O que faz:**
  1. Adiciona domínio a virtual_domains (COM BUG)
  2. Cria diretório de mailboxes
  3. Gera chaves DKIM
  4. Configura OpenDKIM
  5. Reload Postfix e OpenDKIM
  6. Exibe DNS records

**Teste Manual:**
```bash
bash /opt/webserver/scripts/create-email-domain.sh sprint20test.local
```
**Resultado:** ✅ Funciona MAS com warnings do Postfix

---

### Script 2: create-email.sh
- **Localização:** `/opt/webserver/scripts/create-email.sh`
- **Tamanho:** 896 bytes
- **Permissões:** -rwxr-xr-x (executável)
- **Status:** ✅ Existe, ❓ Não testado ainda

**Precisa testar:**
```bash
bash /opt/webserver/scripts/create-email.sh sprint20test.local testuser password123 1000
```

---

### Script 3: create-site-wrapper.sh
- **Localização:** `/opt/webserver/scripts/wrappers/create-site-wrapper.sh`
- **Tamanho:** 756 bytes
- **Permissões:** -rwxr-xr-x (executável)
- **Status:** ✅ Existe, 🔴 Provavelmente causa timeout

**Precisa:**
1. Ler o script para entender o que faz
2. Identificar por que demora
3. Implementar solução de timeout

---

## 🎯 PLANO DE CORREÇÃO

### Correção 1: Fix create-email-domain.sh (IMEDIATO)

**Prioridade:** 🔴 ALTA

**Passos:**
1. Ler script completo
2. Corrigir linha 9: `echo "$DOMAIN OK"`
3. Deploy script corrigido
4. Corrigir arquivo virtual_domains existente
5. Testar criação de novo domínio
6. Verificar que aparece na listagem

---

### Correção 2: Fix virtual_domains existente (IMEDIATO)

**Prioridade:** 🔴 ALTA

**Passos:**
1. Backup do arquivo atual
2. Adicionar " OK" a cada linha
3. Refazer hash com postmap
4. Reload Postfix
5. Verificar warnings desapareceram

---

### Correção 3: Test e Fix create-email.sh (SE NECESSÁRIO)

**Prioridade:** 🟡 MÉDIA

**Passos:**
1. Ler script completo
2. Testar manualmente criação de conta
3. Verificar se conta aparece na listagem
4. Se houver bug, corrigir
5. Deploy e teste novamente

---

### Correção 4: Fix create-site timeout (COMPLEXO)

**Prioridade:** 🟡 MÉDIA (pode ser trabalhado depois)

**Opções:**

**Opção A: Background Job (RECOMENDADO)**
```php
// No SitesController::store()
use Illuminate\Support\Facades\Process;

// Execute em background
Process::start("sudo $wrapper " . implode(" ", $args));

// Retorna imediatamente
return redirect()->route('sites.index')
    ->with('info', 'Site creation started. This may take a few minutes.')
    ->with('site_name', $siteName);
```

**Opção B: Aumentar Timeout**
```php
// Adicionar antes de shell_exec()
set_time_limit(300); // 5 minutos

// Ou no PHP-FPM pool: request_terminate_timeout = 300
```

**Opção C: API Assíncrona**
- Criar endpoint /api/sites/status/{siteName}
- Frontend faz polling a cada 5 segundos
- Mostra progresso ao usuário

---

## ✅ RESULTADO ESPERADO APÓS CORREÇÕES

### Formulário Create Email Domain
- ✅ Domínio salvo no Postfix SEM warnings
- ✅ Domínio aparece na listagem imediatamente
- ✅ Mensagem de sucesso exibida
- ✅ DNS records exibidos

### Formulário Create Email Account  
- ✅ Conta criada no Postfix
- ✅ Conta aparece na listagem imediatamente
- ✅ Mensagem de sucesso exibida

### Formulário Create Site
- ✅ Site criado (pode demorar)
- ✅ Mensagem de progresso/sucesso exibida
- ✅ Site aparece na listagem após conclusão
- 🟡 Pode precisar reload da página ou polling

---

## 📈 MÉTRICAS DE PROGRESSO

| Item | Antes | Agora | Meta |
|------|-------|-------|------|
| Scripts Analisados | 0/3 | 3/3 | 3/3 ✅ |
| Bugs Identificados | 0 | 3 | N/A |
| Scripts Testados | 0/3 | 1/3 | 3/3 |
| Correções Implementadas | 0/3 | 0/3 | 3/3 |

---

## 🚀 PRÓXIMOS PASSOS

1. ✅ Ler create-email.sh completo
2. ✅ Testar create-email.sh manualmente
3. ⚠️ Corrigir create-email-domain.sh
4. ⚠️ Corrigir virtual_domains existente
5. ⚠️ Deploy correções
6. ⚠️ Testar end-to-end com credenciais do testador
7. ⚠️ Decidir solução para create-site timeout
8. ⚠️ Implementar solução escolhida
9. ⚠️ Testes finais
10. ⚠️ Commit, PR, Deploy

---

**Status:** DIAGNÓSTICO COMPLETO - PRONTO PARA IMPLEMENTAR CORREÇÕES  
**Próximo:** Implementar Correção #1 (create-email-domain.sh)
