#!/bin/bash

# Script de monitoramento para Atendechat
# Monitor Script

echo "📊 Monitor do Atendechat"
echo "========================"

# Função para verificar status de um serviço
check_service() {
    local service_name=$1
    local url=$2
    
    if curl -f -s "$url" > /dev/null 2>&1; then
        echo "✅ $service_name: OK"
    else
        echo "❌ $service_name: FALHA"
    fi
}

# Função para mostrar uso de recursos
show_resources() {
    echo ""
    echo "💾 Uso de recursos:"
    echo "==================="
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Função para mostrar logs recentes
show_recent_logs() {
    echo ""
    echo "📋 Logs recentes:"
    echo "================="
    echo ""
    echo "🔧 Backend:"
    docker-compose logs --tail=5 backend
    echo ""
    echo "🌐 Frontend:"
    docker-compose logs --tail=5 frontend
    echo ""
    echo "🗄️  PostgreSQL:"
    docker-compose logs --tail=5 postgres
    echo ""
    echo "🔄 Redis:"
    docker-compose logs --tail=5 redis
}

# Verificar se os containers estão rodando
echo "🔍 Status dos containers:"
echo "========================="
docker-compose ps

echo ""
echo "🌐 Conectividade dos serviços:"
echo "=============================="

# Verificar serviços
check_service "Frontend" "http://localhost:3000"
check_service "Backend" "http://localhost:8080/api/auth/refresh"
check_service "PostgreSQL" "localhost:5432"
check_service "Redis" "localhost:6379"

# Mostrar uso de recursos
show_resources

# Perguntar se quer ver logs
echo ""
read -p "📋 Deseja ver os logs recentes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    show_recent_logs
fi

# Menu de opções
echo ""
echo "🛠️  Opções disponíveis:"
echo "======================"
echo "1. Ver logs em tempo real"
echo "2. Reiniciar serviços"
echo "3. Parar todos os serviços"
echo "4. Ver estatísticas detalhadas"
echo "5. Executar migração manual"
echo "6. Backup do banco de dados"
echo "0. Sair"
echo ""

read -p "Escolha uma opção (0-6): " -n 1 -r
echo

case $REPLY in
    1)
        echo "📋 Mostrando logs em tempo real (Ctrl+C para sair)..."
        docker-compose logs -f
        ;;
    2)
        echo "🔄 Reiniciando serviços..."
        docker-compose restart
        echo "✅ Serviços reiniciados"
        ;;
    3)
        echo "🛑 Parando todos os serviços..."
        docker-compose down
        echo "✅ Serviços parados"
        ;;
    4)
        echo "📊 Estatísticas detalhadas:"
        docker stats
        ;;
    5)
        echo "🔧 Executando migração manual..."
        docker-compose exec backend npm run db:migrate
        docker-compose exec backend npm run db:seed
        echo "✅ Migração concluída"
        ;;
    6)
        echo "💾 Fazendo backup do banco de dados..."
        timestamp=$(date +%Y%m%d_%H%M%S)
        docker-compose exec postgres pg_dump -U atendechat atendechat > "backup_${timestamp}.sql"
        echo "✅ Backup salvo como backup_${timestamp}.sql"
        ;;
    0)
        echo "👋 Saindo..."
        ;;
    *)
        echo "❌ Opção inválida"
        ;;
esac
