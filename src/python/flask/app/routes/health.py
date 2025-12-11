from flask import Blueprint, current_app
from app.services.database import get_db_service
from app.services.cache import get_cache_service
from datetime import datetime
import asyncio

bp = Blueprint('health', __name__, url_prefix='/health')

@bp.route('/')
def root():
    """Root endpoint"""
    return {
        'name': 'Benchmark API - Python Flask',
        'version': '1.0.0',
        'runtime': 'Python',
        'framework': 'Flask',
        'database': 'PostgreSQL',
        'cache': 'Redis',
        'status': 'running'
    }

@bp.route('')
def health_check():
    """Health check endpoint that verifies database and cache connectivity"""
    try:
        db_service = get_db_service()
        cache_service = get_cache_service()

        # Check database health
        db_result = asyncio.run(db_service.health_check())
        db_status = 'connected' if db_result.get('database') == 'connected' else 'disconnected'

        # Check cache health
        cache_result = asyncio.run(cache_service.health_check())
        cache_status = 'connected' if cache_result.get('cache') == 'connected' else 'disconnected'

        overall_status = 'healthy' if db_status == 'connected' and cache_status == 'connected' else 'unhealthy'

        return {
            'status': overall_status,
            'version': '1.0.0',
            'timestamp': datetime.utcnow().isoformat(),
            'database': db_status,
            'cache': cache_status
        }
    except Exception as e:
        current_app.logger.error(f"Health check failed: {str(e)}")
        return {
            'status': 'error',
            'version': '1.0.0',
            'timestamp': datetime.utcnow().isoformat(),
            'database': 'disconnected',
            'cache': 'disconnected',
            'error': 'Internal server error'
        }, 500

@bp.route('/healthz')
def healthz():
    """Kubernetes-style health check"""
    return {'status': 'ok'}
