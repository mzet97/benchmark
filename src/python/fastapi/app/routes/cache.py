from fastapi import APIRouter, HTTPException, status, Query
from app.models.cache import CACHE_TTL_SECONDS, CacheResponse
from datetime import datetime
import structlog

logger = structlog.get_logger()

router = APIRouter(prefix="/cache", tags=["cache"])


def get_cache_service():
    from app.main import cache_service
    return cache_service


@router.get("", response_model=CacheResponse, status_code=status.HTTP_200_OK)
async def cache_operations(key: str = Query(default="test", description="Cache key")):
    """Get or set cache value"""
    try:
        cache = get_cache_service()
        new_value = f"cached-value-{key}-{int(datetime.now().timestamp() * 1000)}"
        value, source = await cache.get_or_set(key, new_value, ttl_seconds=CACHE_TTL_SECONDS)
        cached = source == "cache"
        return CacheResponse.create(key, value, cached)
    except Exception as e:
        logger.error("Cache operation error", key=key, error=str(e))
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error": "Cache error"})
