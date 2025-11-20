# ✅ CHECKLIST PASSO-A-PASSO - NOVA SESSÃO IA

**Use este checklist para resolver o problema DEFINITIVAMENTE**

---

## 📋 FASE 0: PREPARAÇÃO (5 minutos)

### [ ] 0.1 - Ler Documentação
- [ ] Ler `PROMPT_COMPLETO_NOVA_SESSAO_IA.md` (documento principal - 33KB)
- [ ] Ler `RESUMO_EXECUTIVO_RAPIDO.md` (resumo executivo)
- [ ] Ter `CREDENCIAIS_E_COMANDOS.txt` aberto para copiar comandos
- [ ] Ter `ARQUITETURA_VISUAL.md` como referência

### [ ] 0.2 - Setup GitHub
```bash
cd /home/user/webapp
# Use tool setup_github_environment
```

### [ ] 0.3 - Criar TODO List
```bash
# Use TodoWrite tool para criar lista detalhada Sprint 32
```

**Exemplo TODO**:
```
Sprint 32: Validação Definitiva e Correção Final

[pending] HIGH: Fase 1 - Investigação (30min)
  ├─ [pending] Verificar deploy Sprint 30
  ├─ [pending] Verificar banco de dados
  ├─ [pending] Verificar filesystem
  ├─ [pending] Verificar logs
  └─ [pending] Determinar causa raiz

[pending] HIGH: Fase 2 - Teste ao Vivo (20min)
  ├─ [pending] Criar site teste 1
  ├─ [pending] Verificar resultado
  └─ [pending] Documentar evidências

[pending] MEDIUM: Fase 3 - Correção (SE necessário - 1h)
  ├─ [pending] Deploy Sprint 30 (se não estiver)
  ├─ [pending] Corrigir bug específico (se houver)
  └─ [pending] Validar correção

[pending] MEDIUM: Fase 4 - Validação Final (30min)
  ├─ [pending] Criar 3 sites novos
  ├─ [pending] Verificar todos passam
  └─ [pending] Coletar evidências

[pending] LOW: Fase 5 - Documentação (20min)
  ├─ [pending] Commit final
  ├─ [pending] Update PR
  └─ [pending] Fornecer link PR
```

---

## 🔍 FASE 1: INVESTIGAÇÃO (30 minutos)

**OBJETIVO**: Determinar se deploy Sprint 30 está em produção e se sistema funciona

### [ ] 1.1 - Verificar Código em Produção (CRÍTICO)

**Comando**:
```bash
ssh root@72.61.53.222 "grep -n 'postScript' /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php | head -10"
```

**Análise**:
- [ ] **Se linha contém `&& sudo`**: Deploy NÃO foi feito → Ir para 1.7 (Deploy Manual)
- [ ] **Se linha contém `&& "`** (sem sudo): Deploy OK → Continuar para 1.2

**Documentar resultado**:
```
Checkpoint 1.1: [ PASS / FAIL ]
Linha encontrada: _________________________________
Deploy Sprint 30: [ SIM / NÃO ]
```

---

### [ ] 1.2 - Verificar Database Status

**Comando**:
```bash
ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e 'SELECT id, site_name, status, ssl_enabled, created_at FROM sites ORDER BY created_at DESC LIMIT 10;'"
```

**Análise**:
- [ ] Contar sites com `status='active'`: _______
- [ ] Contar sites com `status='inactive'`: _______
- [ ] Todos têm `ssl_enabled=1`?: [ SIM / NÃO ]

**Se há sites 'inactive'**:
- [ ] Verificar se são recentes (created_at < 2 minutos)
- [ ] Se antigos: Bug não corrigido → Ir para 1.7

**Documentar resultado**:
```
Checkpoint 1.2: [ PASS / FAIL ]
Total sites: ______
Sites ativos: ______
Sites inativos: ______
```

---

### [ ] 1.3 - Verificar Git Log Produção

**Comando**:
```bash
ssh root@72.61.53.222 "cd /opt/webserver/admin-panel && git log --oneline -5"
```

**Análise**:
- [ ] Procurar commit `5c71f52` ou "Sprint 30" ou "Sprint 31"
- [ ] Commit encontrado?: [ SIM / NÃO ]
- [ ] Se NÃO: Git pull não foi feito → Ir para 1.7

