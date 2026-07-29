import uuid
from datetime import datetime, timezone

import strawberry
from strawberry.types import Info

from db import check_db, get_user, get_complex_orders
from cache import check_cache, cache_get, cache_set


@strawberry.type
class Health:
    status: str
    version: str
    timestamp: str
    database: str
    cache: str


@strawberry.type
class JsonItem:
    id: int
    uuid: str
    name: str
    email: str
    created_at: str
    is_active: bool


@strawberry.type
class JsonItemsResult:
    items: list[JsonItem]
    count: int
    timestamp: str


@strawberry.type
class User:
    id: int
    email: str
    first_name: str
    last_name: str
    age: int
    created_at: str


@strawberry.type
class UserOrderStats:
    user_id: int
    user_name: str
    total_orders: int
    total_value: float
    average_order_value: float


@strawberry.type
class ComplexOrdersResult:
    period_days: int
    total_users: int
    data: list[UserOrderStats]


@strawberry.type
class CacheEntry:
    key: str
    value: str
    cached: bool
    ttl: int


@strawberry.type
class Query:
    @strawberry.field
    def health(self, info: Info) -> Health:
        db_status = check_db()
        cache_status = check_cache()
        return Health(
            status="ok",
            version="1.0.0",
            timestamp=datetime.now(timezone.utc).isoformat(),
            database=db_status,
            cache=cache_status,
        )

    @strawberry.field
    def json_items(self, limit: int = 1000) -> JsonItemsResult:
        now = datetime.now(timezone.utc).isoformat()
        items = [
            JsonItem(
                id=i,
                uuid=str(uuid.uuid4()),
                name=f"Item {i}",
                email=f"item{i}@example.com",
                created_at=now,
                is_active=i % 2 == 0,
            )
            for i in range(1, limit + 1)
        ]
        return JsonItemsResult(
            items=items,
            count=len(items),
            timestamp=now,
        )

    @strawberry.field
    def user(self, id: int) -> User | None:
        row = get_user(id)
        if row is None:
            return None
        return User(
            id=row["id"],
            email=row["email"],
            first_name=row["first_name"],
            last_name=row["last_name"],
            age=row["age"],
            created_at=row["created_at"],
        )

    @strawberry.field
    def complex_orders(self, days: int = 30) -> ComplexOrdersResult:
        data = get_complex_orders(days)
        stats = [
            UserOrderStats(
                user_id=r["user_id"],
                user_name=r["user_name"],
                total_orders=r["total_orders"],
                total_value=r["total_value"],
                average_order_value=r["average_order_value"],
            )
            for r in data
        ]
        return ComplexOrdersResult(
            period_days=days,
            total_users=len(stats),
            data=stats,
        )

    @strawberry.field
    def cache(self, key: str) -> CacheEntry:
        value, ttl = cache_get(key)
        if value is not None:
            return CacheEntry(
                key=key,
                value=value,
                cached=True,
                ttl=ttl,
            )

        generated = f"value-for-{key}"
        cache_set(key, generated, 300)
        return CacheEntry(
            key=key,
            value=generated,
            cached=False,
            ttl=300,
        )


schema = strawberry.Schema(query=Query)
