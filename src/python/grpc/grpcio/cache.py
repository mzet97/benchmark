"""Redis connection management for the benchmark service."""

import os

import redis


_pool: redis.ConnectionPool | None = None


def get_client() -> redis.Redis:
    """Get or create the Redis client."""
    global _pool
    if _pool is None:
        redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
        _pool = redis.ConnectionPool.from_url(
            redis_url,
            decode_responses=True,
            max_connections=10,
        )
    return redis.Redis(connection_pool=_pool)


def check_cache() -> str:
    """Check Redis connectivity and return status."""
    try:
        client = get_client()
        client.ping()
        return "connected"
    except Exception as e:
        return f"error: {e}"


def close_pool():
    """Close the Redis connection pool."""
    global _pool
    if _pool is not None:
        _pool.disconnect()
        _pool = None
