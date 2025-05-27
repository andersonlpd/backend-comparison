# Python Backend API

Este projeto é uma API RESTful desenvolvida com Django e Django REST Framework, com arquitetura escalável e desacoplada, focada em alto desempenho e observabilidade.

## Visão Geral

A API fornece funcionalidades para gerenciamento de usuários e processamento assíncrono de arquivos CSV, utilizando tecnologias modernas como:

- **Django/DRF**: Framework web para construção rápida de APIs robustas
- **JWT Authentication**: Sistema seguro de autenticação baseado em tokens
- **PostgreSQL**: Banco de dados relacional para persistência de dados
- **Redis**: Cache e broker de mensagens para tarefas assíncronas
- **Celery**: Processamento distribuído de tarefas em background
- **Prometheus**: Monitoramento e métricas de performance
- **OpenTelemetry**: Rastreamento de requisições para observabilidade

## Estrutura do Projeto

```
python-backend/
├── app/                           # Código fonte principal
│   ├── core/                      # Configurações do projeto Django
│   ├── users_uc/                  # Aplicação para gerenciamento de usuários
│   └── tasks/                     # Aplicação para processamento de tarefas assíncronas
├── docker-compose.yml             # Configuração dos serviços em contêineres
├── Dockerfile                     # Instruções para build da imagem Docker
├── entrypoint.sh                  # Script de inicialização do contêiner
└── requirements.txt               # Dependências Python do projeto
```

## Componentes Principais

### Core (/app/core/)

Este módulo contém as configurações principais do projeto Django:

- **settings.py**: Configurações do Django, banco de dados, autenticação e Celery
- **urls.py**: Definição das rotas principais da API
- **celery.py**: Configuração do Celery para processamento assíncrono
- **wsgi.py/asgi.py**: Pontos de entrada para servidores web

### Módulo de Usuários (/app/users_uc/)

Gerencia a autenticação e cadastro de usuários:

- **models.py**: Define o modelo de User personalizado
- **serializers.py**: Serializa dados de usuário para JSON
- **views.py**: Implementa os endpoints de API para CRUD de usuários
- **auth.py**: Configura a autenticação JWT personalizada

### Módulo de Tarefas (/app/tasks/)

Implementa o processamento assíncrono de dados:

- **tasks.py**: Define workers Celery para processamento de arquivos CSV
- **views.py**: Endpoints para upload de arquivos e verificação de status
- **urls.py**: Rotas para funcionalidades relacionadas a tarefas

## Casos de Uso

### 1. Autenticação e Gerenciamento de Usuários

- **Registro de novos usuários**: `POST /api/register/`
- **Login (obtenção de token JWT)**: `POST /api/auth/login/`
- **Refresh de token**: `POST /api/auth/refresh/`
- **CRUD de usuários**: Endpoints em `/api/users/`

### 2. Processamento Assíncrono de Arquivos CSV

- **Upload de arquivo CSV**: `POST /api/contacts/upload-csv/`
- **Verificação de status de processamento**: `GET /api/contacts/task-status/{task_id}/`

## Tecnologias e Componentes

### PostgreSQL

Utilizado como banco de dados principal para armazenamento persistente de dados. A conexão é configurada via variáveis de ambiente para facilitar a implantação em diferentes ambientes.

### Redis

Serve a dois propósitos principais:

1. **Message Broker para o Celery**: Enfileira tarefas que serão executadas de forma assíncrona pelos workers
2. **Backend para resultados do Celery**: Armazena os resultados das tarefas para consulta posterior

### Celery

Framework de processamento distribuído de tarefas utilizado para:

1. **Processamento assíncrono de arquivos CSV**: Evita bloqueio do servidor web durante operações longas
2. **Escalabilidade horizontal**: Permite adicionar mais workers para lidar com maior volume de processamento
3. **Retentativas automáticas**: Garante a execução das tarefas mesmo em caso de falhas temporárias

O fluxo de processamento assíncrono funciona da seguinte forma:

1. Cliente faz upload de arquivo CSV via API
2. API salva o arquivo temporariamente e enfileira uma tarefa no Redis
3. Worker Celery processa o arquivo em background
4. Cliente pode verificar o status do processamento via API

