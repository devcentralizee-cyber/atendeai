# 🚀 Deploy do Atendechat no EasyPanel

Este guia te ajudará a fazer o deploy do sistema Atendechat no EasyPanel usando Docker.

## 📋 Pré-requisitos

- Conta no EasyPanel
- Domínio configurado (opcional, mas recomendado)
- Acesso ao repositório do código

## 🔧 Configuração no EasyPanel

### 1. Criar um novo projeto

1. Acesse seu painel do EasyPanel
2. Clique em "Create Project"
3. Escolha "Docker Compose"
4. Dê um nome ao projeto (ex: `atendechat`)

### 2. Configurar variáveis de ambiente

No EasyPanel, vá para a seção "Environment Variables" e adicione as seguintes variáveis:

```env
# Ambiente
NODE_ENV=production

# URLs (ajustar conforme seu domínio)
BACKEND_URL=https://seu-dominio.com
FRONTEND_URL=https://seu-dominio.com
PROXY_PORT=443

# Portas
BACKEND_PORT=8080
FRONTEND_PORT=3000
DB_PORT=5432
REDIS_PORT=6379

# Banco de dados
DB_NAME=atendechat
DB_USER=atendechat
DB_PASS=SUA_SENHA_SEGURA_AQUI

# Redis
REDIS_PASS=SUA_SENHA_REDIS_AQUI

# JWT (GERE NOVOS SECRETS!)
JWT_SECRET=SEU_JWT_SECRET_AQUI
JWT_REFRESH_SECRET=SEU_JWT_REFRESH_SECRET_AQUI

# Limites
USER_LIMIT=10000
CONNECTIONS_LIMIT=100000
CLOSED_SEND_BY_ME=true

# Email (opcional)
MAIL_HOST=smtp.gmail.com
MAIL_USER=seu@gmail.com
MAIL_PASS=sua-senha-app
MAIL_FROM=seu@gmail.com
MAIL_PORT=465

# Frontend
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
```

### 3. Upload do código

1. Faça upload do código do projeto para o EasyPanel
2. Certifique-se de que todos os arquivos estão presentes:
   - `docker-compose.yml`
   - `backend/Dockerfile`
   - `frontend/Dockerfile`
   - `backend/Dockerfile.sqlsetup`

### 4. Configurar domínio (opcional)

1. No EasyPanel, vá para "Domains"
2. Adicione seu domínio
3. Configure o SSL (Let's Encrypt)

### 5. Deploy

1. Clique em "Deploy"
2. Aguarde o build e deploy dos containers
3. Verifique os logs para garantir que tudo está funcionando

## 🔍 Verificação do Deploy

### Verificar serviços

1. **PostgreSQL**: Deve estar rodando na porta 5432
2. **Redis**: Deve estar rodando na porta 6379
3. **Backend**: Deve estar rodando na porta 8080
4. **Frontend**: Deve estar rodando na porta 3000 (mapeada para 80 no container)

### Testar a aplicação

1. Acesse o frontend: `https://seu-dominio.com`
2. Teste o backend: `https://seu-dominio.com/api/auth/refresh`

## 🛠️ Comandos úteis

### Verificar logs
```bash
# Logs do backend
docker logs atendechat-backend

# Logs do frontend
docker logs atendechat-frontend

# Logs do banco
docker logs atendechat-postgres
```

### Executar migrações manualmente (se necessário)
```bash
# Entrar no container do backend
docker exec -it atendechat-backend sh

# Executar migrações
npm run db:migrate
npm run db:seed
```

## 🔒 Segurança

### Senhas importantes para alterar:

1. **DB_PASS**: Senha do PostgreSQL
2. **REDIS_PASS**: Senha do Redis
3. **JWT_SECRET**: Secret para tokens JWT
4. **JWT_REFRESH_SECRET**: Secret para refresh tokens

### Gerar novos JWT secrets:
```bash
# No terminal
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

## 📊 Monitoramento

### Verificar saúde dos serviços

O docker-compose inclui health checks para todos os serviços. Você pode verificar o status no painel do EasyPanel.

### Logs importantes

- **Backend**: Logs da API e conexões WhatsApp
- **Frontend**: Logs do Nginx
- **PostgreSQL**: Logs do banco de dados
- **Redis**: Logs do cache

## 🚨 Troubleshooting

### Problemas comuns:

1. **Erro de conexão com banco**: Verifique se o PostgreSQL está rodando e as credenciais estão corretas
2. **Erro de conexão com Redis**: Verifique se o Redis está rodando e a senha está correta
3. **Frontend não carrega**: Verifique se o backend está rodando e as URLs estão corretas
4. **Erro de migração**: Execute as migrações manualmente

### Reiniciar serviços:
```bash
# Reiniciar todos os serviços
docker-compose restart

# Reiniciar apenas o backend
docker-compose restart backend
```

## 📞 Suporte

Se você encontrar problemas durante o deploy, verifique:

1. Logs dos containers
2. Configurações de rede
3. Variáveis de ambiente
4. Permissões de arquivos

## 🎉 Pronto!

Após seguir estes passos, seu sistema Atendechat deve estar rodando no EasyPanel. Acesse o frontend e faça o primeiro login para configurar o sistema.
