#!/bin/bash

# Script Simples de Instalação do Atendechat
set -e

echo "🚀 Instalador do Atendechat"
echo "=========================="
echo ""

# Função para coletar informações
collect_info() {
    echo "Vamos coletar as informações necessárias:"
    echo ""
    
    # Frontend
    echo "1. DOMÍNIO DO FRONTEND"
    echo "   Exemplo: app.seudominio.com"
    while true; do
        read -p "   Digite: " FRONTEND_DOMAIN
        if [[ -n "$FRONTEND_DOMAIN" ]]; then
            echo "   ✅ Frontend: https://$FRONTEND_DOMAIN"
            break
        fi
        echo "   ❌ Digite um domínio válido"
    done
    
    echo ""
    
    # Backend  
    echo "2. DOMÍNIO DO BACKEND"
    echo "   Exemplo: api.seudominio.com"
    while true; do
        read -p "   Digite: " BACKEND_DOMAIN
        if [[ -n "$BACKEND_DOMAIN" && "$BACKEND_DOMAIN" != "$FRONTEND_DOMAIN" ]]; then
            echo "   ✅ Backend: https://$BACKEND_DOMAIN"
            break
        fi
        echo "   ❌ Digite um domínio válido e diferente do frontend"
    done
    
    echo ""
    
    # Email
    echo "3. EMAIL PARA SSL"
    echo "   Exemplo: admin@seudominio.com"
    while true; do
        read -p "   Digite: " EMAIL
        if [[ -n "$EMAIL" ]]; then
            echo "   ✅ Email: $EMAIL"
            break
        fi
        echo "   ❌ Digite um email válido"
    done
    
    echo ""
    echo "RESUMO:"
    echo "Frontend: https://$FRONTEND_DOMAIN"
    echo "Backend:  https://$BACKEND_DOMAIN"
    echo "Email:    $EMAIL"
    echo ""
    
    read -p "Confirma? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Cancelado"
        exit 1
    fi
    
    # Exportar variáveis
    export FRONTEND_DOMAIN
    export BACKEND_DOMAIN  
    export EMAIL
    
    echo "✅ Informações coletadas!"
}

# Executar coleta
collect_info

echo ""
echo "🚀 Baixando e executando instalador principal..."
echo ""

# Baixar e executar o instalador principal com as variáveis
curl -fsSL https://raw.githubusercontent.com/devcentralizee-cyber/atendeai/main/install.sh | \
FRONTEND_DOMAIN="$FRONTEND_DOMAIN" \
BACKEND_DOMAIN="$BACKEND_DOMAIN" \
EMAIL="$EMAIL" \
bash
