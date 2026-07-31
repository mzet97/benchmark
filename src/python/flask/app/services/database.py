"""
Database service using psycopg2 (sync driver for Flask)
"""

import psycopg2
import psycopg2.extras
import structlog
from typing import Optional, List, Dict, Any
import os

logger = structlog.get_logger(__name__)

DATABASE_URL = os.environ["DATABASE_URL"]


class DatabaseService:
    """Database service with connection pooling"""

    def __init__(self):
        self._conn = None

    def _get_conn(self):
        """Get or create database connection"""
        if self._conn is None or self._conn.closed:
            self._conn = psycopg2.connect(DATABASE_URL)
            self._conn.autocommit = True
        return self._conn

    def health_check(self) -> Dict[str, Any]:
        """Check database health"""
        try:
            conn = self._get_conn()
            with conn.cursor() as cur:
                cur.execute("SELECT 1 as status")
                result = cur.fetchone()
                return {
                    'status': 'healthy',
                    'database': 'connected',
                    'result': {'status': result[0]}
                }
        except Exception as e:
            logger.error("Database health check failed", error=str(e))
            return {
                'status': 'unhealthy',
                'database': 'disconnected',
                'error': str(e)
            }

    def find_user_by_id(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Find user by ID"""
        try:
            conn = self._get_conn()
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute("""
                    SELECT id, email, first_name, last_name, age, created_at
                    FROM users
                    WHERE id = %s
                """, (user_id,))
                row = cur.fetchone()
                if row:
                    return dict(row)
                return None
        except Exception as e:
            logger.error("Error finding user", user_id=user_id, error=str(e))
            return None

    def get_user_stats(self, days: int) -> List[Dict[str, Any]]:
        """Get user statistics with aggregation"""
        try:
            conn = self._get_conn()
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute("""
                    SELECT u.id as user_id,
                           CONCAT(u.first_name, ' ', u.last_name) as user_name,
                           COUNT(DISTINCT o.id) as total_orders,
                           COALESCE(SUM(o.total_amount), 0) as total_value,
                           COALESCE(AVG(o.total_amount), 0) as average_value
                    FROM users u
                    LEFT JOIN orders o ON u.id = o.user_id
                      AND o.created_at >= NOW() - INTERVAL '%s days'
                    GROUP BY u.id, u.first_name, u.last_name
                    HAVING COUNT(DISTINCT o.id) > 0
                    ORDER BY total_value DESC
                    LIMIT 100
                """, (days,))
                rows = cur.fetchall()
                return [dict(row) for row in rows]
        except Exception as e:
            logger.error("Error getting user stats", days=days, error=str(e))
            return []

    def close(self):
        """Close database connection"""
        if self._conn and not self._conn.closed:
            self._conn.close()


# Global database service instance
db_service: Optional[DatabaseService] = None


def get_db_service() -> DatabaseService:
    """Get database service instance"""
    global db_service
    if db_service is None:
        db_service = DatabaseService()
    return db_service
