#!/bin/bash

# Script de Auto-Atualização do Centralizee
# Este script puxa automaticamente as atualizações do repositório

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretório do projeto
PROJECT_DIR="/opt/atendechat"

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

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    error "Este script deve ser executado como root (sudo)"
fi

log "🚀 Iniciando auto-atualização do Centralizee..."

# Navegar para o diretório do projeto
cd $PROJECT_DIR || error "Diretório $PROJECT_DIR não encontrado"

# Fazer backup das configurações importantes
log "📦 Fazendo backup das configurações..."
cp backend/.env backend/.env.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
cp frontend/.env frontend/.env.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Verificar se há mudanças locais
if ! git diff --quiet; then
    warning "Há mudanças locais não commitadas. Fazendo stash..."
    git stash push -m "Auto-backup antes da atualização $(date)"
fi

# Puxar as atualizações
log "⬇️ Baixando atualizações do repositório..."
git fetch origin
git reset --hard origin/main

# Atualizar dependências do backend se necessário
if [ -f "backend/package.json" ]; then
    log "📦 Verificando dependências do backend..."
    cd backend
    npm install --production
    cd ..
fi

# Rebuild do frontend
log "🔨 Reconstruindo frontend com as novas atualizações..."
cd frontend
npm install --production
npm run build
cd ..

# Verificar se o build foi bem-sucedido
if [ ! -d "frontend/build" ]; then
    error "Falha no build do frontend"
fi

# Restart dos serviços
log "🔄 Reiniciando serviços..."

# Tentar diferentes métodos de restart
if command -v docker-compose &> /dev/null; then
    log "Usando Docker Compose..."
    docker-compose restart
elif command -v pm2 &> /dev/null; then
    log "Usando PM2..."
    pm2 restart all
elif systemctl is-active --quiet atendechat-frontend; then
    log "Usando Systemctl..."
    systemctl restart atendechat-frontend
    systemctl restart atendechat-backend
else
    warning "Método de restart não identificado. Reinicie manualmente os serviços."
fi

# Reload do Nginx se estiver rodando
if systemctl is-active --quiet nginx; then
    log "🔄 Recarregando Nginx..."
    nginx -s reload
fi

# Limpar cache se necessário
log "🧹 Limpando cache..."
rm -rf frontend/node_modules/.cache 2>/dev/null || true

log "✅ Atualização concluída com sucesso!"
log "🌐 Acesse seu sistema e force refresh (Ctrl+F5) para ver as mudanças"

# Mostrar informações úteis
info "📋 Informações da atualização:"
info "   - Data: $(date)"
info "   - Commit atual: $(git rev-parse --short HEAD)"
info "   - Branch: $(git branch --show-current)"

log "🎉 Sistema atualizado e rodando com as novas cores azuis!"
