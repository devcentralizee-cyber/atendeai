#!/bin/bash

# Script de Desinstalação do Atendechat
# Remove completamente o sistema

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
BACKUP_DIR="/opt/atendechat-uninstall-backup-$(date +%Y%m%d_%H%M%S)"

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

# Confirmação do usuário
confirm_uninstall() {
    echo ""
    echo "⚠️  ATENÇÃO: DESINSTALAÇÃO DO ATENDECHAT"
    echo "========================================"
    echo ""
    echo "Esta ação irá:"
    echo "❌ Remover completamente o Atendechat"
    echo "❌ Parar todos os serviços"
    echo "❌ Remover banco de dados"
    echo "❌ Remover arquivos de configuração"
    echo "❌ Remover certificados SSL"
    echo ""
    echo "💾 Um backup será criado em: $BACKUP_DIR"
    echo ""
    
    read -p "❓ Tem certeza que deseja continuar? Digite 'CONFIRMAR' para prosseguir: " confirmation
    
    if [[ "$confirmation" != "CONFIRMAR" ]]; then
        echo "❌ Desinstalação cancelada"
        exit 0
    fi
    
    echo ""
    read -p "❓ Deseja manter o backup após a desinstalação? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        REMOVE_BACKUP=true
    else
        REMOVE_BACKUP=false
    fi
}

