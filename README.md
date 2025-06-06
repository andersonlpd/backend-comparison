# Comparação de Performance: Python vs Node.js

Este projeto contém uma API REST de gerenciamento de inventário desenvolvida em Python (FastAPI) para comparação de performance com implementação similar em Node.js.

## Estrutura do Projeto

```
backend-comparison/
├── python-backend/
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
├── docker-compose.yml
├── prometheus/
│   └── prometheus.yml
├── grafana/
│   └── datasources.yml
└── jmeter/
    └── backend-test-plan.jmx
```

## Requisitos

- Docker e Docker Compose
- Python 3.9+
- JMeter (para testes)

## Como Executar

1. Clone o repositório:
   ```
   git clone https://github.com/seu-usuario/backend-comparison.git
   cd backend-comparison
   ```

2. Inicie os containers com Docker Compose:
   ```
   docker-compose up -d
   ```

3. Acesse a API Python:
   - API: http://localhost:8000
   - Documentação: http://localhost:8000/docs

4. Acesse o monitoramento:
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 (usuário: admin, senha: admin)

## Endpoints da API

### Autenticação
- `POST /api/auth/register` - Registrar novo usuário
- `POST /api/auth/login` - Login

### Produtos
- `GET /api/products` - Listar produtos
- `POST /api/products` - Criar produto
- `GET /api/products/{id}` - Obter produto
- `PUT /api/products/{id}` - Atualizar produto
- `DELETE /api/products/{id}` - Excluir produto

### Inventário
- `GET /api/inventory` - Listar itens em estoque
- `POST /api/inventory/add` - Adicionar ao estoque
- `POST /api/inventory/remove` - Remover do estoque

### Pedidos
- `GET /api/orders` - Listar pedidos
- `POST /api/orders` - Criar pedido
- `GET /api/orders/{id}` - Obter detalhes do pedido

## Testes de Performance

Execute os testes JMeter:

```
jmeter -n -t jmeter/backend-test-plan.jmx -l results.jtl
```

## Visualização de Métricas

1. Acesse o Grafana em http://localhost:3000
2. Faça login com usuário `admin` e senha `admin`
3. Navegue até os dashboards pré-configurados para visualizar métricas de performance:
   - **API Performance Dashboard**: Monitora taxa de requisições, latência e erros por endpoint
   - **System Resources Dashboard**: Monitora CPU, memória, rede e disco dos containers
   - **Python vs Node.js Comparison**: Compara diretamente o desempenho entre os backends

Os dashboards exibem informações importantes como:

- Throughput (requisições/segundo) por endpoint e método
- Latência de resposta (percentil 95) para os vários endpoints
- Taxa de erros (status 5xx)
- Uso de recursos do sistema (CPU, memória, rede, disco)
- Comparação direta entre o backend Python e Node.js

Estas métricas são essenciais para entender qual stack tem melhor desempenho em diferentes cenários de carga e tipos de operações.
