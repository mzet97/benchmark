"""BenchmarkService betterproto implementation.

betterproto generates Pythonic dataclass-based message types and abstract service
classes. It uses grpclib as its gRPC transport engine -- the service base class
is provided by grpclib, while the request/response types are betterproto dataclasses.

Key differences from grpcio/standard protobuf:
  - Messages are Python dataclasses with typed fields
  - No .proto field numbers visible in generated code
  - Default values are Python-native (0, "", False, etc.)
  - Service base class is generated with async method signatures
  - grpclib handles the actual gRPC wire protocol
"""

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
# betterproto produces dataclass-based messages and grpclib-compatible service stubs
from generated import benchmark_grpc, benchmark

from cache import get_client as get_redis
from db import check_database, get_connection, release_connection


class BenchmarkService(benchmark_grpc.BenchmarkServiceBase):
    """Implementation of BenchmarkService using betterproto + grpclib.

    betterproto generates a base class with abstract async methods.
    Each method receives a stream (grpclib.server.Stream) from which
    we read the request message and write the response message.

    The message types (benchmark.HealthResponse, etc.) are Python
    dataclasses produced by betterproto, not standard protobuf classes.
    """

    VERSION = "1.0.0"

    async def Health(self, stream: grpclib.server.Stream) -> None:
        """Scenario 1: Health check."""
        request = await stream.recv_message()
        from cache import check_cache

        await stream.send_message(
            benchmark.HealthResponse(
                status="ok",
                version=self.VERSION,
                timestamp=datetime.datetime.utcnow().isoformat() + "Z",
                database=check_database(),
                cache=check_cache(),
            )
        )

    async def GetJsonItems(self, stream: grpclib.server.Stream) -> None:
        """Scenario 2: JSON serialization (1000 items)."""
        request = await stream.recv_message()
        # The previous version minted a uuid.uuid4() per item -- 1000 random
        # UUIDs per request -- numbered items from 1 and named them "user_3"
        # at user_3@benchmark.dev. See contracts/rest/canonical-payloads.md.
        limit = item_count(request.limit)
        items = [
            benchmark.JsonItem(
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
            benchmark.JsonItemsResponse(
                items=items,
                count=len(items),
                timestamp=datetime.datetime.utcnow().isoformat() + "Z",
            )
        )

    async def GetUser(self, stream: grpclib.server.Stream) -> None:
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
                    benchmark.UserResponse(
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

    async def GetComplexOrders(self, stream: grpclib.server.Stream) -> None:
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
                        benchmark.UserOrderStats(
                            user_id=row[0],
                            user_name=row[1],
                            total_orders=row[2],
                            total_value=float(row[3]),
                            average_order_value=float(row[4]),
                        )
                    )
                await stream.send_message(
                    benchmark.ComplexOrdersResponse(
                        period_days=days,
                        total_users=len(data),
                        data=data,
                    )
                )
        finally:
            release_connection(conn)

    async def GetCacheValue(self, stream: grpclib.server.Stream) -> None:
        """Scenario 5: Cache hit/miss."""
        request = await stream.recv_message()
        client = get_redis()
        cached = client.get(request.key)
        if cached is not None:
            ttl = client.ttl(request.key)
            await stream.send_message(
                benchmark.CacheResponse(
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
                benchmark.CacheResponse(
                    key=request.key,
                    value=value,
                    cached=False,
                    ttl=3600,
                    timestamp=datetime.datetime.utcnow().isoformat() + "Z",
                )
            )
