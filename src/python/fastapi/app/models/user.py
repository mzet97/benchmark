from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# Wire names are camelCase throughout, matching the proto3 JSON mapping of the
# snake_case proto fields. See contracts/rest/canonical-payloads.md. The
# normative SQL aliases its columns to the same camelCase names, so a row maps
# onto these models with no field-by-field translation layer.


class UserBase(BaseModel):
    """Base user model with common fields"""
    # NOTE: deliberately a plain str, not pydantic EmailStr. EmailStr runs
    # email_validator.validate_email(), whose deliverability check does live DNS
    # lookups (MX). The seed data uses @example.com, which that check flags as
    # undeliverable -> EmailUndeliverableError is raised while constructing the
    # User, the route catches it and returns 500 "Database error". This is a
    # response DTO mirroring a DB row, not user input, so no email validation is
    # appropriate here.
    email: str
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

    class Config:
        from_attributes = True
