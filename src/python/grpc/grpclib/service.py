"""BenchmarkService grpclib implementation."""

import datetime
import uuid

import grpclib
from grpclib import const
from canonical import (
    CANONICAL_CREATED_AT,
    canonical_email,
    canonical_is_active,
    canonical_name,
    canonical_uuid,
    item_count,
)

# Generated stubs -- available after running generate.py
from generated import benchmark_grpc
from generated import benchmark_pb2

from cache import get_client as get_redis
from db import check_database, get_connection, release_connection


class BenchmarkService(benchmark_grpc.BenchmarkServiceBase):
    """Implementation of BenchmarkService using grpclib."""

    VERSION = "1.0.0"

    async def Health(self, stream):
        """Scenario 1: Health check."""
        request = await stream.recv_message()
        from cache import check_cache

        await stream.send_message(
            benchmark_pb2.HealthResponse(
                status="ok",
                version=self.VERSION,
                timestamp=datetime.datetime.utcnow().isoformat() + "Z",
                database=check_database(),
                cache=check_cache(),
            )
        )

    async def GetJsonItems(self, stream):
        """Scenario 2: JSON serialization (1000 items)."""
        request = await stream.recv_message()
        # The previous version minted a uuid.uuid4() per item -- 1000 random
        # UUIDs per request -- numbered items from 1 and named them "user_3"
        # at user_3@benchmark.dev. See contracts/rest/canonical-payloads.md.
        limit = item_count(request.limit)
        items = [
            benchmark_pb2.JsonItem(
                id=i,
                uuid=canonical_uuid(i),
                name=canonical_name(i),
                email=canonical_email(i),
                created_at=CANONICAL_CREATED_AT,
                is_active=canonical_is_active(i),
            )
            for i in range(limit)
        ]
        await stream.send_message(
            benchmark_pb2.JsonItemsResponse(
                items=items,
                count=len(items),
                timestamp=datetime.datetime.utcnow().isoformat() + "Z",
            )
        )

    async def GetUser(self, stream):
        """Scenario 3: Simple database query (single row)."""
        request = await stream.recv_message()
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
                    raise grpclib.GRPCError(
                        const.Status.NOT_FOUND,
                        f"User {request.id} not found",
                    )
                await stream.send_message(
                    benchmark_pb2.UserResponse(
                        id=row[0],
                        email=row[1],
                        first_name=row[2],
                        last_name=row[3],
                        age=row[4],
                        created_at=str(row[5]),
                    )
                )
        finally:
            release_connection(conn)

    async def GetComplexOrders(self, stream):
        """Scenario 4: Complex database query (JOIN + aggregation)."""
        request = await stream.recv_message()
        days = request.days if request.days > 0 else 30
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    -- Normative SQL, see contracts/rest/canonical-payloads.md. The
                    -- previous query aggregated o.total or o.amount, columns the schema
                    -- does not have; the interval was pasted in as text rather than
                    -- bound, so it was never substituted; the ORDER BY had no tiebreak;
                    -- and there was no LIMIT, so it returned every user rather than the
                    -- 100 the contract fixes -- which changes the payload size and the
                    -- network ceiling of this scenario.
                    SELECT
                        u.id AS user_id,
                        u.first_name || ' ' || u.last_name AS user_name,
                        COUNT(o.id) AS total_orders,
                        COALESCE(SUM(o.total_amount), 0) AS total_value,
                        COALESCE(AVG(o.total_amount), 0) AS average_order_value
                    FROM users u
                    INNER JOIN orders o ON u.id = o.user_id
                        WHERE o.created_at >= NOW() - INTERVAL '1 day' * %s
                    GROUP BY u.id, u.first_name, u.last_name
                    ORDER BY total_orders DESC, u.id
                    LIMIT 100
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
                await stream.send_message(
                    benchmark_pb2.ComplexOrdersResponse(
                        period_days=days,
                        total_users=len(data),
                        data=data,
                    )
                )
        finally:
            release_connection(conn)

    async def GetCacheValue(self, stream):
        """Scenario 5: Cache hit/miss."""
        request = await stream.recv_message()
        client = get_redis()
        cached = client.get(request.key)
        if cached is not None:
            ttl = client.ttl(request.key)
            await stream.send_message(
                benchmark_pb2.CacheResponse(
                    key=request.key,
                    value=cached,
                    cached=True,
                    ttl=ttl if ttl >= 0 else 0,
                    timestamp=datetime.datetime.utcnow().isoformat() + "Z",
                )
            )
        else:
            # Cache miss: generate a value and store it
            value = f"value_for_{request.key}_{uuid.uuid4()}"
            client.setex(request.key, 3600, value)
            await stream.send_message(
                benchmark_pb2.CacheResponse(
                    key=request.key,
                    value=value,
                    cached=False,
                    ttl=3600,
                    timestamp=datetime.datetime.utcnow().isoformat() + "Z",
                )
            )
