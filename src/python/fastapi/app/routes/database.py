from fastapi import APIRouter, HTTPException, status, Query
from app.models.user import UserResponse, UserStatsResponse
from datetime import datetime
import structlog

logger = structlog.get_logger()

router = APIRouter(prefix="/db", tags=["database"])


def get_db_service():
    from app.main import db_service
    return db_service


@router.get("/simple", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def get_user_simple(id: int = Query(default=1, ge=1, description="User ID")):
    """Get user by ID"""
    try:
        db = get_db_service()
        user = await db.find_user_by_id(id)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": f"User with id {id} not found"})
        return user
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error fetching user", user_id=id, error=str(e))
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Database error")


@router.get("/complex", response_model=UserStatsResponse, status_code=status.HTTP_200_OK)
async def get_user_stats(days: int = Query(default=30, ge=1, le=365, description="Number of days")):
    """Get aggregated user statistics"""
    try:
        db = get_db_service()
        data = await db.get_user_stats(days)
        return UserStatsResponse(periodDays=days, totalUsers=len(data), data=data)
    except Exception as e:
        logger.error("Error fetching user stats", days=days, error=str(e))
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error": "Database error"})
