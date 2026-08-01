from flask import Blueprint, request, jsonify, current_app
from app.services.cache import get_cache_service
import time
from datetime import datetime

bp = Blueprint('cache', __name__)

# The TTL is part of the response contract and must match what is written
# to Redis. See contracts/rest/canonical-payloads.md.
CACHE_TTL_SECONDS = 300


@bp.route('/cache')
def cache_endpoint():
    """Cache operations endpoint"""
    try:
        key = request.args.get('key', default='test')
        if not key:
            return jsonify({
                'error': 'Key parameter is required'
            }), 400

        cache_service = get_cache_service()

        # Try to get from cache first
        cached_value = cache_service.get(key)

        if cached_value:
            return jsonify({
                'key': key,
                'value': cached_value,
                'cached': True,
                'ttl': CACHE_TTL_SECONDS,
                'timestamp': datetime.utcnow().isoformat()
            })

        # If not in cache, create new value
        value = f"Cached value for {key} at {datetime.utcnow().isoformat()}"

        # Store in cache with 5 minute TTL
        cache_service.set(key, value, ttl=CACHE_TTL_SECONDS)

        return jsonify({
            'key': key,
            'value': value,
            'cached': False,
            'ttl': CACHE_TTL_SECONDS,
            'timestamp': datetime.utcnow().isoformat()
        })

    except Exception as e:
        current_app.logger.error(f"Cache operation failed: {str(e)}")
        return jsonify({
            'error': 'Cache operation failed'
        }), 500
