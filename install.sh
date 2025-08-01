#!/bin/bash

# Script de Instalação Automática do Atendechat
# Versão: 1.0.0
# Compatível com: Ubuntu 20.04+ / Debian 11+

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis globais
GITHUB_REPO="https://github.com/devcentralizee-cyber/atendeai.git"
INSTALL_DIR="/opt/atendechat"
USER_NAME="atendechat"
DB_NAME="atendechat"
DB_USER="atendechat"
FRONTEND_DOMAIN=""
BACKEND_DOMAIN=""
EMAIL=""
SUDO_CMD=""

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERRO] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar se é root e configurar sudo
check_root() {
    if [[ $EUID -eq 0 ]]; then
        warning "Executando como root. Recomendamos usar um usuário com sudo."
        SUDO_CMD=""
        echo ""
        read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Instalação cancelada. Crie um usuário com sudo e execute novamente."
        fi
    else
        SUDO_CMD="sudo"
    fi
}

# Verificar sistema operacional
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Sistema operacional não suportado"
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        error "Sistema operacional não suportado. Use Ubuntu 20.04+ ou Debian 11+"
    fi
    
    log "Sistema operacional detectado: $PRETTY_NAME"
}

# Coletar informações do usuário
collect_info() {
    echo ""
    echo "🚀 Bem-vindo ao Instalador do Atendechat!"
    echo "=========================================="
    echo ""
    echo "Vamos configurar seu sistema passo a passo."
    echo "Você precisará fornecer 3 informações:"
    echo ""

    # Passo 1: Frontend Domain
    echo "📍 PASSO 1/3 - Domínio do Frontend"
    echo "─────────────────────────────────────"
    echo ""
    echo "O frontend é a interface que seus usuários vão acessar."
    echo "Exemplo: app.seudominio.com, painel.seudominio.com"
    echo ""
    while true; do
        read -p "🌐 Digite o domínio do FRONTEND: " FRONTEND_DOMAIN
        if [[ -z "$FRONTEND_DOMAIN" ]]; then
            echo "❌ Domínio não pode estar vazio. Tente novamente."
        elif [[ ! "$FRONTEND_DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "❌ Formato inválido. Use: subdominio.seudominio.com"
        else
            echo "✅ Frontend configurado: https://$FRONTEND_DOMAIN"
            break
        fi
        echo ""
    done

    echo ""
    echo "Pressione ENTER para continuar..."
    read
    clear

    # Passo 2: Backend Domain
    echo "📍 PASSO 2/3 - Domínio do Backend"
    echo "─────────────────────────────────────"
    echo ""
    echo "O backend é a API que processa os dados do sistema."
    echo "Exemplo: api.seudominio.com, backend.seudominio.com"
    echo ""
    echo "⚠️  DEVE ser diferente do frontend: $FRONTEND_DOMAIN"
    echo ""
    while true; do
        read -p "⚙️  Digite o domínio do BACKEND: " BACKEND_DOMAIN
        if [[ -z "$BACKEND_DOMAIN" ]]; then
            echo "❌ Domínio não pode estar vazio. Tente novamente."
        elif [[ ! "$BACKEND_DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "❌ Formato inválido. Use: subdominio.seudominio.com"
        elif [[ "$BACKEND_DOMAIN" == "$FRONTEND_DOMAIN" ]]; then
            echo "❌ Backend deve ser diferente do frontend. Use outro subdomínio."
        else
            echo "✅ Backend configurado: https://$BACKEND_DOMAIN"
            break
        fi
        echo ""
    done

    echo ""
    echo "Pressione ENTER para continuar..."
    read
    clear

    # Passo 3: Email
    echo "📍 PASSO 3/3 - Email para SSL"
    echo "─────────────────────────────────────"
    echo ""
    echo "Precisamos de um email válido para gerar certificados SSL gratuitos"
    echo "com Let's Encrypt. Este email será usado apenas para isso."
    echo ""
    while true; do
        read -p "📧 Digite seu email: " EMAIL
        if [[ -z "$EMAIL" ]]; then
            echo "❌ Email não pode estar vazio. Tente novamente."
        elif [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "❌ Email inválido. Use: usuario@dominio.com"
        else
            echo "✅ Email configurado: $EMAIL"
            break
        fi
        echo ""
    done

    echo ""
    echo "Pressione ENTER para revisar as configurações..."
    read
    clear
}
    
    # Confirmar informações
    echo "🎯 REVISÃO FINAL"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "📋 Suas configurações:"
    echo ""
    echo "   🌐 Frontend: https://$FRONTEND_DOMAIN"
    echo "      └─ Interface do usuário (React.js)"
    echo ""
    echo "   ⚙️  Backend:  https://$BACKEND_DOMAIN"
    echo "      └─ API do sistema (Node.js)"
    echo ""
    echo "   📧 Email:    $EMAIL"
    echo "      └─ Para certificados SSL"
    echo ""
    echo "   📁 Local:    $INSTALL_DIR"
    echo "      └─ Diretório de instalação"
    echo ""
    echo "🔧 Componentes que serão instalados:"
    echo "   • Node.js 20        (Runtime JavaScript)"
    echo "   • PostgreSQL        (Banco de dados)"
    echo "   • Redis             (Cache e filas)"
    echo "   • Nginx             (Servidor web)"
    echo "   • PM2               (Gerenciador de processos)"
    echo "   • Certbot           (Certificados SSL)"
    echo ""
    echo "⏱️  Tempo estimado: 10-15 minutos"
    echo "💾 Espaço necessário: ~2GB"
    echo ""
    echo "⚠️  IMPORTANTE: Certifique-se que os domínios estão apontados para esta VPS!"
    echo ""

    while true; do
        read -p "✅ Tudo correto? Digite 'CONFIRMAR' para iniciar: " confirmation
        if [[ "$confirmation" == "CONFIRMAR" ]]; then
            break
        elif [[ "$confirmation" == "CANCELAR" ]]; then
            error "Instalação cancelada pelo usuário"
        else
            echo "❌ Digite 'CONFIRMAR' para continuar ou 'CANCELAR' para sair"
        fi
    done

    echo ""
    echo "🚀 Iniciando instalação do Atendechat..."
    echo "   Isso pode levar alguns minutos. Não interrompa o processo!"
    echo ""
    sleep 2
}

# Atualizar sistema
update_system() {
    log "Atualizando sistema..."
    $SUDO_CMD apt update && $SUDO_CMD apt upgrade -y
}

# Instalar dependências básicas
install_dependencies() {
    log "Instalando dependências básicas..."
    $SUDO_CMD apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
}

# Instalar Node.js
install_nodejs() {
    log "Instalando Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO_CMD -E bash -
    $SUDO_CMD apt install -y nodejs
    
    # Verificar instalação
    node_version=$(node --version)
    npm_version=$(npm --version)
    log "Node.js instalado: $node_version"
    log "NPM instalado: $npm_version"
}

# Instalar PostgreSQL
install_postgresql() {
    log "Instalando PostgreSQL..."
    sudo apt install -y postgresql postgresql-contrib
    
    # Iniciar e habilitar PostgreSQL
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    log "PostgreSQL instalado e iniciado"
}

# Instalar Redis
install_redis() {
    log "Instalando Redis..."
    sudo apt install -y redis-server
    
    # Configurar Redis para iniciar automaticamente
    sudo systemctl start redis-server
    sudo systemctl enable redis-server
    
    log "Redis instalado e iniciado"
}

# Instalar Nginx
install_nginx() {
    log "Instalando Nginx..."
    sudo apt install -y nginx
    
    # Iniciar e habilitar Nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    log "Nginx instalado e iniciado"
}

# Instalar PM2
install_pm2() {
    log "Instalando PM2..."
    sudo npm install -g pm2
    
    # Configurar PM2 para iniciar automaticamente
    sudo pm2 startup
    
    log "PM2 instalado"
}

# Instalar Certbot para SSL
install_certbot() {
    log "Instalando Certbot para SSL..."
    sudo apt install -y certbot python3-certbot-nginx
    
    log "Certbot instalado"
}

# Criar usuário do sistema
create_user() {
    log "Criando usuário do sistema: $USER_NAME"
    
    if id "$USER_NAME" &>/dev/null; then
        warning "Usuário $USER_NAME já existe"
    else
        sudo useradd -m -s /bin/bash $USER_NAME
        sudo usermod -aG www-data $USER_NAME
        log "Usuário $USER_NAME criado"
    fi
}

# Configurar banco de dados
setup_database() {
    log "Configurando banco de dados PostgreSQL..."
    
    # Gerar senha aleatória para o banco
    DB_PASS=$(openssl rand -base64 32)
    
    # Criar banco e usuário
    sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
\q
EOF
    
    log "Banco de dados configurado"
    echo "DB_PASS=$DB_PASS" >> /tmp/atendechat_env
}

# Configurar Redis
setup_redis() {
    log "Configurando Redis..."
    
    # Gerar senha para Redis
    REDIS_PASS=$(openssl rand -base64 32)
    
    # Configurar senha no Redis
    echo "requirepass $REDIS_PASS" | sudo tee -a /etc/redis/redis.conf
    sudo systemctl restart redis-server
    
    log "Redis configurado com senha"
    echo "REDIS_PASS=$REDIS_PASS" >> /tmp/atendechat_env
}

# Clonar repositório
clone_repository() {
    log "Clonando repositório do GitHub..."

    # Remover diretório se existir
    if [[ -d "$INSTALL_DIR" ]]; then
        sudo rm -rf "$INSTALL_DIR"
    fi

    # Criar diretório e clonar
    sudo mkdir -p "$INSTALL_DIR"
    sudo git clone "$GITHUB_REPO" "$INSTALL_DIR"

    # Dar permissões ao usuário
    sudo chown -R $USER_NAME:$USER_NAME "$INSTALL_DIR"

    log "Repositório clonado em $INSTALL_DIR"
}

# Configurar variáveis de ambiente
setup_environment() {
    log "Configurando variáveis de ambiente..."
    
    # Ler senhas geradas
    source /tmp/atendechat_env
    
    # Gerar JWT secrets
    JWT_SECRET=$(openssl rand -base64 32)
    JWT_REFRESH_SECRET=$(openssl rand -base64 32)
    
    # Criar arquivo .env para backend
    sudo -u $USER_NAME tee "$INSTALL_DIR/backend/.env" > /dev/null << EOF
NODE_ENV=production
BACKEND_URL=https://$BACKEND_DOMAIN
FRONTEND_URL=https://$FRONTEND_DOMAIN
PROXY_PORT=443
PORT=8080

DB_DIALECT=postgres
DB_HOST=localhost
DB_PORT=5432
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME

JWT_SECRET=$JWT_SECRET
JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET

REDIS_URI=redis://:$REDIS_PASS@127.0.0.1:6379
REDIS_OPT_LIMITER_MAX=1
REDIS_OPT_LIMITER_DURATION=3000

USER_LIMIT=10000
CONNECTIONS_LIMIT=100000
CLOSED_SEND_BY_ME=true

GERENCIANET_SANDBOX=false
GERENCIANET_CLIENT_ID=
GERENCIANET_CLIENT_SECRET=
GERENCIANET_PIX_CERT=
GERENCIANET_PIX_KEY=

MAIL_HOST=smtp.gmail.com
MAIL_USER=
MAIL_PASS=
MAIL_FROM=
MAIL_PORT=465
EOF
    
    # Criar arquivo .env para frontend
    sudo -u $USER_NAME tee "$INSTALL_DIR/frontend/.env" > /dev/null << EOF
REACT_APP_BACKEND_URL=https://$BACKEND_DOMAIN
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
EOF
    
    log "Arquivos .env criados"
    
    # Limpar arquivo temporário
    rm -f /tmp/atendechat_env
}

# Função principal
main() {
    echo ""
    echo "🚀 Instalador Automático do Atendechat"
    echo "======================================"
    echo ""
    
    check_root
    check_os
    collect_info
    
    update_system
    install_dependencies
    install_nodejs
    install_postgresql
    install_redis
    install_nginx
    install_pm2
    install_certbot
    create_user
    setup_database
    setup_redis
    clone_repository
    setup_environment
    
    log "Instalação básica concluída!"
    log "Execute './install-part2.sh' para continuar com a configuração da aplicação"
}

# Executar função principal
main "$@"
