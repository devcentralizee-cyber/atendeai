#!/bin/bash

# Script de Backup do Atendechat
# Faz backup completo do sistema

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variáveis
INSTALL_DIR="/opt/atendechat"
BACKUP_BASE_DIR="/opt/backups/atendechat"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE_DIR/$DATE"
USER_NAME="atendechat"

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

# Criar diretório de backup
create_backup_dir() {
    log "Criando diretório de backup: $BACKUP_DIR"
    
    sudo mkdir -p "$BACKUP_DIR"
    sudo mkdir -p "$BACKUP_DIR/configs"
    sudo mkdir -p "$BACKUP_DIR/database"
    sudo mkdir -p "$BACKUP_DIR/files"
    sudo mkdir -p "$BACKUP_DIR/logs"
}

# Backup das configurações
backup_configs() {
    log "Fazendo backup das configurações..."
    
    # Arquivos .env
    sudo cp "$INSTALL_DIR/backend/.env" "$BACKUP_DIR/configs/backend.env"
    sudo cp "$INSTALL_DIR/frontend/.env" "$BACKUP_DIR/configs/frontend.env"
    
    # Configuração do PM2
    if [[ -f "$INSTALL_DIR/ecosystem.config.js" ]]; then
        sudo cp "$INSTALL_DIR/ecosystem.config.js" "$BACKUP_DIR/configs/"
    fi
    
    # Configuração do Nginx
    DOMAIN=$(grep "FRONTEND_URL" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2 | sed 's/https:\/\///')
    if [[ -f "/etc/nginx/sites-available/$DOMAIN" ]]; then
        sudo cp "/etc/nginx/sites-available/$DOMAIN" "$BACKUP_DIR/configs/nginx.conf"
    fi
    
    # Certificados SSL
    if [[ -d "/etc/letsencrypt/live/$DOMAIN" ]]; then
        sudo cp -r "/etc/letsencrypt/live/$DOMAIN" "$BACKUP_DIR/configs/ssl/"
    fi
    
    log "Configurações salvas"
}

