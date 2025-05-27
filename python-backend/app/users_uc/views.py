from rest_framework import generics, permissions, status
from rest_framework.response import Response
from .models import User
from .serializers import UserSerializer
from rest_framework.views import APIView

class UserListCreateAPIView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UserRetrieveUpdateDestroyAPIView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [permissions.IsAuthenticated]
    queryset = User.objects.all()
    serializer_class = UserSerializer
    
class RegisterUserView(APIView):
    """
    View para registrar novos usuários sem precisar de autenticação
    """
    permission_classes = []  # Permite acesso anônimo
    
    def post(self, request, *args, **kwargs):
        data = request.data
        
        # Verificar se os campos obrigatórios estão presentes
        if not data.get('email') or not data.get('password') or not data.get('name'):
            return Response(
                {"error": "Os campos email, password e name são obrigatórios"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Verificar se o email já está em uso
        if User.objects.filter(email=data['email']).exists():
            return Response(
                {"error": "Este email já está em uso"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Criar o usuário
        user = User.objects.create_user(
            email=data['email'],
            password=data['password'],
            name=data['name']
        )
        
        # Retornar os dados do usuário sem a senha
        serializer = UserSerializer(user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)