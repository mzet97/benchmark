from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from benchmark.services.database_service import DatabaseService
from datetime import datetime

@api_view(['GET'])
def db_simple(request):
    user_id = request.GET.get('id')
    if not user_id:
        return Response({'error': 'Bad Request', 'message': 'id parameter is required'}, status=400)

    try:
        user_id = int(user_id)
    except ValueError:
        return Response({'error': 'Bad Request', 'message': 'id must be a number'}, status=400)

    try:
        user = DatabaseService.get_user_by_id(user_id)
        if not user:
            return Response({'error': 'Not Found', 'message': f'User with id {user_id} not found'}, status=404)

        return Response(user)
    except Exception as e:
        return Response({'error': 'Internal Server Error', 'message': str(e)}, status=500)

@api_view(['GET'])
def db_complex(request):
    days = request.GET.get('days', '30')
    try:
        days = int(days)
    except ValueError:
        return Response({'error': 'Bad Request', 'message': 'days must be a number'}, status=400)

    if days <= 0 or days > 365:
        return Response({'error': 'Bad Request', 'message': 'days must be between 1 and 365'}, status=400)

    try:
        data = DatabaseService.get_complex_query(days)
        return Response({
            'periodDays': days,
            'totalUsers': len(data),
            'data': data,
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        return Response({'error': 'Internal Server Error', 'message': str(e)}, status=500)
