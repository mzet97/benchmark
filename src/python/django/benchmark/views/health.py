from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db import connection
from benchmark.services.cache_service import CacheService
from datetime import datetime

@api_view(['GET'])
def health(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        db_status = 'connected'
    except:
        db_status = 'disconnected'

    cache_status = 'connected' if CacheService.ping() else 'disconnected'

    return Response({
        'status': 'healthy' if db_status == 'connected' and cache_status == 'connected' else 'unhealthy',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat(),
        'database': db_status,
        'cache': cache_status
    })

@api_view(['GET'])
def healthz(request):
    return Response({'status': 'ok'})
