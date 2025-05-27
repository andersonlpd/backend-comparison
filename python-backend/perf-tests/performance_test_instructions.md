# Instruções para Execução do Teste de Performance

## Pré-requisitos

1. Instalar o Apache JMeter:
   ```bash
   sudo apt update
   sudo apt install jmeter
   ```

2. Verificar se o JMeter está instalado corretamente:
   ```bash
   jmeter --version
   ```

## Preparação para o Teste

1. Certifique-se de que sua aplicação está em execução:
   ```bash
   cd ./backend-comparison/python-backend
   docker-compose up -d
   ```

2. Crie um usuário admin para os testes (se ainda não existir):
   ```bash
   docker-compose exec app python manage.py shell -c "from users_uc.models import User; User.objects.create_superuser('admin@exemplo.com', 'adminpassword', name='Administrador')"
   ```

3. Modifique as variáveis no arquivo JMX se necessário:
   - Host: localhost (ou o host onde sua API está rodando)
   - Port: 8000 (ou a porta configurada)
   - Admin Email/Password: verifique se correspondem ao usuário criado

## Executando o Teste

1. Usando o script de automação:
   ```bash
   ./run_performance_test.sh
   ```

2. Manualmente via JMeter GUI (para ajustes e monitoramento em tempo real):
   ```bash
   jmeter -t python_api_performance_test.jmx
   ```

## Cenários Testados

O teste de performance inclui os seguintes cenários:

1. **Autenticação**
   - Login (obtenção de JWT token)
   - Refresh token

2. **Operações de Usuário**
   - Listar usuários
   - Criar novos usuários
   - Obter usuário por ID
   - Atualizar usuário

3. **Gerenciamento de Tarefas**
   - Verificação de status de tarefas

## Análise dos Resultados

Após a execução, os resultados serão salvos na pasta `performance_results` com:
- Arquivo JTL (formato JMeter para resultados)
- Relatório HTML interativo

Principais métricas a serem analisadas:
- Tempo médio de resposta
- Throughput (solicitações por segundo)
- Taxa de erro
- Percentis (90%, 95%, 99%)

## Notas

- O teste foi configurado para simular uma carga moderada. Ajuste os parâmetros de threads e duração conforme necessário.
- Para um teste mais realista, execute em uma máquina separada da instância da aplicação.
- Monitor resources (CPU, memory, network) during the test to identify bottlenecks.
