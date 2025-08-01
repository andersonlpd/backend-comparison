# Comparação de Performance: Python vs Node.js

Este projeto contém uma comparação completa de performance entre duas implementações de uma API REST de gerenciamento de inventário: uma em Python (FastAPI) e outra em Node.js (Express). O projeto inclui monitoramento completo com Prometheus, Grafana e InfluxDB, além de testes de carga automatizados com JMeter.

## Estrutura do Projeto

```
backend-comparison/
├── python-backend/                 # API Python com FastAPI
│   ├── app/
│   │   ├── api/
│   │   │   ├── endpoints/
│   │   │   │   ├── auth.py
│   │   │   │   ├── products.py
│   │   │   │   ├── inventory.py
│   │   │   │   └── orders.py
│   │   │   ├── dependencies.py
│   │   │   └── router.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   └── security.py
│   │   ├── db/
│   │   │   ├── models.py
│   │   │   └── database.py
│   │   ├── schemas/
│   │   │   ├── user.py
│   │   │   ├── product.py
│   │   │   ├── inventory.py
│   │   │   └── order.py
│   │   └── main.py
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
├── node-backend/                   # API Node.js com Express
│   ├── src/
│   │   ├── config/
│   │   │   └── database.js
│   │   ├── models/
│   │   │   ├── index.js
│   │   │   ├── User.js
│   │   │   ├── Product.js
│   │   │   ├── InventoryItem.js
│   │   │   ├── Order.js
│   │   │   └── OrderItem.js
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── products.js
│   │   │   ├── inventory.js
│   │   │   └── orders.js
│   │   ├── middleware/
│   │   │   └── auth.js
│   │   └── app.js
│   ├── package.json
│   ├── Dockerfile
│   └── .env
├── jmeter/                         # Testes de carga
│   ├── backend-test-plan.jmx       # Teste original Python
│   ├── node-test-plan.jmx          # Teste específico Node.js
│   ├── python-test-plan-influx.jmx # Teste Python para InfluxDB
│   ├── node-test-plan-influx.jmx   # Teste Node.js para InfluxDB
│   └── Dockerfile
├── grafana/                        # Configuração Grafana
│   ├── datasources.yml             # Prometheus + InfluxDB
│   ├── provisioning/
│   │   └── datasources/
│   │       └── influxdb.yml
│   └── dashboards/
│       ├── python-metrics-dashboard.json
│       ├── node-metrics-dashboard.json
│       └── jmeter-influx-dashboard.json
├── prometheus/
│   └── prometheus.yml              # Configuração Prometheus
├── scripts/                        # Scripts de automação
│   ├── run-jmeter-tests.sh
│   ├── run-node-jmeter-tests.sh
│   └── run-influx-tests.sh
├── docker-compose.yml
└── README.md
```

## Arquitetura e Tecnologias

### Backend Python
- **Framework**: FastAPI
- **ORM**: SQLAlchemy
- **Autenticação**: JWT + bcrypt
- **Métricas**: prometheus-fastapi-instrumentator
- **Database**: PostgreSQL

### Backend Node.js
- **Framework**: Express.js
- **ORM**: Sequelize
- **Autenticação**: JWT + bcryptjs
- **Métricas**: prom-client (custom)
- **Database**: PostgreSQL (compartilhado)

### Monitoramento
- **Métricas**: Prometheus (aplicações) + InfluxDB (JMeter)
- **Visualização**: Grafana
- **Testes de Carga**: JMeter
- **Infraestrutura**: Docker + Docker Compose

## Requisitos

- Docker e Docker Compose
- JMeter 5.4+ (opcional, para testes manuais)
- 4GB+ RAM disponível
- Portas livres: 3000, 5432, 8000, 8001, 8086, 9090, 9270, 9271

## Como Executar

1. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/backend-comparison.git
   cd backend-comparison
   ```

2. Inicie toda a infraestrutura:
   ```bash
   docker-compose up -d
   ```

3. Aguarde todos os serviços iniciarem (pode levar 1-2 minutos):
   ```bash
   docker-compose logs -f
   ```

4. Acesse os serviços:
   - **API Python**: http://localhost:8000 | [Docs](http://localhost:8000/docs)
   - **API Node.js**: http://localhost:8001
   - **Grafana**: http://localhost:3000 (admin/admin)
   - **Prometheus**: http://localhost:9090
   - **InfluxDB**: http://localhost:8086

## Endpoints da API

Ambas as APIs implementam os mesmos endpoints para comparação direta:

### Autenticação
- `POST /api/v1/auth/register` - Registrar novo usuário
- `POST /api/v1/auth/login` - Login (retorna JWT token)

### Produtos
- `GET /api/v1/products` - Listar produtos (com paginação)
- `POST /api/v1/products` - Criar produto
- `GET /api/v1/products/{id}` - Obter produto específico
- `PUT /api/v1/products/{id}` - Atualizar produto
- `DELETE /api/v1/products/{id}` - Excluir produto

### Inventário
- `GET /api/v1/inventory` - Listar itens em estoque
- `POST /api/v1/inventory/add` - Adicionar ao estoque
- `POST /api/v1/inventory/remove` - Remover do estoque

### Pedidos
- `GET /api/v1/orders` - Listar pedidos do usuário
- `POST /api/v1/orders` - Criar novo pedido
- `GET /api/v1/orders/{id}` - Obter detalhes do pedido

## Testes de Performance

### Execução Automatizada

1. **Testes simultâneos com InfluxDB** (recomendado):
   ```bash
   chmod +x scripts/run-influx-tests.sh
   ./scripts/run-influx-tests.sh
   ```

2. **Testes individuais com Prometheus**:
   ```bash
   # Python
   chmod +x scripts/run-jmeter-tests.sh
   ./scripts/run-jmeter-tests.sh
   
   # Node.js
   chmod +x scripts/run-node-jmeter-tests.sh
   ./scripts/run-node-jmeter-tests.sh
   ```

### Configuração dos Testes
- **Threads**: 10 usuários simultâneos
- **Ramp-up**: 30 segundos
- **Loops**: 100 iterações por usuário
- **Total**: ~1000 requisições por backend

## Dashboards e Métricas

### 1. Python Application Metrics Dashboard
**Métricas Específicas do Python:**
- Request rate e latência por endpoint
- CPU usage via `process_cpu_seconds_total`
- Memory usage (resident + heap)
- Métricas customizadas da aplicação

### 2. Node.js Application Metrics Dashboard
**Métricas Específicas do Node.js:**
- Event Loop Lag (crucial para Node.js)
- Garbage Collection duration e frequency
- Heap usage detalhado (V8 engine)
- Active handles por tipo
- Network I/O
- Database query duration e rate

### 3. JMeter Load Testing Dashboard
**Métricas de Teste de Carga:**
- Response time percentiles (50th, 95th, 99th)
- Throughput por aplicação
- Error rate comparison
- Active threads/virtual users
- Comparação lado-a-lado Python vs Node.js

## Métricas Coletadas

### Aplicação (Prometheus)
- **Request metrics**: rate, duration, status codes
- **System metrics**: CPU, memory, network, file descriptors
- **Database metrics**: query duration, connection pool
- **Custom metrics**: business logic specific

### Load Testing (InfluxDB)
- **Response times**: avg, min, max, percentiles
- **Throughput**: requests/second
- **Errors**: count e percentage
- **Virtual users**: concurrent threads

## Comparação de Performance

### Pontos de Análise

1. **Latência de Response Time**:
   - Percentil 95 para diferentes endpoints
   - Comportamento sob carga crescente

2. **Throughput**:
   - Requisições por segundo máximas
   - Degradação com aumento de carga

3. **Uso de Recursos**:
   - CPU efficiency
   - Memory footprint
   - Database query performance

4. **Características Específicas**:
   - Python: GIL impact, blocking I/O
   - Node.js: Event loop performance, garbage collection

### Resultados Esperados

**Python (FastAPI) - Pontos Fortes:**
- Maior throughput para operações CPU-intensivas
- Melhor para processamento de dados complexos
- Documentação automática superior

**Node.js (Express) - Pontos Fortes:**
- Menor latência para I/O operations
- Melhor para aplicações real-time
- Menor memory footprint inicial

## Troubleshooting

### Problemas Comuns

1. **Containers não iniciam**:
   ```bash
   docker-compose down
   docker system prune -f
   docker-compose up -d
   ```

2. **Métricas não aparecem no Grafana**:
   - Verificar se datasources estão configurados
   - Verificar conectividade: `docker-compose logs grafana`

3. **JMeter connection errors**:
   - Verificar se backends estão healthy
   - Aguardar inicialização completa (~2 minutos)

### Logs e Debug

```bash
# Ver logs de todos os serviços
docker-compose logs -f

# Logs específicos
docker-compose logs python-backend
docker-compose logs node-backend
docker-compose logs grafana
```