from rest_framework.decorators import api_view
from rest_framework.response import Response
from datetime import datetime

@api_view(['GET'])
def json_endpoint(request):
    items = [{'id': i, 'name': f'User {i}', 'email': f'user{i}@example.com', 'timestamp': datetime.utcnow().isoformat()} for i in range(1000)]
    return Response({'items': items, 'count': len(items), 'timestamp': datetime.utcnow().isoformat()})
