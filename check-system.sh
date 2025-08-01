#!/bin/bash

# Script de Verificação do Sistema Atendechat
# Verifica se todos os componentes estão funcionando corretamente

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

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERRO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se a instalação existe
check_installation() {
    echo "🔍 Verificando instalação..."
    echo "=========================="
    
    if [[ -d "$INSTALL_DIR" ]]; then
        success "Diretório de instalação encontrado: $INSTALL_DIR"
    else
        fail "Diretório de instalação não encontrado: $INSTALL_DIR"
        return 1
    fi
    
    if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
        success "Arquivo de configuração do backend encontrado"
    else
        fail "Arquivo de configuração do backend não encontrado"
        return 1
    fi
    
    if [[ -f "$INSTALL_DIR/frontend/.env" ]]; then
        success "Arquivo de configuração do frontend encontrado"
    else
        fail "Arquivo de configuração do frontend não encontrado"
        return 1
    fi
    
    echo ""
}

# Verificar dependências do sistema
check_system_dependencies() {
    echo "🔧 Verificando dependências do sistema..."
    echo "========================================"
    
    # Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        success "Node.js instalado: $NODE_VERSION"
    else
        fail "Node.js não está instalado"
    fi
    
    # NPM
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        success "NPM instalado: $NPM_VERSION"
    else
        fail "NPM não está instalado"
    fi
    
    # PostgreSQL
    if command -v psql &> /dev/null; then
        PG_VERSION=$(sudo -u postgres psql --version)
        success "PostgreSQL instalado: $PG_VERSION"
    else
        fail "PostgreSQL não está instalado"
    fi
    
    # Redis
    if command -v redis-server &> /dev/null; then
        REDIS_VERSION=$(redis-server --version)
        success "Redis instalado: $REDIS_VERSION"
    else
        fail "Redis não está instalado"
    fi
    
    # Nginx
    if command -v nginx &> /dev/null; then
        NGINX_VERSION=$(nginx -v 2>&1)
        success "Nginx instalado: $NGINX_VERSION"
    else
        fail "Nginx não está instalado"
    fi
    
    # PM2
    if command -v pm2 &> /dev/null; then
        PM2_VERSION=$(pm2 --version)
        success "PM2 instalado: $PM2_VERSION"
    else
        fail "PM2 não está instalado"
    fi
    
    echo ""
}

# Verificar status dos serviços
check_services_status() {
    echo "🔄 Verificando status dos serviços..."
    echo "===================================="
    
    # PostgreSQL
    if systemctl is-active --quiet postgresql; then
        success "PostgreSQL está rodando"
    else
        fail "PostgreSQL não está rodando"
    fi
    
    # Redis
    if systemctl is-active --quiet redis-server; then
        success "Redis está rodando"
    else
        fail "Redis não está rodando"
    fi
    
    # Nginx
    if systemctl is-active --quiet nginx; then
        success "Nginx está rodando"
    else
        fail "Nginx não está rodando"
    fi
    
    echo ""
}

# Verificar aplicação PM2
check_pm2_application() {
    echo "📱 Verificando aplicação PM2..."
    echo "==============================="
    
    if sudo -u $USER_NAME pm2 list | grep -q "atendechat-backend"; then
        PM2_STATUS=$(sudo -u $USER_NAME pm2 list | grep "atendechat-backend" | awk '{print $10}')
        if [[ "$PM2_STATUS" == "online" ]]; then
            success "Backend está rodando no PM2"
        else
            fail "Backend não está online no PM2 (Status: $PM2_STATUS)"
        fi
    else
        fail "Backend não encontrado no PM2"
    fi
    
    echo ""
}

# Verificar conectividade
check_connectivity() {
    echo "🌐 Verificando conectividade..."
    echo "=============================="
    
    # Backend
    if curl -f -s http://localhost:8080/api/auth/refresh > /dev/null 2>&1; then
        success "Backend está respondendo (porta 8080)"
    else
        fail "Backend não está respondendo (porta 8080)"
    fi
    
    # Frontend (se Nginx estiver configurado)
    if curl -f -s http://localhost:80 > /dev/null 2>&1; then
        success "Frontend está respondendo (porta 80)"
    else
        warning "Frontend não está respondendo (porta 80) - pode ser normal se SSL estiver configurado"
    fi
    
    # HTTPS (se configurado)
    if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
        DOMAIN=$(grep "FRONTEND_URL" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2 | sed 's/https:\/\///')
        if [[ -n "$DOMAIN" ]]; then
            if curl -f -s "https://$DOMAIN" > /dev/null 2>&1; then
                success "HTTPS está funcionando para $DOMAIN"
            else
                warning "HTTPS não está respondendo para $DOMAIN"
            fi
        fi
    fi
    
    echo ""
}

