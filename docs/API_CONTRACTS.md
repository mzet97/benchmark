# API Contracts — Benchmark

## Overview

All three protocols (REST, gRPC, GraphQL) implement the same **5 functional scenarios** to ensure fair comparison.

## Scenario 1: Health Check

**Purpose**: Measure pure framework overhead (no I/O).

### REST

```http
GET /health
GET /healthz    # Kubernetes liveness probe (no DB check)
GET /readyz     # Kubernetes readiness probe (with DB check)
```

Response:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2026-07-28T00:00:00.000Z",
  "database": "connected",
  "cache": "connected"
}
```

### gRPC

```protobuf
rpc Health(HealthRequest) returns (HealthResponse);
```

File: `contracts/grpc/benchmark.proto`

### GraphQL

```graphql
query Health {
  health {
    status
    version
    timestamp
    database
    cache
  }
}
```

File: `contracts/graphql/schema.graphql`

---

## Scenario 2: JSON Serialization (1000 objects)

**Purpose**: Measure serialization throughput (CPU-bound).

### REST

```http
GET /json
```

Response:
```json
{
  "items": [
    {
      "id": 1,
      "uuid": "uuid-0001-0000-0000-000000000000",
      "name": "User 1",
      "email": "user1@benchmark.local",
      "createdAt": "2026-07-28T00:00:00.000Z",
      "isActive": true
    }
  ],
  "count": 1000,
  "timestamp": "2026-07-28T00:00:00.000Z"
}
```

### gRPC

```protobuf
rpc GetJsonItems(JsonItemsRequest) returns (JsonItemsResponse);
message JsonItemsRequest { int32 limit = 1; }
```

### GraphQL

```graphql
query JsonItems {
  jsonItems(limit: 1000) {
    id
    uuid
    name
    email
    createdAt
    isActive
  }
}
```

**Rule**: All implementations must return exactly 1000 objects with the same fields.

---

## Scenario 3: Simple Database Query (single row)

**Purpose**: Measure database access latency (I/O-bound).

### REST

```http
GET /db/simple?id=1
```

Response:
```json
{
  "id": 1,
  "email": "user1@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "age": 30,
  "created_at": "2026-01-01T00:00:00.000Z"
}
```

### gRPC

```protobuf
rpc GetUser(GetUserRequest) returns (UserResponse);
message GetUserRequest { int32 id = 1; }
```

### GraphQL

```graphql
query User {
  user(id: 1) {
    id
    email
    firstName
    lastName
    age
    createdAt
  }
}
```

---

## Scenario 4: Complex Database Query (JOIN + aggregation)

**Purpose**: Measure complex SQL performance.

### REST

```http
GET /db/complex?days=30
```

Response:
```json
{
  "period_days": 30,
  "total_users": 100,
  "data": [
    {
      "user_id": 42,
      "user_name": "John Doe",
      "total_orders": 15,
      "total_value": 1234.56,
      "average_value": 82.30
    }
  ]
}
```

### gRPC

```protobuf
rpc GetComplexOrders(ComplexOrdersRequest) returns (ComplexOrdersResponse);
message ComplexOrdersRequest { int32 days = 1; }
```

### GraphQL

```graphql
query ComplexOrders {
  complexOrders(days: 30) {
    periodDays
    totalUsers
    data {
      userId
      userName
      totalOrders
      totalValue
      averageOrderValue
    }
  }
}
```

---

## Scenario 5: Cache (hit / miss)

**Purpose**: Measure cache access and hit/miss differentiation.

### REST

```http
GET /cache?key=benchmark
```

Response (cache hit):
```json
{
  "key": "benchmark",
  "value": "cached_value_here",
  "cached": true,
  "ttl": 300
}
```

Response (cache miss):
```json
{
  "key": "benchmark",
  "value": "benchmark_value_benchmark_1690000000000",
  "cached": false,
  "ttl": 300
}
```

### gRPC

```protobuf
rpc GetCacheValue(CacheRequest) returns (CacheResponse);
message CacheRequest { string key = 1; }
```

### GraphQL

```graphql
query Cache {
  cache(key: "benchmark") {
    key
    value
    cached
    ttl
  }
}
```

**Rule**: Cache hit and cache miss results must be reported separately in rankings.

---

## Contracts Location

| Protocol | File |
|----------|------|
| REST | Inline in each implementation (OpenAPI optional) |
| gRPC | `contracts/grpc/benchmark.proto` |
| GraphQL | `contracts/graphql/schema.graphql` |

## gRPC Specific Rules

- Start with unary RPCs only
- Streaming is a separate suite, not in the main ranking
- HTTP/2 without TLS inside the cluster
- No compression in the primary scenario
- Validate: stub generation, interoperability, metadata, deadlines, cancellation, status codes
- Use gRPC standard health service when supported

## GraphQL Specific Rules

- Use `POST /graphql` for all requests
- Disable: GraphiQL, Playground, Apollo Sandbox, internal tracing
- Disable introspection during benchmarks (enable for smoke tests only)
- Disable persisted queries in the primary scenario
- Disable automatic response caching
- No DataLoader for scenarios without N+1
- Keep standard engine validation and parsing
- Create a secondary scenario with persisted queries later

---

**Last Updated**: 2026-07-28
