#!/bin/bash

# Script para configurar InfluxDB após o deploy
set -e

NAMESPACE="backend-comparison"

echo "🔧 Configurando InfluxDB para integração com JMeter..."

# Função para executar comando no InfluxDB com retry
execute_influx_command() {
    local cmd="$1"
    local description="$2"
    local max_retries=5
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if kubectl exec -n $NAMESPACE deployment/influxdb -- $cmd 2>/dev/null; then
            echo "✅ $description"
            return 0
        else
            retry_count=$((retry_count + 1))
            echo "⏳ Tentativa $retry_count/$max_retries para $description"
            sleep 5
        fi
    done
    
    echo "⚠️  $description - comando pode ter falhado mas continuando..."
    return 0
}

# Aguardar InfluxDB estar pronto
echo "⏳ Aguardando InfluxDB estar pronto..."
kubectl wait --for=condition=Ready pod -l app=influxdb -n $NAMESPACE --timeout=300s
sleep 10

# Obter ID do bucket jmeter
echo "📋 Obtendo informações do bucket jmeter..."
BUCKET_ID=$(kubectl exec -n $NAMESPACE deployment/influxdb -- influx bucket list --name jmeter -o backend-comparison --json 2>/dev/null | grep -o '"id":"[^"]*"' | cut -d'"' -f4 || echo "")

if [ -z "$BUCKET_ID" ]; then
    echo "📦 Criando bucket jmeter..."
    execute_influx_command "influx bucket create -n jmeter -o backend-comparison -r 0" "Bucket jmeter criado"
    
    # Obter ID do bucket após criação
    BUCKET_ID=$(kubectl exec -n $NAMESPACE deployment/influxdb -- influx bucket list --name jmeter -o backend-comparison --json 2>/dev/null | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
else
    echo "✅ Bucket jmeter já existe: $BUCKET_ID"
fi

# Criar DBRP mapping para compatibilidade v1
echo "🔗 Configurando DBRP mapping para v1 API..."
execute_influx_command "influx v1 dbrp create --bucket-id $BUCKET_ID --database jmeter --retention-policy autogen --default" "DBRP mapping configurado"

# Criar usuário jmeter
echo "👤 Criando usuário jmeter..."
execute_influx_command "influx user create -n jmeter -p jmeter123" "Usuário jmeter criado"

# Criar autorização v1 para o usuário jmeter
echo "🔐 Configurando autorização v1 para usuário jmeter..."
execute_influx_command "influx v1 auth create --username jmeter --password jmeter123 --write-bucket $BUCKET_ID --read-bucket $BUCKET_ID" "Autorização v1 configurada"

echo ""
echo "✅ Configuração do InfluxDB concluída!"
echo ""
echo "📊 Verificando configuração:"
echo "   - Bucket: jmeter (ID: $BUCKET_ID)"
echo "   - Usuário v1: jmeter / jmeter123"
echo "   - DBRP: jmeter -> $BUCKET_ID"
echo ""
echo "🧪 JMeter pode agora enviar dados para:"
echo "   URL: http://localhost:30004/write?db=jmeter&u=jmeter&p=jmeter123"
