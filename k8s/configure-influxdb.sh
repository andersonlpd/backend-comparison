#!/bin/bash

# Script para configurar InfluxDB após o deploy
set -e

NAMESPACE="backend-comparison"

echo "🔧 Configurando InfluxDB para integração com JMeter..."

# Obtém token de admin dentro do pod para usar nas chamadas da CLI
ADMIN_TOKEN=$(kubectl exec -n $NAMESPACE deployment/influxdb -- printenv DOCKER_INFLUXDB_INIT_ADMIN_TOKEN 2>/dev/null || echo "")

if [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Não foi possível obter o token de admin do InfluxDB. Verifique se o pod está saudável."
    exit 1
fi

# (Removido mecanismo de retry; operações agora são single-shot idempotentes)

# Aguardar InfluxDB estar pronto
echo "⏳ Aguardando InfluxDB estar pronto..."
kubectl wait --for=condition=Ready pod -l app=influxdb -n $NAMESPACE --timeout=300s
sleep 10

echo "📋 Obtendo informações do bucket jmeter..."
get_bucket_id() {
    # Tentativa JSON
    local id_json
    id_json=$(kubectl exec -n $NAMESPACE deployment/influxdb -- bash -c "INFLUX_TOKEN=$ADMIN_TOKEN influx bucket list --name jmeter -o backend-comparison --json" 2>/dev/null | grep -o '"id":"[^"]*"' | head -n1 | cut -d'"' -f4 || true)
    if [ -n "$id_json" ]; then
        echo "$id_json"
        return 0
    fi
    # Fallback formato tabela (coluna 1 = ID, 2 = Name)
    local id_table
    id_table=$(kubectl exec -n $NAMESPACE deployment/influxdb -- bash -c "INFLUX_TOKEN=$ADMIN_TOKEN influx bucket list -o backend-comparison" 2>/dev/null | awk '$2=="jmeter" {print $1; exit}')
    if [ -n "$id_table" ]; then
        echo "$id_table"
        return 0
    fi
    echo ""
}

BUCKET_ID=$(get_bucket_id)

if [ -z "$BUCKET_ID" ]; then
    echo "📦 Criando bucket jmeter (ou já existe)..."
    kubectl exec -n $NAMESPACE deployment/influxdb -- bash -c "INFLUX_TOKEN=$ADMIN_TOKEN influx bucket create --name jmeter -o backend-comparison --retention 0" 2>&1 || echo "ℹ️  Bucket já existe ou erro ignorável."
    BUCKET_ID=$(get_bucket_id)
fi

if [ -z "$BUCKET_ID" ]; then
    echo "⚠️  Não foi possível determinar o ID do bucket jmeter. Continuando mesmo assim (operações que dependem dele podem falhar)."
else
    echo "✅ Bucket jmeter ID: $BUCKET_ID"
fi

# Criar DBRP mapping para compatibilidade v1
echo "🔗 Configurando DBRP mapping para v1 API..."
# Verifica se já existe
if [ -n "$BUCKET_ID" ]; then
    DBRP_EXISTS=$(kubectl exec -n $NAMESPACE deployment/influxdb -- bash -c "INFLUX_TOKEN=$ADMIN_TOKEN influx v1 dbrp list -o backend-comparison --json" 2>/dev/null | grep -c "$BUCKET_ID" || echo "0")
    if [ "${DBRP_EXISTS}" -gt 0 ] 2>/dev/null; then
        echo "✅ DBRP mapping já existe"
    else
        echo "🧩 Criando DBRP mapping..."
        kubectl exec -n $NAMESPACE deployment/influxdb -- bash -c "INFLUX_TOKEN=$ADMIN_TOKEN influx v1 dbrp create --bucket-id $BUCKET_ID --db jmeter --rp autogen --default -o backend-comparison" 2>&1 || echo "ℹ️  DBRP pode já existir ou erro ignorável."
    fi
else
    echo "⚠️  Pulando criação de DBRP (ID do bucket não identificado)."
fi

# Criar usuário jmeter
echo "👤 Criando usuário jmeter (idempotente)..."
USER_EXISTS=$(kubectl exec -n $NAMESPACE deployment/influxdb -- bash -c "INFLUX_TOKEN=$ADMIN_TOKEN influx user list --json" 2>/dev/null | grep -c '"name":"jmeter"' || echo "0")
USER_EXISTS=${USER_EXISTS//[^0-9]/}
if [ -n "$USER_EXISTS" ] && [ "$USER_EXISTS" -gt 0 ] 2>/dev/null; then
    echo "✅ Usuário jmeter já existe"
else
    echo "👥 Criando usuário jmeter..."
    kubectl exec -n $NAMESPACE deployment/influxdb -- bash -c "INFLUX_TOKEN=$ADMIN_TOKEN influx user create -n jmeter -p jmeter123" 2>&1 || echo "ℹ️  Usuário já existe ou erro ignorável."
fi

# Criar autorização v1 para o usuário jmeter
echo "🔐 Configurando autorização v1 para usuário jmeter..."
AUTH_EXISTS=$(kubectl exec -n $NAMESPACE deployment/influxdb -- bash -c "INFLUX_TOKEN=$ADMIN_TOKEN influx v1 auth list --json" 2>/dev/null | grep -c '"userName":"jmeter"' || echo "0")
AUTH_EXISTS=${AUTH_EXISTS//[^0-9]/}
if [ -n "$AUTH_EXISTS" ] && [ "$AUTH_EXISTS" -gt 0 ] 2>/dev/null; then
    echo "✅ Autorização v1 já existe para usuário jmeter"
else
    if [ -n "$BUCKET_ID" ]; then
    echo "🔑 Criando autorização v1..."
    kubectl exec -n $NAMESPACE deployment/influxdb -- bash -c "INFLUX_TOKEN=$ADMIN_TOKEN influx v1 auth create --username jmeter --password jmeter123 --write-bucket $BUCKET_ID --read-bucket $BUCKET_ID" 2>&1 || echo "ℹ️  Auth já existe ou erro ignorável."
    else
        echo "⚠️  Pulando criação de auth v1 (ID do bucket desconhecido)."
    fi
fi

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
