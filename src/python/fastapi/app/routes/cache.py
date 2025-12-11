from fastapi import APIRouter, Depends, HTTPException, status, Query
from app.services.cache import CacheService
from app.models.cache import CacheRequest, CacheResponse
from datetime import datetime
import structlog

logger = structlog.get_logger()

router = APIRouter(prefix="/cache", tags=["cache"])


@router.get(
    "",
    response_model=CacheResponse,
    status_code=status.HTTP_200_OK,
    summary="Cache operations",
    description="Get or set cache value",
    responses={
        500: {"description": "Cache error"}
    }
)
async def cache_operations(
    key: str = Query(default="test", description="Cache key"),
    cache_service: CacheService = Depends()
):
    """
    Retrieve a value from cache or generate a new one.

    Args:
        key: Cache key (default: "test")
        cache_service: Cache service dependency

    Returns:
        Cached or generated value with cached indicator

    Raises:
        HTTPException: 500 if cache error occurs
    """
    try:
        new_value = f"cached-value-{key}-{int(datetime.now().timestamp() * 1000)}"
        value, source = await cache_service.get_or_set(key, new_value, ttl_seconds=300)
        cached = source == "cache"

        return CacheResponse.create(key, value, cached)
    except Exception as e:
        logger.error("Cache operation error", key=key, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Cache error",
                "message": str(e)
            }
        )
