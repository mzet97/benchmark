from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class OrderBase(BaseModel):
    """Base order model"""
    user_id: int
    total_amount: float = Field(..., gt=0)
    status: str = Field(..., min_length=1, max_length=50)


class Order(OrderBase):
    """Complete order model"""
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class OrderItemBase(BaseModel):
    """Base order item model"""
    order_id: int
    product_name: str
    quantity: int = Field(..., gt=0)
    price: float = Field(..., gt=0)


class OrderItem(OrderItemBase):
    """Complete order item model"""
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class OrderWithItems(Order):
    """Order with items"""
    items: list["OrderItem"] = []

    class Config:
        from_attributes = True
