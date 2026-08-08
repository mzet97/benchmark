from django.urls import path

# Import the view modules explicitly. `from . import views` only imports the
# package (runs __init__.py); the submodules (health, json, ...) are not
# loaded automatically, so `views.health` raised
# "AttributeError: module 'benchmark.views' has no attribute 'health'".
from .views import health, json, database, cache

urlpatterns = [
    path('', health.health, name='root'),
    path('health', health.health, name='health'),
    path('healthz', health.healthz, name='healthz'),
    path('json', json.json_endpoint, name='json'),
    path('db/simple', database.db_simple, name='db_simple'),
    path('db/complex', database.db_complex, name='db_complex'),
    path('cache', cache.cache, name='cache'),
]
