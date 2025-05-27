#!/bin/bash

# Script para executar testes de performance com JMeter
# Certifique-se de ter o JMeter instalado e no PATH

# Definir variáveis
JMETER_PATH="jmeter"  # Altere para o caminho completo se necessário
TEST_PLAN="./python_api_performance_test.jmx"
RESULTS_FOLDER="./performance_results"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Criar pasta para resultados se não existir
mkdir -p $RESULTS_FOLDER

# Arquivo de resultados
JTL_FILE="$RESULTS_FOLDER/results_$DATE.jtl"
HTML_REPORT="$RESULTS_FOLDER/report_$DATE"

# Executar o teste
echo "Iniciando teste de performance..."
$JMETER_PATH -n -t $TEST_PLAN -l $JTL_FILE

# Gerar relatório HTML
echo "Gerando relatório HTML..."
$JMETER_PATH -g $JTL_FILE -o $HTML_REPORT

echo "Teste concluído!"
echo "Resultados salvos em: $JTL_FILE"
echo "Relatório HTML gerado em: $HTML_REPORT"
