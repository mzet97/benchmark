"""
Cache service using redis.asyncio
"""

import json
import redis.asyncio as redis
import structlog
from typing import Any, Optional
import os

logger = structlog.get_logger(__name__)

class CacheService:
    """Redis cache service"""

    def __init__(self, redis_url: str):
        self.redis_url = redis_url
        self._client: Optional[redis.Redis] = None

    async def initialize(self):
        """Initialize Redis client"""
        try:
            self._client = redis.from_url(
                self.redis_url,
                encoding="utf-8",
                decode_responses=True,
                retry_on_timeout=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                socket_keepalive=True,
                socket_keepalive_options={}
            )
            await self._client.ping()
            logger.info("Redis cache connected")
        except Exception as e:
            logger.error("Failed to connect to Redis", error=str(e))
            raise

    async def close(self):
        """Close Redis connection"""
        if self._client:
            await self._client.close()
            logger.info("Redis connection closed")

    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        try:
            value = await self._client.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error("Error getting cache value", key=key, error=str(e))
            return None

    async def set(self, key: str, value: Any, ttl: int = 300) -> bool:
        """Set value in cache"""
        try:
            serialized = json.dumps(value, default=str)
            await self._client.setex(key, ttl, serialized)
            return True
        except Exception as e:
            logger.error("Error setting cache value", key=key, error=str(e))
            return False

    async def delete(self, key: str) -> bool:
        """Delete value from cache"""
        try:
            await self._client.delete(key)
            return True
        except Exception as e:
            logger.error("Error deleting cache value", key=key, error=str(e))
            return False

    async def exists(self, key: str) -> bool:
        """Check if key exists in cache"""
        try:
            result = await self._client.exists(key)
            return bool(result)
        except Exception as e:
            logger.error("Error checking cache key", key=key, error=str(e))
            return False

    async def health_check(self) -> Dict[str, Any]:
        """Check Redis health"""
        try:
            await self._client.ping()
            info = await self._client.info()
            return {
                'status': 'healthy',
                'cache': 'connected',
                'redis_version': info.get('redis_version'),
                'connected_clients': info.get('connected_clients')
            }
        except Exception as e:
            logger.error("Redis health check failed", error=str(e))
            return {
                'status': 'unhealthy',
                'cache': 'disconnected',
                'error': str(e)
            }

# Global cache service instance
cache_service: Optional[CacheService] = None

def get_cache_service() -> CacheService:
    """Get cache service instance"""
    global cache_service
    if cache_service is None:
        cache_service = CacheService(
            redis_url=os.getenv('REDIS_URL', 'redis://:Admin@123@redis.home.arpa:30379')
        )
    return cache_service
