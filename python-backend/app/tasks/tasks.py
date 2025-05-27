from celery import shared_task
import pandas as pd
import logging
from users_uc.models import User
from django.db import IntegrityError, transaction

logger = logging.getLogger(__name__)

@shared_task
def process_csv(file_path):
    try:
        # Ler o arquivo CSV
        df = pd.read_csv(file_path)
        
        # Contar registros iniciais
        total_records = len(df)
        successful = 0
        failed = 0
        
        # Processar linha por linha para melhor controle de erros
        for index, row in df.iterrows():
            try:
                # Verificar se tem as colunas necessárias
                if 'name' not in row or 'email' not in row:
                    logger.warning(f"Linha {index} ignorada: faltam colunas obrigatórias")
                    failed += 1
                    continue
                
                # Validação básica
                if not row['email'] or not row['name']:
                    logger.warning(f"Linha {index} ignorada: dados incompletos")
                    failed += 1
                    continue
                
                # Verificar se usuário já existe
                with transaction.atomic():
                    user, created = User.objects.get_or_create(
                        email=row['email'],
                        defaults={'name': row['name']}
                    )
                    
                    # Se usuário já existe, atualizar seus dados
                    if not created:
                        user.name = row['name']
                        user.save()
                
                successful += 1
                logger.info(f"Usuário processado com sucesso: {row['email']}")
                
            except IntegrityError:
                logger.error(f"Erro de integridade ao processar linha {index}: {row['email']}")
                failed += 1
            except Exception as e:
                logger.error(f"Erro ao processar linha {index}: {str(e)}")
                failed += 1
        
        # Resultado do processamento
        return {
            "status": "success",
            "message": "CSV processado com sucesso!",
            "total": total_records,
            "successful": successful,
            "failed": failed
        }
    except Exception as e:
        logger.error(f"Erro no processamento do CSV: {str(e)}")
        return {
            "status": "error",
            "message": f"Erro: {str(e)}"
        }