"""Canonical /json payload contract.

See contracts/rest/canonical-payloads.md.

The gRPC and GraphQL item types differ per implementation -- generated
protobuf classes, graphene objects, strawberry dataclasses, plain dicts -- so
this module exposes the field values rather than a type. Every implementation
builds its own object from the same numbers.

Item content is a pure function of the index: no randomness and no wall
clock, so the payload is stable across runs and identical across languages
and protocols.
"""

DEFAULT_ITEMS = 1000
MAX_ITEMS = 10_000

# Fixed by the contract. Reading the clock once per item is work no
# implementation should be timed on.
CANONICAL_CREATED_AT = "2026-01-01T00:00:00Z"


def canonical_uuid(i: int) -> str:
    return f"00000000-0000-0000-0000-{i:012d}"


def canonical_name(i: int) -> str:
    return f"Item {i}"


def canonical_email(i: int) -> str:
    return f"item{i}@benchmark.local"


def canonical_is_active(i: int) -> bool:
    return i % 2 == 0


def item_count(limit) -> int:
    """Clamp the requested limit.

    On a 1 GbE link 1000 items is network-bound, so the serialization
    ranking is taken at 100.
    """
    if limit is None:
        return DEFAULT_ITEMS
    try:
        n = int(limit)
    except (TypeError, ValueError):
        return DEFAULT_ITEMS
    if n <= 0:
        return DEFAULT_ITEMS
    return min(n, MAX_ITEMS)
