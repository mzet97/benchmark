from flask import Blueprint, request, jsonify, current_app
from app.services.database import get_db_service
from datetime import datetime

bp = Blueprint('database', __name__)


@bp.route('/db/simple')
def db_simple():
    """Simple database query endpoint"""
    user_id = request.args.get('id')
    if not user_id:
        return jsonify({
            'error': 'Invalid id parameter'
        }), 400

    try:
        user_id = int(user_id)
    except ValueError:
        return jsonify({
            'error': 'Invalid id parameter'
        }), 400

    try:
        db_service = get_db_service()
        user = db_service.find_user_by_id(user_id)

        if not user:
            return jsonify({
                'error': f'User with id {user_id} not found'
            }), 404

        return jsonify(user)
    except Exception as e:
        current_app.logger.error(f"Database simple query failed: {str(e)}")
        return jsonify({
            'error': 'Database query failed'
        }), 500


@bp.route('/db/complex')
def db_complex():
    """Complex database query with joins endpoint"""
    try:
        days = request.args.get('days', type=int, default=30)

        if days <= 0 or days > 365:
            return jsonify({
                'error': 'Days must be between 1 and 365'
            }), 400

        db_service = get_db_service()
        data = db_service.get_user_stats(days)

        return jsonify({
            'periodDays': days,
            'totalUsers': len(data),
            'data': data
        })
    except Exception as e:
        current_app.logger.error(f"Database complex query failed: {str(e)}")
        return jsonify({
            'error': 'Database query failed'
        }), 500
