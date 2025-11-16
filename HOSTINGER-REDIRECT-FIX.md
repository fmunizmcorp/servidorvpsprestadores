# 🚨 FIX CRÍTICO: Erro 500 - Hostinger Redirect Incorreto

**Data:** 2025-11-16  
**Problema:** Site retorna erro 500 ao acessar https://prestadores.clinfec.com.br  
**Causa Raiz:** Hostinger redirecionando incorretamente para `http://72.61.53.222`  
**Prioridade:** 🔴 CRÍTICA

---

## 📊 DIAGNÓSTICO COMPLETO

### ✅ O QUE ESTÁ FUNCIONANDO:

**VPS (72.61.53.222):**
```bash
# Teste local HTTP
curl -I http://127.0.0.1 -H 'Host: prestadores.clinfec.com.br'
→ HTTP/1.1 301 Moved Permanently (redirect to HTTPS) ✅

# Teste local HTTPS
curl -k -I https://127.0.0.1 -H 'Host: prestadores.clinfec.com.br'
→ HTTP/2 302 (redirect to login page) ✅

# Serviços
NGINX: active (running) ✅
PHP-FPM: active (running) ✅
Portas: 80, 443 listening ✅
```

**NGINX Configuration:**
- ✅ Sites enabled corretamente
- ✅ SSL certificate instalado
- ✅ Root directory existente
- ✅ PHP-FPM pool ativo
- ✅ Permissions corretas

### ❌ O QUE ESTÁ QUEBRADO:

**Acesso Externo via Domínio:**
```bash
curl -I https://prestadores.clinfec.com.br
→ HTTP/2 301 Moved Permanently
→ Location: http://72.61.53.222  ❌ ERRADO!
→ Server: LiteSpeed (Hostinger)
```

**Problema:**
O Hostinger está fazendo redirect para o **IP do VPS** em vez de manter o domínio.

---

## 🔍 ANÁLISE DA CAUSA RAIZ

### Fluxo Correto (Esperado):
```
1. User acessa: https://prestadores.clinfec.com.br
2. Hostinger proxy para: VPS 72.61.53.222
3. VPS responde: HTTP 302 (login page)
4. User vê: https://prestadores.clinfec.com.br/login ✅
```

### Fluxo Atual (Quebrado):
```
1. User acessa: https://prestadores.clinfec.com.br
2. Hostinger redireciona para: http://72.61.53.222 ❌
3. Browser tenta: http://72.61.53.222
4. VPS responde: HTTP 301 → https://72.61.53.222
5. Browser tenta: https://72.61.53.222
6. SSL mismatch (cert é para prestadores.clinfec.com.br)
7. User vê: Erro 500 ou SSL Error ❌
```

### Causa Raiz:
**Configuração incorreta no Hostinger hPanel:**
- Proxy reverso mal configurado
- Redirect rule incorreta
- Domain forwarding para IP em vez de proxy

---

## 🔧 SOLUÇÃO: Corrigir Configuração no hPanel

### OPÇÃO 1: Desabilitar Redirect Incorreto (Recomendado)

#### PASSO 1: Acesse hPanel
1. Login: https://hpanel.hostinger.com/
2. Selecione: prestadores.clinfec.com.br

#### PASSO 2: Verifique Redirects
1. Menu: **"Domínios"** ou **"Domains"**
2. Clique em: **prestadores.clinfec.com.br**
3. Procure: **"Redirects"** ou **"Redirecionamentos"**
4. Verifique se há redirect ativo para `72.61.53.222`

