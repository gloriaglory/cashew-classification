from django.db import models
from apps.authentication.models import User


class Disease(models.Model):
    disease_name = models.CharField(max_length=150, unique=True, db_index=True)
    description = models.TextField()
    symptoms = models.TextField()
    prevention = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'diseases'
        ordering = ['disease_name']

    def __str__(self):
        return self.disease_name


class Pesticide(models.Model):
    disease = models.ForeignKey(Disease, on_delete=models.CASCADE, related_name='pesticides')
    pesticide_name = models.CharField(max_length=200)
    dosage = models.CharField(max_length=255)
    application_method = models.TextField()
    recommendation = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'pesticides'

    def __str__(self):
        return f"{self.pesticide_name} ({self.disease.disease_name})"


class Detection(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='detections')
    disease = models.ForeignKey(Disease, on_delete=models.SET_NULL, null=True, related_name='detections')
    image_path = models.CharField(max_length=500)
    confidence_score = models.DecimalField(max_digits=5, decimal_places=2)
    pesticide_recommended = models.CharField(max_length=200, blank=True)
    is_healthy = models.BooleanField(default=False)
    detection_date = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'detections'
        ordering = ['-detection_date']


class Activity(models.Model):
    TYPES = [
        ('REGISTER', 'Register'), ('LOGIN', 'Login'),
        ('LOGOUT', 'Logout'), ('DETECTION', 'Detection'),
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='activities')
    activity_type = models.CharField(max_length=80, choices=TYPES)
    description = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'activities'
        ordering = ['-timestamp']


class SystemConfig(models.Model):
    """Key-value store for runtime settings (e.g. active AI model)."""
    key = models.CharField(max_length=100, unique=True)
    value = models.CharField(max_length=255)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'system_config'

    @classmethod
    def get(cls, key, default=None):
        try:
            return cls.objects.get(key=key).value
        except cls.DoesNotExist:
            return default

    @classmethod
    def set(cls, key, value):
        obj, _ = cls.objects.get_or_create(key=key)
        obj.value = value
        obj.save()
        return obj
