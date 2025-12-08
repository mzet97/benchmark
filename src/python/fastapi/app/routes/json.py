from fastapi import APIRouter, HTTPException, status
from app.models.json_item import JsonResponse, JsonItem
from datetime import datetime
import structlog

logger = structlog.get_logger()

router = APIRouter(prefix="/json", tags=["json"])


@router.get(
    "",
    response_model=JsonResponse,
    status_code=status.HTTP_200_OK,
    summary="JSON response",
    description="Returns 1000 JSON objects"
)
async def get_json():
    """
    Generate and return 1000 JSON objects.
    Each object contains random data for testing serialization.
    """
    try:
        items = [JsonItem.create(i) for i in range(1000)]
        timestamp = items[0].timestamp if items else datetime.now().isoformat()

        return JsonResponse(
            items=items,
            count=len(items),
            timestamp=timestamp
        )
    except Exception as e:
        logger.error("Error generating JSON response", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate JSON response"
        )
