# 🚀 INÍCIO RÁPIDO - RESETAR CREDENCIAIS ADMIN

**VPS**: 72.61.53.222 | **Servidor**: srv1131556.hostinger.com

---

## ⚡ SOLUÇÃO RÁPIDA (5 MINUTOS)

### **1️⃣ ACESSAR CONSOLE DO VPS**

1. Abra: https://hpanel.hostinger.com/
2. Faça login na Hostinger
3. Menu lateral → **VPS**
4. Selecione: **srv1131556**
5. Clique em: **"Browser terminal"** ou **"Console"**
6. Aguarde carregar

### **2️⃣ FAZER LOGIN**

```
srv1131556 login: root
Password: [sua senha do root]
```

### **3️⃣ EXECUTAR COMANDO**

**Copie TUDO abaixo** e cole no console (Ctrl+Shift+V ou botão direito):

```bash
cd /opt/webserver/admin-panel && cat > /tmp/reset.php << 'EOFPHP'
<?php
require_once "/opt/webserver/admin-panel/vendor/autoload.php";
$app = require_once "/opt/webserver/admin-panel/bootstrap/app.php";
$app->make("Illuminate\Contracts\Console\Kernel")->bootstrap();
\App\Models\User::where("email", "LIKE", "%admin%")->delete();
$user = \App\Models\User::create([
    "name" => "Administrador VPS",
    "email" => "admin@vps.local",
    "password" => \Illuminate\Support\Facades\Hash::make("VpsAdmin2024!@#$"),
    "email_verified_at" => now(),
]);
echo "\n✅ Usuário criado: " . $user->email . " (ID: " . $user->id . ")\n";
EOFPHP
php /tmp/reset.php && php artisan cache:clear && php artisan config:clear && systemctl restart php8.2-fpm && echo "" && echo "═══════════════════════════════════════" && echo "✅ CREDENCIAIS ATUALIZADAS!" && echo "═══════════════════════════════════════" && echo "🌐 URL:   https://72.61.53.222:8443/login" && echo "📧 Email: admin@vps.local" && echo "🔑 Senha: VpsAdmin2024!@#$" && echo "═══════════════════════════════════════" && rm -f /tmp/reset.php
```

**Aguarde 5-10 segundos**. Você verá:

```
✅ CREDENCIAIS ATUALIZADAS!
═══════════════════════════════════════
🌐 URL:   https://72.61.53.222:8443/login
📧 Email: admin@vps.local
🔑 Senha: VpsAdmin2024!@#$
═══════════════════════════════════════
```

### **4️⃣ TESTAR LOGIN**

1. Abra no navegador: **https://72.61.53.222:8443/login**
2. Você verá um aviso: **"Sua conexão não é particular"**
   - Clique em **"Avançado"**
   - Clique em **"Continuar para 72.61.53.222"**
3. Faça login:
   - **Email**: `admin@vps.local`
   - **Senha**: `VpsAdmin2024!@#$`

✅ **Pronto!** Você deve estar no painel admin.

---

## 🔐 SUAS NOVAS CREDENCIAIS

```
═══════════════════════════════════════════════════════
             🌐 PAINEL DE ADMINISTRAÇÃO VPS
═══════════════════════════════════════════════════════

🔗 URL DE ACESSO:
   https://72.61.53.222:8443/login

👤 CREDENCIAIS:
   Email: admin@vps.local
   Senha: VpsAdmin2024!@#$

⚠️  IMPORTANTE:
   - Aceite o aviso do navegador (certificado autoassinado)
   - Isso é normal e seguro para uso interno
   - Para remover o aviso, configure um domínio com Let's Encrypt

═══════════════════════════════════════════════════════
```

---

## ❓ PROBLEMAS?

### **Comando não funciona?**

Use o método manual com Tinker:

```bash
cd /opt/webserver/admin-panel
php artisan tinker
```

Dentro do Tinker, execute linha por linha:

```php
\App\Models\User::where("email", "LIKE", "%admin%")->delete();

$user = \App\Models\User::create([
    "name" => "Administrador VPS",
    "email" => "admin@vps.local",
    "password" => \Illuminate\Support\Facades\Hash::make("VpsAdmin2024!@#$"),
    "email_verified_at" => now(),
]);

echo $user->email;

exit
```

Depois:

```bash
php artisan cache:clear
php artisan config:clear
systemctl restart php8.2-fpm
```

### **Não consegue acessar o console do VPS?**

Entre em contato com suporte da Hostinger:
- Chat ao vivo no hpanel
- Ticket de suporte
- Email: support@hostinger.com

### **Página não carrega (timeout)?**

Verifique se os serviços estão rodando:

```bash
systemctl status nginx
systemctl status php8.2-fpm
```

Se algum estiver parado, inicie:

```bash
systemctl start nginx
systemctl start php8.2-fpm
```

---

## 🌐 SOBRE O AVISO DO NAVEGADOR

### **Por que aparece "Não seguro"?**

O servidor está usando um **certificado SSL autoassinado**.

Isso significa:
- ✅ A conexão é **criptografada** (segura)
- ⚠️ O certificado não foi **verificado** por uma autoridade confiável
- 🔓 Navegadores mostram aviso por precaução

### **É seguro continuar?**

**SIM!** Para uso interno/privado (painel admin), é totalmente seguro.

### **Como remover o aviso?**

Use **Let's Encrypt** (SSL gratuito). Você precisa:

1. **Ter um domínio** (ex: `meusite.com`)
2. **Apontar o domínio para o IP**: `72.61.53.222`
3. **Executar no servidor**:
   ```bash
   certbot --nginx -d admin.meusite.com
   ```

O certbot irá:
- Obter certificado SSL válido e gratuito
- Configurar NGINX automaticamente
- Renovar o certificado automaticamente

**Nota**: Let's Encrypt **NÃO funciona com IP**. Você precisa de um domínio válido.

---

## 📋 CHECKLIST FINAL

- [ ] Console do VPS acessado
- [ ] Comando de reset executado
- [ ] Mensagem de sucesso exibida
- [ ] URL https://72.61.53.222:8443/login aberta
- [ ] Aviso de certificado aceito
- [ ] Login com admin@vps.local / VpsAdmin2024!@#$ realizado
- [ ] Painel admin carregado com sucesso

---

## 📚 DOCUMENTAÇÃO ADICIONAL

Para mais detalhes, consulte:

- **INSTRUCOES_RESET_ADMIN.md** - Guia completo passo a passo
- **RESUMO_FINAL_TAREFAS.md** - Status geral e próximos passos
- **RESET_ADMIN_CREDENTIALS.sh** - Script automatizado completo

---

## 🎯 PRÓXIMOS PASSOS

Após o login funcionar:

1. **Explorar o painel**:
   - Dashboard
   - Gerenciamento de sites
   - Configurações de email
   - Monitoramento de recursos

2. **Alterar sua senha** (opcional):
   - No painel → Configurações → Alterar senha
   - Use uma senha forte e única

3. **Configurar domínio** (opcional):
   - Registre um domínio
   - Aponte para 72.61.53.222
   - Execute certbot para SSL válido

---

**Data**: 2025-11-16  
**Suporte**: Criado automaticamente durante configuração do VPS  
**Versão**: Laravel 11.x + NGINX + PHP 8.2-FPM

---

✅ **Tudo pronto! Sucesso na sua jornada com o VPS!** 🚀
