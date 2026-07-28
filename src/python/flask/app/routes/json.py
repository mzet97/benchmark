from flask import Blueprint, jsonify
from datetime import datetime
import uuid

bp = Blueprint('json', __name__)


@bp.route('/json')
def json_endpoint():
    """JSON serialization endpoint - returns 1000 objects"""
    timestamp = datetime.utcnow().isoformat()
    items = [
        {
            'id': i,
            'uuid': str(uuid.uuid4()),
            'name': f'Item {i}',
            'description': f'This is item number {i}',
            'timestamp': timestamp,
            'random': f'data-{uuid.uuid4()}'
        }
        for i in range(1000)
    ]
    return jsonify({
        'items': items,
        'count': len(items),
        'timestamp': timestamp
    })
