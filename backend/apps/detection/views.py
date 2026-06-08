import os
import uuid
import csv
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from django.conf import settings
from django.http import HttpResponse
from django.db.models import Count
from .models import Disease, Pesticide, Detection, Activity, SystemConfig
from .serializers import DetectionSerializer, DiseaseSerializer, PesticideSerializer, ActivitySerializer
from ai.registry import get_model, switch_model as do_switch_model


ALLOWED_EXTS = {'png', 'jpg', 'jpeg', 'webp'}


# ── USER DETECTION ENDPOINTS ───────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser])
def predict(request):
    image = request.FILES.get('image')
    if not image:
        return Response({'success': False, 'message': 'No image file provided.'}, status=400)

    ext = image.name.rsplit('.', 1)[-1].lower() if '.' in image.name else ''
    if ext not in ALLOWED_EXTS:
        return Response({'success': False, 'message': 'Invalid file type. Use PNG, JPG, or JPEG.'}, status=400)

    upload_dir = settings.MEDIA_ROOT
    os.makedirs(upload_dir, exist_ok=True)
    filename = f"{uuid.uuid4().hex}.{ext}"
    image_path = os.path.join(upload_dir, filename)

    with open(image_path, 'wb') as f:
        for chunk in image.chunks():
            f.write(chunk)

    try:
        result = get_model().predict(image_path)
    except Exception as e:
        os.remove(image_path)
        return Response({'success': False, 'message': f'Prediction failed: {str(e)}'}, status=500)

    disease, _ = Disease.objects.get_or_create(
        disease_name=result['disease_name'],
        defaults={
            'description': result.get('description', ''),
            'symptoms':    result.get('symptoms', ''),
            'prevention':  result.get('prevention', ''),
        },
    )
    detection = Detection.objects.create(
        user=request.user,
        disease=disease,
        image_path=filename,
        confidence_score=result['confidence'],
        pesticide_recommended=result.get('pesticide_name', ''),
        is_healthy=result['is_healthy'],
    )
    Activity.objects.create(
        user=request.user,
        activity_type='DETECTION',
        description=f"Detected: {result['disease_name']} ({result['confidence']:.1f}%)",
    )

    result['detection_id'] = detection.id
    result['image_url'] = f"/uploads/{filename}"
    return Response({'success': True, 'result': result})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def history(request):
    qs = Detection.objects.filter(user=request.user).select_related('disease')

    search = request.GET.get('search', '').strip()
    if search:
        qs = qs.filter(disease__disease_name__icontains=search)

    f = request.GET.get('filter', 'all').lower()
    if f == 'healthy':
        qs = qs.filter(is_healthy=True)
    elif f == 'diseased':
        qs = qs.filter(is_healthy=False)

    sort = request.GET.get('sort', 'desc').lower()
    qs = qs.order_by('detection_date' if sort == 'asc' else '-detection_date')

    limit = min(int(request.GET.get('limit', 50)), 200)
    offset = int(request.GET.get('offset', 0))
    total = qs.count()

    return Response({
        'success': True,
        'history': DetectionSerializer(qs[offset:offset + limit], many=True).data,
        'total': total, 'limit': limit, 'offset': offset,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def detection_detail(request, detection_id):
    try:
        det = Detection.objects.select_related('disease').get(id=detection_id, user=request.user)
    except Detection.DoesNotExist:
        return Response({'success': False, 'message': 'Detection not found.'}, status=404)
    return Response({'success': True, 'detection': DetectionSerializer(det).data})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_stats(request):
    qs = Detection.objects.filter(user=request.user)
    return Response({
        'success': True,
        'stats': {
            'total_scans': qs.count(),
            'healthy_leaves': qs.filter(is_healthy=True).count(),
            'diseased_leaves': qs.filter(is_healthy=False).count(),
        },
    })


# ── ADMIN API ENDPOINTS ────────────────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_statistics(request):
    from apps.authentication.models import User
    dist = (Detection.objects
            .values('disease__disease_name')
            .annotate(count=Count('id'))
            .order_by('-count'))
    dist = [d for d in dist if d['disease__disease_name']]
    most_common = dist[0] if dist else None
    return Response({
        'success': True,
        'stats': {
            'total_users': User.objects.count(),
            'total_detections': Detection.objects.count(),
            'healthy_leaves': Detection.objects.filter(is_healthy=True).count(),
            'diseased_leaves': Detection.objects.filter(is_healthy=False).count(),
        },
        'most_common_disease': most_common,
        'disease_distribution': list(dist),
    })


@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_users(request):
    from apps.authentication.models import User
    from apps.authentication.serializers import UserSerializer
    qs = User.objects.all().order_by('-created_at')
    search = request.GET.get('search', '').strip()
    if search:
        qs = qs.filter(full_name__icontains=search) | qs.filter(username__icontains=search)
    limit = min(int(request.GET.get('limit', 50)), 500)
    offset = int(request.GET.get('offset', 0))
    return Response({'success': True, 'users': UserSerializer(qs[offset:offset + limit], many=True).data})


@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_activities(request):
    qs = Activity.objects.select_related('user').order_by('-timestamp')
    search = request.GET.get('search', '').strip()
    if search:
        qs = qs.filter(user__full_name__icontains=search) | qs.filter(user__username__icontains=search)
    ft = request.GET.get('filter', '').strip().upper()
    if ft:
        qs = qs.filter(activity_type=ft)
    limit = min(int(request.GET.get('limit', 100)), 1000)
    offset = int(request.GET.get('offset', 0))
    return Response({'success': True, 'activities': ActivitySerializer(qs[offset:offset + limit], many=True).data})


@api_view(['GET'])
@permission_classes([IsAdminUser])
def export_activities(request):
    acts = Activity.objects.select_related('user').order_by('-timestamp')
    resp = HttpResponse(content_type='text/csv')
    resp['Content-Disposition'] = 'attachment; filename=activities.csv'
    w = csv.writer(resp)
    w.writerow(['User Name', 'Username', 'Activity Type', 'Description', 'Timestamp'])
    for a in acts:
        w.writerow([a.user.full_name, a.user.username, a.activity_type, a.description, a.timestamp])
    return resp


@api_view(['DELETE'])
@permission_classes([IsAdminUser])
def delete_activity(request, activity_id):
    Activity.objects.filter(id=activity_id).delete()
    return Response({'success': True, 'message': 'Activity deleted.'})


# ── DISEASE CRUD ───────────────────────────────────────────────────────────────

@api_view(['GET', 'POST'])
@permission_classes([IsAdminUser])
def diseases(request):
    if request.method == 'GET':
        return Response({'success': True, 'diseases': DiseaseSerializer(Disease.objects.all(), many=True).data})
    s = DiseaseSerializer(data=request.data)
    if not s.is_valid():
        return Response({'success': False, 'message': str(next(iter(s.errors.values()))[0])}, status=400)
    d = s.save()
    return Response({'success': True, 'message': 'Disease added.', 'id': d.id}, status=201)


@api_view(['PUT', 'DELETE'])
@permission_classes([IsAdminUser])
def disease_detail(request, disease_id):
    try:
        disease = Disease.objects.get(id=disease_id)
    except Disease.DoesNotExist:
        return Response({'success': False, 'message': 'Disease not found.'}, status=404)
    if request.method == 'DELETE':
        disease.delete()
        return Response({'success': True, 'message': 'Disease deleted.'})
    s = DiseaseSerializer(disease, data=request.data, partial=True)
    if not s.is_valid():
        return Response({'success': False, 'message': str(next(iter(s.errors.values()))[0])}, status=400)
    s.save()
    return Response({'success': True, 'message': 'Disease updated.'})


# ── PESTICIDE CRUD ─────────────────────────────────────────────────────────────

@api_view(['GET', 'POST'])
@permission_classes([IsAdminUser])
def pesticides(request):
    if request.method == 'GET':
        return Response({'success': True, 'pesticides': PesticideSerializer(
            Pesticide.objects.select_related('disease').all(), many=True).data})
    s = PesticideSerializer(data=request.data)
    if not s.is_valid():
        return Response({'success': False, 'message': str(next(iter(s.errors.values()))[0])}, status=400)
    p = s.save()
    return Response({'success': True, 'message': 'Pesticide added.', 'id': p.id}, status=201)


@api_view(['PUT', 'DELETE'])
@permission_classes([IsAdminUser])
def pesticide_detail(request, pesticide_id):
    try:
        pesticide = Pesticide.objects.get(id=pesticide_id)
    except Pesticide.DoesNotExist:
        return Response({'success': False, 'message': 'Pesticide not found.'}, status=404)
    if request.method == 'DELETE':
        pesticide.delete()
        return Response({'success': True, 'message': 'Pesticide deleted.'})
    s = PesticideSerializer(pesticide, data=request.data, partial=True)
    if not s.is_valid():
        return Response({'success': False, 'message': str(next(iter(s.errors.values()))[0])}, status=400)
    s.save()
    return Response({'success': True, 'message': 'Pesticide updated.'})


# ── AI MODEL SWITCHING ─────────────────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAdminUser])
def active_model_info(request):
    active = SystemConfig.get('active_model', settings.ACTIVE_AI_MODEL)
    try:
        classes = get_model().classes
    except Exception:
        classes = []
    return Response({'success': True, 'active_model': active, 'classes': classes})


@api_view(['POST'])
@permission_classes([IsAdminUser])
def switch_model(request):
    model_type = request.data.get('model_type', '').strip()
    if model_type not in ('keras', 'tflite'):
        return Response({'success': False, 'message': 'model_type must be keras or tflite.'}, status=400)
    do_switch_model(model_type)
    return Response({'success': True, 'message': f'Switched to {model_type} model.', 'active_model': model_type})
