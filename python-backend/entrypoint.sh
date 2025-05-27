#!/bin/bash
set -e

# Esperar pelo banco de dados PostgreSQL
echo "Aguardando o PostgreSQL..."
while ! nc -z $DB_HOST 5432; do
  sleep 0.5
done
echo "PostgreSQL disponível!"

# Navega para o diretório da aplicação
cd /python-backend/app

# Aplica as migrações
echo "Aplicando migrações..."
python manage.py makemigrations
python manage.py migrate

# Executa o servidor Gunicorn
echo "Iniciando servidor Gunicorn..."
exec gunicorn --bind 0.0.0.0:8000 --workers 4 core.wsgi
