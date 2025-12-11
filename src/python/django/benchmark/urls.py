from django.urls import path
from . import views

urlpatterns = [
    path('', views.health.health, name='root'),
    path('health', views.health.health, name='health'),
    path('healthz', views.health.healthz, name='healthz'),
    path('json', views.json.json_endpoint, name='json'),
    path('db/simple', views.database.db_simple, name='db_simple'),
    path('db/complex', views.database.db_complex, name='db_complex'),
    path('cache', views.cache.cache, name='cache'),
]
