"""
Database service using asyncpg
"""

import asyncio
import asyncpg
import structlog
from typing import Optional, List, Dict, Any
import os

logger = structlog.get_logger(__name__)

class DatabaseService:
    """Database service with connection pooling"""

    def __init__(self, database_url: str):
        self.database_url = database_url
        self._pool: Optional[asyncpg.Pool] = None

    async def initialize(self):
        """Initialize database connection pool"""
        try:
            self._pool = await asyncpg.create_pool(
                self.database_url,
                min_size=5,
                max_size=25,
                command_timeout=60,
                server_settings={
                    'application_name': 'benchmark_flask'
                }
            )
            logger.info("Database connection pool initialized")
        except Exception as e:
            logger.error("Failed to initialize database pool", error=str(e))
            raise

    async def close(self):
        """Close database connection pool"""
        if self._pool:
            await self._pool.close()
            logger.info("Database connection pool closed")

    async def health_check(self) -> Dict[str, Any]:
        """Check database health"""
        try:
            async with self._pool.acquire() as conn:
                result = await conn.fetchrow("SELECT 1 as status")
                return {
                    'status': 'healthy',
                    'database': 'connected',
                    'result': dict(result)
                }
        except Exception as e:
            logger.error("Database health check failed", error=str(e))
            return {
                'status': 'unhealthy',
                'database': 'disconnected',
                'error': str(e)
            }

    async def find_user_by_id(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Find user by ID"""
        try:
            async with self._pool.acquire() as conn:
                row = await conn.fetchrow("""
                    SELECT id, email, first_name, last_name, age, created_at
                    FROM users
                    WHERE id = $1
                """, user_id)

                if row:
                    return dict(row)
                return None
        except Exception as e:
            logger.error("Error finding user", user_id=user_id, error=str(e))
            return None

    async def get_user_stats(self, days: int) -> List[Dict[str, Any]]:
        """Get user statistics with aggregation"""
        try:
            async with self._pool.acquire() as conn:
                rows = await conn.fetch("""
                    SELECT u.id as user_id,
                           CONCAT(u.first_name, ' ', u.last_name) as user_name,
                           COUNT(DISTINCT o.id) as total_orders,
                           COALESCE(SUM(o.total_amount), 0) as total_value,
                           COALESCE(AVG(o.total_amount), 0) as average_value
                    FROM users u
                    LEFT JOIN orders o ON u.id = o.user_id
                      AND o.created_at >= NOW() - INTERVAL '$1 days'
                    GROUP BY u.id, u.first_name, u.last_name
                    HAVING COUNT(DISTINCT o.id) > 0
                    ORDER BY total_value DESC
                    LIMIT 100
                """, days)

                return [dict(row) for row in rows]
        except Exception as e:
            logger.error("Error getting user stats", days=days, error=str(e))
            return []

    async def execute_query(self, query: str, *args) -> List[Dict[str, Any]]:
        """Execute a custom query"""
        try:
            async with self._pool.acquire() as conn:
                rows = await conn.fetch(query, *args)
                return [dict(row) for row in rows]
        except Exception as e:
            logger.error("Error executing query", query=query, error=str(e))
            return []

# Global database service instance
db_service: Optional[DatabaseService] = None

def get_db_service() -> DatabaseService:
    """Get database service instance"""
    global db_service
    if db_service is None:
        db_service = DatabaseService(
            database_url=os.getenv('DATABASE_URL', 'postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api')
        )
    return db_service
