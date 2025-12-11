from flask import Blueprint, request, jsonify, current_app
from app.services.cache import get_cache_service
import asyncio
import time
from datetime import datetime

bp = Blueprint('cache', __name__)

@bp.route('')
def cache_endpoint():
    """Cache operations endpoint"""
    try:
        key = request.args.get('key', default='test')
        cache_service = get_cache_service()

        # Try to get from cache first
        cached_value = asyncio.run(cache_service.get(key))

        if cached_value:
            current_app.logger.info("Cache hit", extra={'key': key})
            return jsonify({
                'key': key,
                'value': cached_value,
                'cached': True,
                'timestamp': datetime.utcnow().isoformat()
            })

        # If not in cache, create new value
        value = f"cached-value-{key}-{int(time.time() * 1000)}"

        # Store in cache with 5 minute TTL
        asyncio.run(cache_service.set(key, value, ttl=300))

        current_app.logger.info("Cache miss - value stored", extra={'key': key})

        return jsonify({
            'key': key,
            'value': value,
            'cached': False,
            'timestamp': datetime.utcnow().isoformat()
        })

    except Exception as e:
        current_app.logger.error(f"Cache operation failed: {str(e)}")
        return jsonify({
            'error': 'Cache operation failed',
            'message': str(e)
        }), 500
