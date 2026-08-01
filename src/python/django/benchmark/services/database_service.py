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
                "SELECT id, email, first_name, last_name, age, created_at "
                "FROM users WHERE id = %s",
                [user_id]
            )
            row = cursor.fetchone()

            if not row:
                return None

            # Wire names are camelCase; see contracts/rest/canonical-payloads.md.
            return {
                'id': row[0],
                'email': row[1],
                'firstName': row[2],
                'lastName': row[3],
                'age': row[4],
                'createdAt': row[5]
            }

    @staticmethod
    def get_complex_query(days: int) -> List[Dict[str, Any]]:
        """Execute complex query with aggregation"""
        with connection.cursor() as cursor:
            # Normative SQL, see contracts/rest/canonical-payloads.md. The
            # previous query interpolated `days` straight into the SQL with an
            # f-string, and ordered only by total_value, so rows with equal
            # values came back in arbitrary order.
            cursor.execute("""
                SELECT
                    u.id AS user_id,
                    u.first_name || ' ' || u.last_name AS user_name,
                    COUNT(o.id) AS total_orders,
                    COALESCE(SUM(o.total_amount), 0) AS total_value,
                    COALESCE(AVG(o.total_amount), 0) AS average_order_value
                FROM users u
                INNER JOIN orders o ON u.id = o.user_id
                    WHERE o.created_at >= NOW() - INTERVAL '1 day' * %s
                GROUP BY u.id, u.first_name, u.last_name
                ORDER BY total_orders DESC, u.id
                LIMIT 100
            """, [days])
            rows = cursor.fetchall()

            return [
                {
                    'userId': row[0],
                    'userName': row[1],
                    'totalOrders': row[2],
                    'totalValue': float(row[3]),
                    'averageOrderValue': float(row[4])
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
