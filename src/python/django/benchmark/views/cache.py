from rest_framework.decorators import api_view
from rest_framework.response import Response
from benchmark.services.cache_service import CacheService
from datetime import datetime

# The TTL is part of the response contract and must match what is written
# to Redis. See contracts/rest/canonical-payloads.md.
CACHE_TTL_SECONDS = 300

@api_view(['GET'])
def cache(request):
    key = request.GET.get('key', 'test')
    value, was_cached = CacheService.get_or_set(key)

    return Response({
        'key': key,
        'value': value,
        'cached': was_cached,
        'ttl': CACHE_TTL_SECONDS,
        'timestamp': datetime.utcnow().isoformat()
    })
