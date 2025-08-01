#!/bin/bash

# Script de Atualização do Atendechat
# Atualiza o sistema mantendo as configurações

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
BACKUP_DIR="/opt/atendechat-backup-$(date +%Y%m%d_%H%M%S)"

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

# Verificar se a instalação existe
check_installation() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        error "Atendechat não está instalado em $INSTALL_DIR"
    fi
    
    if [[ ! -f "$INSTALL_DIR/backend/.env" ]]; then
        error "Arquivo de configuração não encontrado"
    fi
    
    log "Instalação encontrada em $INSTALL_DIR"
}

# Fazer backup das configurações
backup_configs() {
    log "Fazendo backup das configurações..."
    
    sudo mkdir -p "$BACKUP_DIR"
    
    # Backup dos arquivos .env
    sudo cp "$INSTALL_DIR/backend/.env" "$BACKUP_DIR/backend.env"
    sudo cp "$INSTALL_DIR/frontend/.env" "$BACKUP_DIR/frontend.env"
    
    # Backup da pasta public (arquivos enviados)
    if [[ -d "$INSTALL_DIR/backend/public" ]]; then
        sudo cp -r "$INSTALL_DIR/backend/public" "$BACKUP_DIR/"
    fi
    
    # Backup do banco de dados
    DB_NAME=$(grep "DB_NAME" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
    DB_USER=$(grep "DB_USER" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
    
    sudo -u postgres pg_dump "$DB_NAME" > "$BACKUP_DIR/database.sql"
    
    log "Backup criado em: $BACKUP_DIR"
}

# Parar serviços
stop_services() {
    log "Parando serviços..."
    
    # Parar PM2
    sudo -u $USER_NAME pm2 stop all || true
    
    log "Serviços parados"
}

# Atualizar código
update_code() {
    log "Atualizando código do GitHub..."
    
    cd "$INSTALL_DIR"
    
    # Fazer stash das mudanças locais
    sudo -u $USER_NAME git stash
    
    # Atualizar código
    sudo -u $USER_NAME git pull origin main
    
    log "Código atualizado"
}

# Restaurar configurações
restore_configs() {
    log "Restaurando configurações..."
    
    # Restaurar arquivos .env
    sudo cp "$BACKUP_DIR/backend.env" "$INSTALL_DIR/backend/.env"
    sudo cp "$BACKUP_DIR/frontend.env" "$INSTALL_DIR/frontend/.env"
    
    # Restaurar pasta public se não existir
    if [[ ! -d "$INSTALL_DIR/backend/public" && -d "$BACKUP_DIR/public" ]]; then
        sudo cp -r "$BACKUP_DIR/public" "$INSTALL_DIR/backend/"
    fi
    
    # Ajustar permissões
    sudo chown -R $USER_NAME:$USER_NAME "$INSTALL_DIR"
    
    log "Configurações restauradas"
}

# Atualizar dependências
update_dependencies() {
    log "Atualizando dependências..."
    
    # Backend
    cd "$INSTALL_DIR/backend"
    sudo -u $USER_NAME npm install --force
    
    # Frontend
    cd "$INSTALL_DIR/frontend"
    sudo -u $USER_NAME npm install --force
    
    log "Dependências atualizadas"
}

# Fazer build
build_application() {
    log "Fazendo build da aplicação..."
    
    # Build do backend
    cd "$INSTALL_DIR/backend"
    sudo -u $USER_NAME npm run build
    
    # Build do frontend
    cd "$INSTALL_DIR/frontend"
    sudo -u $USER_NAME npm run build
    
    log "Build concluído"
}

# Executar migrações
run_migrations() {
    log "Executando migrações do banco..."
    
    cd "$INSTALL_DIR/backend"
    sudo -u $USER_NAME npm run db:migrate
    
    log "Migrações executadas"
}

# Iniciar serviços
start_services() {
    log "Iniciando serviços..."
    
    # Iniciar PM2
    cd "$INSTALL_DIR"
    sudo -u $USER_NAME pm2 start ecosystem.config.js
    
    # Recarregar Nginx
    sudo systemctl reload nginx
    
    log "Serviços iniciados"
}

# Verificar saúde da aplicação
health_check() {
    log "Verificando saúde da aplicação..."
    
    sleep 10
    
    # Verificar se o backend está respondendo
    if curl -f -s http://localhost:8080/api/auth/refresh > /dev/null; then
        log "✅ Backend está funcionando"
    else
        warning "❌ Backend não está respondendo"
    fi
    
    # Verificar PM2
    sudo -u $USER_NAME pm2 list
}

# Limpar backups antigos (manter apenas os 5 mais recentes)
cleanup_old_backups() {
    log "Limpando backups antigos..."
    
    # Manter apenas os 5 backups mais recentes
    ls -dt /opt/atendechat-backup-* 2>/dev/null | tail -n +6 | sudo xargs rm -rf
    
    log "Limpeza concluída"
}

# Menu de opções
show_menu() {
    echo ""
    echo "🔄 Atualizador do Atendechat"
    echo "============================"
    echo ""
    echo "1. Atualização completa (recomendado)"
    echo "2. Apenas atualizar código"
    echo "3. Apenas executar migrações"
    echo "4. Restaurar backup"
    echo "5. Ver logs"
    echo "0. Sair"
    echo ""
    
    read -p "Escolha uma opção (0-5): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            full_update
            ;;
        2)
            code_only_update
            ;;
        3)
            migrations_only
            ;;
        4)
            restore_backup
            ;;
        5)
            show_logs
            ;;
        0)
            echo "👋 Saindo..."
            exit 0
            ;;
        *)
            error "Opção inválida"
            ;;
    esac
}

