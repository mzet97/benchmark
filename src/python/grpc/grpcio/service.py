"""BenchmarkService gRPC implementation."""

import datetime
import uuid

import grpc

# Generated stubs -- available after running generate.py
from generated import benchmark_pb2
from generated import benchmark_pb2_grpc

from cache import get_client as get_redis
from db import check_database, get_connection, release_connection


class BenchmarkServiceServicer(benchmark_pb2_grpc.BenchmarkServiceServicer):
    """Implementation of BenchmarkService."""

    VERSION = "1.0.0"

    def Health(self, request, context):
        """Scenario 1: Health check."""
        from cache import check_cache

        return benchmark_pb2.HealthResponse(
            status="ok",
            version=self.VERSION,
            timestamp=datetime.datetime.utcnow().isoformat() + "Z",
            database=check_database(),
            cache=check_cache(),
        )

    def GetJsonItems(self, request, context):
        """Scenario 2: JSON serialization (1000 items)."""
        limit = request.limit if request.limit > 0 else 1000
        items = []
        for i in range(1, limit + 1):
            items.append(
                benchmark_pb2.JsonItem(
                    id=i,
                    uuid=str(uuid.uuid4()),
                    name=f"user_{i}",
                    email=f"user_{i}@benchmark.dev",
                    created_at=datetime.datetime(2024, 1, 1, 0, 0, 0).isoformat() + "Z",
                    is_active=(i % 2 == 0),
                )
            )
        return benchmark_pb2.JsonItemsResponse(
            items=items,
            count=len(items),
            timestamp=datetime.datetime.utcnow().isoformat() + "Z",
        )

    def GetUser(self, request, context):
        """Scenario 3: Simple database query (single row)."""
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, email, first_name, last_name, age, created_at "
                    "FROM users WHERE id = %s",
                    (request.id,),
                )
                row = cur.fetchone()
                if row is None:
                    context.abort(grpc.StatusCode.NOT_FOUND, f"User {request.id} not found")
                return benchmark_pb2.UserResponse(
                    id=row[0],
                    email=row[1],
                    first_name=row[2],
                    last_name=row[3],
                    age=row[4],
                    created_at=str(row[5]),
                )
        finally:
            release_connection(conn)

    def GetComplexOrders(self, request, context):
        """Scenario 4: Complex database query (JOIN + aggregation)."""
        days = request.days if request.days > 0 else 30
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT
                        u.id AS user_id,
                        u.first_name || ' ' || u.last_name AS user_name,
                        COUNT(o.id) AS total_orders,
                        COALESCE(SUM(o.total), 0) AS total_value,
                        COALESCE(AVG(o.total), 0) AS average_order_value
                    FROM users u
                    LEFT JOIN orders o ON u.id = o.user_id
                        AND o.created_at >= NOW() - INTERVAL '%s days'
                    GROUP BY u.id, u.first_name, u.last_name
                    ORDER BY total_value DESC
                    """,
                    (days,),
                )
                rows = cur.fetchall()
                data = []
                for row in rows:
                    data.append(
                        benchmark_pb2.UserOrderStats(
                            user_id=row[0],
                            user_name=row[1],
                            total_orders=row[2],
                            total_value=float(row[3]),
                            average_order_value=float(row[4]),
                        )
                    )
                return benchmark_pb2.ComplexOrdersResponse(
                    period_days=days,
                    total_users=len(data),
                    data=data,
                )
        finally:
            release_connection(conn)

    def GetCacheValue(self, request, context):
        """Scenario 5: Cache hit/miss."""
        client = get_redis()
        cached = client.get(request.key)
        if cached is not None:
            ttl = client.ttl(request.key)
            return benchmark_pb2.CacheResponse(
                key=request.key,
                value=cached,
                cached=True,
                ttl=ttl if ttl >= 0 else 0,
                timestamp=datetime.datetime.utcnow().isoformat() + "Z",
            )

        # Cache miss: generate a value and store it
        value = f"value_for_{request.key}_{uuid.uuid4()}"
        client.setex(request.key, 3600, value)
        return benchmark_pb2.CacheResponse(
            key=request.key,
            value=value,
            cached=False,
            ttl=3600,
            timestamp=datetime.datetime.utcnow().isoformat() + "Z",
        )
