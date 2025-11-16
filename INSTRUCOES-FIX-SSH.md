# INSTRUÇÕES PARA RESTAURAR ACESSO SSH

## 🚨 PROBLEMA IDENTIFICADO

O UFW (firewall) que foi configurado está bloqueando o acesso SSH externo ao servidor 72.61.53.222.

## 📋 O QUE VOCÊ PRECISA

1. **Acesso ao servidor via:**
   - Console web do seu provedor de VPS (Contabo, DigitalOcean, Vultr, etc.)
   - Terminal físico (se aplicável)
   - KVM/IPMI (se disponível)

2. **Acesso root** ao servidor

## 🔧 SOLUÇÃO - ESCOLHA UMA OPÇÃO

### ⭐ OPÇÃO 1: FIX NORMAL (RECOMENDADO)

Execute estes comandos diretamente no terminal do servidor:

```bash
# Permitir SSH no UFW
ufw allow 22/tcp
ufw allow ssh

# Recarregar UFW
ufw reload

# Verificar status
ufw status verbose
```

**OU** baixe e execute o script completo:

```bash
# Fazer upload do arquivo fix-ssh-firewall.sh para o servidor
# Depois:
chmod +x fix-ssh-firewall.sh
./fix-ssh-firewall.sh
```

### 🆘 OPÇÃO 2: EMERGÊNCIA (SE OPÇÃO 1 NÃO FUNCIONAR)

Se a opção 1 não funcionar, DESABILITE o UFW temporariamente:

```bash
# Desabilitar UFW completamente
ufw disable

# Verificar status
ufw status

# Reiniciar SSH
systemctl restart ssh
```

**OU** execute o script de emergência:

```bash
# Fazer upload do arquivo fix-ssh-firewall-EMERGENCY.sh
chmod +x fix-ssh-firewall-EMERGENCY.sh
./fix-ssh-firewall-EMERGENCY.sh
```

### ✅ OPÇÃO 3: RECONFIGURAÇÃO COMPLETA (APÓS RECUPERAR ACESSO)

Depois de recuperar o acesso SSH, execute este script para reconfigurar tudo corretamente:

```bash
# Fazer upload do arquivo reconfigure-ufw-complete.sh
chmod +x reconfigure-ufw-complete.sh
./reconfigure-ufw-complete.sh
```

## 📝 PASSO A PASSO DETALHADO

### PASSO 1: Acesse o console do servidor

1. Entre no painel do seu provedor VPS
2. Localize a opção "Console" ou "Terminal" ou "VNC"
3. Faça login como root com a senha: `Jm@D@KDPnw7Q`

### PASSO 2: Execute os comandos de fix

Copie e cole estes comandos **UM POR VEZ** no terminal:

```bash
# Verificar status atual do UFW
ufw status verbose

# Permitir SSH IMEDIATAMENTE
ufw allow 22/tcp

# Permitir SSH (método alternativo)
ufw allow ssh

# Recarregar firewall
ufw reload

# Verificar se funcionou
ufw status verbose | grep 22
```

### PASSO 3: Teste a conexão

Abra um terminal na sua máquina local e teste:

```bash
ssh root@72.61.53.222
```

Se conectar com sucesso, **INFORME-ME IMEDIATAMENTE** que vou continuar com o deployment automático.

### PASSO 4 (SE AINDA NÃO FUNCIONAR): Desabilitar UFW temporariamente

```bash
# EMERGÊNCIA: Desabilitar firewall
ufw disable

# Verificar
ufw status

# Reiniciar SSH
systemctl restart ssh

# Testar novamente
```

## 🎯 COMANDOS RÁPIDOS (COPIAR E COLAR)

### Solução Rápida 1-liner:

```bash
ufw allow 22/tcp && ufw allow ssh && ufw reload && ufw status verbose
```

### Solução de Emergência 1-liner:

```bash
ufw disable && systemctl restart ssh && ufw status
```

## 📤 COMO FAZER UPLOAD DOS SCRIPTS

### Opção A: Via Console (se tiver acesso a colar texto)

1. Abra o console do servidor
2. Execute: `nano fix-ssh-firewall.sh`
3. Cole o conteúdo do script
4. Salve: `Ctrl+X`, depois `Y`, depois `Enter`
5. Execute: `chmod +x fix-ssh-firewall.sh && ./fix-ssh-firewall.sh`

### Opção B: Via download direto (se servidor tiver internet)

```bash
# Criar o script manualmente
cat > fix-ssh-firewall.sh << 'EOF'
#!/bin/bash
ufw allow 22/tcp
ufw allow ssh
ufw reload
ufw status verbose
echo "SSH should now be accessible"
EOF

# Executar
chmod +x fix-ssh-firewall.sh
./fix-ssh-firewall.sh
```

## ✅ APÓS O FIX

Quando o SSH estiver funcionando novamente:

1. **ME INFORME IMEDIATAMENTE** digitando: "SSH FUNCIONANDO"
2. Eu vou continuar automaticamente com:
   - Deploy do dashboard fix
   - Deploy de todos os controllers
   - Criação de todas as views
   - Deploy de todos os scripts
   - Configuração do Roundcube
   - Integração do SpamAssassin
   - Testes end-to-end
   - Documentação final

## 🔍 VERIFICAÇÕES

### Verificar se SSH está rodando:

```bash
systemctl status ssh
# ou
systemctl status sshd
```

### Verificar se porta 22 está escutando:

```bash
ss -tlnp | grep :22
# ou
netstat -tlnp | grep :22
```

### Verificar regras do UFW:

```bash
ufw status numbered
```

## 📞 SUPORTE

Se tiver qualquer problema:

1. Copie a saída dos comandos
2. Envie para mim
3. Vou ajustar o script conforme necessário

## ⚠️ IMPORTANTE

- **NÃO FECHE** o console do servidor até confirmar que SSH externo funciona
- **TESTE** de outra máquina antes de desconectar do console
- Se usar a opção EMERGÊNCIA (desabilitar UFW), **RECONECTE VIA SSH IMEDIATAMENTE** e execute o script de reconfiguração completa

---

**STATUS**: Aguardando você executar os comandos e confirmar que SSH está acessível.

**PRÓXIMO PASSO**: Assim que SSH funcionar, informar "SSH FUNCIONANDO" para eu continuar com todo o deployment automaticamente.
