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
    source: str = Field(..., description="Source of the value: cache or generated")
    timestamp: str

    class Config:
        from_attributes = True

    @staticmethod
    def create(key: str, value: str, source: str) -> "CacheResponse":
        """Create cache response"""
        from datetime import datetime
        return CacheResponse(
            key=key,
            value=value,
            source=source,
            timestamp=datetime.now().isoformat()
        )
