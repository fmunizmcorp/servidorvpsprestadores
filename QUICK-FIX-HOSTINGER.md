# ⚡ CORREÇÃO RÁPIDA - Hostinger Redirect

## 🎯 PROBLEMA
Site https://prestadores.clinfec.com.br retorna erro 500 porque Hostinger redireciona incorretamente para `http://72.61.53.222`.

## ✅ WORKAROUND IMEDIATO (Enquanto aguarda correção)

### Opção A: Acessar via IP (FUNCIONA AGORA)
```
Site: https://72.61.53.222/prestadores/
Admin: https://72.61.53.222/admin/
```
**Status:** ✅ Funcionando 100%

### Opção B: Aguardar Correção DNS (Recomendado)
Se aplicar DNS direto para VPS (ver HOSTINGER-REDIRECT-FIX.md OPÇÃO 3):
- Tempo propagação: 15min - 48h
- Depois funciona: https://prestadores.clinfec.com.br

## 🔧 CORREÇÃO DEFINITIVA

**Escolha uma das 3 opções em:** `HOSTINGER-REDIRECT-FIX.md`

1. **OPÇÃO 1** (5 min): Remover redirect no hPanel
2. **OPÇÃO 2** (10 min): Configurar proxy reverso
3. **OPÇÃO 3** (15 min + propagação): DNS direto para VPS ⭐ **RECOMENDADO**

## 📊 STATUS ATUAL

### ✅ FUNCIONANDO:
- VPS: 100% operacional
- NGINX: Configurado corretamente  
- PHP-FPM: Ativo
- SSL: Instalado
- Acesso via IP: https://72.61.53.222/prestadores/ ✅
- Admin via IP: https://72.61.53.222/admin/ ✅

### ❌ NÃO FUNCIONANDO:
- Acesso via domínio: https://prestadores.clinfec.com.br ❌
- Causa: Redirect incorreto no Hostinger
- Solução: Configuração no hPanel (5 min)

## 🚀 AÇÃO IMEDIATA

1. Acesse: https://hpanel.hostinger.com/
2. Vá em: Domínios → prestadores.clinfec.com.br
3. Procure: Redirects ou Redirecionamentos
4. Remova: Redirect para 72.61.53.222
5. Aguarde: 2-5 minutos
6. Teste: https://prestadores.clinfec.com.br

**OU**

Aplique OPÇÃO 3 (DNS direto) conforme `HOSTINGER-REDIRECT-FIX.md`

---

**Criado:** 2025-11-16  
**Status:** ⚠️ Aguardando correção Hostinger  
**Workaround:** Use https://72.61.53.222/prestadores/