# Fazer backup antes da desinstalação
create_backup() {
    log "Criando backup antes da desinstalação..."
    
    if [[ -f "./backup.sh" ]]; then
        ./backup.sh --full
        log "Backup automático criado"
    else
        # Backup manual básico
        sudo mkdir -p "$BACKUP_DIR"
        
        if [[ -d "$INSTALL_DIR" ]]; then
            sudo cp -r "$INSTALL_DIR" "$BACKUP_DIR/"
        fi
        
        # Backup do banco
        if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
            DB_NAME=$(grep "DB_NAME" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
            if [[ -n "$DB_NAME" ]]; then
                sudo -u postgres pg_dump "$DB_NAME" > "$BACKUP_DIR/database.sql" 2>/dev/null || true
            fi
        fi
        
        log "Backup manual criado em: $BACKUP_DIR"
    fi
}

# Parar serviços
stop_services() {
    log "Parando serviços do Atendechat..."
    
    # Parar PM2
    if command -v pm2 &> /dev/null; then
        sudo -u $USER_NAME pm2 stop all 2>/dev/null || true
        sudo -u $USER_NAME pm2 delete all 2>/dev/null || true
    fi
    
    log "Serviços parados"
}

# Remover configurações do Nginx
remove_nginx_config() {
    log "Removendo configurações do Nginx..."
    
    if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
        DOMAIN=$(grep "FRONTEND_URL" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2 | sed 's/https:\/\///')
        
        # Remover configuração do site
        if [[ -f "/etc/nginx/sites-available/$DOMAIN" ]]; then
            sudo rm -f "/etc/nginx/sites-available/$DOMAIN"
        fi
        
        if [[ -f "/etc/nginx/sites-enabled/$DOMAIN" ]]; then
            sudo rm -f "/etc/nginx/sites-enabled/$DOMAIN"
        fi
        
        # Recarregar Nginx
        sudo systemctl reload nginx 2>/dev/null || true
        
        log "Configurações do Nginx removidas"
    fi
}

# Remover certificados SSL
remove_ssl_certificates() {
    log "Removendo certificados SSL..."
    
    if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
        DOMAIN=$(grep "FRONTEND_URL" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2 | sed 's/https:\/\///')
        
        if [[ -d "/etc/letsencrypt/live/$DOMAIN" ]]; then
            sudo certbot delete --cert-name "$DOMAIN" --non-interactive 2>/dev/null || true
            log "Certificados SSL removidos"
        fi
    fi
}

# Remover banco de dados
remove_database() {
    log "Removendo banco de dados..."
    
    if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
        DB_NAME=$(grep "DB_NAME" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
        DB_USER=$(grep "DB_USER" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
        
        if [[ -n "$DB_NAME" ]]; then
            # Remover banco
            sudo -u postgres dropdb "$DB_NAME" 2>/dev/null || true
            
            # Remover usuário
            if [[ -n "$DB_USER" ]]; then
                sudo -u postgres dropuser "$DB_USER" 2>/dev/null || true
            fi
            
            log "Banco de dados removido"
        fi
    fi
}

# Remover usuário do sistema
remove_system_user() {
    log "Removendo usuário do sistema..."
    
    if id "$USER_NAME" &>/dev/null; then
        sudo userdel -r "$USER_NAME" 2>/dev/null || true
        log "Usuário $USER_NAME removido"
    fi
}

# Remover arquivos da aplicação
remove_application_files() {
    log "Removendo arquivos da aplicação..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        sudo rm -rf "$INSTALL_DIR"
        log "Diretório $INSTALL_DIR removido"
    fi
}

# Remover scripts de gerenciamento
remove_management_scripts() {
    log "Removendo scripts de gerenciamento..."
    
    sudo rm -f /usr/local/bin/atendechat-*
    
    log "Scripts de gerenciamento removidos"
}

# Limpar configurações do PM2
cleanup_pm2() {
    log "Limpando configurações do PM2..."
    
    # Remover PM2 startup
    sudo pm2 unstartup systemd 2>/dev/null || true
    
    log "Configurações do PM2 limpas"
}

# Remover dependências (opcional)
remove_dependencies() {
    echo ""
    read -p "❓ Deseja remover as dependências instaladas (Node.js, PostgreSQL, Redis, Nginx)? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removendo dependências..."
        
        # Parar serviços
        sudo systemctl stop postgresql redis-server nginx 2>/dev/null || true
        
        # Remover pacotes
        sudo apt remove --purge -y nodejs postgresql postgresql-contrib redis-server nginx 2>/dev/null || true
        sudo apt autoremove -y 2>/dev/null || true
        
        # Remover PM2 globalmente
        sudo npm uninstall -g pm2 2>/dev/null || true
        
        log "Dependências removidas"
    else
        log "Dependências mantidas"
    fi
}

# Limpar regras do firewall
cleanup_firewall() {
    log "Limpando regras do firewall..."
    
    # Remover regras específicas do Atendechat
    sudo ufw delete allow 80/tcp 2>/dev/null || true
    sudo ufw delete allow 443/tcp 2>/dev/null || true
    
    log "Regras do firewall limpas"
}

# Remover backup se solicitado
cleanup_backup() {
    if [[ "$REMOVE_BACKUP" == "true" ]]; then
        log "Removendo backup..."
        sudo rm -rf "$BACKUP_DIR"
        log "Backup removido"
    fi
}

# Mostrar resumo final
show_summary() {
    echo ""
    echo "🎯 Desinstalação concluída!"
    echo "=========================="
    echo ""
    
    if [[ "$REMOVE_BACKUP" != "true" ]]; then
        echo "💾 Backup salvo em: $BACKUP_DIR"
        echo ""
    fi
    
    echo "✅ Itens removidos:"
    echo "   - Aplicação Atendechat"
    echo "   - Banco de dados"
    echo "   - Usuário do sistema"
    echo "   - Configurações do Nginx"
    echo "   - Certificados SSL"
    echo "   - Scripts de gerenciamento"
    echo ""
    
    echo "ℹ️  Itens que podem ter sido mantidos:"
    echo "   - Node.js, PostgreSQL, Redis, Nginx (se escolheu manter)"
    echo "   - Logs do sistema"
    echo "   - Configurações globais do sistema"
    echo ""
    
    echo "🔄 Para reinstalar:"
    echo "   curl -fsSL https://raw.githubusercontent.com/SEU_USUARIO/atendechat/main/install.sh | bash"
    echo ""
}

# Função principal
main() {
    echo ""
    echo "🗑️  Desinstalador do Atendechat"
    echo "=============================="
    echo ""
    
    confirm_uninstall
    create_backup
    stop_services
    remove_nginx_config
    remove_ssl_certificates
    remove_database
    remove_system_user
    remove_application_files
    remove_management_scripts
    cleanup_pm2
    cleanup_firewall
    remove_dependencies
    cleanup_backup
    show_summary
}

# Executar função principal
main "$@"
