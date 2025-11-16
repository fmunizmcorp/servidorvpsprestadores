# 🔒 GUIA COMPLETO: Instalar SSL via Hostinger hPanel
## prestadores.clinfec.com.br

**Tempo estimado:** 5 minutos  
**Custo:** GRATUITO (Let's Encrypt)  
**Dificuldade:** ⭐ Fácil  
**Resultado:** HTTPS válido, sem avisos de segurança

---

## 📋 PRÉ-REQUISITOS

✅ Acesso ao hPanel Hostinger  
✅ Domínio: prestadores.clinfec.com.br  
✅ Domínio apontando para Hostinger (já configurado)  
✅ Site ativo e acessível

---

## 🚀 INSTALAÇÃO PASSO-A-PASSO

### PASSO 1: Acesse o hPanel

1. **Abra o navegador**
2. **Acesse:** https://hpanel.hostinger.com/
3. **Faça login** com suas credenciais Hostinger

```
┌─────────────────────────────────────┐
│   HOSTINGER hPanel Login            │
│                                     │
│   Email: seu-email@dominio.com      │
│   Senha: ******************         │
│                                     │
│   [        LOGIN        ]           │
└─────────────────────────────────────┘
```

---

### PASSO 2: Selecione o Domínio

1. **No painel principal**, localize o domínio:
   ```
   prestadores.clinfec.com.br
   ```

2. **Clique** no domínio ou em **"Gerenciar"**

```
┌─────────────────────────────────────────────┐
│  Seus Websites                              │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ prestadores.clinfec.com.br          │   │
│  │ [  Gerenciar  ]                     │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

### PASSO 3: Navegue até SSL

**Opção A: Menu Lateral**
1. No menu lateral esquerdo
2. Procure seção **"Segurança"** ou **"Avançado"**
3. Clique em **"SSL/TLS"** ou **"Gerenciar SSL"**

**Opção B: Busca Rápida**
1. Use a **barra de busca** no topo do painel
2. Digite: **"SSL"**
3. Clique no resultado **"SSL/TLS"**

```
┌─────────────────────────────────────┐
│  Menu                               │
│  ├─ Dashboard                       │
│  ├─ Websites                        │
│  ├─ E-mail                          │
│  ├─ Domínios                        │
│  ├─ Segurança                       │
│  │  ├─ SSL/TLS ← CLIQUE AQUI        │
│  │  └─ Backup                       │
│  └─ Avançado                        │
└─────────────────────────────────────┘
```

---

### PASSO 4: Instale Let's Encrypt SSL

1. **Na página SSL**, você verá:
   - Lista de domínios
   - Status atual do SSL
   - Opções de instalação

2. **Localize** o domínio:
   ```
   prestadores.clinfec.com.br
   ```

3. **Clique em:**
   - **"Instalar SSL"** ou
   - **"Gerenciar SSL"** ou
   - **"+ Adicionar SSL"**

```
┌──────────────────────────────────────────────┐
│  SSL/TLS Certificates                        │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │ prestadores.clinfec.com.br           │   │
│  │ Status: ⚠️ Sem SSL                   │   │
│  │                                      │   │
│  │ [    Instalar SSL    ]              │   │
│  └──────────────────────────────────────┘   │
└──────────────────────────────────────────────┘
```

---

### PASSO 5: Escolha Let's Encrypt

1. **Selecione a opção:**
   ```
   ☑️ Let's Encrypt (Recomendado)
   ```

2. **Marque as opções:**
   ```
   ☑️ prestadores.clinfec.com.br
   ☑️ www.prestadores.clinfec.com.br
   ```

3. **Opções adicionais (se disponíveis):**
   ```
   ☑️ Force HTTPS (Forçar HTTPS)
   ☑️ Incluir www
   ```

```
┌──────────────────────────────────────────────┐
│  Escolha o Tipo de Certificado              │
│                                              │
│  ○ Nenhum                                    │
│  ● Let's Encrypt (Gratuito) ← SELECIONE     │
│  ○ Certificado Personalizado                │
│                                              │
│  Domínios incluídos:                         │
│  ☑️ prestadores.clinfec.com.br               │
│  ☑️ www.prestadores.clinfec.com.br           │
│                                              │
│  [   Instalar Certificado   ]                │
└──────────────────────────────────────────────┘
```

---

### PASSO 6: Aguarde a Instalação

1. **Clique** em:
   ```
   [  Instalar Certificado  ]
   ```
   ou
   ```
   [  Generate  ]  /  [  Gerar  ]
   ```

2. **Aguarde** a instalação:
   ```
   ⏱️ Tempo: 1-5 minutos
   📊 Você verá uma barra de progresso
   ```

3. **Processo automático:**
   - ✅ Validação do domínio
   - ✅ Geração do certificado
   - ✅ Instalação no servidor
   - ✅ Configuração HTTPS

```
┌──────────────────────────────────────────────┐
│  Instalando Certificado SSL...              │
│                                              │
│  ████████████████░░░░░░░░░░ 65%             │
│                                              │
│  ⚙️  Validando domínio...                    │
│  ⚙️  Gerando certificado...                  │
│  ⚙️  Instalando no servidor...               │
│                                              │
│  Aguarde alguns instantes...                 │
└──────────────────────────────────────────────┘
```

---

### PASSO 7: Confirmação de Sucesso

1. **Você verá a mensagem:**
   ```
   ✅ SSL Instalado com Sucesso!
   ```
   ou
   ```
   ✅ Certificado Ativo
   ```

2. **Status atualizado:**
   ```
   Status: ✅ SSL Ativo
   Emissor: Let's Encrypt
   Validade: 90 dias (renovação automática)
   ```

```
┌──────────────────────────────────────────────┐
│  ✅ Certificado SSL Instalado com Sucesso!   │
│                                              │
│  Domínio: prestadores.clinfec.com.br         │
│  Tipo: Let's Encrypt                         │
│  Validade: 90 dias                           │
│  Renovação: Automática                       │
│                                              │
│  Seu site agora está seguro com HTTPS! 🔒   │
│                                              │
│  [      Voltar ao Painel      ]              │
└──────────────────────────────────────────────┘
```

---

### PASSO 8: Ative Force HTTPS (Opcional mas Recomendado)

1. **Na mesma página SSL** ou em **"Configurações"**
2. **Procure a opção:**
   ```
   Force HTTPS
   ou
   Always Use HTTPS
   ou
   Forçar HTTPS
   ```

3. **Ative o toggle/checkbox:**
   ```
   ☑️ Force HTTPS
   ```

4. **Salve as alterações**

```
┌──────────────────────────────────────────────┐
│  Configurações SSL                           │
│                                              │
│  ☑️ Force HTTPS (Forçar HTTPS)               │
│     Redirecionar todo tráfego HTTP para      │
│     HTTPS automaticamente                    │
│                                              │
│  ☑️ HSTS (HTTP Strict Transport Security)    │
│     Aumenta a segurança forçando HTTPS       │
│     em navegadores modernos                  │
│                                              │
│  [        Salvar Alterações        ]         │
└──────────────────────────────────────────────┘
```

---

### PASSO 9: Verifique o SSL

1. **Abra uma nova aba do navegador**

2. **Acesse:**
   ```
   https://prestadores.clinfec.com.br
   ```

3. **Verifique o cadeado 🔒:**
   - Clique no cadeado na barra de endereços
   - Deve mostrar: **"Conexão segura"** ou **"Secure"**
   - Emissor: **Let's Encrypt Authority**

4. **Teste o redirect HTTP:**
   ```
   http://prestadores.clinfec.com.br
   ```
   - Deve redirecionar automaticamente para HTTPS

```
┌──────────────────────────────────────────────┐
│  🔒 prestadores.clinfec.com.br              │
│                                              │
│  ✅ Conexão Segura                           │
│                                              │
│  Certificado válido                          │
│  Emissor: Let's Encrypt Authority X3         │
│  Validade: até DD/MM/AAAA                    │
│                                              │
│  Este certificado foi verificado e é         │
│  confiável.                                  │
└──────────────────────────────────────────────┘
```

---

## ✅ VERIFICAÇÕES FINAIS

### Checklist de Validação:

```bash
# 1. Acesse o site
✅ https://prestadores.clinfec.com.br carrega sem avisos

# 2. Verifique o cadeado
✅ Cadeado verde 🔒 aparece no navegador

# 3. Inspecione o certificado
✅ Emissor: Let's Encrypt
✅ Válido para: prestadores.clinfec.com.br
✅ Validade: ~90 dias (com renovação automática)

# 4. Teste redirect HTTP→HTTPS
✅ http://prestadores.clinfec.com.br → https://...

# 5. Teste www
✅ https://www.prestadores.clinfec.com.br funciona
```

### Ferramentas de Teste Online:

**1. SSL Labs Test** (Recomendado)
```
https://www.ssllabs.com/ssltest/analyze.html?d=prestadores.clinfec.com.br
```
- Meta: Rating A ou A+
- Tempo: 2-3 minutos de análise

**2. Why No Padlock**
```
https://www.whynopadlock.com/results/prestadores.clinfec.com.br
```
- Verifica conteúdo misto (HTTP em HTTPS)
- Identifica problemas de segurança

**3. SSL Checker**
```
https://www.sslshopper.com/ssl-checker.html#hostname=prestadores.clinfec.com.br
```
- Verifica validade do certificado
- Mostra cadeia de certificação

---

## 🔄 RENOVAÇÃO AUTOMÁTICA

### Como Funciona:

✅ **Hostinger renova automaticamente**
- Verificação diária de certificados
- Renovação ~30 dias antes do vencimento
- Processo totalmente automático
- Zero intervenção manual necessária

### Monitoramento:

**No hPanel:**
1. Acesse SSL/TLS
2. Verifique data de validade
3. Status deve mostrar: "Ativo" ou "Active"

**Por E-mail:**
- Hostinger pode enviar notificações
- Configure em: Settings → Notificações
- Ative alertas de SSL

**Logs de Renovação:**
- Disponíveis no hPanel
- Seção: SSL/TLS → Histórico
- Mostra todas as renovações

---

## 🆘 SOLUÇÃO DE PROBLEMAS

### Problema 1: "Certificado não pôde ser instalado"

**Causas possíveis:**
- DNS não propagado
- Domínio não apontando para Hostinger
- Outro certificado ativo

**Solução:**
```
1. Verifique DNS:
   - Acesse: https://dnschecker.org/
   - Digite: prestadores.clinfec.com.br
   - Aguarde propagação (até 48h)

2. Remova certificado antigo:
   - hPanel → SSL/TLS
   - Remover certificado existente
   - Tente instalar novamente

3. Contate suporte Hostinger se persistir
```

---

### Problema 2: "Aviso de segurança mesmo após instalação"

**Causas possíveis:**
- Cache do navegador
- Conteúdo misto (HTTP em HTTPS)
- Certificado não propagado

**Solução:**
```
1. Limpe cache do navegador:
   - Chrome: Ctrl+Shift+Delete
   - Firefox: Ctrl+Shift+Delete
   - Safari: Cmd+Option+E

2. Teste em modo anônimo/privado

3. Aguarde 5-10 minutos para propagação

4. Verifique conteúdo misto:
   - Use: https://www.whynopadlock.com/
   - Corrija links HTTP para HTTPS
```

---

### Problema 3: "Redirect loop (loop infinito)"

**Causas:**
- Conflito entre Force HTTPS do hPanel e do site
- .htaccess com redirects conflitantes

**Solução:**
```
1. No hPanel:
   - Desative "Force HTTPS" temporariamente

2. Verifique .htaccess do site:
   - Remova redirects HTTPS duplicados
   - Mantenha apenas um método de redirect

3. Reative Force HTTPS no hPanel

4. Limpe cache e teste
```

---

### Problema 4: "Certificado expirado"

**Causas:**
- Renovação automática falhou
- Problema com validação

**Solução:**
```
1. No hPanel → SSL/TLS
2. Clique em "Renovar Certificado" ou "Reinstalar"
3. Aguarde nova instalação
4. Se falhar, contate suporte Hostinger
```

---

## 📧 SUPORTE HOSTINGER

Se precisar de ajuda:

**Chat ao Vivo:**
- Disponível 24/7
- No hPanel, ícone de chat no canto inferior direito
- Resposta em minutos

**Base de Conhecimento:**
- https://support.hostinger.com/
- Artigos sobre SSL
- Tutoriais em vídeo

**E-mail:**
- support@hostinger.com
- Resposta em 24-48 horas

**Telefone (Brasil):**
- Verifique no hPanel → Suporte
- Horário comercial

---

## 💡 DICAS ADICIONAIS

### Melhore seu Rating SSL:

1. **No hPanel, ative:**
   ```
   ☑️ HSTS (HTTP Strict Transport Security)
   ☑️ TLS 1.2 mínimo
   ☑️ Redirect automático HTTP→HTTPS
   ```

2. **No site, adicione headers:**
   ```nginx
   add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
   ```
   (Já configurado no VPS NGINX)

3. **Teste regularmente:**
   - SSL Labs mensalmente
   - Verifique avisos do navegador
   - Monitore renovação

### Otimizações:

- **CDN com SSL:** Cloudflare Free (opcional)
- **Preload HSTS:** https://hstspreload.org/
- **Certificate Transparency:** Automático com Let's Encrypt

---

## 📊 COMPARATIVO: Antes vs Depois

| Aspecto | ANTES (Self-Signed) | DEPOIS (Let's Encrypt) |
|---------|---------------------|------------------------|
| Cadeado | ⚠️ Vermelho/Amarelo | ✅ Verde |
| Aviso | "Não seguro" | "Conexão segura" |
| Navegadores | Bloqueiam | Confiam |
| SEO Google | ❌ Penalizado | ✅ Bonificado |
| Usuários | Desconfiam | Confiam |
| Conversão | ⬇️ Diminui | ⬆️ Aumenta |
| Manutenção | Manual | Automática |
| Custo | R$ 0 | R$ 0 |

---

## ✅ CONCLUSÃO

### Resumo do Processo:

1. ✅ Acesse hPanel Hostinger
2. ✅ Navegue até SSL/TLS
3. ✅ Escolha Let's Encrypt
4. ✅ Instale certificado
5. ✅ Ative Force HTTPS
6. ✅ Verifique o resultado

### Benefícios Imediatos:

✅ **Segurança:** Criptografia TLS 1.2/1.3  
✅ **Confiança:** Sem avisos de segurança  
✅ **SEO:** Melhora ranking Google  
✅ **Conversão:** Usuários confiam mais  
✅ **Automático:** Renovação sem intervenção  
✅ **Gratuito:** Let's Encrypt sem custo  

### Tempo Total: ⏱️ 5 minutos
### Dificuldade: ⭐ Fácil
### Resultado: 🎉 HTTPS Válido e Seguro!

---

**Precisa de ajuda?**
- 💬 Suporte Hostinger: 24/7 via chat
- 📧 E-mail: support@hostinger.com
- 📚 Base de conhecimento: support.hostinger.com

---

*Guia criado em: 2025-11-16*  
*Para: prestadores.clinfec.com.br*  
*Plataforma: Hostinger hPanel*  
*Certificado: Let's Encrypt (Gratuito)*