**Documentar resultado**:
```
Checkpoint 1.3: [ PASS / FAIL ]
Último commit: _________________________________
Commit Sprint 30-31 presente: [ SIM / NÃO ]
```

---

### [ ] 1.4 - Verificar Filesystem

**Comandos**:
```bash
# Diretórios sites
ssh root@72.61.53.222 "ls -la /var/www/ | grep -E 'sprint|test' | wc -l"

# Configs NGINX
ssh root@72.61.53.222 "ls -la /etc/nginx/sites-available/ | grep -E 'sprint|test' | wc -l"
```

**Análise**:
- [ ] Número de diretórios em /var/www/: _______
- [ ] Número de configs NGINX: _______
- [ ] Números batem com DB?: [ SIM / NÃO ]

**Documentar resultado**:
```
Checkpoint 1.4: [ PASS / FAIL ]
Diretórios: ______ Configs: ______ DB: ______
```

---

### [ ] 1.5 - Verificar Logs de Criação

**Comando**:
```bash
ssh root@72.61.53.222 "ls -la /tmp/site-creation-*.log | tail -5"
ssh root@72.61.53.222 "tail -50 /tmp/site-creation-sprint31final1763516724.log"
```

**Análise**:
- [ ] Logs existem?: [ SIM / NÃO ]
- [ ] Procurar erros: `grep -i error`
- [ ] Procurar "sudo: a terminal": [ SIM / NÃO ]
- [ ] Procurar "updated to active": [ SIM / NÃO ]

**Se contém erro "sudo: a terminal"**:
- [ ] Bug Sprint 30 NÃO corrigido → Ir para 1.7

**Documentar resultado**:
```
Checkpoint 1.5: [ PASS / FAIL ]
Logs existem: [ SIM / NÃO ]
Contém erros: [ SIM / NÃO ]
Tipo erro: _________________________________
```

---

### [ ] 1.6 - Verificar Scripts Storage

**Comando**:
```bash
ssh root@72.61.53.222 "cat /opt/webserver/admin-panel/storage/app/post_site_creation.sh | head -20"
```

**Análise**:
- [ ] Script existe?: [ SIM / NÃO ]
- [ ] Usa `mysql -u root -p'...'`?: [ SIM / NÃO ]
- [ ] Tem `sleep 3`?: [ SIM / NÃO ]
- [ ] UPDATE usa `status='active'`?: [ SIM / NÃO ]

**Documentar resultado**:
```
Checkpoint 1.6: [ PASS / FAIL ]
Script correto: [ SIM / NÃO ]
```

---

### [ ] 1.7 - Deploy Manual (SE NECESSÁRIO)

**Executar APENAS se checkpoints 1.1 ou 1.3 falharam**

```bash
ssh root@72.61.53.222 << 'ENDSSH'
cd /opt/webserver/admin-panel
git fetch origin genspark_ai_developer
git checkout genspark_ai_developer
git pull origin genspark_ai_developer
composer install --no-dev --optimize-autoloader
php artisan config:cache
php artisan route:cache
php artisan view:cache
chown -R www-data:www-data /opt/webserver/admin-panel
chmod -R 755 storage bootstrap/cache
systemctl restart php8.3-fpm
systemctl reload nginx
echo "Deploy completo!"
ENDSSH
```

**Após deploy**:
- [ ] Repetir checkpoint 1.1
- [ ] Repetir checkpoint 1.3
- [ ] Ambos PASS agora?: [ SIM / NÃO ]

---

### [ ] 1.8 - Determinar Causa Raiz

**Com base nos checkpoints acima**:

- [ ] **CENÁRIO A**: Todos checkpoints PASS
  - Deploy está correto
  - Sistema deve estar funcional
  - **Ação**: Ir para Fase 2 (Teste ao Vivo)

- [ ] **CENÁRIO B**: Checkpoint 1.1 FAIL (código errado)
  - Deploy Sprint 30 não foi feito
  - **Ação**: Executar 1.7, depois Fase 2

