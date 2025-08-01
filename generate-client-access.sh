#!/bin/bash

# Script para Gerar Acesso de Cliente
# Cria tokens temporários para instalação

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Gerar token temporário
generate_temp_token() {
    echo ""
    echo "🔑 Gerador de Token de Acesso para Cliente"
    echo "=========================================="
    echo ""
    
    # Informações do cliente
    read -p "📝 Nome do cliente: " CLIENT_NAME
    read -p "📧 Email do cliente: " CLIENT_EMAIL
    read -p "🏢 Empresa: " CLIENT_COMPANY
    
    # Gerar token único
    TOKEN=$(openssl rand -hex 32)
    
    # Data de expiração (7 dias)
    EXPIRY_DATE=$(date -d "+7 days" +"%Y-%m-%d")
    
    echo ""
    echo "✅ Token gerado com sucesso!"
    echo "=========================="
    echo ""
    echo "👤 Cliente: $CLIENT_NAME"
    echo "🏢 Empresa: $CLIENT_COMPANY"
    echo "📧 Email: $CLIENT_EMAIL"
    echo "🔑 Token: $TOKEN"
    echo "📅 Expira em: $EXPIRY_DATE"
    echo ""
    
    # Salvar informações
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$CLIENT_NAME,$CLIENT_EMAIL,$CLIENT_COMPANY,$TOKEN,$EXPIRY_DATE" >> client_tokens.csv
    
    echo "💾 Informações salvas em: client_tokens.csv"
    echo ""
    
    # Instruções para o cliente
    echo "📋 INSTRUÇÕES PARA O CLIENTE:"
    echo "============================"
    echo ""
    echo "Envie as seguintes instruções para $CLIENT_NAME:"
    echo ""
    echo "---"
    echo "🚀 INSTALAÇÃO DO ATENDECHAT"
    echo ""
    echo "1. Acesse sua VPS via SSH"
    echo "2. Execute o comando:"
    echo ""
    echo "   curl -fsSL https://raw.githubusercontent.com/vitor/atendeaibase/main/install.sh | bash"
    echo ""
    echo "3. Quando solicitado, use este token:"
    echo "   $TOKEN"
    echo ""
    echo "4. O token expira em: $EXPIRY_DATE"
    echo ""
    echo "📞 Suporte: suporte@atendechat.com"
    echo "---"
    echo ""
}

# Listar tokens ativos
list_active_tokens() {
    echo ""
    echo "📋 Tokens Ativos"
    echo "================"
    echo ""
    
    if [[ -f "client_tokens.csv" ]]; then
        echo "Data,Cliente,Email,Empresa,Token,Expira"
        echo "----------------------------------------"
        
        while IFS=',' read -r date client email company token expiry; do
            # Verificar se não expirou
            if [[ $(date -d "$expiry" +%s) -gt $(date +%s) ]]; then
                echo "$date,$client,$email,$company,${token:0:8}...,$expiry"
            fi
        done < client_tokens.csv
    else
        echo "Nenhum token encontrado."
    fi
    echo ""
}

# Revogar token
revoke_token() {
    echo ""
    echo "🚫 Revogar Token"
    echo "================"
    echo ""
    
    if [[ ! -f "client_tokens.csv" ]]; then
        error "Arquivo de tokens não encontrado."
    fi
    
    list_active_tokens
    
    read -p "Digite o email do cliente para revogar: " email_to_revoke
    
    # Criar arquivo temporário sem o token
    grep -v "$email_to_revoke" client_tokens.csv > temp_tokens.csv || true
    mv temp_tokens.csv client_tokens.csv
    
    log "Token revogado para: $email_to_revoke"
}

# Limpar tokens expirados
cleanup_expired_tokens() {
    echo ""
    echo "🧹 Limpando Tokens Expirados"
    echo "============================"
    echo ""
    
    if [[ ! -f "client_tokens.csv" ]]; then
        warning "Arquivo de tokens não encontrado."
        return
    fi
    
    # Criar arquivo temporário apenas com tokens válidos
    temp_file=$(mktemp)
    
    while IFS=',' read -r date client email company token expiry; do
        # Manter apenas tokens não expirados
        if [[ $(date -d "$expiry" +%s) -gt $(date +%s) ]]; then
            echo "$date,$client,$email,$company,$token,$expiry" >> "$temp_file"
        fi
    done < client_tokens.csv
    
    mv "$temp_file" client_tokens.csv
    
    log "Tokens expirados removidos."
}

# Gerar comando de instalação personalizado
generate_install_command() {
    echo ""
    echo "📦 Gerador de Comando de Instalação"
    echo "==================================="
    echo ""
    
    read -p "📝 Nome do cliente: " CLIENT_NAME
    read -p "🔑 Token do cliente: " CLIENT_TOKEN
    
    echo ""
    echo "📋 Comando personalizado para $CLIENT_NAME:"
    echo "==========================================="
    echo ""
    echo "# Instalação do Atendechat"
    echo "# Cliente: $CLIENT_NAME"
    echo "# Data: $(date)"
    echo ""
    echo "curl -fsSL https://raw.githubusercontent.com/vitor/atendeaibase/main/install.sh | bash"
    echo ""
    echo "# Quando solicitado, use o token: $CLIENT_TOKEN"
    echo ""
}

# Menu principal
show_menu() {
    echo ""
    echo "🔐 Gerenciador de Acesso de Clientes"
    echo "===================================="
    echo ""
    echo "1. Gerar novo token para cliente"
    echo "2. Listar tokens ativos"
    echo "3. Revogar token"
    echo "4. Limpar tokens expirados"
    echo "5. Gerar comando de instalação"
    echo "0. Sair"
    echo ""
    
    read -p "Escolha uma opção (0-5): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            generate_temp_token
            ;;
        2)
            list_active_tokens
            ;;
        3)
            revoke_token
            ;;
        4)
            cleanup_expired_tokens
            ;;
        5)
            generate_install_command
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

# Criar cabeçalho do CSV se não existir
initialize_csv() {
    if [[ ! -f "client_tokens.csv" ]]; then
        echo "Data,Cliente,Email,Empresa,Token,Expira" > client_tokens.csv
    fi
}

# Função principal
main() {
    initialize_csv
    
    if [[ $# -eq 0 ]]; then
        show_menu
    else
        case $1 in
            --generate)
                generate_temp_token
                ;;
            --list)
                list_active_tokens
                ;;
            --cleanup)
                cleanup_expired_tokens
                ;;
            *)
                echo "Uso: $0 [--generate|--list|--cleanup]"
                exit 1
                ;;
        esac
    fi
}

# Executar função principal
main "$@"
