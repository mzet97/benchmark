from django.db import connection
from typing import Optional, List, Dict, Any
from datetime import datetime


class DatabaseService:
    """Service for database operations"""

    @staticmethod
    def get_user_by_id(user_id: int) -> Optional[Dict[str, Any]]:
        """Get user by ID from database"""
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = %s",
                [user_id]
            )
            row = cursor.fetchone()

            if not row:
                return None

            return {
                'id': row[0],
                'email': row[1],
                'first_name': row[2],
                'last_name': row[3],
                'age': row[4],
                'created_at': row[5]
            }

    @staticmethod
    def get_complex_query(days: int) -> List[Dict[str, Any]]:
        """Execute complex query with aggregation"""
        with connection.cursor() as cursor:
            cursor.execute(f"""
                SELECT u.id as user_id, CONCAT(u.first_name, ' ', u.last_name) as user_name,
                       COUNT(DISTINCT o.id) as total_orders,
                       COALESCE(SUM(o.total_amount), 0) as total_value,
                       COALESCE(AVG(o.total_amount), 0) as average_value
                FROM users u
                LEFT JOIN orders o ON u.id = o.user_id
                  AND o.created_at >= NOW() - INTERVAL '{days} days'
                GROUP BY u.id, u.first_name, u.last_name
                HAVING COUNT(DISTINCT o.id) > 0
                ORDER BY total_value DESC
                LIMIT 100
            """)
            rows = cursor.fetchall()

            return [
                {
                    'user_id': row[0],
                    'user_name': row[1],
                    'total_orders': row[2],
                    'total_value': float(row[3]),
                    'average_value': float(row[4])
                }
                for row in rows
            ]

    @staticmethod
    def health_check() -> bool:
        """Check database health"""
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            return True
        except Exception as e:
            print(f"Database health check failed: {e}")
            return False
