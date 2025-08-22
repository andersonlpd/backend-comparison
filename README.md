# Comparação de Performance: Python vs Node.js

Este projeto contém uma comparação completa de performance entre duas implementações de uma API REST de gerenciamento de inventário: uma em Python (FastAPI) e outra em Node.js (Express). O projeto inclui monitoramento completo com Prometheus, Grafana e InfluxDB, além de testes de carga automatizados com JMeter.

## 🚀 Ambientes de Deploy Disponíveis

- **Docker Compose** - Ambiente local completo com todos os serviços
- **Kubernetes (Kind)** - Deploy em cluster Kubernetes local para testes mais realistas

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
├── k8s/                           # Deploy Kubernetes
│   ├── kind-config.yaml           # Configuração cluster Kind
│   ├── setup-kind.sh              # Setup cluster
│   ├── deploy.sh                  # Deploy aplicações
│   ├── run-tests.sh               # Execução de testes
│   ├── monitor.sh                 # Monitoramento
│   ├── cleanup.sh                 # Limpeza ambiente
│   ├── namespace/                 # Namespace manifests
│   ├── database/                  # PostgreSQL manifests  
│   ├── backends/                  # Python & Node.js manifests
│   ├── monitoring/                # Prometheus, Grafana, InfluxDB
│   ├── jmeter/                    # JMeter jobs
│   └── README.md                  # Documentação Kubernetes
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

### Opção 1: Docker Compose (Recomendado para desenvolvimento)

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

### Opção 2: Kubernetes com Kind (Recomendado para testes de performance)

1. **Pré-requisitos**: Docker, Kind e kubectl instalados

2. **Setup inicial**:
   ```bash
   cd k8s
   ./setup-kind.sh
   ```

3. **Deploy das aplicações**:
   ```bash
   ./deploy.sh
   ```

4. **Executar testes de performance**:
   ```bash
   ./run-tests.sh  # Ambos backends
   # ou
   ./run-tests.sh python  # Apenas Python
   ./run-tests.sh node    # Apenas Node.js
   ```

5. **Monitorar cluster**:
   ```bash
   ./monitor.sh  # Status geral
   ./monitor.sh logs  # Com logs
   ./monitor.sh watch  # Monitoramento contínuo
   ```

6. **Acesse os serviços**:
   - **API Python**: http://localhost:30001
   - **API Node.js**: http://localhost:30002
   - **Prometheus**: http://localhost:30003
   - **InfluxDB**: http://localhost:30004
   - **Grafana**: http://localhost:30005 (admin/admin)

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
   ./scripts/run-jmeter-tests.sh python
   
   # Node.js
   ./scripts/run-jmeter-tests.sh node
   ```

### Configuração dos Testes
- **Threads**: 20 usuários simultâneos
- **Steps**: Ramp-up de 5 threads a cada 5 minutos

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