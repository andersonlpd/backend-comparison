from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
import os
from .tasks import process_csv


class CSVUploadView(APIView):
    """
    View para upload de arquivo CSV e processamento em segundo plano.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        if 'file' not in request.FILES:
            return Response({"error": "Nenhum arquivo enviado"}, status=status.HTTP_400_BAD_REQUEST)
        
        file = request.FILES['file']
        
        # Verificar se é um arquivo CSV
        if not file.name.endswith('.csv'):
            return Response({"error": "O arquivo deve ser CSV"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Salvar o arquivo temporariamente
        path = default_storage.save(f'csv_uploads/{file.name}', ContentFile(file.read()))
        file_path = os.path.join(default_storage.location, path)
        
        # Processar o arquivo em segundo plano
        task = process_csv.delay(file_path)
        
        return Response({
            "message": "Upload realizado com sucesso. O arquivo será processado em segundo plano.",
            "task_id": task.id
        }, status=status.HTTP_202_ACCEPTED)


class TaskStatusView(APIView):
    """
    View para verificar o status de uma tarefa (task) do Celery.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request, task_id, *args, **kwargs):
        from celery.result import AsyncResult
        
        task_result = AsyncResult(task_id)
        
        result = {
            "task_id": task_id,
            "status": task_result.status
        }
        
        if task_result.successful():
            result["result"] = task_result.get()
        
        return Response(result)
