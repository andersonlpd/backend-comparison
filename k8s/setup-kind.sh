#!/bin/bash

set -e

echo "🚀 Iniciando configuração do cluster Kind para Backend Comparison..."

# Verificar se o Kind está instalado
if ! command -v kind &> /dev/null; then
    echo "❌ Kind não está instalado. Por favor, instale o Kind primeiro:"
    echo "https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Verificar se o kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não está instalado. Por favor, instale o kubectl primeiro:"
    echo "https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Verificar se o Docker está instalado e rodando
if ! docker info &> /dev/null; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
    exit 1
fi

CLUSTER_NAME="backend-comparison"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📁 Diretório atual: $CURRENT_DIR"

# Verificar se o cluster já existe
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "⚠️  Cluster ${CLUSTER_NAME} já existe. Removendo..."
    kind delete cluster --name="${CLUSTER_NAME}"
    echo "✅ Cluster removido com sucesso"
fi

# Criar o cluster Kind
echo "🔧 Criando cluster Kind..."
kind create cluster --config="${CURRENT_DIR}/kind-config.yaml" --name="${CLUSTER_NAME}"

# Aguardar o cluster estar pronto
echo "⏳ Aguardando cluster estar pronto..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Construir e carregar as imagens Docker no Kind
echo "🐳 Construindo imagens Docker..."

# Navegar para o diretório raiz do projeto
cd "${CURRENT_DIR}/.."

# Construir imagem Python
echo "📦 Construindo imagem Python backend..."
docker build -t backend-comparison/python-backend:latest ./python-backend/

# Construir imagem Node.js
echo "📦 Construindo imagem Node.js backend..."
docker build -t backend-comparison/node-backend:latest ./node-backend/

# Carregar imagens no cluster Kind
echo "📤 Carregando imagens no cluster Kind..."
kind load docker-image backend-comparison/python-backend:latest --name="${CLUSTER_NAME}"
kind load docker-image backend-comparison/node-backend:latest --name="${CLUSTER_NAME}"

# Voltar para o diretório k8s
cd "${CURRENT_DIR}"

echo "✅ Cluster Kind configurado com sucesso!"
echo ""
echo "🎯 Próximos passos:"
echo "1. Execute: ./deploy.sh para fazer o deploy de todas as aplicações"
echo "2. Aguarde alguns minutos para todos os pods estarem prontos"
echo "3. Acesse os serviços:"
echo "   - Python Backend: http://localhost:30001"
echo "   - Node.js Backend: http://localhost:30002"
echo "   - Prometheus: http://localhost:30003"
echo "   - InfluxDB: http://localhost:30004"
echo "   - Grafana: http://localhost:30005 (admin/admin)"
