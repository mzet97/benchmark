from fastapi import APIRouter, Depends, HTTPException, status, Query
from app.services.database import DatabaseService
from app.models.user import UserResponse, UserStatsResponse
from datetime import datetime
import structlog

logger = structlog.get_logger()

router = APIRouter(prefix="/db", tags=["database"])


@router.get(
    "/simple",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Simple database query",
    description="Get user by ID",
    responses={
        404: {"description": "User not found"}
    }
)
async def get_user_simple(
    id: int = Query(default=1, ge=1, description="User ID"),
    db_service: DatabaseService = Depends()
):
    """
    Retrieve a single user by ID from the database.

    Args:
        id: User ID (default: 1)
        db_service: Database service dependency

    Returns:
        User data with timestamp

    Raises:
        HTTPException: 404 if user not found
    """
    try:
        user = await db_service.find_user_by_id(id)

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={
                    "error": "Not Found",
                    "message": f"User with id {id} not found"
                }
            )

        return user
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error fetching user", user_id=id, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error"
        )


@router.get(
    "/complex",
    response_model=UserStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Complex database query",
    description="Get user statistics aggregation",
    responses={
        500: {"description": "Database error"}
    }
)
async def get_user_stats(
    days: int = Query(default=30, ge=1, le=365, description="Number of days"),
    db_service: DatabaseService = Depends()
):
    """
    Retrieve aggregated user statistics within a specified time period.

    Args:
        days: Number of days to look back (default: 30, max: 365)
        db_service: Database service dependency

    Returns:
        User statistics with total orders, values, and averages

    Raises:
        HTTPException: 500 if database error occurs
    """
    try:
        data = await db_service.get_user_stats(days)

        return UserStatsResponse(
            period_days=days,
            total_users=len(data),
            data=data,
            timestamp=datetime.now().isoformat()
        )
    except Exception as e:
        logger.error("Error fetching user stats", days=days, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Database error",
                "message": str(e)
            }
        )
