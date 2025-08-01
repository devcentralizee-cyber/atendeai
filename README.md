# Atendechat

O Atendechat é uma empresa distribuidora de White Label que possui uma solução de atendimentos via Whatsapp que aumenta a produtividade e organização das equipes

## 🚀 Instalação Automática (Recomendado)

### Instalação em VPS com um comando

Para instalar o Atendechat em sua VPS Ubuntu/Debian, execute:

```bash
curl -fsSL https://raw.githubusercontent.com/devcentralizee-cyber/atendeai/main/install.sh | bash
```

Ou baixe e execute manualmente:

```bash
wget https://raw.githubusercontent.com/devcentralizee-cyber/atendeai/main/install.sh
chmod +x install.sh
./install.sh
```

### Pré-requisitos para instalação automática

- VPS com Ubuntu 20.04+ ou Debian 11+
- Acesso root/sudo
- Domínio apontado para o servidor
- Portas 80 e 443 abertas

### O que o instalador faz automaticamente

✅ Instala todas as dependências (Node.js, PostgreSQL, Redis, Nginx)
✅ Configura banco de dados e usuários
✅ Clona o código do GitHub
✅ Configura variáveis de ambiente
✅ Faz build do frontend e backend
✅ Configura Nginx como proxy reverso
✅ Configura SSL com Let's Encrypt
✅ Configura PM2 para gerenciar processos
✅ Configura firewall básico

### Após a instalação

Acesse seu domínio e faça o primeiro login para configurar o sistema.

## 🔧 Scripts de Gerenciamento

Após a instalação, você terá acesso aos seguintes comandos:

```bash
# Ver status dos serviços
atendechat-status

# Reiniciar aplicação
atendechat-restart

# Ver logs em tempo real
atendechat-logs

# Atualizar sistema
./update.sh

# Fazer backup
./backup.sh
```

## 🚀 Começando (Instalação Manual)

O repositório do Atendechat possui 3 pastas importantes:

- backend
- frontend
- instalador

O backend é feito em Express e possui toda a estrutura organizada dentro dessa pasta para que seja aplicado no ambiente do cliente. A pasta de frontend contém todo o framework do React.js que gerencia toda a interação com o usuário do sistema.

Consulte **[Implantação Manual](#-implanta%C3%A7%C3%A3o-manual)** para saber como implantar o projeto manualmente.

### 📋 Pré-requisitos

```
- Node.js v20.x
- Postgres (release)
- Npm ( latest )
- Docker (bionic stable)
- Redis
```

### 🔧 Instalação

Para iniciar a instalação do projeto é necessário ter todas as ferramentas de pré-requisitos disponíveis para uso

#### Redis

```
- su - root
- docker run --name redis-${instancia_add} -p ${redis_port}:6379 --restart always --detach redis redis-server --requirepass ${root_password}
```

#### Postgres

```
- sudo su - postgres
- createdb ${instancia_add};
- psql
- CREATE USER ${instancia_add} SUPERUSER INHERIT CREATEDB CREATEROLE;
- ALTER USER ${instancia_add} PASSWORD '${root_password}';
```

#### .env backend

```
NODE_ENV=
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}
PROXY_PORT=443
PORT=${backend_port}

DB_DIALECT=postgres
DB_HOST=localhost
DB_PORT=5432
DB_USER=${instancia_add}
DB_PASS=${mysql_root_password}
DB_NAME=${instancia_add}

JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}

REDIS_URI=redis://:${mysql_root_password}@127.0.0.1:${redis_port}
REDIS_OPT_LIMITER_MAX=1
REGIS_OPT_LIMITER_DURATION=3000

USER_LIMIT=${max_user}
CONNECTIONS_LIMIT=${max_whats}
CLOSED_SEND_BY_ME=true

GERENCIANET_SANDBOX=false
GERENCIANET_CLIENT_ID=Client_Id_Gerencianet
GERENCIANET_CLIENT_SECRET=Client_Secret_Gerencianet
GERENCIANET_PIX_CERT=certificado-Gerencianet
GERENCIANET_PIX_KEY=chave pix gerencianet

# EMAIL
 MAIL_HOST="smtp.gmail.com"
 MAIL_USER="seu@gmail.com"
 MAIL_PASS="SuaSenha"
 MAIL_FROM="seu@gmail.com"
 MAIL_PORT="465"

```

#### .env frontend

```
REACT_APP_BACKEND_URL=${backend_url}
REACT_APP_HOURS_CLOSE_TICKETS_AUTO = 24
```

#### Instalando dependências

```
cd backend/
npm install --force
cd frontend/
npm install --force
```

### Rodando localmente

```
cd backend/
npm run watch
npm start

cd frontend/
npm start
```

## ⚙️ Executando os testes

//

### 🔩 Analise os testes de ponta a ponta

//

## 📦 Implantação Manual

### Atualização em produção (método tradicional)

Para correta implantação é necessário realizar uma atualização do código fonte da aplicação e criar novamente os arquivos da pasta dist/

Atenção: é necessário acessar utilizando o usuário de deploy

```bash
su - deploy
```

**Frontend:**

```bash
cd /home/deploy/${empresa_atualizar}
pm2 stop ${empresa_atualizar}-frontend
git pull
cd /home/deploy/${empresa_atualizar}/frontend
npm install
rm -rf build
npm run build
pm2 start ${empresa_atualizar}-frontend
pm2 save
```

**Backend:**

```bash
cd /home/deploy/${empresa_atualizar}
pm2 stop ${empresa_atualizar}-backend
git pull
cd /home/deploy/${empresa_atualizar}/backend
npm install
npm update -f
npm install @types/fs-extra
rm -rf dist
npm run build
npx sequelize db:migrate
npx sequelize db:seed
pm2 start ${empresa_atualizar}-backend
pm2 save
```

### 🐳 Deploy com Docker

Se preferir usar Docker, utilize os arquivos incluídos:

```bash
# Build e start com docker-compose
docker-compose up -d --build

# Ou usando os scripts
./scripts/deploy.sh
```

### ☁️ Deploy no EasyPanel

Para deploy no EasyPanel, consulte o arquivo `DEPLOY-EASYPANEL.md` incluído no projeto.

## 🛠️ Construído com

- [Express](https://expressjs.com/pt-br/) - O framework backend usado
- [React](https://react.dev/) - Framework frontend usado
- [NPM](https://www.npmjs.com/) - Gerenciador de dependências

## 🖇️ Colaborando

//

## 📌 Versão

Versão 1.0.0

## 📄 Licença

Este projeto está sob a licença

⌨️ com ❤️ por [Atendechat](https://atendechat.com) 😊

Todos os direitos reservados a https://atendechat.com
