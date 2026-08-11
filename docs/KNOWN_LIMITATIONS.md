# Known Limitations

## Ecosystem Limitations

### Dart gRPC

Only **1 mature gRPC server implementation** exists for Dart (`grpc-dart`). The gRPC matrix for Dart has only 1 entry instead of 3.

### Dart REST

Only **1 REST implementation** exists (Vaden/Shelf). Unlike other environments with 3-4 frameworks, Dart has a single entry.

### Java GraphQL

Only **2 GraphQL implementations** exist for Java (Spring for GraphQL, Netflix DGS). SmallRye GraphQL (Quarkus) was not implemented.

### Bun/Deno gRPC

All 3 gRPC options for Bun and Deno are marked **EXPERIMENTAL** because they depend on Node.js API compatibility and HTTP/2 support that may not be fully stable in these runtimes.

### betterproto (Python)

`betterproto` uses `grpclib` as its gRPC transport engine internally. It is not an independent gRPC implementation — it's a different serialization layer on top of grpclion.

### MagicOnion (C#)

Uses **MessagePack** serialization instead of Protocol Buffers. This makes direct throughput comparison with other gRPC implementations unfair without noting the serialization difference.

### async-graphql (Rust)

The Axum and Actix integrations share the **same GraphQL engine** (`async-graphql`). The difference is the HTTP integration layer, not the GraphQL engine itself.

## Technical Limitations

### Previous Results Are Not Defensible

Benchmark runs *were* executed and produced the numbers in the 9 `docs/*RESULTS*.md`
files and `BENCHMARK_RESULTS_K3S.md`. Those results have been reviewed and declared
**INVALID — DO NOT CITE**. The defects that invalidated them are documented in
`docs/ACTION_PLAN.md` (Anexo A): a 5-second sample instead of the methodology's
5×60s, a load generator sharing the SUT's only node, non-comparable payloads,
unequal worker counts, and three conflicting resource profiles. The remediation
plan (Fases 0–7) is in progress; until Fase 6 completes, no measured numbers in
this repository should be cited or compared.

### Invalidated Measurement: rust-rest-actix-web `/db/complex`

Every `/db/complex` sample recorded for `rust-rest-actix-web` up to and
including `results/run-20260810T001219Z.json` is **INVALID — DO NOT CITE**. The
endpoint answered `200 OK` with `{"periodDays": 30, "totalUsers": 0, "data": []}`
and was ranked first at 32,777 rps.

The defect: the normative SQL filters on `NOW() - INTERVAL '1 day' * $1`.
PostgreSQL has no `interval * int4` operator, so when tokio-postgres prepares the
statement without declaring parameter types the server infers `$1` as `float8` —
and `impl ToSql for i32` accepts only `INT4`. Every execution failed on the
client side, and the handler mapped the error to an empty `Vec` behind a 200.
The sqlx-based siblings (warp, axum, rocket) declare parameter OIDs in `Parse`,
so PostgreSQL resolves `int4 → float8` through its implicit cast; they were
never affected and returned ~11 kB at ~750 rps.

Five consecutive runs recorded the empty response as a legitimate result because
`scripts/validate-parity.py` only compared the top-level key set of
`/db/complex`, which `data: []` satisfies. The parameter is now bound as `f64`,
driver errors return 500, and the parity gate asserts the payload is non-empty
and shaped (`check_db_payloads`). The bytes-per-response ratio is what exposes
this class of defect: 220 B against ~11 kB for the same endpoint.

The same `$1` bug, plus a `COUNT()`/`int32` decode panic, affected all three Rust
GraphQL and all three Rust gRPC implementations, which had never produced a valid
`complexOrders`/`GetComplexOrders` measurement.

### Database Connection Pooling

All implementations now use a pooled connection with `DB_POOL_MAX=32` set via
the ConfigMap (see `deploy/k3s/base/configmap.yaml`). For multi-process runtimes
(Node, Bun, Deno, Dart) the bootstrap divides this by the worker count and
injects the per-process limit into each child, so the pod's total stays at 32.
The previous state — Go REST with a single `pgx.Conn`, others with pools of 10
or 25 — was one of the defects that invalidated the earlier results and has been
corrected in Fase 3.

The three Rust gRPC implementations were missed by that pass: they held a single
bare `tokio_postgres::Client` with no pool at all until this remediation, i.e.
1/32 of the contract's database concurrency. The three Rust GraphQL
implementations left `deadpool`'s `max_size` unset, which defaults to
`cpu_count * 4` — 160 connections in the 40-CPU pod, five times the contract.
Neither read `DB_POOL_MAX`.

### Redis Connection Handling

Redis access must be multiplexed or pooled. The four Rust REST implementations
called `redis::Client::get_async_connection()` inside each handler, which opens a
new TCP connection per request; `/cache` measured 1,636 rps at a 109 ms p99
against 186,825 rps for Lettuce-backed http4k, describing a TCP handshake and the
TIME_WAIT pileup behind it rather than Redis. They now hold one
`MultiplexedConnection` established at startup.

Note that `MultiplexedConnection` does not reconnect on its own: if Redis drops
the connection, the affected pod's `/cache` and `/health` fail until it is
restarted. `ConnectionManager` (redis feature `connection-manager`) does
reconnect and is what the Rust GraphQL implementations use; the REST ones stayed
on `MultiplexedConnection` to avoid a dependency-feature change mid-remediation.

### No TLS

All communication inside the cluster is **plaintext** (no TLS). This is standard for benchmark purposes but doesn't reflect production security requirements.

### Fixed Query Plans

The benchmark uses fixed queries. Real-world performance depends on query plan caching, connection state, and data distribution.

### Mode C (Scale-Out) Is Not Executable on This Cluster

Mode C (5 replicas) was designed for horizontal scalability analysis. It is
**not executable** on the current single-node cluster: each pod requests 7 of
the node's 8 vCPUs (QoS Guaranteed), so 5 replicas would require 35 dedicated
cores against 8 available. This is recorded in `docs/ACTION_PLAN.md`, Fase 5.

## Protocol Comparison Caveats

### REST vs gRPC

- REST uses JSON serialization; gRPC uses Protocol Buffers
- JSON is human-readable but larger; Protobuf is binary and smaller
- Direct throughput comparison requires noting the serialization difference

### REST vs GraphQL

- REST returns complete responses; GraphQL can return partial responses
- A GraphQL query selecting 3 fields is not comparable to a REST endpoint returning all fields
- The benchmark uses equivalent field selections

### Unary vs Streaming

The gRPC benchmark uses **unary RPCs only**. Streaming is a separate suite not included in the main ranking.

## Infrastructure Limitations

### K3s Specific

- Uses containerd (not Docker)
- Built-in Traefik ingress (not used in primary benchmark)
- Built-in ServiceLB (not used in primary benchmark)
- Single-node clusters may show different results than multi-node

### External Dependencies

PostgreSQL and Redis are **external to the cluster**. Network latency between the cluster and these services affects all implementations equally but may vary by environment.

---

**Last Updated**: 2026-08-06