```
┌──────────────────────────────────────────┐
│  Redirects Ativos                        │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ De: prestadores.clinfec.com.br     │ │
│  │ Para: http://72.61.53.222  ← REMOVER│
│  │ Tipo: 301 Permanente               │ │
│  │                                    │ │
│  │ [  ❌ Remover  ]                   │ │
│  └────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

#### PASSO 3: Remover Redirect
1. Clique em **"Remover"** ou **"Delete"**
2. Confirme a remoção
3. Aguarde 2-5 minutos para propagação

---

### OPÇÃO 2: Configurar Proxy Reverso Corretamente

Se o Hostinger usa proxy reverso:

#### PASSO 1: Verifique DNS
1. Menu: **"DNS Zone Editor"** ou **"Gerenciar DNS"**
2. Certifique-se que o A record aponta para Hostinger IP (não VPS)
3. Confirme:
   ```
   Type: A
   Name: @
   Value: 82.180.156.19 (Hostinger IP)
   ```

#### PASSO 2: Configure Proxy
1. Menu: **"Proxy"** ou **"Advanced"**
2. Procure: **"Reverse Proxy"** settings
3. Configure:
   ```
   Origin Server: http://72.61.53.222 ou https://72.61.53.222
   Forward Host Header: Yes
   SSL: Use Origin SSL
   ```

---

### OPÇÃO 3: Apontar DNS Diretamente para VPS

**⚠️ ATENÇÃO:** Isso remove o Hostinger do meio, mas resolve o problema.

#### PASSO 1: Altere DNS
1. hPanel → **"DNS Zone Editor"**
2. Edite o A record:
   ```
   Type: A
   Name: @
   Value: 72.61.53.222  (IP do VPS)
   TTL: 14400
   ```
3. Se houver www:
   ```
   Type: A
   Name: www
   Value: 72.61.53.222
   TTL: 14400
   ```

#### PASSO 2: Aguarde Propagação
- Tempo: 15 minutos a 48 horas
- Verifique: https://dnschecker.org/

#### PASSO 3: Instale SSL Let's Encrypt no VPS
Como o domínio agora aponta direto para o VPS, Let's Encrypt funcionará:

```bash
# No VPS, execute:
certbot certonly --webroot \
  -w /opt/webserver/sites/prestadores/public_html \
  -d prestadores.clinfec.com.br \
  -d www.prestadores.clinfec.com.br \
  --email admin@clinfec.com.br \
  --agree-tos \
  --non-interactive
