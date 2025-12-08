import asyncpg
from typing import Optional, List
from app.models.user import User
from app.models.complex_order import ComplexOrderResult
import structlog
import os


logger = structlog.get_logger()


class DatabaseService:
    """Database service for PostgreSQL operations"""

    def __init__(self):
        self._pool: Optional[asyncpg.Pool] = None
        self.connection_string = os.getenv(
            "DATABASE_URL",
            "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
        )

    async def init_pool(self):
        """Initialize connection pool"""
        if self._pool is None:
            logger.info("Initializing database connection pool")
            self._pool = await asyncpg.create_pool(
                self.connection_string,
                min_size=5,
                max_size=25,
                command_timeout=60,
                server_settings={
                    'application_name': 'benchmark-api'
                }
            )
            logger.info("Database connection pool initialized")

    async def close_pool(self):
        """Close connection pool"""
        if self._pool:
            await self._pool.close()
            logger.info("Database connection pool closed")

    async def find_user_by_id(self, user_id: int) -> Optional[User]:
        """Find user by ID"""
        query = """
            SELECT id, email, first_name, last_name, age, created_at
            FROM users
            WHERE id = $1
        """

        try:
            async with self._pool.acquire() as conn:
                row = await conn.fetchrow(query, user_id)
                if row:
                    return User(**dict(row))
                return None
        except Exception as e:
            logger.error("Error fetching user", user_id=user_id, error=str(e))
            raise

    async def find_complex_orders(self, days: int) -> List[ComplexOrderResult]:
        """Find complex order statistics"""
        query = """
            SELECT
                u.id as user_id,
                u.email,
                COUNT(o.id) as order_count,
                SUM(o.total_amount) as total_amount,
                AVG(o.total_amount) as avg_amount,
                EXTRACT(DAY FROM (NOW() - MIN(o.created_at))) as days_since_first_order
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
            WHERE o.created_at >= NOW() - ($1 || ' days')::INTERVAL
            GROUP BY u.id, u.email
            ORDER BY order_count DESC
            LIMIT 100
        """

        try:
            async with self._pool.acquire() as conn:
                rows = await conn.fetch(query, days)
                return [ComplexOrderResult(**dict(row)) for row in rows]
        except Exception as e:
            logger.error("Error fetching complex orders", days=days, error=str(e))
            raise

    async def health_check(self) -> bool:
        """Perform database health check"""
        query = "SELECT 1"

        try:
            async with self._pool.acquire() as conn:
                result = await conn.fetchval(query)
                return result == 1
        except Exception as e:
            logger.error("Database health check failed", error=str(e))
            return False
