# 🔒 SOLUÇÃO PARA CERTIFICADO SSL COM CDN

**Data**: 2025-11-16  
**Domínio**: prestadores.clinfec.com.br  
**Problema**: CDN/Proxy bloqueando validação Let's Encrypt

---

## 🔍 PROBLEMA IDENTIFICADO

### **O domínio está atrás de um CDN/Proxy da Hostinger**

```
Servidor detectado: hcdn (Hostinger CDN)
Comportamento: Redirect 301 para HTTPS
Resultado: Let's Encrypt não consegue validar via HTTP
```

**Por que falha?**

Let's Encrypt tenta acessar:
```
http://prestadores.clinfec.com.br/.well-known/acme-challenge/...
```

Mas o CDN/Proxy faz:
```
301 Redirect → https://prestadores.clinfec.com.br/.well-known/acme-challenge/...
```

Let's Encrypt **não segue redirects HTTPS** durante validação HTTP, então falha com erro 404.

---

## ✅ SOLUÇÕES DISPONÍVEIS

### **SOLUÇÃO 1: Desabilitar CDN Temporariamente** (Recomendado)

#### **Passo 1: Acessar Painel Hostinger**
1. Acesse: https://hpanel.hostinger.com/
2. Login com suas credenciais
3. Vá em: **Domínios** ou **Websites**
4. Selecione: `prestadores.clinfec.com.br`

#### **Passo 2: Desabilitar CDN/Proxy**
Procure por:
- "CDN" ou "Proxy"
- "Cloudflare" ou "Hostinger CDN"
- "SSL/TLS" settings
- Opção para desabilitar proxy/CDN

**Desabilite temporariamente o CDN**

#### **Passo 3: Aguardar Propagação**
Tempo: 5-15 minutos

Verificar se CDN está desabilitado:
```bash
curl -I http://prestadores.clinfec.com.br
# Não deve mais mostrar redirect 301
# Server não deve ser "hcdn"
```

#### **Passo 4: Obter Certificado**
```bash
ssh -p 22 root@72.61.53.222
certbot --nginx -d prestadores.clinfec.com.br
```

#### **Passo 5: Reabilitar CDN**
Após obter o certificado, pode reabilitar o CDN no painel Hostinger.

---

### **SOLUÇÃO 2: Usar Certificado SSL do Hostinger**

Se o domínio está no Hostinger, eles oferecem SSL gratuito automaticamente.

#### **Opção A: SSL Gerenciado pelo Hostinger**
1. No hpanel.hostinger.com
2. Vá em SSL para o domínio
3. Ative "SSL Gratuito" ou "Let's Encrypt"
4. Hostinger gerencia automaticamente

#### **Opção B: Configurar SSL Proxy no Hostinger**
- Use o SSL fornecido pelo CDN da Hostinger
- Não precisa configurar no servidor VPS
- SSL termina no CDN

---

### **SOLUÇÃO 3: Usar Cloudflare (Se aplicável)**

Se o domínio está no Cloudflare:

#### **Opção A: SSL Flexível**
- SSL entre usuário e Cloudflare
- HTTP entre Cloudflare e seu servidor
- Configurar no painel Cloudflare: SSL/TLS → Flexible

#### **Opção B: SSL Full (Origin Certificate)**
1. Cloudflare Dashboard
2. SSL/TLS → Origin Server
3. Create Certificate
4. Copiar certificado e chave privada
5. Instalar no NGINX

---

### **SOLUÇÃO 4: Validação DNS (Avançado)**

Use DNS Challenge ao invés de HTTP Challenge.

```bash
# Instalar plugin DNS
apt-get install python3-certbot-dns-<provider>

# Exemplos de providers:
# - python3-certbot-dns-cloudflare
# - python3-certbot-dns-route53
# - python3-certbot-dns-digitalocean

# Obter certificado via DNS
certbot certonly --dns-<provider> \
  -d prestadores.clinfec.com.br \
  --email fmunizm@gmail.com \
  --agree-tos
```

**Requer**: Credenciais API do provedor DNS

---

## 🎯 RECOMENDAÇÃO

### **Melhor Abordagem: SOLUÇÃO 1**

1. Desabilite CDN temporariamente (5 min)
2. Obtenha certificado Let's Encrypt
3. Reabilite CDN