### Prometheus

Sistema de monitoramento integrado via django-prometheus que coleta métricas sobre:

- Requisições HTTP (volume, latência, códigos de resposta)
- Consultas ao banco de dados
- Uso de recursos do sistema

Essas métricas podem ser visualizadas em dashboards Grafana para análise de performance.

### JWT Authentication

Implementa autenticação baseada em tokens com:

- Tokens de acesso de curta duração (1 hora)
- Tokens de refresh de longa duração (1 dia)
- Claims personalizados com dados do usuário

## Implantação

A aplicação é containerizada com Docker e orquestrada via Docker Compose:

```bash
# Iniciar todos os serviços
docker-compose up -d

# Verificar logs
docker-compose logs -f app
docker-compose logs -f celery

# Parar todos os serviços
docker-compose down
```

## Testes de Performance

O projeto inclui scripts JMeter para testes de carga:

- **python_api_performance_test.jmx**: Teste completo de todos os endpoints
- **run_performance_test.sh**: Script para executar os testes via linha de comando

Para executar os testes:

```bash
./run_performance_test.sh
```

## Ambiente de Desenvolvimento

### Pré-requisitos

- Docker e Docker Compose
- Python 3.13+
- PostgreSQL 14+
- Redis 7+

### Configuração

1. Clone o repositório
2. Configure as variáveis de ambiente no docker-compose.yml
3. Execute `docker-compose up -d`
4. Acesse a API em http://localhost:8000/api/

## Variáveis de Ambiente

- `DB_HOST`: Host do PostgreSQL
- `DB_NAME`: Nome do banco de dados
- `DB_USER`: Usuário do banco de dados
- `DB_PASSWORD`: Senha do banco de dados
- `JWT_SECRET_KEY`: Chave secreta para assinatura de tokens JWT
- `OTEL_EXPORTER_JAEGER_ENDPOINT`: Endpoint do Jaeger para telemetria

## Arquivos e Módulos Detalhados

### docker-compose.yml

Define os serviços necessários para rodar a aplicação:

- **postgres**: Banco de dados PostgreSQL
- **redis**: Message broker e cache
- **app**: Aplicação Django/DRF
- **celery**: Worker para processamento assíncrono

### Dockerfile

Configura o ambiente de execução da aplicação, incluindo:

- Instalação de dependências
- Configuração do diretório de trabalho
- Script de entrypoint para verificar dependências e executar migrações

### entrypoint.sh

Script de inicialização do contêiner que:

1. Aguarda o PostgreSQL estar disponível
2. Executa migrações do banco de dados
3. Inicia o servidor Gunicorn

### app/core/settings.py

Configurações centrais do Django, incluindo:

- Configurações de banco de dados
- Configurações de autenticação JWT
- Configurações do Celery
- Integrações com Prometheus

### app/core/celery.py

Configuração do Celery para processamento assíncrono:

- Define a instância do aplicativo Celery
- Configura descoberta automática de tarefas
- Define tarefas de diagnóstico

### app/users_uc/models.py

Define o modelo de usuário personalizado que:

- Usa e-mail como identificador principal
- Implementa métodos para gerenciamento de usuários
- Estende AbstractUser com campos adicionais

### app/tasks/tasks.py

Implementa tarefas Celery para processamento em background:

- `process_csv`: Processa arquivos CSV e importa usuários
- Implementa validação, tratamento de erros e estatísticas de processamento

### app/tasks/views.py

Views para gerenciamento de tarefas:

- `CSVUploadView`: Endpoint para upload de arquivos CSV
- `TaskStatusView`: Endpoint para verificação de status de tarefas

## Conclusão

Este projeto demonstra a implementação de uma API robusta usando Django/DRF com processamento assíncrono via Celery/Redis. A arquitetura escolhida permite escalabilidade, observabilidade e manutenção simplificada, sendo ideal para aplicações que necessitam processar dados em background sem comprometer a performance da interface principal.

Para contribuições ou dúvidas, consulte a documentação dos componentes utilizados ou abra uma issue no repositório do projeto.