- [ ] **CENÁRIO C**: Checkpoints PASS mas há sites 'inactive'
  - Bug diferente ou intermitente
  - **Ação**: Ir para Fase 2 (criar site novo)

- [ ] **CENÁRIO D**: Múltiplos checkpoints FAIL
  - Problema maior (servidor, serviços, etc)
  - **Ação**: Verificar serviços (nginx, php-fpm, mysql)

**Documentar conclusão Fase 1**:
```
FASE 1 COMPLETA: ___________
Causa raiz: _________________________________
Cenário: [ A / B / C / D ]
Próxima ação: _________________________________
```

---

## 🧪 FASE 2: TESTE AO VIVO (20 minutos)

**OBJETIVO**: Criar um site NOVO e verificar se funciona end-to-end

### [ ] 2.1 - Preparar Teste

**Gerar timestamp**:
```bash
TIMESTAMP=$(date +%s)
echo "Timestamp: $TIMESTAMP"
```

**Dados do teste**:
- Site name: `validafinal{TIMESTAMP}`
- Domain: `validafinal{TIMESTAMP}.com`
- Description: `Teste validação definitiva Sprint 32`

---

### [ ] 2.2 - Criar Site via Web Interface

**Passos**:
1. [ ] Abrir: `https://72.61.53.222/admin`
2. [ ] Login: `admin@example.com` / `Admin@123`
3. [ ] Navegar: Sites → Create New
4. [ ] Preencher formulário:
   - site_name: `validafinal{TIMESTAMP}`
   - domain_name: `validafinal{TIMESTAMP}.com`
   - description: `Teste definitivo`
5. [ ] Submit
6. [ ] Capturar mensagem retornada (PID)
7. [ ] **IMPORTANTE**: Aguardar 30 segundos

**Documentar**:
```
Site criado: validafinal___________
PID retornado: ___________
Timestamp início: ___________
```

---

### [ ] 2.3 - Verificar Database (Imediato - 5s após submit)

**Comando**:
```bash
ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e \"SELECT * FROM sites WHERE site_name LIKE 'validafinal%';\""
```

**Análise**:
- [ ] Site aparece no DB?: [ SIM / NÃO ]
- [ ] Status inicial: [ active / inactive ]
- [ ] SSL enabled: [ 0 / 1 ]

**Esperado**:
- Status: `inactive` (normal nos primeiros 5s)
- SSL: `0` (normal nos primeiros 5s)

**Documentar**:
```
Checkpoint 2.3: [ PASS / FAIL ]
Status: ___________
SSL: ___________
```

---

### [ ] 2.4 - Aguardar Background Process (30 segundos)

```bash
echo "Aguardando 30 segundos..."
sleep 30
echo "Pronto para verificar resultado"
```

---

### [ ] 2.5 - Verificar Database (Após 30s)

**Comando** (mesmo do 2.3):
```bash
ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e \"SELECT * FROM sites WHERE site_name LIKE 'validafinal%';\""
```

**Análise CRÍTICA**:
- [ ] Status agora é: [ active / inactive ]
- [ ] SSL enabled agora é: [ 0 / 1 ]

**Resultado**:
- [ ] **PASS**: `status='active'` E `ssl_enabled=1`
  - Sistema funciona! ✅
  - Ir para 2.6

- [ ] **FAIL**: `status='inactive'` OU `ssl_enabled=0`
  - Bug ainda existe ❌
  - Ir para 2.8 (Diagnóstico Detalhado)

**Documentar**:
```
Checkpoint 2.5: [ PASS / FAIL ]
Status final: ___________
SSL final: ___________
Sistema funciona: [ SIM / NÃO ]
```

---

### [ ] 2.6 - Verificar Filesystem (Se 2.5 PASS)

**Comandos**:
```bash
# Diretório site
ssh root@72.61.53.222 "ls -la /var/www/ | grep validafinal"

# Config NGINX
ssh root@72.61.53.222 "ls -la /etc/nginx/sites-available/ | grep validafinal"

# Conteúdo config
ssh root@72.61.53.222 "cat /etc/nginx/sites-available/validafinal*.conf | head -20"
```

