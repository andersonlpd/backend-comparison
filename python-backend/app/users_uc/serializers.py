from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'created_at']
        
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Adicionar custom claims
        token['name'] = user.name
        token['email'] = user.email
        return token
        
    def validate(self, attrs):
        # A validação padrão usa o USERNAME_FIELD do modelo de usuário
        data = super().validate(attrs)
        # Adicionar dados adicionais à resposta
        data['user_id'] = self.user.id
        data['name'] = self.user.name
        data['email'] = self.user.email
        return data