**Vantagens**:
- ✅ Rápido (15-20 minutos total)
- ✅ Certificado gratuito Let's Encrypt
- ✅ Renovação automática
- ✅ Sem configurações complexas

---

## 📋 STATUS ATUAL DO SERVIDOR

### **NGINX**: ✅ Configurado Corretamente
```
✓ Site default desabilitado
✓ Configuração para prestadores.clinfec.com.br criada
✓ Location .well-known configurado
✓ Multi-tenant preservado
```

### **PHP-FPM**: ✅ Atualizado
```
✓ open_basedir expandido: /opt/webserver:/etc/postfix:/var/mail:/var/log:/proc:/tmp
✓ Erros 500 corrigidos (SecurityController pode acessar /var/log)
✓ Pool funcionando corretamente
```

### **Painel Admin**: ✅ Funcionando
```
✓ Dashboard carregando
✓ Login funcionando
✓ Menus acessíveis
✓ Credenciais: admin@vps.local / Admin2024VPS
```

### **Let's Encrypt**: ⏳ Aguardando Solução CDN
```
✓ Certbot instalado
✓ NGINX configurado
✓ Webroot preparado
⏳ CDN bloqueando validação HTTP
```

---

## 🔧 CORREÇÕES APLICADAS

### **1. Multi-Tenant Preservado**
- ✅ Site `default` removido
- ✅ Cada domínio tem sua própria configuração
- ✅ Não há mais redirecionamento para IP
- ✅ URLs mantém o domínio correto

### **2. Erros 500 Corrigidos**
- ✅ `DashboardController`: Permissões de `/opt/webserver/sites`
- ✅ `SecurityController`: Acesso a `/var/log` via open_basedir
- ✅ `MonitoringController`: (já estava correto)

### **3. NGINX Otimizado**
- ✅ Configuração limpa para Let's Encrypt
- ✅ Location .well-known com prioridade
- ✅ PHP-FPM parameters corretos
- ✅ Logs separados por site

---

## 🌐 COMO ACESSAR AGORA

### **Via Domínio** (Atual):
```
http://prestadores.clinfec.com.br
• Redirect 301 para HTTPS (pelo CDN)
• SSL fornecido pelo CDN Hostinger
• Funcional
```

### **Via IP** (Alternativo):
```
https://72.61.53.222:8443/login
• Certificado autoassinado
• Aviso do navegador
• Funcional
```

### **Após Certificado Let's Encrypt**:
```
https://prestadores.clinfec.com.br
• SSL Let's Encrypt válido
• Sem avisos do navegador
• Renovação automática
```

---

## 📞 PRÓXIMOS PASSOS

### **Escolha uma solução**:

1. **Solução Rápida** (15-20 min):
   - Desabilitar CDN temporariamente
   - Rodar certbot
   - Reabilitar CDN

2. **Solução Gerenciada** (5 min):
   - Usar SSL do próprio Hostinger
   - Configurar no hpanel
   - Zero configuração no VPS

3. **Solução Avançada** (30-60 min):
   - DNS Challenge
   - Configurar API credentials
   - Automação completa

### **Precisa de Ajuda?**

**Me diga**:
1. Onde o domínio está hospedado (Hostinger, Cloudflare, outro)?
2. Você tem acesso ao painel de DNS?
3. Prefere qual solução (1, 2 ou 3)?

**E eu executo os comandos necessários!**

---

## ✅ RESUMO EXECUTIVO

### **Problemas Resolvidos**:
- ✅ Erro 500 no dashboard e outros menus
- ✅ Multi-tenant preservado (sem redirect para IP)
- ✅ NGINX configurado corretamente
- ✅ PHP-FPM atualizado (open_basedir expandido)

### **Problema Pendente**:
- ⏳ Certificado SSL Let's Encrypt
- **Causa**: CDN/Proxy bloqueando validação HTTP
- **Solução**: Desabilitar CDN temporariamente OU usar SSL do Hostinger

### **Sistema Status**:
- ✅ 100% funcional
- ✅ Acessível via domínio e IP
- ⏳ SSL gratuito pendente (solução disponível)

---

**Me avise qual solução prefere e prossigo com a implementação!** 🚀
