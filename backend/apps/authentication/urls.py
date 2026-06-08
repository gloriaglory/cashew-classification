from django.urls import path
from . import views

urlpatterns = [
    path('register', views.register),
    path('login', views.login),
    path('admin/login', views.admin_login),
    path('logout', views.logout),
    path('profile', views.profile),
    path('change-password', views.change_password),
]
