from fastapi import APIRouter, HTTPException, status
from app.models.health import HealthResponse
from datetime import datetime
import structlog

logger = structlog.get_logger()

router = APIRouter(prefix="/health", tags=["health"])


def get_db_service():
    from app.main import db_service
    return db_service


def get_cache_service():
    from app.main import cache_service
    return cache_service


@router.get("", response_model=HealthResponse, status_code=status.HTTP_200_OK)
async def health_check():
    """Health check endpoint"""
    db = get_db_service()
    cache = get_cache_service()
    db_healthy = await db.health_check()
    cache_healthy = await cache.health_check()

    # Contract: {"status","version","timestamp","database","cache"} with HTTP 200.
    # The parity gate uses `curl -sf`, which treats any non-200 as a hard
    # failure and reports the endpoint as empty. Always return 200 and surface
    # per-dependency state in the values instead.
    return HealthResponse.create(db_healthy, cache_healthy)


@router.get("/live")
async def liveness_check():
    """Kubernetes liveness probe"""
    return {"status": "alive", "timestamp": datetime.now().isoformat()}


@router.get("/ready")
async def readiness_check():
    """Kubernetes readiness probe"""
    db = get_db_service()
    healthy = await db.health_check()
    if not healthy:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail={"status": "not ready"})
    return {"status": "ready"}
