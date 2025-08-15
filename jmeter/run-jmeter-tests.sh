#!/bin/bash

# Script para executar testes JMeter via linha de comando
# Uso: ./run-jmeter-tests.sh [python|node|both]

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="results"

# Criar diretório de resultados
mkdir -p $RESULTS_DIR

# Função para executar teste Python
run_python_test() {
    echo "🐍 Executando teste do Python Backend..."
    jmeter -n -t backend-test-plan.jmx \
        -l $RESULTS_DIR/python-backend-$TIMESTAMP.jtl \
        -e -o $RESULTS_DIR/python-backend-report-$TIMESTAMP
    echo "✅ Teste Python concluído! Relatório em: $RESULTS_DIR/python-backend-report-$TIMESTAMP"
}

# Função para executar teste Node
run_node_test() {
    echo "🟢 Executando teste do Node Backend..."
    jmeter -n -t node-test-plan.jmx \
        -l $RESULTS_DIR/node-backend-$TIMESTAMP.jtl \
        -e -o $RESULTS_DIR/node-backend-report-$TIMESTAMP
    echo "✅ Teste Node concluído! Relatório em: $RESULTS_DIR/node-backend-report-$TIMESTAMP"
}

# Verificar parâmetro
case "${1:-both}" in
    "python")
        run_python_test
        ;;
    "node")
        run_node_test
        ;;
    "both")
        run_python_test
        echo "⏳ Aguardando 30 segundos entre os testes..."
        sleep 30
        run_node_test
        ;;
    *)
        echo "❌ Uso: $0 [python|node|both]"
        echo "   python - Executa apenas o teste do Python"
        echo "   node   - Executa apenas o teste do Node"
        echo "   both   - Executa ambos os testes (padrão)"
        exit 1
        ;;
esac

echo "🎉 Testes concluídos! Verifique os resultados em: $RESULTS_DIR/"
