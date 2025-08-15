#!/bin/bash

# Deploy script para todas as aplicações no Kubernetes
set -e

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="backend-comparison"

echo "🚀 Iniciando deploy das aplicações no cluster Kubernetes..."

# Verificar se o cluster existe
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "❌ Cluster ${CLUSTER_NAME} não encontrado. Execute ./setup-kind.sh primeiro."
    exit 1
fi

# Configurar o contexto do kubectl
kubectl cluster-info --context kind-${CLUSTER_NAME}

echo "1️⃣ Criando namespace..."
kubectl apply -f "${CURRENT_DIR}/namespace/namespace.yaml"

echo "2️⃣ Deploying banco de dados PostgreSQL..."
kubectl apply -f "${CURRENT_DIR}/database/postgres.yaml"

echo "3️⃣ Aguardando PostgreSQL estar pronto..."
kubectl wait --for=condition=Ready pod -l app=postgres -n backend-comparison --timeout=300s

echo "4️⃣ Deploying monitoring stack..."
kubectl apply -f "${CURRENT_DIR}/monitoring/prometheus.yaml"
kubectl apply -f "${CURRENT_DIR}/monitoring/node-exporter.yaml"
kubectl apply -f "${CURRENT_DIR}/monitoring/cadvisor.yaml"
kubectl apply -f "${CURRENT_DIR}/monitoring/influxdb.yaml"
kubectl apply -f "${CURRENT_DIR}/monitoring/grafana.yaml"

echo "5️⃣ Aguardando serviços de monitoramento estarem prontos..."
kubectl wait --for=condition=Ready pod -l app=prometheus -n backend-comparison --timeout=300s
kubectl wait --for=condition=Ready pod -l app=influxdb -n backend-comparison --timeout=300s
kubectl wait --for=condition=Ready pod -l app=grafana -n backend-comparison --timeout=300s

echo "6️⃣ Deploying backends Python e Node.js..."
kubectl apply -f "${CURRENT_DIR}/backends/python-backend.yaml"
kubectl apply -f "${CURRENT_DIR}/backends/node-backend.yaml"

echo "7️⃣ Aguardando backends estarem prontos..."
kubectl wait --for=condition=Ready pod -l app=python-backend -n backend-comparison --timeout=300s
kubectl wait --for=condition=Ready pod -l app=node-backend -n backend-comparison --timeout=300s

echo "8️⃣ Configurando InfluxDB para JMeter..."
# Executar script de configuração do InfluxDB
"${CURRENT_DIR}/configure-influxdb.sh"

echo "✅ Deploy concluído com sucesso!"
echo ""
echo "🔍 Validando ambiente..."
"${CURRENT_DIR}/validate.sh"
echo ""
echo "🎯 Verificando status dos pods..."
kubectl get pods -n backend-comparison

echo ""
echo "📊 Serviços disponíveis:"
echo "   - Python Backend: http://localhost:30001"
echo "   - Node.js Backend: http://localhost:30002"  
echo "   - Prometheus: http://localhost:30003"
echo "   - InfluxDB: http://localhost:30004"
echo "   - Grafana: http://localhost:30005 (admin/admin)"
echo ""
echo "🧪 Para executar testes JMeter:"
echo "   kubectl create job jmeter-python-test-\$(date +%s) --from=job/jmeter-python-test -n backend-comparison"
echo "   kubectl create job jmeter-node-test-\$(date +%s) --from=job/jmeter-node-test -n backend-comparison"
echo ""
echo "🔍 Para monitorar:"
echo "   kubectl get pods -n backend-comparison -w"
echo "   kubectl logs -f deployment/python-backend -n backend-comparison"
echo "   kubectl logs -f deployment/node-backend -n backend-comparison"