**Análise**:
- [ ] Diretório `/var/www/validafinal*` existe?: [ SIM / NÃO ]
- [ ] Config `/etc/nginx/sites-available/validafinal*.conf` existe?: [ SIM / NÃO ]
- [ ] Config tem `ssl_certificate`?: [ SIM / NÃO ]

**Documentar**:
```
Checkpoint 2.6: [ PASS / FAIL ]
Filesystem completo: [ SIM / NÃO ]
```

---

### [ ] 2.7 - Verificar Logs (Se 2.5 PASS ou FAIL)

**Comando**:
```bash
ssh root@72.61.53.222 "tail -100 /tmp/site-creation-validafinal*.log"
```

**Análise**:
- [ ] Log existe?: [ SIM / NÃO ]
- [ ] Contém erros?: [ SIM / NÃO ]
- [ ] Contém "updated to active"?: [ SIM / NÃO ]

**Se PASS (2.5)**:
- Log deve mostrar sucesso completo

**Se FAIL (2.5)**:
- Log deve mostrar erro específico → usar para diagnóstico

**Documentar**:
```
Checkpoint 2.7: [ PASS / FAIL ]
Log mostra: _________________________________
Erro encontrado: _________________________________
```

---

### [ ] 2.8 - Diagnóstico Detalhado (Se 2.5 FAIL)

**Investigar causa exata**:

**A. Verificar post_site_creation.sh executou**:
```bash
ssh root@72.61.53.222 "grep 'updated to active' /tmp/site-creation-validafinal*.log"
```
- [ ] Linha encontrada?: [ SIM / NÃO ]
- [ ] Se NÃO: Script não executou

**B. Verificar erro sudo**:
```bash
ssh root@72.61.53.222 "grep 'sudo: a terminal' /tmp/site-creation-validafinal*.log"
```
- [ ] Erro encontrado?: [ SIM / NÃO ]
- [ ] Se SIM: Bug Sprint 30 ainda presente

**C. Verificar MySQL access**:
```bash
ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' -e 'SELECT 1;'"
```
- [ ] Conecta?: [ SIM / NÃO ]
- [ ] Se NÃO: Credenciais erradas

**D. Testar UPDATE manual**:
```bash
ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e \"UPDATE sites SET status='active', ssl_enabled=1 WHERE site_name LIKE 'validafinal%';\""
```
- [ ] UPDATE funciona manualmente?: [ SIM / NÃO ]

**Documentar causa**:
```
Causa exata: _________________________________
Teste A: [ PASS / FAIL ]
Teste B: [ PASS / FAIL ]
Teste C: [ PASS / FAIL ]
Teste D: [ PASS / FAIL ]
```

---

### [ ] 2.9 - Conclusão Fase 2

**Baseado nos testes**:

- [ ] **RESULTADO A**: Checkpoint 2.5 PASS
  - Sistema funciona!
  - Deploy Sprint 30 está correto
  - **Ação**: Ir para Fase 4 (Validação Final)

- [ ] **RESULTADO B**: Checkpoint 2.5 FAIL + erro sudo
  - Deploy Sprint 30 NÃO foi feito corretamente
  - **Ação**: Ir para Fase 3 (Correção)

- [ ] **RESULTADO C**: Checkpoint 2.5 FAIL + outro erro
  - Bug diferente ou novo
  - **Ação**: Ir para Fase 3 (Correção)

**Documentar conclusão Fase 2**:
```
FASE 2 COMPLETA: ___________
Resultado: [ A / B / C ]
Sistema funciona: [ SIM / NÃO ]
Próxima ação: _________________________________
```

---

## 🔧 FASE 3: CORREÇÃO (SE NECESSÁRIO - 1 hora)

**EXECUTAR APENAS SE Fase 2 FAIL**

### [ ] 3.1 - Identificar Correção Necessária

**Com base no diagnóstico 2.8**:

**Caso 1: Erro "sudo: a terminal"**
- [ ] Causa: Deploy Sprint 30 não aplicado OU revertido
- [ ] Solução: Re-deploy Sprint 30
- [ ] Ir para 3.2

**Caso 2: Script não executou**
- [ ] Causa: Permissões, cópia falhou, ou path errado
- [ ] Solução: Verificar SitesController linha 105-120
- [ ] Ir para 3.3

