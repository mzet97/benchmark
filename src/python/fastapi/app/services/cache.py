import redis.asyncio as aioredis
from typing import Optional, Tuple
import structlog
import os


logger = structlog.get_logger()


class CacheService:
    """Cache service for Redis operations"""

    def __init__(self):
        self._redis: Optional[aioredis.Redis] = None
        self.redis_url = os.environ["REDIS_URL"]

    async def init_redis(self):
        """Initialize Redis connection"""
        if self._redis is None:
            logger.info("Initializing Redis connection")
            self._redis = aioredis.from_url(
                self.redis_url,
                encoding="utf-8",
                decode_responses=True,
                retry_on_timeout=True,
            )
            await self._redis.ping()
            logger.info("Redis connection initialized")

    async def close_redis(self):
        """Close Redis connection"""
        if self._redis:
            await self._redis.close()
            logger.info("Redis connection closed")

    async def get(self, key: str) -> Optional[str]:
        """Get value from cache"""
        try:
            value = await self._redis.get(key)
            if value:
                logger.info("Cache hit", key=key)
            else:
                logger.info("Cache miss", key=key)
            return value
        except Exception as e:
            logger.error("Cache get error", key=key, error=str(e))
            return None

    async def set(self, key: str, value: str, ttl_seconds: int = 300) -> bool:
        """Set value in cache with TTL"""
        try:
            await self._redis.setex(key, ttl_seconds, value)
            return True
        except Exception as e:
            logger.error("Cache set error", key=key, error=str(e))
            return False

    async def get_or_set(self, key: str, new_value: str, ttl_seconds: int = 300) -> Tuple[str, str]:
        """Get value from cache or set new value"""
        existing = await self.get(key)
        if existing is not None:
            return existing, "cache"
        await self.set(key, new_value, ttl_seconds)
        return new_value, "generated"

    async def health_check(self) -> bool:
        """Perform Redis health check"""
        try:
            result = await self._redis.ping()
            return result == b"PONG" if isinstance(result, bytes) else result == "PONG"
        except Exception as e:
            logger.error("Redis health check failed", error=str(e))
            return False
