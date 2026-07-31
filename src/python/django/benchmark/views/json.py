from datetime import datetime, timezone

from rest_framework.decorators import api_view
from rest_framework.response import Response

# Canonical /json payload. See contracts/rest/canonical-payloads.md.
#
# The previous implementation called datetime.utcnow() inside the list
# comprehension -- 1000 clock reads per request -- and returned a shape that
# matched neither the proto nor any other implementation.
DEFAULT_ITEMS = 1000
MAX_ITEMS = 10000
CANONICAL_CREATED_AT = '2026-01-01T00:00:00Z'


def canonical_item(i):
    """Item content is a pure function of the index: no randomness, no clock."""
    return {
        'id': i,
        'uuid': f'00000000-0000-0000-0000-{i:012d}',
        'name': f'Item {i}',
        'email': f'item{i}@benchmark.local',
        'createdAt': CANONICAL_CREATED_AT,
        'isActive': i % 2 == 0,
    }


def item_count(request):
    """
    Parse ?n=. On a 1 GbE link n=1000 is network-bound at ~734 rps, so the
    serialization ranking is taken at n=100.
    """
    raw = request.GET.get('n')
    if raw is None:
        return DEFAULT_ITEMS
    try:
        n = int(raw)
    except (TypeError, ValueError):
        return DEFAULT_ITEMS
    if n < 0:
        return DEFAULT_ITEMS
    return min(n, MAX_ITEMS)


@api_view(['GET'])
def json_endpoint(request):
    n = item_count(request)
    # The envelope timestamp is the only clock-dependent field and is excluded
    # from the parity hash.
    return Response({
        'items': [canonical_item(i) for i in range(n)],
        'count': n,
        'timestamp': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    })