**Caso 3: MySQL access negado**
- [ ] Causa: Credenciais erradas ou user sem permissão
- [ ] Solução: Corrigir post_site_creation.sh
- [ ] Ir para 3.4

**Caso 4: Outro erro**
- [ ] Causa: Específica do log
- [ ] Solução: Análise caso-a-caso
- [ ] Ir para 3.5

---

### [ ] 3.2 - Re-Deploy Sprint 30 (Caso 1)

**Verificar código local**:
```bash
cd /home/user/webapp
grep -n 'postScript' laravel_controllers/SitesController.php | grep -v Binary
```

**Deve mostrar** (linha ~121):
```
&& " . $postScript . " " . escapeshellarg
```
(SEM 'sudo' antes de $postScript)

**Se local está correto**:
```bash
# Re-deploy
ssh root@72.61.53.222 << 'ENDSSH'
cd /opt/webserver/admin-panel
git fetch origin genspark_ai_developer
git reset --hard origin/genspark_ai_developer
php artisan config:cache
systemctl restart php8.3-fpm
ENDSSH
```

**Verificar aplicado**:
```bash
ssh root@72.61.53.222 "grep -n 'postScript' /opt/webserver/admin-panel/app/Http/Controllers/SitesController.php | head -5"
```

- [ ] Agora sem 'sudo'?: [ SIM / NÃO ]
- [ ] Se SIM: Ir para 2.2 (repetir teste)

---

### [ ] 3.3 - Corrigir Cópia de Scripts (Caso 2)

**Verificar scripts em storage**:
```bash
ssh root@72.61.53.222 "ls -la /opt/webserver/admin-panel/storage/app/*.sh"
```

**Se scripts não existem**:
```bash
# Copiar do repo local para servidor
scp /home/user/webapp/post_site_creation.sh root@72.61.53.222:/opt/webserver/admin-panel/storage/app/
scp /home/user/webapp/create-site-wrapper.sh root@72.61.53.222:/opt/webserver/admin-panel/storage/app/

# Ajustar permissões
ssh root@72.61.53.222 "chmod 755 /opt/webserver/admin-panel/storage/app/*.sh"
```

- [ ] Scripts copiados?: [ SIM / NÃO ]
- [ ] Ir para 2.2 (repetir teste)

---

### [ ] 3.4 - Corrigir MySQL Access (Caso 3)

**Testar credenciais**:
```bash
ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' -e 'SELECT USER();'"
```

**Se falha**:
```bash
# Verificar .env
ssh root@72.61.53.222 "grep DB_PASSWORD /opt/webserver/admin-panel/.env"
```

**Corrigir post_site_creation.sh com senha correta**:
```bash
ssh root@72.61.53.222 "nano /opt/webserver/admin-panel/storage/app/post_site_creation.sh"
# Ajustar linha: mysql -u root -p'SENHA_CORRETA' admin_panel
```

- [ ] Credenciais corrigidas?: [ SIM / NÃO ]
- [ ] Ir para 2.2 (repetir teste)

---

### [ ] 3.5 - Correção Customizada (Caso 4)

**Analisar erro específico do log**:
```
Erro: _________________________________
```

**Pesquisar solução**:
- [ ] Google: "laravel {erro}"
- [ ] Verificar logs Laravel: `/opt/webserver/admin-panel/storage/logs/laravel.log`
- [ ] Verificar logs NGINX: `/var/log/nginx/error.log`

**Implementar correção**:
```
Correção aplicada: _________________________________
```

**Testar**:
- [ ] Ir para 2.2 (repetir teste)

---

### [ ] 3.6 - Commit Correção

**Se código foi modificado**:

```bash
cd /home/user/webapp
git add .
git status
git commit -m "fix(sprint-32): Correção [descrição específica]"
```

**Deploy**:
```bash
git push origin genspark_ai_developer

ssh root@72.61.53.222 "cd /opt/webserver/admin-panel && git pull origin genspark_ai_developer && php artisan config:cache && systemctl restart php8.3-fpm"
```

- [ ] Commit feito?: [ SIM / NÃO ]
- [ ] Deploy feito?: [ SIM / NÃO ]

---

### [ ] 3.7 - Validar Correção

