import uuid
from datetime import datetime, timezone

import graphene

from db import check_db, get_user, get_complex_orders
from cache import check_cache, cache_get, cache_set


class Health(graphene.ObjectType):
    status = graphene.NonNull(graphene.String)
    version = graphene.NonNull(graphene.String)
    timestamp = graphene.NonNull(graphene.String)
    database = graphene.NonNull(graphene.String)
    cache = graphene.NonNull(graphene.String)


class JsonItem(graphene.ObjectType):
    id = graphene.NonNull(graphene.Int)
    uuid = graphene.NonNull(graphene.String)
    name = graphene.NonNull(graphene.String)
    email = graphene.NonNull(graphene.String)
    created_at = graphene.NonNull(graphene.String, name="createdAt")
    is_active = graphene.NonNull(graphene.Boolean, name="isActive")


class JsonItemsResult(graphene.ObjectType):
    items = graphene.NonNull(graphene.List(graphene.NonNull(JsonItem)))
    count = graphene.NonNull(graphene.Int)
    timestamp = graphene.NonNull(graphene.String)


class User(graphene.ObjectType):
    id = graphene.NonNull(graphene.Int)
    email = graphene.NonNull(graphene.String)
    first_name = graphene.NonNull(graphene.String, name="firstName")
    last_name = graphene.NonNull(graphene.String, name="lastName")
    age = graphene.NonNull(graphene.Int)
    created_at = graphene.NonNull(graphene.String, name="createdAt")


class UserOrderStats(graphene.ObjectType):
    user_id = graphene.NonNull(graphene.Int, name="userId")
    user_name = graphene.NonNull(graphene.String, name="userName")
    total_orders = graphene.NonNull(graphene.Int, name="totalOrders")
    total_value = graphene.NonNull(graphene.Float, name="totalValue")
    average_order_value = graphene.NonNull(graphene.Float, name="averageOrderValue")


class ComplexOrdersResult(graphene.ObjectType):
    period_days = graphene.NonNull(graphene.Int, name="periodDays")
    total_users = graphene.NonNull(graphene.Int, name="totalUsers")
    data = graphene.NonNull(graphene.List(graphene.NonNull(UserOrderStats)))


class CacheEntry(graphene.ObjectType):
    key = graphene.NonNull(graphene.String)
    value = graphene.NonNull(graphene.String)
    cached = graphene.NonNull(graphene.Boolean)
    ttl = graphene.NonNull(graphene.Int)


class Query(graphene.ObjectType):
    health = graphene.NonNull(Health)
    json_items = graphene.NonNull(JsonItemsResult, limit=graphene.Int(default_value=1000), name="jsonItems")
    user = graphene.Field(User, id=graphene.NonNull(graphene.Int))
    complex_orders = graphene.NonNull(ComplexOrdersResult, days=graphene.Int(default_value=30), name="complexOrders")
    cache = graphene.NonNull(CacheEntry, key=graphene.NonNull(graphene.String))

    def resolve_health(self, info):
        db_status = check_db()
        cache_status = check_cache()
        return Health(
            status="ok",
            version="1.0.0",
            timestamp=datetime.now(timezone.utc).isoformat(),
            database=db_status,
            cache=cache_status,
        )

    def resolve_json_items(self, info, limit):
        now = datetime.now(timezone.utc).isoformat()
        items = [
            JsonItem(
                id=i,
                uuid=str(uuid.uuid4()),
                name=f"Item {i}",
                email=f"user{i}@example.com",
                created_at=now,
                is_active=i % 3 != 0,
            )
            for i in range(1, limit + 1)
        ]
        return JsonItemsResult(
            items=items,
            count=len(items),
            timestamp=now,
        )

    def resolve_user(self, info, id):
        row = get_user(id)
        if row is None:
            return None
        return User(
            id=row["id"],
            email=row["email"],
            first_name=row["firstName"],
            last_name=row["lastName"],
            age=row["age"],
            created_at=row["createdAt"],
        )

    def resolve_complex_orders(self, info, days):
        data = get_complex_orders(days)
        stats = [
            UserOrderStats(
                user_id=r["userId"],
                user_name=r["userName"],
                total_orders=r["totalOrders"],
                total_value=r["totalValue"],
                average_order_value=r["averageOrderValue"],
            )
            for r in data
        ]
        return ComplexOrdersResult(
            period_days=days,
            total_users=len(stats),
            data=stats,
        )

    def resolve_cache(self, info, key):
        value, ttl = cache_get(key)
        if value is not None:
            return CacheEntry(
                key=key,
                value=value,
                cached=True,
                ttl=ttl,
            )

        generated = f'{{"key": "{key}", "generated": true}}'
        cache_set(key, generated, 300)
        return CacheEntry(
            key=key,
            value=generated,
            cached=False,
            ttl=300,
        )


schema = graphene.Schema(query=Query)
