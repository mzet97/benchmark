from pydantic import BaseModel, Field
from typing import Optional
import uuid


class CacheRequest(BaseModel):
    """Cache request model"""
    key: Optional[str] = Field(default="test", description="Cache key")


class CacheResponse(BaseModel):
    """Cache response model"""
    key: str
    value: str
    cached: bool = Field(..., description="Whether the value was retrieved from cache")
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
            timestamp=datetime.now().isoformat()
        )
