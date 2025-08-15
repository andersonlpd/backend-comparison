#!/bin/bash

# Script de validação para verificar se todo o ambiente está funcionando
set -e

NAMESPACE="backend-comparison"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validando ambiente Backend Comparison..."
echo ""

# Função para verificar se um pod está rodando
check_pod() {
    local app=$1
    local status=$(kubectl get pods -n $NAMESPACE -l app=$app -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
    
    if [ "$status" = "Running" ]; then
        echo -e "✅ ${GREEN}$app${NC} - Pod rodando"
        return 0
    else
        echo -e "❌ ${RED}$app${NC} - Pod não está rodando (Status: $status)"
        return 1
    fi
}

# Função para verificar se um serviço responde
check_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "✅ ${GREEN}$name${NC} - Serviço respondendo ($url)"
        return 0
    else
        echo -e "❌ ${RED}$name${NC} - Serviço não responde ($url) - HTTP $response"
        return 1
    fi
}

# Função para verificar métricas no Prometheus
check_prometheus_metrics() {
    local metric=$1
    local name=$2
    
    local count=$(curl -s "http://localhost:30003/api/v1/query?query=$metric" 2>/dev/null | grep -o '"result":\[.*\]' | grep -o '\[.*\]' | grep -c '{"metric"' 2>/dev/null || echo "0")
    
    if [ "$count" -gt "0" ] 2>/dev/null; then
        echo -e "✅ ${GREEN}$name${NC} - $count métricas disponíveis"
        return 0
    else
        echo -e "❌ ${RED}$name${NC} - Nenhuma métrica encontrada"
        return 1
    fi
}

errors=0

echo "📋 Verificando Pods..."
check_pod "postgres" || ((errors++))
check_pod "python-backend" || ((errors++))
check_pod "node-backend" || ((errors++))
check_pod "prometheus" || ((errors++))
check_pod "grafana" || ((errors++))
check_pod "influxdb" || ((errors++))

# Verificar cAdvisor (DaemonSet)
cadvisor_status=$(kubectl get daemonset cadvisor -n $NAMESPACE -o jsonpath='{.status.numberReady}' 2>/dev/null || echo "0")
if [ "$cadvisor_status" -gt "0" ]; then
    echo -e "✅ ${GREEN}cadvisor${NC} - DaemonSet rodando ($cadvisor_status pods)"
else
    echo -e "❌ ${RED}cadvisor${NC} - DaemonSet não está rodando"
    ((errors++))
fi

echo ""
echo "🌐 Verificando Conectividade dos Serviços..."
check_service "Python Backend" "http://localhost:30001/docs" || ((errors++))
check_service "Node Backend" "http://localhost:30002/" || ((errors++))
check_service "Prometheus" "http://localhost:30003/-/ready" || ((errors++))
check_service "Grafana" "http://localhost:30005/api/health" || ((errors++))
check_service "InfluxDB" "http://localhost:30004/ping" 204 || ((errors++))

echo ""
echo "📊 Verificando Métricas no Prometheus..."
check_prometheus_metrics "up" "Targets Ativos" || ((errors++))
check_prometheus_metrics "container_memory_usage_bytes" "Métricas cAdvisor" || ((errors++))
# Nota: Métricas das aplicações aparecerão após o primeiro uso
echo -e "ℹ️  ${YELLOW}Nota${NC}: Métricas das aplicações aparecerão após receberem requisições"

echo ""
echo "💾 Verificando Configuração do InfluxDB..."

# Verificar bucket jmeter
bucket_exists=$(kubectl exec -n $NAMESPACE deployment/influxdb -- influx bucket list --name jmeter -o backend-comparison 2>/dev/null | grep -c "jmeter" || echo "0")
if [ "$bucket_exists" -gt "0" ]; then
    echo -e "✅ ${GREEN}InfluxDB Bucket${NC} - Bucket 'jmeter' existe"
else
    echo -e "❌ ${RED}InfluxDB Bucket${NC} - Bucket 'jmeter' não encontrado"
    ((errors++))
fi

# Verificar usuário jmeter
user_exists=$(kubectl exec -n $NAMESPACE deployment/influxdb -- influx user list 2>/dev/null | grep -c "jmeter" || echo "0")
if [ "$user_exists" -gt "0" ]; then
    echo -e "✅ ${GREEN}InfluxDB User${NC} - Usuário 'jmeter' existe"
else
    echo -e "❌ ${RED}InfluxDB User${NC} - Usuário 'jmeter' não encontrado"
    ((errors++))
fi

# Verificar DBRP mapping
dbrp_exists=$(kubectl exec -n $NAMESPACE deployment/influxdb -- influx v1 dbrp list 2>/dev/null | grep -c "jmeter" || echo "0")
if [ "$dbrp_exists" -gt "0" ]; then
    echo -e "✅ ${GREEN}InfluxDB DBRP${NC} - Mapping v1 configurado"
else
    echo -e "❌ ${RED}InfluxDB DBRP${NC} - Mapping v1 não encontrado"
    ((errors++))
fi

echo ""
echo "🧪 Teste Rápido de Conectividade JMeter → InfluxDB..."

# Fazer um teste simples de escrita no InfluxDB
test_write=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://localhost:30004/write?db=jmeter&u=jmeter&p=jmeter123" --data-binary "test,source=validation value=1" 2>/dev/null || echo "000")

if [ "$test_write" = "204" ]; then
    echo -e "✅ ${GREEN}JMeter → InfluxDB${NC} - Escrita funcionando"
else
    echo -e "❌ ${RED}JMeter → InfluxDB${NC} - Erro na escrita (HTTP $test_write)"
    ((errors++))
fi

echo ""
echo "📈 Resumo da Validação:"

if [ $errors -eq 0 ]; then
    echo -e "🎉 ${GREEN}SUCESSO!${NC} Todos os componentes estão funcionando corretamente."
    echo ""
    echo "✅ Ambiente pronto para uso!"
    echo ""
    echo "🚀 Próximos passos:"
    echo "   1. Acesse Grafana: http://localhost:30005 (admin/admin)"
    echo "   2. Execute testes: cd ../jmeter && ./run-jmeter-tests.sh both"
    echo "   3. Monitore dashboards em tempo real"
    exit 0
else
    echo -e "⚠️  ${YELLOW}ATENÇÃO!${NC} Encontrados $errors problemas."
    echo ""
    echo "🔧 Para corrigir os problemas:"
    echo "   1. Verifique logs: ./manage.sh logs [app]"
    echo "   2. Reconfigure InfluxDB: ./manage.sh config"
    echo "   3. Consulte TROUBLESHOOTING.md"
    echo ""
    exit 1
fi
