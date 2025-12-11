from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid


class JsonItem(BaseModel):
    """JSON response item"""
    id: int
    name: str
    email: str
    timestamp: str

    class Config:
        from_attributes = True

    @staticmethod
    def create(item_id: int) -> "JsonItem":
        """Create a new JSON item"""
        timestamp = datetime.now().isoformat()
        return JsonItem(
            id=item_id,
            name=f"User {item_id}",
            email=f"user{item_id}@example.com",
            timestamp=timestamp
        )


class JsonResponse(BaseModel):
    """JSON response with items"""
    items: list[JsonItem]
    count: int
    timestamp: str

    class Config:
        from_attributes = True
