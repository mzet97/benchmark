"""
Cache service using redis (sync driver for Flask)
"""

import redis
import structlog
from typing import Any, Optional, Dict
import os

logger = structlog.get_logger(__name__)

REDIS_URL = os.environ["REDIS_URL"]


class CacheService:
    """Redis cache service (sync)"""

    def __init__(self):
        self._client: Optional[redis.Redis] = None

    def _get_client(self) -> redis.Redis:
        """Get or create Redis client"""
        if self._client is None:
            self._client = redis.from_url(
                REDIS_URL,
                encoding="utf-8",
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
            )
        return self._client

    def get(self, key: str) -> Optional[str]:
        """Get value from cache"""
        try:
            client = self._get_client()
            return client.get(key)
        except Exception as e:
            logger.error("Error getting cache value", key=key, error=str(e))
            return None

    def set(self, key: str, value: str, ttl: int = 300) -> bool:
        """Set value in cache"""
        try:
            client = self._get_client()
            client.setex(key, ttl, value)
            return True
        except Exception as e:
            logger.error("Error setting cache value", key=key, error=str(e))
            return False

    def delete(self, key: str) -> bool:
        """Delete value from cache"""
        try:
            client = self._get_client()
            client.delete(key)
            return True
        except Exception as e:
            logger.error("Error deleting cache value", key=key, error=str(e))
            return False

    def health_check(self) -> Dict[str, Any]:
        """Check Redis health"""
        try:
            client = self._get_client()
            client.ping()
            info = client.info()
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

    def close(self):
        """Close Redis connection"""
        if self._client:
            self._client.close()


# Global cache service instance
cache_service: Optional[CacheService] = None


def get_cache_service() -> CacheService:
    """Get cache service instance"""
    global cache_service
    if cache_service is None:
        cache_service = CacheService()
    return cache_service
