# Canonical REST Payloads

**Normative.** Every REST implementation must produce exactly these payloads.
Divergence is a bug, not a framework characteristic.

## Why this file exists

Before it, `/json` returned a different object in every language:

| Implementação | Item | Bytes/item | Trabalho extra por request |
|---|---|---:|---|
| `src/go/fiber` | `{id, name, description, timestamp, random}` | ~154 | 16 KB de `crypto/rand` |
| `src/nodejs/express` | `{id, name, email, active, tags[]}` | ~106 | nenhum |

A 45% difference in bytes and a CSPRNG on one side make the `/json` ranking
meaningless: it compared different workloads over different amounts of wire.

The shape below matches `contracts/grpc/benchmark.proto` (`JsonItem`) and
`contracts/graphql/schema.graphql` (`type JsonItem`), so the three protocols
serialize the same data.

## Determinism rules

1. **No randomness per request.** Item content is a pure function of its index.
2. **No wall-clock inside items.** `createdAt` is a fixed constant. The only
   clock-dependent field is `timestamp` in the envelope.
3. **No per-request allocation of entropy** (`crypto/rand`, `uuid.New()`, etc).
4. Field names are **camelCase** in REST and GraphQL, matching the proto3 JSON
   mapping of the snake_case proto fields.

## Scenario 2 — `GET /json?n=<count>`

`n` defaults to `1000`. Implementations must support at least `n` in
{10, 100, 1000}; the benchmark runs all three because only the small sizes stay
below the network ceiling on 1 GbE (see `docs/BASELINE_CEILINGS.md`).

### Item, as a function of its index `i` (0-based)

| Field | Type | Value |
|---|---|---|
| `id` | int | `i` |
| `uuid` | string | `"00000000-0000-0000-0000-"` + `i` zero-padded to 12 digits |
| `name` | string | `"Item "` + `i` in **decimal** |
| `email` | string | `"item"` + `i` + `"@benchmark.local"` |
| `createdAt` | string | `"2026-01-01T00:00:00Z"` (constant) |
| `isActive` | bool | `i % 2 == 0` |

> `name` must use decimal formatting. `src/go/fiber` used
> `"Item " + string(rune(id))`, which converts the integer to a Unicode code
> point — a NUL byte for `id=0` and multi-byte UTF-8 for `id >= 128`.

### Envelope

```json
{
  "items": [ /* n items */ ],
  "count": 1000,
  "timestamp": "2026-07-31T12:00:00Z"
}
```

`timestamp` is RFC 3339 UTC at request time. It is the **only** non-deterministic
field and is excluded from parity hashing.

### Reference output for `n=2`

```json
{"items":[{"id":0,"uuid":"00000000-0000-0000-0000-000000000000","name":"Item 0","email":"item0@benchmark.local","createdAt":"2026-01-01T00:00:00Z","isActive":true},{"id":1,"uuid":"00000000-0000-0000-0000-000000000001","name":"Item 1","email":"item1@benchmark.local","createdAt":"2026-01-01T00:00:00Z","isActive":false}],"count":2,"timestamp":"..."}
```

Size: **160 bytes per item** (measured via `scripts/validate-parity.py
--reference --n 1000`). Network ceiling at 1 GbE (117,6 MB/s useful):

| `n` | Response | Teto de rede | Classificação esperada |
|---:|---:|---:|---|
| 10 | ~1,8 KB | ~65.300 rps | encosta no teto de PPS → `PPS_BOUND` |
| **100** | ~16 KB | **~7.259 rps** | **`FRAMEWORK_BOUND` — ranking primário** |
| 1000 | ~160 KB | ~734 rps | `NET_BOUND`, só custo de CPU/req |

`n=100` is the size that actually measures serialization on this topology:
large enough that per-request overhead does not dominate, small enough to stay
far below both the bandwidth and the packet-rate ceiling.

## Scenario 3 — `GET /db/simple?id=<id>`

Mirrors `UserResponse` in the proto. Values come from the database.

```json
{"id":1,"email":"...","firstName":"...","lastName":"...","age":30,"createdAt":"..."}
```

Not parity-hashed (content is data-dependent), but the **key set and casing**
are checked.

The SQL is normative too. An implementation that runs a different query is
not measuring the same thing, however similar the response looks:

```sql
SELECT id, email, first_name AS "firstName", last_name AS "lastName",
       age, created_at AS "createdAt"
FROM users
WHERE id = $1
```

The double-quoted aliases make Postgres return camelCase column names, so
implementations that serialize a row straight to JSON — most of the dynamic
ones do — need no per-field mapping layer.

## Scenario 4 — `GET /db/complex?days=<days>`

Mirrors `ComplexOrdersResponse`. `LIMIT 100` is part of the contract — changing
it changes the payload size and therefore the network ceiling.

```json
{"periodDays":30,"totalUsers":100,"data":[{"userId":1,"userName":"...","totalOrders":12,"totalValue":1234.56,"averageOrderValue":102.88}]}
```

Normative SQL:

```sql
SELECT
    u.id AS "userId",
    u.first_name || ' ' || u.last_name AS "userName",
    COUNT(o.id) AS "totalOrders",
    COALESCE(SUM(o.total_amount), 0) AS "totalValue",
    COALESCE(AVG(o.total_amount), 0) AS "averageOrderValue"
FROM users u
INNER JOIN orders o ON u.id = o.user_id
    WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
GROUP BY u.id, u.first_name, u.last_name
ORDER BY "totalOrders" DESC, u.id
LIMIT 100
```

Three things this pins down, each of which was wrong somewhere:

- **`ORDER BY` has a tiebreak.** Ordering by an aggregate alone leaves rows
  with equal values in arbitrary order, so the response is not reproducible
  between runs and cannot be compared at all.
- **The interval is a bound parameter**, `INTERVAL '1 day' * $1`. Several
  implementations wrote `INTERVAL '%s days'` or `INTERVAL '{days} days'`.
  Inside the quotes there is no placeholder: Postgres reads the literal
  string `%s days`. The `{days}` form is worse — it is string interpolation
  straight into SQL.
- **No join to `order_items`.** Aggregating `quantity * price` across a
  second join is a materially heavier query than summing `o.total_amount`,
  and implementations that did it were being timed on a different workload.

## Scenario 5 — `GET /cache?key=<key>`

Mirrors `CacheResponse`.

```json
{"key":"benchmark","value":"...","cached":true,"ttl":300,"timestamp":"..."}
```

## Scenario 1 — `GET /health`

Mirrors `HealthResponse`.

```json
{"status":"ok","version":"...","timestamp":"...","database":"up","cache":"up"}
```

## How parity is enforced

`scripts/validate-parity.py` fetches each scenario, normalizes the JSON
(recursively sorted keys, compact separators, volatile fields stripped) and
compares the SHA-256 against the reference produced by
`scripts/canonical-payload.py`.

Normalizing rather than comparing raw bytes is deliberate: requiring
byte-identical serialization across 11 languages would fail on key order and
float formatting, which are not the divergences we care about.

Volatile fields excluded from hashing: `timestamp` (envelope), and every field
under `/db/*` and `/cache` whose value comes from the database or Redis.
