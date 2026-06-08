from django.contrib import admin
from .models import Disease, Pesticide, Detection, Activity, SystemConfig


@admin.register(Disease)
class DiseaseAdmin(admin.ModelAdmin):
    list_display = ['disease_name', 'created_at']
    search_fields = ['disease_name']


@admin.register(Pesticide)
class PesticideAdmin(admin.ModelAdmin):
    list_display = ['pesticide_name', 'disease', 'dosage']
    list_filter = ['disease']


@admin.register(Detection)
class DetectionAdmin(admin.ModelAdmin):
    list_display = ['user', 'disease', 'confidence_score', 'is_healthy', 'detection_date']
    list_filter = ['is_healthy']
    date_hierarchy = 'detection_date'


@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ['user', 'activity_type', 'description', 'timestamp']
    list_filter = ['activity_type']


@admin.register(SystemConfig)
class SystemConfigAdmin(admin.ModelAdmin):
    list_display = ['key', 'value', 'updated_at']
