from rest_framework import serializers
from .models import Disease, Pesticide, Detection, Activity


class PesticideSerializer(serializers.ModelSerializer):
    disease_name = serializers.CharField(source='disease.disease_name', read_only=True)

    class Meta:
        model = Pesticide
        fields = ['id', 'disease', 'disease_name', 'pesticide_name', 'dosage',
                  'application_method', 'recommendation', 'created_at']


class DiseaseSerializer(serializers.ModelSerializer):
    pesticides = PesticideSerializer(many=True, read_only=True)

    class Meta:
        model = Disease
        fields = ['id', 'disease_name', 'description', 'symptoms', 'prevention',
                  'pesticides', 'created_at']


class DetectionSerializer(serializers.ModelSerializer):
    disease_name = serializers.SerializerMethodField()
    description = serializers.SerializerMethodField()
    symptoms = serializers.SerializerMethodField()
    prevention = serializers.SerializerMethodField()

    def get_disease_name(self, obj):
        return obj.disease.disease_name if obj.disease else 'Unknown'

    def get_description(self, obj):
        return obj.disease.description if obj.disease else ''

    def get_symptoms(self, obj):
        return obj.disease.symptoms if obj.disease else ''

    def get_prevention(self, obj):
        return obj.disease.prevention if obj.disease else ''

    class Meta:
        model = Detection
        fields = ['id', 'image_path', 'confidence_score', 'is_healthy',
                  'pesticide_recommended', 'detection_date', 'disease_name',
                  'description', 'symptoms', 'prevention']


class ActivitySerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = Activity
        fields = ['id', 'user_name', 'username', 'activity_type', 'description', 'timestamp']
