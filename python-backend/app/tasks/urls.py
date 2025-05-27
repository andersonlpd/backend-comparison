from django.urls import path
from .views import CSVUploadView, TaskStatusView

urlpatterns = [
    path('upload-csv/', CSVUploadView.as_view(), name='upload_csv'),
    path('task-status/<str:task_id>/', TaskStatusView.as_view(), name='task_status'),
]
