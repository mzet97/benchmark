from pydantic import BaseModel

# Canonical /json payload. See contracts/rest/canonical-payloads.md.
#
# The shape matches JsonItem in contracts/grpc/benchmark.proto and
# type JsonItem in contracts/graphql/schema.graphql, so all three protocols
# serialize the same data.
CANONICAL_CREATED_AT = "2026-01-01T00:00:00Z"


class JsonItem(BaseModel):
    """JSON response item."""

    id: int
    uuid: str
    name: str
    email: str
    createdAt: str  # noqa: N815 - camelCase is the contract (proto3 JSON mapping)
    isActive: bool  # noqa: N815

    class Config:
        from_attributes = True

    @staticmethod
    def create(item_id: int) -> "JsonItem":
        """
        Build item i.

        Content is a pure function of the index: no randomness and no
        wall-clock, so the payload is stable across runs and identical across
        languages. The previous version stamped datetime.now() into every
        item, which made the response impossible to parity-hash.
        """
        return JsonItem(
            id=item_id,
            uuid=f"00000000-0000-0000-0000-{item_id:012d}",
            name=f"Item {item_id}",
            email=f"item{item_id}@benchmark.local",
            createdAt=CANONICAL_CREATED_AT,
            isActive=item_id % 2 == 0,
        )


class JsonResponse(BaseModel):
    """JSON response envelope."""

    items: list[JsonItem]
    count: int
    timestamp: str

    class Config:
        from_attributes = True
