from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


# Wire names are camelCase throughout, matching the proto3 JSON mapping of the
# snake_case proto fields. See contracts/rest/canonical-payloads.md. The
# normative SQL aliases its columns to the same camelCase names, so a row maps
# onto these models with no field-by-field translation layer.


class UserBase(BaseModel):
    """Base user model with common fields"""
    email: EmailStr
    firstName: str = Field(..., min_length=1, max_length=100)
    lastName: str = Field(..., min_length=1, max_length=100)
    # Nullable in the schema, and the reference implementation carries it as a
    # pointer. A range constraint here would reject real rows.
    age: Optional[int] = None


class User(UserBase):
    """Complete user model"""
    id: int
    createdAt: datetime

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
    """Mirrors UserOrderStats in contracts/grpc/benchmark.proto"""
    userId: int
    userName: str
    totalOrders: int
    totalValue: float
    averageOrderValue: float

    class Config:
        from_attributes = True


class UserStatsResponse(BaseModel):
    """Mirrors ComplexOrdersResponse"""
    periodDays: int
    totalUsers: int
    data: list[UserStats]
    timestamp: str

    class Config:
        from_attributes = True
