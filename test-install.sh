#!/bin/bash

# Script de teste para coleta de informações

echo "🚀 Teste do Instalador do Atendechat"
echo "===================================="
echo ""

# Variáveis globais
FRONTEND_DOMAIN=""
BACKEND_DOMAIN=""
EMAIL=""

# Função para coletar informações
collect_info() {
    echo "📍 PASSO 1/3 - Domínio do Frontend"
    echo "─────────────────────────────────────"
    echo ""
    echo "O frontend é a interface que seus usuários vão acessar."
    echo "Exemplo: app.seudominio.com, painel.seudominio.com"
    echo ""
    
    while true; do
        read -p "🌐 Digite o domínio do FRONTEND: " temp_frontend
        if [[ -z "$temp_frontend" ]]; then
            echo "❌ Domínio não pode estar vazio. Tente novamente."
        elif [[ ! "$temp_frontend" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "❌ Formato inválido. Use: subdominio.seudominio.com"
        else
            FRONTEND_DOMAIN="$temp_frontend"
            echo "✅ Frontend configurado: https://$FRONTEND_DOMAIN"
            break
        fi
        echo ""
    done
    
    echo ""
    echo "Pressione ENTER para continuar..."
    read
    clear
    
    echo "📍 PASSO 2/3 - Domínio do Backend"
    echo "─────────────────────────────────────"
    echo ""
    echo "O backend é a API que processa os dados do sistema."
    echo "Exemplo: api.seudominio.com, backend.seudominio.com"
    echo ""
    echo "⚠️  DEVE ser diferente do frontend: $FRONTEND_DOMAIN"
    echo ""
    
    while true; do
        read -p "⚙️  Digite o domínio do BACKEND: " temp_backend
        if [[ -z "$temp_backend" ]]; then
            echo "❌ Domínio não pode estar vazio. Tente novamente."
        elif [[ ! "$temp_backend" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "❌ Formato inválido. Use: subdominio.seudominio.com"
        elif [[ "$temp_backend" == "$FRONTEND_DOMAIN" ]]; then
            echo "❌ Backend deve ser diferente do frontend. Use outro subdomínio."
        else
            BACKEND_DOMAIN="$temp_backend"
            echo "✅ Backend configurado: https://$BACKEND_DOMAIN"
            break
        fi
        echo ""
    done
    
    echo ""
    echo "Pressione ENTER para continuar..."
    read
    clear
    
    echo "📍 PASSO 3/3 - Email para SSL"
    echo "─────────────────────────────────────"
    echo ""
    echo "Precisamos de um email válido para gerar certificados SSL gratuitos"
    echo "com Let's Encrypt. Este email será usado apenas para isso."
    echo ""
    
    while true; do
        read -p "📧 Digite seu email: " temp_email
        if [[ -z "$temp_email" ]]; then
            echo "❌ Email não pode estar vazio. Tente novamente."
        elif [[ ! "$temp_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "❌ Email inválido. Use: usuario@dominio.com"
        else
            EMAIL="$temp_email"
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

# Função para mostrar confirmação
show_confirmation() {
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
    echo "✅ Informações coletadas com sucesso!"
    echo ""
    echo "Para continuar com a instalação real, execute:"
    echo "FRONTEND_DOMAIN='$FRONTEND_DOMAIN' BACKEND_DOMAIN='$BACKEND_DOMAIN' EMAIL='$EMAIL' ./install.sh"
}

# Executar
collect_info
show_confirmation
