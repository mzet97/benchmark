from fastapi import APIRouter, Depends, HTTPException, status
from app.services.database import DatabaseService
from app.services.cache import CacheService
from app.models.health import HealthResponse
from datetime import datetime
import structlog

logger = structlog.get_logger()

router = APIRouter(prefix="/health", tags=["health"])


@router.get(
    "",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Health check",
    description="Check database and cache connectivity"
)
async def health_check(
    db_service: DatabaseService = Depends(),
    cache_service: CacheService = Depends()
):
    """
    Health check endpoint that verifies:
    - PostgreSQL database connectivity
    - Redis cache connectivity
    """
    db_healthy = await db_service.health_check()
    cache_healthy = await cache_service.health_check()

    response = HealthResponse.create(db_healthy, cache_healthy)

    if not (db_healthy and cache_healthy):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=response.model_dump()
        )

    return response


@router.get(
    "/live",
    summary="Liveness check",
    description="Kubernetes liveness probe endpoint"
)
async def liveness_check():
    """Simple liveness check for Kubernetes"""
    return {"status": "alive", "timestamp": datetime.now().isoformat()}


@router.get(
    "/ready",
    summary="Readiness check",
    description="Kubernetes readiness probe endpoint"
)
async def readiness_check(
    db_service: DatabaseService = Depends()
):
    """Readiness check that verifies database connectivity"""
    healthy = await db_service.health_check()

    if not healthy:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "not ready"}
        )

    return {"status": "ready"}