# Atualização completa
full_update() {
    log "Iniciando atualização completa..."
    
    check_installation
    backup_configs
    stop_services
    update_code
    restore_configs
    update_dependencies
    build_application
    run_migrations
    start_services
    health_check
    cleanup_old_backups
    
    echo ""
    echo "🎉 Atualização concluída com sucesso!"
    echo "====================================="
    echo ""
    echo "📋 Backup salvo em: $BACKUP_DIR"
    echo "📊 Status: atendechat-status"
    echo "📋 Logs: atendechat-logs"
    echo ""
}

# Atualização apenas do código
code_only_update() {
    log "Atualizando apenas o código..."
    
    check_installation
    stop_services
    update_code
    start_services
    health_check
    
    log "Código atualizado"
}

# Apenas migrações
migrations_only() {
    log "Executando apenas migrações..."
    
    check_installation
    run_migrations
    
    log "Migrações executadas"
}

# Restaurar backup
restore_backup() {
    echo "📋 Backups disponíveis:"
    ls -la /opt/atendechat-backup-* 2>/dev/null || echo "Nenhum backup encontrado"
    echo ""
    
    read -p "Digite o caminho completo do backup para restaurar: " backup_path
    
    if [[ ! -d "$backup_path" ]]; then
        error "Backup não encontrado: $backup_path"
    fi
    
    log "Restaurando backup de: $backup_path"
    
    stop_services
    
    # Restaurar configurações
    sudo cp "$backup_path/backend.env" "$INSTALL_DIR/backend/.env"
    sudo cp "$backup_path/frontend.env" "$INSTALL_DIR/frontend/.env"
    
    # Restaurar banco de dados
    if [[ -f "$backup_path/database.sql" ]]; then
        DB_NAME=$(grep "DB_NAME" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
        sudo -u postgres psql "$DB_NAME" < "$backup_path/database.sql"
    fi
    
    start_services
    
    log "Backup restaurado"
}

# Mostrar logs
show_logs() {
    sudo -u $USER_NAME pm2 logs --lines 100
}

# Função principal
main() {
    if [[ $# -eq 0 ]]; then
        show_menu
    else
        case $1 in
            --full)
                full_update
                ;;
            --code-only)
                code_only_update
                ;;
            --migrations)
                migrations_only
                ;;
            *)
                echo "Uso: $0 [--full|--code-only|--migrations]"
                exit 1
                ;;
        esac
    fi
}

# Executar função principal
main "$@"
