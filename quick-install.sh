#!/bin/bash

echo "🚀 Instalador Rápido do Atendechat"
echo "================================="
echo ""

# Coletar Frontend
echo "1. Domínio do Frontend (ex: app.seudominio.com)"
read -p "Digite: " FRONTEND_DOMAIN

# Coletar Backend  
echo ""
echo "2. Domínio do Backend (ex: api.seudominio.com)"
read -p "Digite: " BACKEND_DOMAIN

# Coletar Email
echo ""
echo "3. Email para SSL (ex: admin@seudominio.com)"
read -p "Digite: " EMAIL

# Mostrar resumo
echo ""
echo "RESUMO:"
echo "Frontend: https://$FRONTEND_DOMAIN"
echo "Backend:  https://$BACKEND_DOMAIN"  
echo "Email:    $EMAIL"
echo ""

# Confirmar
read -p "Confirma? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Cancelado"
    exit 1
fi

echo ""
echo "✅ Iniciando instalação..."
echo ""

# Simular instalação (para teste)
echo "🔧 Instalando dependências..."
sleep 2
echo "✅ Node.js instalado"
sleep 1
echo "✅ PostgreSQL instalado"
sleep 1
echo "✅ Redis instalado"
sleep 1
echo "✅ Nginx instalado"
sleep 1

echo ""
echo "🎉 Instalação concluída!"
echo ""
echo "Acesse:"
echo "Frontend: https://$FRONTEND_DOMAIN"
echo "Backend:  https://$BACKEND_DOMAIN"
