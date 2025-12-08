from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid


class JsonItem(BaseModel):
    """JSON response item"""
    id: int
    name: str
    description: str
    timestamp: str
    random: str

    class Config:
        from_attributes = True

    @staticmethod
    def create(item_id: int) -> "JsonItem":
        """Create a new JSON item"""
        return JsonItem(
            id=item_id,
            name=f"Item {item_id}",
            description=f"This is item number {item_id}",
            timestamp=datetime.now().isoformat(),
            random=f"data-{uuid.uuid4()}"
        )


class JsonResponse(BaseModel):
    """JSON response with items"""
    items: list[JsonItem]
    count: int
    timestamp: str

    class Config:
        from_attributes = True
