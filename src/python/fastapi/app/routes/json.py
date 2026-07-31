from fastapi import APIRouter, HTTPException, Query, status
from app.models.json_item import JsonResponse, JsonItem
from datetime import datetime, timezone
import structlog

logger = structlog.get_logger()

router = APIRouter(prefix="/json", tags=["json"])

DEFAULT_ITEMS = 1000
MAX_ITEMS = 10000


@router.get(
    "",
    response_model=JsonResponse,
    status_code=status.HTTP_200_OK,
    summary="JSON response",
    description="Returns n canonical JSON objects (default 1000)"
)
async def get_json(
    n: int = Query(DEFAULT_ITEMS, ge=0, le=MAX_ITEMS,
                   description="Item count"),
):
    """
    Generate and return n canonical JSON objects.

    See contracts/rest/canonical-payloads.md. On a 1 GbE link n=1000 is
    network-bound at ~734 rps, so the serialization ranking is taken at n=100.
    """
    try:
        items = [JsonItem.create(i) for i in range(n)]

        # The envelope timestamp is the only clock-dependent field and is
        # excluded from the parity hash.
        return JsonResponse(
            items=items,
            count=n,
            timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        )
    except Exception as e:
        logger.error("Error generating JSON response", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate JSON response"
        )
