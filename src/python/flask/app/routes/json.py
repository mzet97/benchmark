from flask import Blueprint, jsonify
from datetime import datetime

bp = Blueprint('json', __name__)

@bp.route('')
def json_endpoint():
    """Simple JSON response endpoint for benchmarking"""
    timestamp = datetime.utcnow().isoformat()
    items = [
        {
            'id': i,
            'name': f'User {i}',
            'email': f'user{i}@example.com',
            'timestamp': timestamp
        }
        for i in range(1000)
    ]
    return jsonify({
        'items': items,
        'count': len(items),
        'timestamp': timestamp
    })
