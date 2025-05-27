from django.urls import path
from .views import UserListCreateAPIView, UserRetrieveUpdateDestroyAPIView, RegisterUserView

urlpatterns = [
    path('users/', UserListCreateAPIView.as_view()),
    path('users/<int:pk>/', UserRetrieveUpdateDestroyAPIView.as_view()),
    path('register/', RegisterUserView.as_view(), name='register'),
]