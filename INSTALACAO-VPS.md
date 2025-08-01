# 🚀 Guia Completo de Instalação do Atendechat em VPS

Este guia te ajudará a instalar o Atendechat em sua VPS de forma completamente automatizada.

## 📋 Pré-requisitos

### Servidor

- **VPS** com Ubuntu 20.04+ ou Debian 11+
- **RAM**: Mínimo 2GB (recomendado 4GB+)
- **Disco**: Mínimo 20GB de espaço livre
- **CPU**: 1 vCore (recomendado 2+ vCores)

### Rede

- **Domínio** apontado para o IP do servidor
- **Portas abertas**: 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **Acesso root/sudo** no servidor

### Antes de começar

1. Configure seu domínio para apontar para o IP da VPS
2. Tenha acesso SSH ao servidor
3. Tenha um email válido para certificado SSL

## 🎯 Instalação com Um Comando

### Método 1: Download e execução direta

```bash
curl -fsSL https://raw.githubusercontent.com/vitor/atendeaibase/main/install.sh | bash
```

### Método 2: Download manual (recomendado)

```bash
# Baixar o instalador
wget https://raw.githubusercontent.com/vitor/atendeaibase/main/install.sh

# Tornar executável
chmod +x install.sh

# Executar
./install.sh
```

## 📝 Processo de Instalação

### Passo 1: Informações iniciais

O instalador pedirá:

- **Domínio**: ex: `atendechat.seudominio.com`
- **Email**: para certificado SSL

### Passo 2: Instalação automática

O script irá automaticamente:

1. ✅ Atualizar o sistema
2. ✅ Instalar Node.js 20
3. ✅ Instalar PostgreSQL
4. ✅ Instalar Redis
5. ✅ Instalar Nginx
6. ✅ Instalar PM2
7. ✅ Instalar Certbot
8. ✅ Criar usuário do sistema
9. ✅ Configurar banco de dados
10. ✅ Clonar código do GitHub

### Passo 3: Configuração da aplicação

Execute a segunda parte:

```bash
./install-part2.sh
```

Isso irá:

1. ✅ Instalar dependências
2. ✅ Fazer build da aplicação
3. ✅ Executar migrações do banco
4. ✅ Configurar Nginx
5. ✅ Configurar SSL
6. ✅ Iniciar aplicação com PM2
7. ✅ Configurar firewall

## 🎉 Após a Instalação

### Acessar o sistema

1. Acesse: `https://seudominio.com`
2. Faça o primeiro login
3. Configure as integrações WhatsApp

### Comandos úteis

```bash
# Ver status dos serviços
atendechat-status

# Reiniciar aplicação
atendechat-restart

# Ver logs em tempo real
atendechat-logs

# Verificar saúde do sistema
./check-system.sh

# Fazer backup
./backup.sh

# Atualizar sistema
./update.sh
```

## 🔧 Configurações Adicionais

### Email (opcional)

Edite o arquivo de configuração:

```bash
sudo nano /opt/atendechat/backend/.env
```

Configure as variáveis de email:

```env
MAIL_HOST=smtp.gmail.com
MAIL_USER=seu@gmail.com
MAIL_PASS=sua-senha-app
MAIL_FROM=seu@gmail.com
MAIL_PORT=465
```

Reinicie a aplicação:

```bash
atendechat-restart
```

### Pagamentos PIX (opcional)

Configure as variáveis Gerencianet no mesmo arquivo `.env`:

```env
GERENCIANET_SANDBOX=false
GERENCIANET_CLIENT_ID=seu_client_id
GERENCIANET_CLIENT_SECRET=seu_client_secret
GERENCIANET_PIX_CERT=seu_certificado
GERENCIANET_PIX_KEY=sua_chave_pix
```

## 🛠️ Gerenciamento do Sistema

### Backup automático

```bash
# Backup completo
./backup.sh --full

# Backup apenas do banco
./backup.sh --database

# Listar backups
./backup.sh --list
```

### Atualizações

```bash
# Atualização completa
./update.sh --full

# Apenas código
./update.sh --code-only

# Apenas migrações
./update.sh --migrations
```

### Monitoramento

```bash
# Verificação completa
./check-system.sh --full

# Apenas serviços
./check-system.sh --services

# Relatório de saúde
./check-system.sh --report
```

## 🚨 Solução de Problemas

### Problema: Erro de conexão com banco

```bash
# Verificar status do PostgreSQL
sudo systemctl status postgresql

# Reiniciar PostgreSQL
sudo systemctl restart postgresql

# Verificar logs
sudo journalctl -u postgresql -f
```

### Problema: Aplicação não inicia

```bash
# Verificar logs do PM2
atendechat-logs

# Reiniciar aplicação
atendechat-restart

# Verificar configurações
./check-system.sh --full
```

### Problema: SSL não funciona

```bash
# Verificar certificado
sudo certbot certificates

# Renovar certificado
sudo certbot renew

# Verificar configuração do Nginx
sudo nginx -t
```

### Problema: Erro de permissões

```bash
# Corrigir permissões
sudo chown -R atendechat:atendechat /opt/atendechat

# Verificar usuário
id atendechat
```

## 📊 Monitoramento de Performance

### Verificar recursos

```bash
# CPU e memória
htop

# Espaço em disco
df -h

# Status dos serviços
./check-system.sh --services
```

### Logs importantes

```bash
# Logs da aplicação
atendechat-logs

# Logs do Nginx
sudo tail -f /var/log/nginx/error.log

# Logs do sistema
sudo journalctl -f
```

## 🔄 Desinstalação

Se precisar remover completamente o sistema:

```bash
./uninstall.sh
```

⚠️ **Atenção**: Isso removerá todos os dados. Faça backup antes!

## 📞 Suporte

### Verificação rápida

```bash
# Status geral
atendechat-status

# Verificação completa
./check-system.sh

# Logs recentes
atendechat-logs
```

### Informações do sistema

```bash
# Versão do sistema
cat /etc/os-release

# Recursos disponíveis
free -h && df -h

# Processos ativos
ps aux | grep -E "(node|nginx|postgres|redis)"
```

## 🎯 Próximos Passos

1. **Configure WhatsApp**: Acesse o painel e adicione suas conexões
2. **Configure usuários**: Crie contas para sua equipe
3. **Configure filas**: Organize o atendimento
4. **Configure chatbots**: Automatize respostas
5. **Configure relatórios**: Monitore performance

## 📚 Recursos Adicionais

- **Documentação**: Acesse o painel para tutoriais
- **Backup**: Configure backups automáticos
- **Monitoramento**: Use o `check-system.sh` regularmente
- **Atualizações**: Execute `update.sh` mensalmente

---

🎉 **Parabéns!** Seu Atendechat está instalado e funcionando!

Para suporte adicional, verifique os logs e use os scripts de diagnóstico incluídos.
