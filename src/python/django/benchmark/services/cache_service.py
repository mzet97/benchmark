import os
import redis
from typing import Optional
from datetime import datetime

REDIS_URL = os.environ["REDIS_URL"]

r = redis.Redis.from_url(REDIS_URL, decode_responses=True)

class CacheService:
    """Service for cache operations"""

    @staticmethod
    def get_or_set(key: str, default_value: Optional[str] = None, ttl: int = 300) -> tuple:
        """
        Get value from cache or set if not exists
        Returns: (value, was_cached)
        """
        value = r.get(key)
        if value:
            return value, True

        if default_value is None:
            default_value = f'cached-value-{key}-{datetime.utcnow().timestamp()}'

        r.set(key, default_value, ex=ttl)
        return default_value, False

    @staticmethod
    def ping() -> bool:
        """Check if Redis is available"""
        try:
            r.ping()
            return True
        except Exception:
            return False