# Verificar banco de dados
check_database() {
    echo "🗄️  Verificando banco de dados..."
    echo "================================"
    
    if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
        DB_NAME=$(grep "DB_NAME" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
        DB_USER=$(grep "DB_USER" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2)
        
        # Verificar se o banco existe
        if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
            success "Banco de dados '$DB_NAME' existe"
        else
            fail "Banco de dados '$DB_NAME' não existe"
        fi
        
        # Verificar se o usuário existe
        if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
            success "Usuário do banco '$DB_USER' existe"
        else
            fail "Usuário do banco '$DB_USER' não existe"
        fi
        
        # Verificar conexão
        if sudo -u postgres psql -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
            success "Conexão com o banco de dados está funcionando"
        else
            fail "Não foi possível conectar ao banco de dados"
        fi
    fi
    
    echo ""
}

# Verificar Redis
check_redis() {
    echo "🔄 Verificando Redis..."
    echo "======================"
    
    if redis-cli ping > /dev/null 2>&1; then
        success "Redis está respondendo"
    else
        # Tentar com senha
        if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
            REDIS_PASS=$(grep "REDIS_URI" "$INSTALL_DIR/backend/.env" | cut -d':' -f3 | cut -d'@' -f1)
            if [[ -n "$REDIS_PASS" ]]; then
                if redis-cli -a "$REDIS_PASS" ping > /dev/null 2>&1; then
                    success "Redis está respondendo (com autenticação)"
                else
                    fail "Redis não está respondendo"
                fi
            else
                fail "Redis não está respondendo"
            fi
        else
            fail "Redis não está respondendo"
        fi
    fi
    
    echo ""
}

# Verificar certificados SSL
check_ssl_certificates() {
    echo "🔒 Verificando certificados SSL..."
    echo "================================="
    
    if [[ -f "$INSTALL_DIR/backend/.env" ]]; then
        DOMAIN=$(grep "FRONTEND_URL" "$INSTALL_DIR/backend/.env" | cut -d'=' -f2 | sed 's/https:\/\///')
        
        if [[ -n "$DOMAIN" ]]; then
            if [[ -d "/etc/letsencrypt/live/$DOMAIN" ]]; then
                # Verificar validade do certificado
                CERT_EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DOMAIN/cert.pem" | cut -d= -f2)
                success "Certificado SSL existe para $DOMAIN"
                info "Expira em: $CERT_EXPIRY"
                
                # Verificar se expira em menos de 30 dias
                if openssl x509 -checkend 2592000 -noout -in "/etc/letsencrypt/live/$DOMAIN/cert.pem" > /dev/null; then
                    success "Certificado SSL válido por mais de 30 dias"
                else
                    warning "Certificado SSL expira em menos de 30 dias!"
                fi
            else
                warning "Certificado SSL não encontrado para $DOMAIN"
            fi
        fi
    fi
    
    echo ""
}

# Verificar logs por erros
check_logs_for_errors() {
    echo "📋 Verificando logs por erros..."
    echo "==============================="
    
    # Logs do PM2
    if [[ -d "$INSTALL_DIR/logs" ]]; then
        ERROR_COUNT=$(grep -c "ERROR\|Error\|error" "$INSTALL_DIR/logs"/*.log 2>/dev/null | awk -F: '{sum += $2} END {print sum}' || echo "0")
        if [[ "$ERROR_COUNT" -gt 0 ]]; then
            warning "Encontrados $ERROR_COUNT erros nos logs do PM2"
        else
            success "Nenhum erro encontrado nos logs do PM2"
        fi
    fi
    
    # Logs do Nginx
    if [[ -f "/var/log/nginx/error.log" ]]; then
        NGINX_ERRORS=$(tail -n 100 /var/log/nginx/error.log | grep -c "error" || echo "0")
        if [[ "$NGINX_ERRORS" -gt 0 ]]; then
            warning "Encontrados $NGINX_ERRORS erros recentes no Nginx"
        else
            success "Nenhum erro recente no Nginx"
        fi
    fi
    
    echo ""
}

# Verificar espaço em disco
check_disk_space() {
    echo "💾 Verificando espaço em disco..."
    echo "================================"
    
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [[ "$DISK_USAGE" -lt 80 ]]; then
        success "Espaço em disco OK ($DISK_USAGE% usado)"
    elif [[ "$DISK_USAGE" -lt 90 ]]; then
        warning "Espaço em disco baixo ($DISK_USAGE% usado)"
    else
        fail "Espaço em disco crítico ($DISK_USAGE% usado)"
    fi
    
    echo ""
}

# Verificar memória
check_memory() {
    echo "🧠 Verificando uso de memória..."
    echo "==============================="
    
    MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [[ "$MEMORY_USAGE" -lt 80 ]]; then
        success "Uso de memória OK ($MEMORY_USAGE% usado)"
    elif [[ "$MEMORY_USAGE" -lt 90 ]]; then
        warning "Uso de memória alto ($MEMORY_USAGE% usado)"
    else
        fail "Uso de memória crítico ($MEMORY_USAGE% usado)"
    fi
    
    echo ""
}

# Gerar relatório de saúde
generate_health_report() {
    echo "📊 Relatório de Saúde do Sistema"
    echo "==============================="
    echo ""
    echo "Data: $(date)"
    echo "Servidor: $(hostname)"
    echo "Sistema: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Uptime: $(uptime -p)"
    echo ""
    
    # Resumo dos serviços
    echo "Status dos Serviços:"
    echo "-------------------"
    systemctl is-active postgresql && echo "✅ PostgreSQL" || echo "❌ PostgreSQL"
    systemctl is-active redis-server && echo "✅ Redis" || echo "❌ Redis"
    systemctl is-active nginx && echo "✅ Nginx" || echo "❌ Nginx"
    sudo -u $USER_NAME pm2 list | grep -q "online" && echo "✅ Backend (PM2)" || echo "❌ Backend (PM2)"
    echo ""
}

# Menu principal
show_menu() {
    echo ""
    echo "🔍 Verificador do Sistema Atendechat"
    echo "===================================="
    echo ""
    echo "1. Verificação completa"
    echo "2. Verificar apenas serviços"
    echo "3. Verificar apenas conectividade"
    echo "4. Verificar apenas banco de dados"
    echo "5. Gerar relatório de saúde"
    echo "6. Monitoramento contínuo"
    echo "0. Sair"
    echo ""
    
    read -p "Escolha uma opção (0-6): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            full_check
            ;;
        2)
            check_services_status
            check_pm2_application
            ;;
        3)
            check_connectivity
            ;;
        4)
            check_database
            check_redis
            ;;
        5)
            generate_health_report
            ;;
        6)
            continuous_monitoring
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

# Verificação completa
full_check() {
    check_installation
    check_system_dependencies
    check_services_status
    check_pm2_application
    check_connectivity
    check_database
    check_redis
    check_ssl_certificates
    check_logs_for_errors
    check_disk_space
    check_memory
    
    echo "🎯 Verificação completa finalizada!"
    echo ""
}

# Monitoramento contínuo
continuous_monitoring() {
    echo "🔄 Iniciando monitoramento contínuo (Ctrl+C para parar)..."
    echo ""
    
    while true; do
        clear
        echo "🔄 Monitoramento Contínuo - $(date)"
        echo "=================================="
        echo ""
        
        check_services_status
        check_connectivity
        check_disk_space
        check_memory
        
        sleep 30
    done
}

# Função principal
main() {
    if [[ $# -eq 0 ]]; then
        show_menu
    else
        case $1 in
            --full)
                full_check
                ;;
            --services)
                check_services_status
                check_pm2_application
                ;;
            --connectivity)
                check_connectivity
                ;;
            --database)
                check_database
                check_redis
                ;;
            --report)
                generate_health_report
                ;;
            *)
                echo "Uso: $0 [--full|--services|--connectivity|--database|--report]"
                exit 1
                ;;
        esac
    fi
}

# Executar função principal
main "$@"
