import os
import redis

_client = None


def get_client():
    global _client
    if _client is None:
        redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379")
        _client = redis.from_url(redis_url, decode_responses=True)
    return _client


def check_cache():
    """Returns 'connected' or 'disconnected'."""
    try:
        get_client().ping()
        return "connected"
    except Exception:
        return "disconnected"


def cache_get(key: str):
    """Returns (value, ttl) or (None, 0) on miss."""
    client = get_client()
    try:
        value = client.get(key)
        if value is not None:
            ttl = client.ttl(key)
            return value, ttl if ttl > 0 else 0
        return None, 0
    except Exception:
        return None, 0


def cache_set(key: str, value: str, ttl: int = 300):
    client = get_client()
    try:
        client.setex(key, ttl, value)
    except Exception:
        pass
