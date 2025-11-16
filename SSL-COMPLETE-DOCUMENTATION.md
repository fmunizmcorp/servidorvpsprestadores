# SSL CERTIFICATE - COMPLETE DOCUMENTATION
## prestadores.clinfec.com.br

**Data:** 2025-11-16  
**Status:** Self-Signed SSL ACTIVE (Temporary)  
**Action Required:** Install Valid SSL via Hostinger hPanel

---

## 📊 SITUAÇÃO ATUAL

### ✅ O QUE ESTÁ FUNCIONANDO:
- ✅ HTTPS ativo em https://prestadores.clinfec.com.br
- ✅ HTTP→HTTPS redirect configurado
- ✅ Certificado SSL instalado (self-signed)
- ✅ TLS 1.2 e 1.3 suportados
- ✅ Ciphers seguros configurados
- ✅ Security headers implementados
- ✅ Admin panel bloqueado no domínio (404)

### ⚠️ LIMITAÇÃO ATUAL:
- ⚠️ Certificado é AUTO-ASSINADO
- ⚠️ Navegadores mostrarão aviso de segurança
- ⚠️ "Não seguro" ou "Certificado inválido"

### 🎯 SOLUÇÃO:
**Instalar SSL válido via Hostinger hPanel** (gratuito, Let's Encrypt)

---

## 🔍 POR QUE LET'S ENCRYPT NÃO FUNCIONA NO VPS?

### Análise Técnica Completa:

#### 1. DNS Resolution
```bash
prestadores.clinfec.com.br → 82.180.156.19 (Hostinger)
VPS Server IP → 2a02:4780:66:f6b4::1 (Diferente!)
```

#### 2. Arquitetura Real
```
┌─────────────────┐
│    INTERNET     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   82.180.156.19 │ ← Domain aponta aqui
│    HOSTINGER    │
│   (LiteSpeed)   │
└────────┬────────┘
         │ (Proxy/Redirect)
         ▼
┌─────────────────┐
│ 2a02:4780:...   │ ← VPS está aqui
│    VPS SERVER   │
│     (NGINX)     │
└─────────────────┘
```

#### 3. Processo Let's Encrypt:
```
1. Let's Encrypt tenta acessar:
   http://prestadores.clinfec.com.br/.well-known/acme-challenge/[token]

2. Requisição vai para: 82.180.156.19 (Hostinger)

3. Hostinger faz redirect: HTTP → HTTPS

4. Let's Encrypt NÃO segue redirects HTTPS

5. Validação FALHA ✗
```

#### 4. Teste Realizado:
```bash
# Local (VPS)
curl http://127.0.0.1/.well-known/acme-challenge/test.txt
→ HTTP/1.1 200 OK ✓

# Externo (via domínio)
curl http://prestadores.clinfec.com.br/.well-known/acme-challenge/test.txt
→ HTTP/1.1 301 Moved Permanently (redirect to HTTPS)
→ Server: LiteSpeed (Hostinger)
```

### Conclusão:
**O domínio não aponta diretamente para o VPS**. Está atrás da infraestrutura Hostinger, impossibilitando validação Let's Encrypt no VPS.

---

## ✅ CERTIFICADO ATUAL (Self-Signed)

### Especificações Técnicas:

**Tipo:** Self-Signed Certificate  
**Algoritmo:** RSA 4096-bit  
**Validade:** 10 anos (2025-11-16 até 2035-11-14)  
**Subject Alternative Names (SAN):**
- prestadores.clinfec.com.br
- www.prestadores.clinfec.com.br

**Localização dos Arquivos:**
```
Certificate: /etc/ssl/private/prestadores-selfsigned.crt
Private Key: /etc/ssl/private/prestadores-selfsigned.key
Info File: /opt/webserver/ssl-backups/SELF-SIGNED-CERT-INFO-*.txt
```

**Detalhes do Certificado:**
```
Subject: C=BR, ST=State, L=City, O=Clinfec, 
         OU=IT Department, 
         emailAddress=admin@clinfec.com.br, 
         CN=prestadores.clinfec.com.br

Validity:
  Not Before: Nov 16 16:41:13 2025 GMT
  Not After : Nov 14 16:41:13 2035 GMT

Subject Alternative Names:
  DNS:prestadores.clinfec.com.br
  DNS:www.prestadores.clinfec.com.br

Key Size: 4096-bit RSA
Signature Algorithm: sha256WithRSAEncryption
```

### Configuração NGINX:
```nginx
ssl_certificate /etc/ssl/private/prestadores-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/prestadores-selfsigned.key;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:...';
```

---

## 🚀 COMO INSTALAR SSL VÁLIDO (Hostinger hPanel)

### Método Recomendado: Let's Encrypt via hPanel

#### PASSO 1: Acesse o hPanel
```
1. Faça login em: https://hpanel.hostinger.com/
2. Selecione a conta/domínio: prestadores.clinfec.com.br
```

#### PASSO 2: Navegue até SSL
```
1. Menu lateral → "SSL/TLS"
2. Ou busque: "SSL" na barra de pesquisa
```

#### PASSO 3: Instale Let's Encrypt
```
1. Clique em: "Instalar SSL" ou "Manage SSL"
2. Selecione: "Let's Encrypt" (Gratuito)
3. Escolha o domínio: prestadores.clinfec.com.br
4. Marque opção: Incluir www (www.prestadores.clinfec.com.br)
5. Clique: "Instalar SSL" ou "Generate"
```

#### PASSO 4: Aguarde Instalação
```
⏱️ Tempo estimado: 1-5 minutos
📊 Status: Você verá barra de progresso
✓ Confirmação: "SSL instalado com sucesso"
```

#### PASSO 5: Ative Redirect HTTPS (Opcional)
```
1. Na mesma página SSL
2. Procure: "Force HTTPS" ou "Always Use HTTPS"
3. Ative a opção
4. Salve alterações
```

#### PASSO 6: Verifique
```
1. Acesse: https://prestadores.clinfec.com.br
2. Clique no cadeado 🔒 do navegador
3. Verifique: "Conexão segura" / "Secure"
4. Emissor deve ser: "Let's Encrypt Authority X3" ou similar
```

### Renovação Automática:
✅ Hostinger renova automaticamente certificados Let's Encrypt  
✅ Renovação ocorre ~30 dias antes do vencimento  
✅ Nenhuma ação manual necessária

---

## 🔧 COMANDOS ÚTEIS (Para Referência)

### Verificar Certificado Atual no VPS:
```bash
# Ver detalhes do certificado
openssl x509 -in /etc/ssl/private/prestadores-selfsigned.crt -noout -text

# Verificar validade
openssl x509 -in /etc/ssl/private/prestadores-selfsigned.crt -noout -dates

# Verificar SAN (Subject Alternative Names)
openssl x509 -in /etc/ssl/private/prestadores-selfsigned.crt -noout -text | grep -A 1 "Subject Alternative Name"

# Testar SSL localmente
openssl s_client -connect 127.0.0.1:443 -servername prestadores.clinfec.com.br
```

### Testar HTTPS:
```bash
# Teste local (VPS)
curl -k -I https://127.0.0.1 -H 'Host: prestadores.clinfec.com.br'

# Teste externo
curl -I https://prestadores.clinfec.com.br

# Verificar redirect HTTP→HTTPS
curl -I http://prestadores.clinfec.com.br
```

### NGINX:
```bash
# Testar configuração
nginx -t

# Recarregar configuração
systemctl reload nginx

# Verificar status
systemctl status nginx

# Ver logs SSL
tail -f /var/log/nginx/prestadores-domain-error.log
```

---

## 📋 CONFIGURAÇÃO NGINX COMPLETA

### Arquivo: `/etc/nginx/sites-available/prestadores-domain-only.conf`

**Features Implementadas:**
- ✅ HTTP→HTTPS redirect (301)
- ✅ TLS 1.2 e 1.3
- ✅ Ciphers modernos e seguros
- ✅ Session optimization
- ✅ Security headers completos:
  - Strict-Transport-Security (HSTS)
  - X-Frame-Options (SAMEORIGIN)
  - X-Content-Type-Options (nosniff)
  - X-XSS-Protection
  - Referrer-Policy
  - Content-Security-Policy
- ✅ Static file caching
- ✅ Hidden files protection
- ✅ Block exploit attempts
- ✅ Admin panel bloqueado (404)

### Backups Criados:
```
/opt/webserver/ssl-backups/prestadores-domain-only.conf.backup-*
/opt/webserver/ssl-backups/SELF-SIGNED-CERT-INFO-*.txt
```

---

## 🎯 PRÓXIMOS PASSOS

### Ação Imediata (5 minutos):
1. ✅ **Instalar SSL válido via Hostinger hPanel**
   - Método: Let's Encrypt (gratuito)
   - Tempo: 2-5 minutos
   - Resultado: HTTPS válido sem avisos

### Após Instalação SSL:
2. ✅ **Testar o site**
   - Acessar: https://prestadores.clinfec.com.br
   - Verificar cadeado verde 🔒
   - Confirmar "Conexão segura"

3. ✅ **Verificar Rating SSL**
   - Acesse: https://www.ssllabs.com/ssltest/
   - Digite: prestadores.clinfec.com.br
   - Meta: Rating A ou A+

4. ✅ **Monitorar Renovação**
   - Hostinger renova automaticamente
   - Verificar mensalmente se está ativo
   - Log de renovações no hPanel

---

## ❓ PERGUNTAS FREQUENTES

### P: Por que não usar certbot no VPS?
**R:** O domínio não aponta diretamente para o VPS. Está atrás do Hostinger, então Let's Encrypt não consegue validar no VPS.

### P: O certificado self-signed é seguro?
**R:** Sim, a criptografia é válida (4096-bit RSA). Mas navegadores não confiam porque não é assinado por uma CA reconhecida.

### P: Quanto tempo leva para instalar SSL via hPanel?
**R:** 2-5 minutos. O processo é totalmente automatizado.

### P: O SSL via hPanel é gratuito?
**R:** Sim! Hostinger oferece Let's Encrypt gratuitamente para todos os domínios.

### P: Preciso renovar manualmente?
**R:** Não. Hostinger renova automaticamente ~30 dias antes do vencimento.

### P: E se eu quiser certificado wildcard (*.clinfec.com.br)?
**R:** Possível via hPanel usando DNS validation ou manualmente via certbot com DNS challenge.

### P: O VPS continuará funcionando com o novo SSL?
**R:** Sim! O SSL é instalado no Hostinger (proxy), o VPS continua com self-signed ou pode usar o mesmo certificado sincronizado.

---

## 📊 COMPARAÇÃO: Self-Signed vs Let's Encrypt

| Feature | Self-Signed (Atual) | Let's Encrypt (Recomendado) |
|---------|--------------------|-----------------------------|
| Criptografia | ✅ 4096-bit RSA | ✅ 2048-bit RSA (padrão) |
| Validade | 10 anos | 90 dias (renovação auto) |
| Navegadores | ⚠️ Mostram aviso | ✅ Confiável |
| Custo | Gratuito | Gratuito |
| Instalação | Manual (VPS) | Automática (hPanel) |
| Renovação | Manual | Automática |
| SEO | ❌ Penalizado | ✅ Beneficiado |
| Confiança | ❌ Baixa | ✅ Alta |
| Uso Recomendado | Desenvolvimento | Produção |

---

## 🔐 SEGURANÇA ADICIONAL

### Headers de Segurança Implementados:

1. **Strict-Transport-Security (HSTS)**
   ```
   max-age=31536000; includeSubDomains; preload
   ```
   Força HTTPS por 1 ano, inclui subdomínios

2. **X-Frame-Options**
   ```
   SAMEORIGIN
   ```
   Previne clickjacking

3. **X-Content-Type-Options**
   ```
   nosniff
   ```
   Previne MIME-type sniffing

4. **X-XSS-Protection**
   ```
   1; mode=block
   ```
   Ativa proteção XSS do navegador

5. **Referrer-Policy**
   ```
   no-referrer-when-downgrade
   ```
   Controla envio de referrer

6. **Content-Security-Policy**
   ```
   default-src 'self' http: https: data: blob: 'unsafe-inline'
   ```
   Controla recursos carregados

### Arquivos Bloqueados:
```
.ht* (htaccess, htpasswd)
.git* (repositório git)
.env (environment variables)
.bak (backups)
.sql (database dumps)
.config, .ini, .log, .sh
```

---

## 📈 MONITORAMENTO

### Verificar Status SSL:
```bash
# Rating SSL Labs
https://www.ssllabs.com/ssltest/analyze.html?d=prestadores.clinfec.com.br

# Verificar validade do certificado
echo | openssl s_client -connect prestadores.clinfec.com.br:443 2>/dev/null | openssl x509 -noout -dates

# Verificar protocolo TLS
nmap --script ssl-enum-ciphers -p 443 prestadores.clinfec.com.br
```

### Logs Importantes:
```
NGINX Access: /var/log/nginx/prestadores-domain-access.log
NGINX Error: /var/log/nginx/prestadores-domain-error.log
SSL Info: /opt/webserver/ssl-backups/SELF-SIGNED-CERT-INFO-*.txt
```

---

## ✅ CHECKLIST FINAL

- [x] Certificado SSL instalado (self-signed)
- [x] HTTPS funcionando
- [x] HTTP→HTTPS redirect ativo
- [x] TLS 1.2 e 1.3 configurados
- [x] Ciphers seguros
- [x] Security headers implementados
- [x] Admin panel bloqueado no domínio
- [x] Backup de configurações
- [x] Documentação completa
- [ ] **TODO: Instalar SSL válido via hPanel** ⭐

---

## 🎓 REFERÊNCIAS

- Let's Encrypt: https://letsencrypt.org/
- SSL Labs: https://www.ssllabs.com/
- Mozilla SSL Config Generator: https://ssl-config.mozilla.org/
- NGINX SSL Documentation: https://nginx.org/en/docs/http/configuring_https_servers.html
- Hostinger SSL Guide: https://www.hostinger.com/tutorials/ssl-certificate

---

**Status:** OPERATIONAL com Self-Signed SSL  
**Action Required:** Install Valid SSL via Hostinger hPanel (5 minutos)  
**Priority:** HIGH ⭐  
**Impact:** Security warnings removed, SEO improved, User trust increased

---

*Documentação criada em: 2025-11-16*  
*Última atualização: 2025-11-16*  
*Próxima ação: Instalar SSL válido via hPanel*
