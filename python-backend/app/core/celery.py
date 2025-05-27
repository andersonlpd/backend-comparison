import os
from celery import Celery

# Define as configurações do Django para o Celery
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# Cria a instância do app Celery
app = Celery('tasks')

# Lê as configurações do Celery do settings.py do Django
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto descoberta de tarefas nos aplicativos Django
app.autodiscover_tasks()

@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
