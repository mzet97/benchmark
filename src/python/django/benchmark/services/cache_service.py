import redis
from typing import Optional

r = redis.Redis.from_url('redis://:Admin@123@redis.home.arpa:30379')

class CacheService:
    """Service for cache operations"""

    @staticmethod
    def get_or_set(key: str, default_value: Optional[str] = None, ttl: int = 300) -> tuple[str, bool]:
        """
        Get value from cache or set if not exists
        Returns: (value, was_cached)
        """
        value = r.get(key)
        if value:
            return value.decode(), True

        if default_value is None:
            from datetime import datetime
            default_value = f'cached-value-{key}-{datetime.utcnow().timestamp()}'

        r.set(key, default_value, ex=ttl)
        return default_value, False

    @staticmethod
    def ping() -> bool:
        """Check if Redis is available"""
        try:
            r.ping()
            return True
        except:
            return False
