from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'full_name', 'username', 'email', 'phone', 'is_active', 'created_at']


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ['full_name', 'username', 'email', 'phone', 'password']

    def validate_username(self, value):
        if User.objects.filter(username=value.strip()).exists():
            raise serializers.ValidationError('Username already exists.')
        return value.strip()

    def validate_email(self, value):
        if User.objects.filter(email=value.strip().lower()).exists():
            raise serializers.ValidationError('Email already exists.')
        return value.strip().lower()

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user