# Backup do banco de dados
backup_database() {
    log "Fazendo backup do banco de dados..."
    
    # Ler configurações do banco
    DB_NAME=$(grep "DB_NAME" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
    DB_USER=$(grep "DB_USER" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
    
    # Backup completo
    sudo -u postgres pg_dump "$DB_NAME" > "$BACKUP_DIR/database/full_backup.sql"
    
    # Backup apenas da estrutura
    sudo -u postgres pg_dump --schema-only "$DB_NAME" > "$BACKUP_DIR/database/schema_only.sql"
    
    # Backup apenas dos dados
    sudo -u postgres pg_dump --data-only "$DB_NAME" > "$BACKUP_DIR/database/data_only.sql"
    
    # Informações do banco
    echo "Database: $DB_NAME" > "$BACKUP_DIR/database/info.txt"
    echo "User: $DB_USER" >> "$BACKUP_DIR/database/info.txt"
    echo "Backup Date: $(date)" >> "$BACKUP_DIR/database/info.txt"
    
    log "Backup do banco de dados concluído"
}

# Backup dos arquivos
backup_files() {
    log "Fazendo backup dos arquivos..."
    
    # Pasta public (arquivos enviados)
    if [[ -d "$INSTALL_DIR/backend/public" ]]; then
        sudo cp -r "$INSTALL_DIR/backend/public" "$BACKUP_DIR/files/"
        log "Arquivos públicos salvos"
    fi
    
    # Certificados personalizados (se houver)
    if [[ -d "$INSTALL_DIR/backend/certs" ]]; then
        sudo cp -r "$INSTALL_DIR/backend/certs" "$BACKUP_DIR/files/"
        log "Certificados salvos"
    fi
    
    log "Backup dos arquivos concluído"
}

# Backup dos logs
backup_logs() {
    log "Fazendo backup dos logs..."
    
    # Logs do PM2
    if [[ -d "$INSTALL_DIR/logs" ]]; then
        sudo cp -r "$INSTALL_DIR/logs" "$BACKUP_DIR/logs/pm2/"
    fi
    
    # Logs do Nginx
    if [[ -f "/var/log/nginx/access.log" ]]; then
        sudo cp "/var/log/nginx/access.log" "$BACKUP_DIR/logs/nginx_access.log"
    fi
    
    if [[ -f "/var/log/nginx/error.log" ]]; then
        sudo cp "/var/log/nginx/error.log" "$BACKUP_DIR/logs/nginx_error.log"
    fi
    
    # Logs do sistema
    sudo journalctl -u nginx --since "1 week ago" > "$BACKUP_DIR/logs/nginx_journal.log"
    sudo journalctl -u postgresql --since "1 week ago" > "$BACKUP_DIR/logs/postgresql_journal.log"
    sudo journalctl -u redis-server --since "1 week ago" > "$BACKUP_DIR/logs/redis_journal.log"
    
    log "Backup dos logs concluído"
}

# Criar arquivo de informações do backup
create_backup_info() {
    log "Criando arquivo de informações do backup..."
    
    cat > "$BACKUP_DIR/backup_info.txt" << EOF
Backup do Atendechat
===================

Data do Backup: $(date)
Versão do Sistema: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Usuário: $(whoami)

Diretório de Instalação: $INSTALL_DIR
Diretório de Backup: $BACKUP_DIR

Serviços:
- Node.js: $(node --version)
- NPM: $(npm --version)
- PostgreSQL: $(sudo -u postgres psql --version)
- Redis: $(redis-server --version)
- Nginx: $(nginx -v 2>&1)
- PM2: $(pm2 --version)

Status dos Serviços:
$(sudo systemctl is-active nginx postgresql redis-server)

Espaço em Disco:
$(df -h)

Tamanho do Backup:
$(du -sh $BACKUP_DIR)
EOF
    
    log "Arquivo de informações criado"
}

# Compactar backup
compress_backup() {
    log "Compactando backup..."
    
    cd "$BACKUP_BASE_DIR"
    sudo tar -czf "atendechat_backup_$DATE.tar.gz" "$DATE"
    
    # Remover diretório não compactado
    sudo rm -rf "$DATE"
    
    COMPRESSED_FILE="$BACKUP_BASE_DIR/atendechat_backup_$DATE.tar.gz"
    BACKUP_SIZE=$(du -sh "$COMPRESSED_FILE" | cut -f1)
    
    log "Backup compactado: $COMPRESSED_FILE ($BACKUP_SIZE)"
}

# Limpar backups antigos
cleanup_old_backups() {
    log "Limpando backups antigos..."
    
    # Manter apenas os 10 backups mais recentes
    cd "$BACKUP_BASE_DIR"
    ls -t atendechat_backup_*.tar.gz 2>/dev/null | tail -n +11 | sudo xargs rm -f
    
    log "Limpeza concluída"
}

# Enviar backup para armazenamento remoto (opcional)
upload_backup() {
    if [[ -n "$BACKUP_REMOTE_PATH" ]]; then
        log "Enviando backup para armazenamento remoto..."
        
        # Exemplo para rsync
        # rsync -avz "$COMPRESSED_FILE" "$BACKUP_REMOTE_PATH"
        
        # Exemplo para AWS S3
        # aws s3 cp "$COMPRESSED_FILE" "s3://seu-bucket/backups/"
        
        log "Backup enviado para armazenamento remoto"
    fi
}

# Verificar integridade do backup
verify_backup() {
    log "Verificando integridade do backup..."
    
    if [[ -f "$COMPRESSED_FILE" ]]; then
        # Testar se o arquivo tar está íntegro
        if sudo tar -tzf "$COMPRESSED_FILE" > /dev/null; then
            log "✅ Backup íntegro"
        else
            error "❌ Backup corrompido"
        fi
    else
        error "Arquivo de backup não encontrado"
    fi
}

# Backup completo
full_backup() {
    log "Iniciando backup completo do Atendechat..."
    
    check_installation
    create_backup_dir
    backup_configs
    backup_database
    backup_files
    backup_logs
    create_backup_info
    compress_backup
    verify_backup
    cleanup_old_backups
    upload_backup
    
    echo ""
    echo "🎉 Backup concluído com sucesso!"
    echo "================================"
    echo ""
    echo "📁 Arquivo: $COMPRESSED_FILE"
    echo "📊 Tamanho: $BACKUP_SIZE"
    echo "📅 Data: $(date)"
    echo ""
    echo "📋 Para restaurar:"
    echo "   1. Extrair: tar -xzf $COMPRESSED_FILE"
    echo "   2. Executar: ./restore.sh [caminho_do_backup]"
    echo ""
}

# Backup apenas do banco
database_only_backup() {
    log "Fazendo backup apenas do banco de dados..."
    
    check_installation
    sudo mkdir -p "$BACKUP_BASE_DIR"
    
    DB_NAME=$(grep "DB_NAME" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
    DB_BACKUP_FILE="$BACKUP_BASE_DIR/database_backup_$DATE.sql"
    
    sudo -u postgres pg_dump "$DB_NAME" > "$DB_BACKUP_FILE"
    
    log "Backup do banco salvo em: $DB_BACKUP_FILE"
}

# Menu de opções
show_menu() {
    echo ""
    echo "💾 Sistema de Backup do Atendechat"
    echo "=================================="
    echo ""
    echo "1. Backup completo (recomendado)"
    echo "2. Backup apenas do banco de dados"
    echo "3. Listar backups existentes"
    echo "4. Verificar último backup"
    echo "5. Limpar backups antigos"
    echo "0. Sair"
    echo ""
    
    read -p "Escolha uma opção (0-5): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            full_backup
            ;;
        2)
            database_only_backup
            ;;
        3)
            list_backups
            ;;
        4)
            verify_last_backup
            ;;
        5)
            cleanup_old_backups
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

# Listar backups
list_backups() {
    echo ""
    echo "📋 Backups disponíveis:"
    echo "======================="
    
    if [[ -d "$BACKUP_BASE_DIR" ]]; then
        ls -lah "$BACKUP_BASE_DIR"/atendechat_backup_*.tar.gz 2>/dev/null || echo "Nenhum backup encontrado"
    else
        echo "Diretório de backup não existe"
    fi
    echo ""
}

# Verificar último backup
verify_last_backup() {
    LAST_BACKUP=$(ls -t "$BACKUP_BASE_DIR"/atendechat_backup_*.tar.gz 2>/dev/null | head -n1)
    
    if [[ -n "$LAST_BACKUP" ]]; then
        log "Verificando último backup: $LAST_BACKUP"
        
        if sudo tar -tzf "$LAST_BACKUP" > /dev/null; then
            log "✅ Último backup está íntegro"
        else
            error "❌ Último backup está corrompido"
        fi
    else
        warning "Nenhum backup encontrado"
    fi
}

# Função principal
main() {
    # Criar diretório base de backups se não existir
    sudo mkdir -p "$BACKUP_BASE_DIR"
    
    if [[ $# -eq 0 ]]; then
        show_menu
    else
        case $1 in
            --full)
                full_backup
                ;;
            --database)
                database_only_backup
                ;;
            --list)
                list_backups
                ;;
            --verify)
                verify_last_backup
                ;;
            *)
                echo "Uso: $0 [--full|--database|--list|--verify]"
                exit 1
                ;;
        esac
    fi
}

# Executar função principal
main "$@"
