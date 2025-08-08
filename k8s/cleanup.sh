#!/bin/bash

# Script para limpeza completa do ambiente Kubernetes
set -e

CLUSTER_NAME="backend-comparison"

echo "🗑️  Script de limpeza do ambiente Kubernetes"

# Verificar se o cluster existe
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "⚠️  Cluster ${CLUSTER_NAME} não encontrado."
    exit 0
fi

echo "❓ Tem certeza que deseja remover completamente o cluster ${CLUSTER_NAME}? (y/N)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🔧 Removendo cluster Kind..."
    kind delete cluster --name="${CLUSTER_NAME}"
    
    echo "🐳 Removendo imagens Docker locais..."
    docker rmi backend-comparison/python-backend:latest 2>/dev/null || echo "Imagem Python não encontrada"
    docker rmi backend-comparison/node-backend:latest 2>/dev/null || echo "Imagem Node.js não encontrada"
    
    echo "✅ Limpeza concluída!"
    echo ""
    echo "💡 Para recriar o ambiente, execute:"
    echo "   ./setup-kind.sh"
    echo "   ./deploy.sh"
else
    echo "❌ Operação cancelada."
fi
