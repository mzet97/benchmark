import uuid
from datetime import datetime, timezone

from ariadne import QueryType, make_executable_schema

from db import check_db, get_user, get_complex_orders
from cache import check_cache, cache_get, cache_set
from canonical import (
    CANONICAL_CREATED_AT,
    canonical_email,
    canonical_is_active,
    canonical_name,
    canonical_uuid,
    item_count,
)

type_defs = """
    type Health {
        status: String!
        version: String!
        timestamp: String!
        database: String!
        cache: String!
    }

    type JsonItem {
        id: Int!
        uuid: String!
        name: String!
        email: String!
        createdAt: String!
        isActive: Boolean!
    }

    type JsonItemsResult {
        items: [JsonItem!]!
        count: Int!
        timestamp: String!
    }

    type User {
        id: Int!
        email: String!
        firstName: String!
        lastName: String!
        age: Int!
        createdAt: String!
    }

    type UserOrderStats {
        userId: Int!
        userName: String!
        totalOrders: Int!
        totalValue: Float!
        averageOrderValue: Float!
    }

    type ComplexOrdersResult {
        periodDays: Int!
        totalUsers: Int!
        data: [UserOrderStats!]!
    }

    type CacheEntry {
        key: String!
        value: String!
        cached: Boolean!
        ttl: Int!
    }

    type Query {
        health: Health!
        jsonItems(limit: Int = 1000): JsonItemsResult!
        user(id: Int!): User
        complexOrders(days: Int = 30): ComplexOrdersResult!
        cache(key: String!): CacheEntry!
    }
"""

query = QueryType()


@query.field("health")
def resolve_health(*_):
    db_status = check_db()
    cache_status = check_cache()
    return {
        "status": "ok",
        "version": "1.0.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "database": db_status,
        "cache": cache_status,
    }


@query.field("jsonItems")
def resolve_json_items(_, info, limit=1000):
    now = datetime.now(timezone.utc).isoformat()
    # The previous version minted a uuid.uuid4() per item, numbered items from
    # 1, used @example.com, stamped the clock into createdAt and flagged
    # isActive with `i % 3 != 0` instead of `i % 2 == 0`.
    # See contracts/rest/canonical-payloads.md.
    count = item_count(limit)
    items = [
        {
            "id": i,
            "uuid": canonical_uuid(i),
            "name": canonical_name(i),
            "email": canonical_email(i),
            "createdAt": CANONICAL_CREATED_AT,
            "isActive": canonical_is_active(i),
        }
        for i in range(count)
    ]
    return {
        "items": items,
        "count": len(items),
        "timestamp": now,
    }


@query.field("user")
def resolve_user(_, info, id):
    row = get_user(id)
    if row is None:
        return None
    return row


@query.field("complexOrders")
def resolve_complex_orders(_, info, days=30):
    data = get_complex_orders(days)
    return {
        "periodDays": days,
        "totalUsers": len(data),
        "data": data,
    }


@query.field("cache")
def resolve_cache(_, info, key):
    value, ttl = cache_get(key)
    if value is not None:
        return {
            "key": key,
            "value": value,
            "cached": True,
            "ttl": ttl,
        }

    generated = f'{{"key": "{key}", "generated": true}}'
    cache_set(key, generated, 300)
    return {
        "key": key,
        "value": generated,
        "cached": False,
        "ttl": 300,
    }


schema = make_executable_schema(type_defs, query)
