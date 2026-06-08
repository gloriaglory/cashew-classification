from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import User
from .serializers import UserSerializer, RegisterSerializer


def _token(user):
    return str(RefreshToken.for_user(user).access_token)


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    s = RegisterSerializer(data=request.data)
    if not s.is_valid():
        msg = next(iter(s.errors.values()))[0]
        return Response({'success': False, 'message': str(msg)}, status=400)

    user = s.save()
    _log(user, 'REGISTER', 'New user registered')
    return Response({
        'success': True, 'message': 'Registration successful.',
        'token': _token(user), 'user': UserSerializer(user).data,
    }, status=201)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    username = request.data.get('username', '').strip()
    password = request.data.get('password', '')

    if not username or not password:
        return Response({'success': False, 'message': 'Username and password are required.'}, status=400)

    user = authenticate(username=username, password=password)
    if not user:
        return Response({'success': False, 'message': 'Invalid username or password.'}, status=401)
    if not user.is_active:
        return Response({'success': False, 'message': 'Account is deactivated. Contact admin.'}, status=403)

    _log(user, 'LOGIN', 'User logged in')
    return Response({
        'success': True, 'message': 'Login successful.',
        'token': _token(user), 'user': UserSerializer(user).data,
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def admin_login(request):
    """Login endpoint that only accepts staff users."""
    username = request.data.get('username', '').strip()
    password = request.data.get('password', '')

    if not username or not password:
        return Response({'success': False, 'message': 'Username and password are required.'}, status=400)

    user = authenticate(username=username, password=password)
    if not user or not user.is_staff:
        return Response({'success': False, 'message': 'Invalid admin credentials.'}, status=401)

    return Response({
        'success': True, 'message': 'Admin login successful.',
        'token': _token(user),
        'admin': {'id': user.id, 'username': user.username},
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    _log(request.user, 'LOGOUT', 'User logged out')
    return Response({'success': True, 'message': 'Logged out successfully.'})


@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def profile(request):
    user = request.user
    if request.method == 'GET':
        return Response({'success': True, 'user': UserSerializer(user).data})

    for field in ('full_name', 'phone'):
        val = request.data.get(field, '').strip()
        if val:
            setattr(user, field, val)
    user.save()
    return Response({'success': True, 'message': 'Profile updated successfully.'})


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def change_password(request):
    old_pw = request.data.get('old_password', '')
    new_pw = request.data.get('new_password', '')

    if not old_pw or not new_pw:
        return Response({'success': False, 'message': 'Both passwords are required.'}, status=400)
    if len(new_pw) < 6:
        return Response({'success': False, 'message': 'New password must be at least 6 characters.'}, status=400)
    if not request.user.check_password(old_pw):
        return Response({'success': False, 'message': 'Current password is incorrect.'}, status=401)

    request.user.set_password(new_pw)
    request.user.save()
    return Response({'success': True, 'message': 'Password changed successfully.'})


def _log(user, activity_type, description):
    from apps.detection.models import Activity
    Activity.objects.create(user=user, activity_type=activity_type, description=description)
