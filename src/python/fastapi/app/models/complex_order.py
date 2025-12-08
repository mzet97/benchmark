from pydantic import BaseModel, Field
from typing import Optional


class ComplexOrderResult(BaseModel):
    """Complex order aggregation result"""
    user_id: int
    email: str
    order_count: int = Field(..., ge=0)
    total_amount: float = Field(..., ge=0)
    avg_amount: float = Field(..., ge=0)
    days_since_first_order: int = Field(..., ge=0)

    class Config:
        from_attributes = True


class ComplexOrderResponse(BaseModel):
    """Complex order response"""
    orders: list[ComplexOrderResult]
    count: int
    days: int
    timestamp: str

    class Config:
        from_attributes = True
