from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


class UserBase(BaseModel):
    """Base user model with common fields"""
    email: EmailStr
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    age: int = Field(..., ge=18, le=100)


class User(UserBase):
    """Complete user model"""
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class UserCreate(UserBase):
    """User creation model"""
    pass


class UserResponse(User):
    """User response (direct user data)"""

    class Config:
        from_attributes = True


class UserStats(BaseModel):
    """User statistics model"""
    user_id: int
    user_name: str
    total_orders: int
    total_value: float
    average_value: float

    class Config:
        from_attributes = True


class UserStatsResponse(BaseModel):
    """User stats response"""
    period_days: int
    total_users: int
    data: list[UserStats]
    timestamp: str

    class Config:
        from_attributes = True