**Repetir teste completo**:
- [ ] Ir para Fase 2 (2.1 a 2.7)
- [ ] Checkpoint 2.5 agora PASS?: [ SIM / NÃO ]

**Se ainda FAIL**:
- [ ] Analisar novo erro
- [ ] Repetir Fase 3 com nova correção

**Se PASS**:
- [ ] Ir para Fase 4 (Validação Final)

---

## ✅ FASE 4: VALIDAÇÃO FINAL (30 minutos)

**EXECUTAR APENAS SE Fase 2 ou 3 resultou em PASS**

**OBJETIVO**: Provar 100% de funcionalidade com múltiplos testes

### [ ] 4.1 - Criar Site Teste #1

```bash
TIMESTAMP=$(date +%s)
SITE="sprint32test1_${TIMESTAMP}"
```

**Via web interface**:
1. [ ] Criar site: `sprint32test1_{TIMESTAMP}`
2. [ ] Aguardar 30 segundos
3. [ ] Verificar DB: `status='active'`, `ssl_enabled=1`

**Resultado**:
- [ ] PASS: Site ativo
- [ ] FAIL: Site inativo → Repetir Fase 3

---

### [ ] 4.2 - Criar Site Teste #2

```bash
TIMESTAMP=$(date +%s)
SITE="sprint32test2_${TIMESTAMP}"
```

**Via CLI**:
```bash
ssh root@72.61.53.222 << ENDSSH
cd /opt/webserver/admin-panel
php artisan tinker << 'TINKER'
\$ts = ${TIMESTAMP};
\$site = new App\Models\Site(['site_name' => 'sprint32test2_' . \$ts, 'domain_name' => 'sprint32test2_' . \$ts . '.com', 'description' => 'Teste 2 CLI', 'status' => 'inactive', 'ssl_enabled' => false]);
\$site->save();
echo "Site ID: " . \$site->id . "\n";
exit
TINKER
ENDSSH
```

**Aguardar e verificar**:
```bash
sleep 30
ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e \"SELECT * FROM sites WHERE site_name LIKE 'sprint32test2%';\""
```

**Resultado**:
- [ ] PASS: Site ativo
- [ ] FAIL: Site inativo

---

### [ ] 4.3 - Criar Site Teste #3

```bash
TIMESTAMP=$(date +%s)
SITE="sprint32test3_${TIMESTAMP}"
```

**Via web interface novamente**:
1. [ ] Criar site: `sprint32test3_{TIMESTAMP}`
2. [ ] Aguardar 30 segundos
3. [ ] Verificar DB

**Resultado**:
- [ ] PASS: Site ativo
- [ ] FAIL: Site inativo

---

### [ ] 4.4 - Verificação Completa Database

```bash
ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e 'SELECT status, COUNT(*) as total FROM sites GROUP BY status;'"
```

**Análise**:
- Total sites: _______
- Sites ativos: _______
- Sites inativos: _______

**Esperado**:
- Todos ativos OU apenas sites muito recentes (<1 min) inativos

**Resultado**:
- [ ] 100% sites antigos ativos: [ SIM / NÃO ]

---

### [ ] 4.5 - Coletar Evidências

**Screenshot 1: Lista de sites no admin**
```
Acessar: https://72.61.53.222/admin/sites
Capturar tela mostrando todos os sites
```

**Screenshot 2: Database query**
```bash
ssh root@72.61.53.222 "mysql -u root -p'Jm@D@KDPnw7Q' admin_panel -e 'SELECT id, site_name, status, ssl_enabled FROM sites ORDER BY id DESC;' > /tmp/sites_evidence.txt"
ssh root@72.61.53.222 "cat /tmp/sites_evidence.txt"
```

**Screenshot 3: Filesystem**
```bash
ssh root@72.61.53.222 "ls -la /var/www/ | grep sprint32"
```

**Logs sem erros**:
```bash
ssh root@72.61.53.222 "tail -50 /tmp/site-creation-sprint32test1*.log | grep -i error"
# Deve estar vazio
```

---

### [ ] 4.6 - Conclusão Validação