```

Depois atualize NGINX config:
```nginx
ssl_certificate /etc/letsencrypt/live/prestadores.clinfec.com.br/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/prestadores.clinfec.com.br/privkey.pem;
```

---

## 🧪 TESTES DE VERIFICAÇÃO

### Após Aplicar a Correção:

#### Teste 1: Acesso ao Domínio
```bash
curl -I https://prestadores.clinfec.com.br
```
**Esperado:**
```
HTTP/2 302
location: https://prestadores.clinfec.com.br/?page=auth&action=showLoginForm
```

#### Teste 2: Redirect HTTP→HTTPS
```bash
curl -I http://prestadores.clinfec.com.br
```
**Esperado:**
```
HTTP/1.1 301 Moved Permanently
Location: https://prestadores.clinfec.com.br/
```

#### Teste 3: SSL Certificate
```bash
echo | openssl s_client -connect prestadores.clinfec.com.br:443 -servername prestadores.clinfec.com.br 2>/dev/null | openssl x509 -noout -subject
```
**Esperado:**
```
subject=CN = prestadores.clinfec.com.br
```

#### Teste 4: Acesso pelo Navegador
1. Abra: https://prestadores.clinfec.com.br
2. Verifique: URL permanece como prestadores.clinfec.com.br
3. Verifique: Não há erros SSL
4. Verifique: Página carrega corretamente

---

## 📋 CHECKLIST DE VALIDAÇÃO

Após aplicar a correção, verifique:

- [ ] Domínio carrega sem erros
- [ ] URL permanece como prestadores.clinfec.com.br (não muda para IP)
- [ ] HTTPS funciona sem avisos SSL (se SSL válido instalado)
- [ ] HTTP redireciona para HTTPS
- [ ] Admin panel continua bloqueado no domínio (/admin → 404)
- [ ] Admin panel acessível via IP (72.61.53.222/admin → 200)
- [ ] Site funciona normalmente
- [ ] Login funciona
- [ ] Sessões PHP funcionam

---

## 🔍 TROUBLESHOOTING

### Problema: "Ainda retorna erro 500"
**Solução:**
1. Limpe cache do navegador (Ctrl+Shift+Delete)
2. Teste em modo anônimo/privado
3. Aguarde mais tempo para propagação DNS
4. Verifique logs do Hostinger (se disponíveis)
5. Contate suporte Hostinger se persistir

### Problema: "SSL certificate warning"
**Solução:**
1. Se usar Opção 3 (DNS direto), instale Let's Encrypt no VPS
2. Se usar Opção 1 ou 2, instale SSL via hPanel (ver HOSTINGER-SSL-INSTALLATION-GUIDE.md)

### Problema: "DNS não propaga"
**Solução:**
1. Verifique TTL do DNS (menor = propaga mais rápido)
2. Use flush DNS local: `ipconfig /flushdns` (Windows) ou `sudo systemd-resolve --flush-caches` (Linux)
3. Aguarde até 48 horas para propagação mundial

---

## 📊 COMPARATIVO: Antes vs Depois

| Aspecto | ANTES (Quebrado) | DEPOIS (Corrigido) |
|---------|------------------|-------------------|
| URL no browser | http://72.61.53.222 | prestadores.clinfec.com.br ✅ |
| Redirect | 301 → IP | 302 → login ✅ |
| SSL | Mismatch/Error | Válido ✅ |
| Status | 500 Error | 200 OK ✅ |
| Proxy | Mal configurado | Correto ✅ |

---

## 💡 RECOMENDAÇÕES

### Melhor Solução (Longo Prazo):
**OPÇÃO 3: DNS direto para VPS**

**Vantagens:**
- ✅ Controle total sobre configuração
- ✅ Let's Encrypt funciona nativamente
- ✅ Sem intermediários (menos pontos de falha)
- ✅ Performance melhor (sem proxy)
- ✅ Troubleshooting mais fácil

**Desvantagens:**
- ⚠️ Perde features do Hostinger (se houver)
- ⚠️ Responsabilidade de SSL no VPS

### Solução Temporária (Curto Prazo):
**OPÇÃO 1: Remover redirect incorreto**

**Vantagens:**
- ✅ Rápido (5 minutos)
- ✅ Mantém Hostinger no meio
- ✅ SSL pode ser instalado via hPanel

**Desvantagens:**
- ⚠️ Depende de configuração correta do Hostinger
- ⚠️ Menos controle

---

## 📞 SUPORTE

Se precisar de ajuda:

**Hostinger Support:**
- Chat 24/7: https://hpanel.hostinger.com/ → Chat icon
- Email: support@hostinger.com
- Base: https://support.hostinger.com/

**Informações para o Suporte:**
```
Domínio: prestadores.clinfec.com.br
Problema: Redirect incorreto para http://72.61.53.222
Esperado: Proxy reverso mantendo domínio
VPS IP: 72.61.53.222
Solicitação: Remover redirect ou configurar proxy corretamente
```

---

## ✅ PRÓXIMOS PASSOS

1. **IMEDIATO (5 min):**
   - [ ] Aplicar OPÇÃO 1 ou OPÇÃO 3
   - [ ] Testar acesso ao domínio
   - [ ] Verificar se erro 500 sumiu

2. **CURTO PRAZO (1-2 dias):**
   - [ ] Instalar SSL válido (Let's Encrypt)
   - [ ] Testar todos os flows do site
   - [ ] Configurar monitoring

3. **LONGO PRAZO (1 semana):**
   - [ ] Revisar toda configuração DNS
   - [ ] Implementar CDN (Cloudflare) se necessário
   - [ ] Setup backup automático

---

**Status:** ⚠️ AGUARDANDO CORREÇÃO NO HOSTINGER  
**Impacto:** 🔴 CRÍTICO - Site inacessível externamente  
**Solução:** Configuração no hPanel (5 minutos)  
**ETA:** Imediato após aplicar correção

---

*Documentação criada em: 2025-11-16*  
*Última atualização: 2025-11-16*  
*Próxima ação: Aplicar correção no Hostinger hPanel*
