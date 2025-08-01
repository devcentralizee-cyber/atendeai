#!/bin/bash

# Script de deploy para EasyPanel
# Atendechat Deploy Script

set -e

echo "🚀 Iniciando deploy do Atendechat..."

# Verificar se o arquivo .env existe
if [ ! -f .env ]; then
    echo "⚠️  Arquivo .env não encontrado!"
    echo "📋 Copiando .env.example para .env..."
    cp .env.example .env
    echo "✅ Arquivo .env criado. Por favor, configure as variáveis antes de continuar."
    echo "🔧 Edite o arquivo .env com suas configurações:"
    echo "   - URLs do seu domínio"
    echo "   - Senhas do banco e Redis"
    echo "   - JWT secrets"
    echo "   - Configurações de email"
    exit 1
fi

echo "✅ Arquivo .env encontrado"

# Verificar se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
    exit 1
fi

echo "✅ Docker está rodando"

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down --remove-orphans

# Limpar imagens antigas (opcional)
read -p "🗑️  Deseja remover imagens antigas? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Removendo imagens antigas..."
    docker-compose down --rmi all --volumes --remove-orphans
fi

# Build e start dos serviços
echo "🔨 Fazendo build dos containers..."
docker-compose build --no-cache

echo "🚀 Iniciando serviços..."
docker-compose up -d

# Aguardar serviços ficarem prontos
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 30

# Verificar status dos serviços
echo "🔍 Verificando status dos serviços..."
docker-compose ps

# Verificar logs para erros
echo "📋 Verificando logs recentes..."
docker-compose logs --tail=20

# Testar conectividade
echo "🧪 Testando conectividade..."

# Testar backend
if curl -f -s http://localhost:8080/api/auth/refresh > /dev/null; then
    echo "✅ Backend está respondendo"
else
    echo "❌ Backend não está respondendo"
fi

# Testar frontend
if curl -f -s http://localhost:3000 > /dev/null; then
    echo "✅ Frontend está respondendo"
else
    echo "❌ Frontend não está respondendo"
fi

echo ""
echo "🎉 Deploy concluído!"
echo ""
echo "📊 Status dos serviços:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8080"
echo ""
echo "📋 Comandos úteis:"
echo "   Ver logs:           docker-compose logs -f"
echo "   Parar serviços:     docker-compose down"
echo "   Reiniciar:          docker-compose restart"
echo "   Status:             docker-compose ps"
echo ""
echo "🔧 Para configurar o sistema:"
echo "   1. Acesse http://localhost:3000"
echo "   2. Faça o primeiro login"
echo "   3. Configure as integrações WhatsApp"
echo ""