**Critérios de sucesso**:
- [ ] 3/3 sites criados com sucesso
- [ ] 3/3 sites com status='active'
- [ ] 3/3 sites com ssl_enabled=1
- [ ] 3/3 diretórios criados
- [ ] 3/3 configs NGINX criadas
- [ ] 0 erros nos logs

**Resultado final**:
- [ ] **SUCESSO**: Todos critérios PASS ✅
  - Sistema 100% funcional
  - Ir para Fase 5 (Documentação)

- [ ] **FALHA PARCIAL**: Algum critério FAIL
  - Sistema intermitente
  - Investigar mais ou reportar limitação

---

## 📝 FASE 5: DOCUMENTAÇÃO (20 minutos)

**OBJETIVO**: Documentar correção, atualizar PR, fornecer evidências

### [ ] 5.1 - Criar Relatório Final

**Arquivo**: `RELATORIO_SPRINT_32_FINAL.md`

```markdown
# Sprint 32 - Relatório Final

## Status: [SUCESSO / PARCIAL / FALHA]

## Problema Encontrado
[Descrever o problema identificado na Fase 1]

## Correção Aplicada
[Descrever correção da Fase 3, se houver]

## Testes Realizados
- Teste 1: [PASS/FAIL] - sprint32test1_X
- Teste 2: [PASS/FAIL] - sprint32test2_X
- Teste 3: [PASS/FAIL] - sprint32test3_X

## Evidências
### Database
[Colar output da query de verificação]

### Filesystem
[Colar output do ls /var/www/]

### Logs
[Colar output dos logs sem erros]

## Conclusão
Sistema está [100% / X%] funcional.
[Explicação detalhada]

## Deploy
- Código local: commit SHA
- Código produção: commit SHA
- Deploy confirmado: [SIM/NÃO]
```

---

### [ ] 5.2 - Commit Final

```bash
cd /home/user/webapp

# Adicionar relatório
git add RELATORIO_SPRINT_32_FINAL.md

# Adicionar correções (se houver)
git add .

# Commit
git commit -m "feat(sprint-32): Validação definitiva - Sistema [status]

- Investigação completa realizada
- [Correções aplicadas ou confirmação funcionamento]
- 3 testes end-to-end executados
- Evidências coletadas
- Sistema [100% funcional / status atual]"
```

---

### [ ] 5.3 - Git Workflow

```bash
# Fetch latest
git fetch origin main

# Rebase
git rebase origin/main
# Resolver conflitos se houver

# Squash (se múltiplos commits)
git reset --soft origin/main
git commit -m "feat(sprint-32): Sistema [status] - Validação Definitiva Completa

[Descrição completa de tudo que foi feito]

Testes:
- 3 sites criados com sucesso
- Todos com status active e SSL
- Logs sem erros

Evidências documentadas em RELATORIO_SPRINT_32_FINAL.md"

# Push
git push -f origin genspark_ai_developer
```

---

### [ ] 5.4 - Update Pull Request

```bash
cd /home/user/webapp

gh pr edit 1 \
  --title "feat(sprint-32): Sistema 100% Funcional - Validação Definitiva" \
  --body "$(cat <<'EOF'
# Sprint 32: Validação Definitiva Completa

## 🎯 Resultado Final

**Sistema: [100% FUNCIONAL / STATUS]** ✅

## 📊 Investigação Realizada

### Checkpoints
1. ✅ Código em produção verificado
2. ✅ Database status confirmado
3. ✅ Filesystem validado
4. ✅ Logs analisados
5. ✅ Deploy confirmado

### Descoberta
[Descrever o que foi encontrado - deploy estava correto, bug específico, etc]

## 🔧 Correções Aplicadas

[Se houve correção]
- Descrição da correção
- Arquivo modificado
- Linha específica

[Se não houve correção]
- Deploy Sprint 30 estava correto
- Sistema já estava funcional
- Discrepância era metodologia de teste

## 🧪 Testes End-to-End

### Teste 1: sprint32test1_[timestamp]
- Status: active ✅
- SSL: enabled ✅
- Filesystem: criado ✅

### Teste 2: sprint32test2_[timestamp]
- Status: active ✅
- SSL: enabled ✅
- Filesystem: criado ✅

### Teste 3: sprint32test3_[timestamp]
- Status: active ✅
- SSL: enabled ✅
- Filesystem: criado ✅

## 📋 Evidências

### Database Final State
\`\`\`sql
[Colar query mostrando todos sites ativos]
\`\`\`

### Filesystem
\`\`\`bash
[Colar ls mostrando diretórios e configs]
\`\`\`

### Logs
\`\`\`
[Mostrar logs sem erros]
\`\`\`

## ✅ Conclusão

**3/3 Features Funcionando**:
- ✅ Site creation (validado Sprint 32)
- ✅ Email domains (funcional desde Sprint 25)
- ✅ Email accounts (funcional desde Sprint 28)

**Sistema 100% Funcional Confirmado** ✅

Deploy em produção: Confirmado
Testes: 3/3 PASS
Evidências: Documentadas

---

**Relatório Completo**: \`RELATORIO_SPRINT_32_FINAL.md\`
EOF
)"

# Get PR URL
gh pr view 1 --json url --jq '.url'
```

