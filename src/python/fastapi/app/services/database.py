import asyncpg
from typing import Optional, List
from app.models.user import User, UserStats
import structlog
import os


logger = structlog.get_logger()


class DatabaseService:
    """Database service for PostgreSQL operations"""

    def __init__(self):
        self._pool: Optional[asyncpg.Pool] = None
        self.connection_string = os.environ["DATABASE_URL"]

    async def init_pool(self):
        """Initialize connection pool"""
        if self._pool is None:
            logger.info("Initializing database connection pool")
            # Parse connection string manually to handle special chars in password
            # Format: postgresql://user:password@host:port/database
            from urllib.parse import urlparse
            parsed = urlparse(self.connection_string)
            
            self._pool = await asyncpg.create_pool(
                user=parsed.username,
                password=parsed.password,
                host=parsed.hostname,
                port=parsed.port or 5432,
                database=parsed.path.lstrip('/'),
                min_size=5,
                max_size=25,
                command_timeout=60,
                ssl=False,
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
            SELECT id, email, first_name AS "firstName", last_name AS "lastName",
                   age, created_at AS "createdAt"
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

    async def get_user_stats(self, days: int) -> List[UserStats]:
        """Get user statistics with aggregation"""
        query = """
            SELECT
                u.id AS "userId",
                u.first_name || ' ' || u.last_name AS "userName",
                COUNT(o.id) AS "totalOrders",
                COALESCE(SUM(o.total_amount), 0) AS "totalValue",
                COALESCE(AVG(o.total_amount), 0) AS "averageOrderValue"
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
                WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY "totalOrders" DESC, u.id
            LIMIT 100
        """

        try:
            async with self._pool.acquire() as conn:
                rows = await conn.fetch(query, days)
                return [UserStats(**dict(row)) for row in rows]
        except Exception as e:
            logger.error("Error fetching user stats", days=days, error=str(e))
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
