from pydantic import BaseModel, Field
from typing import Optional
import uuid

CACHE_TTL_SECONDS = 300


class CacheRequest(BaseModel):
    """Cache request model"""
    key: Optional[str] = Field(default="test", description="Cache key")


class CacheResponse(BaseModel):
    """Cache response model"""
    key: str
    value: str
    cached: bool = Field(..., description="Whether the value was retrieved from cache")
    # The TTL is part of the response contract and must match what is written
    # to Redis. See contracts/rest/canonical-payloads.md.
    ttl: int = CACHE_TTL_SECONDS
    timestamp: str

    class Config:
        from_attributes = True

    @staticmethod
    def create(key: str, value: str, cached: bool) -> "CacheResponse":
        """Create cache response"""
        from datetime import datetime
        return CacheResponse(
            key=key,
            value=value,
            cached=cached,
            ttl=CACHE_TTL_SECONDS,
            timestamp=datetime.now().isoformat()
        )
