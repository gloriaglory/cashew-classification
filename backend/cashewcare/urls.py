from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, include
from django.http import JsonResponse


def health(request):
    return JsonResponse({'status': 'ok', 'service': 'CashewCare AI API'})


urlpatterns = [
    path('api/health', health),
    path('api/', include('apps.authentication.urls')),
    path('api/', include('apps.detection.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
