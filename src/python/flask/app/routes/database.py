from flask import Blueprint, request, jsonify, current_app
from app.services.database import get_db_service
import asyncio
from datetime import datetime

bp = Blueprint('database', __name__, url_prefix='/db')

@bp.route('/simple')
def db_simple():
    """Simple database query endpoint"""
    user_id = request.args.get('id')
    if not user_id:
        return jsonify({
            'error': 'Bad Request',
            'message': 'id parameter is required'
        }), 400

    try:
        user_id = int(user_id)
    except ValueError:
        return jsonify({
            'error': 'Bad Request',
            'message': 'id must be a number'
        }), 400

    try:
        db_service = get_db_service()
        user = asyncio.run(db_service.find_user_by_id(user_id))

        if not user:
            return jsonify({
                'error': 'Not Found',
                'message': f'User with id {user_id} not found'
            }), 404

        return jsonify(user)
    except Exception as e:
        current_app.logger.error(f"Database simple query failed: {str(e)}")
        return jsonify({
            'error': 'Database query failed',
            'message': str(e)
        }), 500

@bp.route('/complex')
def db_complex():
    """Complex database query with joins endpoint"""
    try:
        days = request.args.get('days', type=int, default=30)

        if days <= 0 or days > 365:
            return jsonify({
                'error': 'Bad Request',
                'message': 'days must be between 1 and 365'
            }), 400

        db_service = get_db_service()
        data = asyncio.run(db_service.get_user_stats(days))

        return jsonify({
            'period_days': days,
            'total_users': len(data),
            'data': data,
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        current_app.logger.error(f"Database complex query failed: {str(e)}")
        return jsonify({
            'error': 'Database query failed',
            'message': str(e)
        }), 500

