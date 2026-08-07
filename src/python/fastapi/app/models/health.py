from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class HealthStatus(str):
    """Health status values"""
    HEALTHY = "healthy"
    UNHEALTHY = "unhealthy"


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    version: str
    database: str
    cache: str
    timestamp: str

    class Config:
        from_attributes = True

    @staticmethod
    def create(db_healthy: bool, cache_healthy: bool) -> "HealthResponse":
        """Create health response"""
        status = HealthStatus.HEALTHY if db_healthy and cache_healthy else HealthStatus.UNHEALTHY
        return HealthResponse(
            status=status,
            version="1.0.0",
            database="connected" if db_healthy else "disconnected",
            cache="connected" if cache_healthy else "disconnected",
            timestamp=datetime.now().isoformat()
        )
