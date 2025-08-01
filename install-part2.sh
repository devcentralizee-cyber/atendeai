#!/bin/bash

# Script de Instalação do Atendechat - Parte 2
# Configuração da aplicação

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variáveis
INSTALL_DIR="/opt/atendechat"
USER_NAME="atendechat"
DOMAIN=""

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

# Ler domínio do arquivo .env
get_domain() {
    if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
        DOMAIN=$(grep "FRONTEND_URL" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2 | sed 's/https:\/\///')
        EMAIL=$(grep "MAIL_USER" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
        if [[ -z "$EMAIL" ]]; then
            # Se não tiver email configurado, pedir para o usuário
            read -p "📧 Digite seu email para certificado SSL: " EMAIL
        fi
    else
        error "Arquivo .env não encontrado. Execute install.sh primeiro."
    fi
}

# Instalar dependências do backend
install_backend_deps() {
    log "Instalando dependências do backend..."
    
    cd "$INSTALL_DIR/backend"
    sudo -u $USER_NAME npm install --force
    
    log "Dependências do backend instaladas"
}

# Instalar dependências do frontend
install_frontend_deps() {
    log "Instalando dependências do frontend..."
    
    cd "$INSTALL_DIR/frontend"
    sudo -u $USER_NAME npm install --force
    
    log "Dependências do frontend instaladas"
}

# Build do backend
build_backend() {
    log "Fazendo build do backend..."
    
    cd "$INSTALL_DIR/backend"
    sudo -u $USER_NAME npm run build
    
    log "Build do backend concluído"
}

# Build do frontend
build_frontend() {
    log "Fazendo build do frontend..."
    
    cd "$INSTALL_DIR/frontend"
    sudo -u $USER_NAME npm run build
    
    log "Build do frontend concluído"
}

# Executar migrações do banco
run_migrations() {
    log "Executando migrações do banco de dados..."
    
    cd "$INSTALL_DIR/backend"
    sudo -u $USER_NAME npm run db:migrate
    sudo -u $USER_NAME npm run db:seed
    
    log "Migrações executadas com sucesso"
}

# Configurar Nginx
setup_nginx() {
    log "Configurando Nginx..."
    
    # Criar configuração do site
    sudo tee "/etc/nginx/sites-available/$DOMAIN" > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # Redirecionar para HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # Certificados SSL (serão configurados pelo Certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Configurações SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Configuração para arquivos estáticos do frontend
    location / {
        root $INSTALL_DIR/frontend/build;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
        
        # Cache para assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Proxy para API do backend
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # WebSocket para Socket.IO
    location /socket.io/ {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Arquivos públicos do backend
    location /public/ {
        alias $INSTALL_DIR/backend/public/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
EOF
    
    # Habilitar site
    sudo ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/"
    
    # Remover site padrão
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Testar configuração
    sudo nginx -t
    
    log "Nginx configurado"
}

# Configurar SSL com Let's Encrypt
setup_ssl() {
    log "Configurando SSL com Let's Encrypt..."
    
    # Obter certificado SSL
    sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect
    
    # Configurar renovação automática
    sudo systemctl enable certbot.timer
    
    log "SSL configurado com sucesso"
}

# Configurar PM2
setup_pm2() {
    log "Configurando PM2..."
    
    # Criar arquivo de configuração do PM2
    sudo -u $USER_NAME tee "$INSTALL_DIR/ecosystem.config.js" > /dev/null << EOF
module.exports = {
  apps: [
    {
      name: 'atendechat-backend',
      cwd: '$INSTALL_DIR/backend',
      script: 'dist/server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 8080
      },
      error_file: '$INSTALL_DIR/logs/backend-error.log',
      out_file: '$INSTALL_DIR/logs/backend-out.log',
      log_file: '$INSTALL_DIR/logs/backend.log',
      time: true,
      max_restarts: 10,
      min_uptime: '10s',
      max_memory_restart: '1G'
    }
  ]
};
EOF
    
    # Criar diretório de logs
    sudo -u $USER_NAME mkdir -p "$INSTALL_DIR/logs"
    
    # Iniciar aplicação com PM2
    cd "$INSTALL_DIR"
    sudo -u $USER_NAME pm2 start ecosystem.config.js
    sudo -u $USER_NAME pm2 save
    
    log "PM2 configurado e aplicação iniciada"
}

# Configurar firewall
setup_firewall() {
    log "Configurando firewall..."
    
    # Habilitar UFW
    sudo ufw --force enable
    
    # Configurar regras básicas
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Permitir SSH, HTTP e HTTPS
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Mostrar status
    sudo ufw status
    
    log "Firewall configurado"
}

# Criar scripts de gerenciamento
create_management_scripts() {
    log "Criando scripts de gerenciamento..."
    
    # Script de status
    sudo tee "/usr/local/bin/atendechat-status" > /dev/null << 'EOF'
#!/bin/bash
echo "=== Status do Atendechat ==="
echo ""
echo "🔧 Backend (PM2):"
sudo -u atendechat pm2 list
echo ""
echo "🌐 Nginx:"
sudo systemctl status nginx --no-pager -l
echo ""
echo "🗄️  PostgreSQL:"
sudo systemctl status postgresql --no-pager -l
echo ""
echo "🔄 Redis:"
sudo systemctl status redis-server --no-pager -l
EOF
    
    # Script de restart
    sudo tee "/usr/local/bin/atendechat-restart" > /dev/null << 'EOF'
#!/bin/bash
echo "🔄 Reiniciando Atendechat..."
sudo -u atendechat pm2 restart all
sudo systemctl restart nginx
echo "✅ Atendechat reiniciado"
EOF
    
    # Script de logs
    sudo tee "/usr/local/bin/atendechat-logs" > /dev/null << 'EOF'
#!/bin/bash
echo "📋 Logs do Atendechat:"
sudo -u atendechat pm2 logs --lines 50
EOF
    
    # Tornar scripts executáveis
    sudo chmod +x /usr/local/bin/atendechat-*
    
    log "Scripts de gerenciamento criados"
}

# Função principal
main() {
    echo ""
    echo "🚀 Instalador do Atendechat - Parte 2"
    echo "====================================="
    echo ""
    
    get_domain
    
    log "Configurando aplicação para domínio: $DOMAIN"
    
    install_backend_deps
    install_frontend_deps
    build_backend
    build_frontend
    run_migrations
    setup_nginx
    setup_ssl
    setup_pm2
    setup_firewall
    create_management_scripts
    
    echo ""
    echo "🎉 Instalação concluída com sucesso!"
    echo "===================================="
    echo ""
    echo "✅ Atendechat instalado e rodando em: https://$DOMAIN"
    echo ""
    echo "📋 Comandos úteis:"
    echo "   Status:    atendechat-status"
    echo "   Reiniciar: atendechat-restart"
    echo "   Logs:      atendechat-logs"
    echo ""
    echo "🔧 Próximos passos:"
    echo "   1. Acesse https://$DOMAIN"
    echo "   2. Faça o primeiro login"
    echo "   3. Configure as integrações WhatsApp"
    echo "   4. Configure email no arquivo: $INSTALL_DIR/backend/.env"
    echo ""
    echo "📞 Suporte: https://atendechat.com"
    echo ""
}

# Executar função principal
main "$@"
