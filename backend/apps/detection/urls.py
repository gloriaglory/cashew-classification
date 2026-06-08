from django.urls import path
from . import views

urlpatterns = [
    # User endpoints (match original Flask URL paths for Flutter compatibility)
    path('predict', views.predict),
    path('dashboard-stats', views.dashboard_stats),
    path('history', views.history),
    path('history/<int:detection_id>', views.detection_detail),

    # Admin API
    path('admin/statistics', views.admin_statistics),
    path('admin/users', views.admin_users),
    path('admin/activities', views.admin_activities),
    path('admin/activities/export', views.export_activities),
    path('admin/activities/<int:activity_id>', views.delete_activity),

    # Disease CRUD (Flask-compatible paths)
    path('admin/diseases', views.diseases),
    path('admin/add-disease', views.diseases),              # POST alias
    path('admin/update-disease/<int:disease_id>', views.disease_detail),
    path('admin/delete-disease/<int:disease_id>', views.disease_detail),

    # Pesticide CRUD (Flask-compatible paths)
    path('admin/pesticides', views.pesticides),
    path('admin/add-pesticide', views.pesticides),          # POST alias
    path('admin/update-pesticide/<int:pesticide_id>', views.pesticide_detail),
    path('admin/delete-pesticide/<int:pesticide_id>', views.pesticide_detail),

    # AI model switching
    path('admin/model', views.active_model_info),
    path('admin/model/switch', views.switch_model),
]