---

### [ ] 5.5 - Fornecer PR Link ao Usuário

**Copiar URL e fornecer**:
```
https://github.com/fmunizmcorp/servidorvpsprestadores/pull/1
```

**Mensagem ao usuário**:
```
✅ SPRINT 32 COMPLETADO

Sistema: [100% FUNCIONAL / STATUS]
Pull Request: [URL]
Commit SHA: [SHA]

Testes Realizados: 3/3 PASS
Evidências: Documentadas no PR e RELATORIO_SPRINT_32_FINAL.md

[Se 100% funcional]
O sistema está completamente funcional. Todos os 3 sites de teste foram criados com sucesso, 
com status 'active' e SSL habilitado.

[Se não 100%]
[Explicar status atual, limitações encontradas, próximos passos recomendados]
```

---

## 🏁 CHECKLIST FINAL

### Fase 1: Investigação
- [ ] 1.1 - Código produção verificado
- [ ] 1.2 - Database verificado
- [ ] 1.3 - Git log verificado
- [ ] 1.4 - Filesystem verificado
- [ ] 1.5 - Logs verificados
- [ ] 1.6 - Scripts verificados
- [ ] 1.7 - Deploy manual (se necessário)
- [ ] 1.8 - Causa raiz determinada

### Fase 2: Teste ao Vivo
- [ ] 2.1 - Teste preparado
- [ ] 2.2 - Site criado via web
- [ ] 2.3 - DB verificado (imediato)
- [ ] 2.4 - Aguardado 30s
- [ ] 2.5 - DB verificado (após 30s)
- [ ] 2.6 - Filesystem verificado
- [ ] 2.7 - Logs verificados
- [ ] 2.8 - Diagnóstico (se FAIL)
- [ ] 2.9 - Conclusão Fase 2

### Fase 3: Correção (se necessário)
- [ ] 3.1 - Correção identificada
- [ ] 3.2-3.5 - Correção aplicada
- [ ] 3.6 - Commit feito
- [ ] 3.7 - Correção validada

### Fase 4: Validação Final
- [ ] 4.1 - Site teste #1 criado
- [ ] 4.2 - Site teste #2 criado
- [ ] 4.3 - Site teste #3 criado
- [ ] 4.4 - Database completo verificado
- [ ] 4.5 - Evidências coletadas
- [ ] 4.6 - Conclusão validação

### Fase 5: Documentação
- [ ] 5.1 - Relatório final criado
- [ ] 5.2 - Commit final feito
- [ ] 5.3 - Git workflow completo
- [ ] 5.4 - PR atualizado
- [ ] 5.5 - PR link fornecido

---

## ✅ CRITÉRIO DE COMPLETUDE

**Sprint 32 está COMPLETO quando**:

- [ ] Todos checkpoints Fase 1 são PASS
- [ ] Teste Fase 2 é PASS (ou corrigido na Fase 3)
- [ ] 3/3 testes Fase 4 são PASS
- [ ] Relatório final criado
- [ ] PR atualizado com evidências
- [ ] PR link fornecido ao usuário
- [ ] TODO list marcada como completa

---

**FIM DO CHECKLIST**

Use este documento sistematicamente para não perder nenhum passo! ✅
