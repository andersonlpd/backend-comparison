# Use a imagem Python 3.12
FROM python:3.13

# Instalar ferramentas necessárias
RUN apt-get update && apt-get install -y netcat-traditional && rm -rf /var/lib/apt/lists/*

# Defina o diretório de trabalho no contêiner
WORKDIR /python-backend

COPY requirements.txt ./
COPY entrypoint.sh ./

# Torna o script executável
RUN chmod +x entrypoint.sh

# Instale as dependências Python
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r ./requirements.txt

WORKDIR /python-backend/app

# Use o script de entrypoint para iniciar a aplicação
ENTRYPOINT ["/python-backend/entrypoint.sh"]