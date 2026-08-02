# Benchmark Methodology

**Updated**: 2026-08-02

This document describes how the benchmark is run. It is normative: the runner
(`scripts/run-benchmark-suite.py`) implements it, and a number produced any
other way does not belong in the results.

> **The previous version of this document described a protocol that was never
> executed, and parts of which could not be.** It specified 5×60 s
> measurements with a 30 s warm-up in randomized order, while
> `run_all_benchmarks.py` ran one 5-second pass with a 2-second warm-up in
> alphabetical order. It also required the load generator to run "inside the
> cluster, scheduled on a different node than the server" — on a cluster that
> has one node. Every published result came from the runner, not from this
> document.

---

## Topology

```
Windows workstation                 VM .51 — K3s, single node
  bombardier / oha / ghz / k6  ──>    8 vCPU / 16 GiB
  (load generator)          1 GbE     ├─ system + K3s ....... 1 CPU
                                      └─ subject pod ........ 7 CPU
                                                │
                                                ▼  VM .52
                                          PostgreSQL + Redis
```

**The generator runs outside the cluster.** With a single node there is
nowhere else to put it: an in-cluster generator competes with the subject for
the same CPUs, which is what the previous runs did.

Access path is a **NodePort** (30080), fixed. No Ingress, no LoadBalancer, no
proxy in between. A fixed port is safe because exactly one implementation runs
at a time.

## Resource profile

One profile, used for every implementation and every ranking:

```yaml
resources:
  requests:  { cpu: "7", memory: "12Gi" }
  limits:    { cpu: "7", memory: "12Gi" }
```

`requests == limits` puts the pod in **Guaranteed** QoS. Combined with
`--cpu-manager-policy=static` and an integer CPU request, the pod gets
exclusive cores and is not subject to CFS throttling. That is what makes
"uses 100% of the hardware" a repeatable statement rather than an aspiration.

Node-level reservations (`--system-reserved=cpu=500m`,
`--kube-reserved=cpu=500m`) keep 1 CPU for the system so the subject is not
descheduled by kubelet under load.

> The earlier "Standard / Small / Unlimited / Scale-Out" profile table is
> gone. Three conflicting profiles existed simultaneously in the repository
> and the one that actually ran (`src/*/k8s`, 100m request / 500m limit, 5
> replicas) matched none of them.

## Test modes

| Mode | Replicas | Access | Status |
|---|---|---|---|
| **A — single pod via NodePort** | 1 | NodePort | **the ranking** |
| B — ClusterIP overhead | 1 | ClusterIP, in-cluster client | not run: needs a second node |
| C — scale-out | 5 | NodePort | not run: see below |

**Mode C is not executable on this cluster.** Five replicas at 7 CPU each
require 35 CPUs; the node has 8. Running it at a smaller per-pod profile would
produce numbers that cannot be compared with Mode A, and mixing them is
exactly what the results tables did before. If scale-out matters, it needs
more nodes — it is not a parameter that can be turned on here.

Results from different modes are **never mixed** in a ranking.

## Execution protocol

For each implementation, in randomized order:

1. Delete any previous implementation; confirm no competing pods are running.
   *A pod left over from the previous subject shares the CPUs, so the run is
   aborted rather than recorded.*
2. Deploy the implementation from its Kustomize overlay.
3. Wait for the rollout to complete.
4. **Run the parity gate** (`scripts/validate-parity.py --url`). An
   implementation that does not serve the canonical payload is skipped, not
   measured — its throughput is not comparable to the others'.
5. Warm-up: 30 s of load, discarded.
6. Settle: 10 s.
7. Measure: **5 repetitions of 60 s**, 10 s apart.
8. Sample pod CPU after each repetition.
9. Delete the implementation; settle 10 s.

The run order is randomized to spread thermal and temporal drift across
implementations rather than concentrating it in whoever runs last. **The seed
is recorded in the output**, so an order can be replayed exactly.

## Parameters

| Parameter | Value |
|---|---|
| Warm-up | 30 s |
| Measurement | 60 s |
| Repetitions | 5 |
| Settle between repetitions | 10 s |
| Connections | 100 (default) |
| Load generator | `bombardier` (throughput), `oha` (fixed-rate latency) |
| Generator location | Windows workstation, outside the cluster |

Concurrency sweeps (1, 10, 50, 100, 200) are a **separate run**, not part of
the ranking pass. Reporting one implementation at 200 connections next to
another at 50 is not a comparison.

## Load generators

| Protocol | Tool | Why |
|---|---|---|
| REST throughput | `bombardier` | native Windows, keep-alive by default |
| REST latency at fixed rate | `oha` | rate limiting, so latency is not subject to coordinated omission |
| gRPC | `ghz` | native |
| GraphQL | `k6` | fixed documents, native binary |

`wrk`/`wrk2` have no native Windows build. WSL2 was rejected: its NAT adds
latency and variance to the thing being measured.

## The network ceiling

The link is 1 GbE — about 941 Mbps, 117.6 MB/s usable. Per scenario:

| Scenario | Body | Network ceiling | Expected bottleneck |
|---|---:|---:|---|
| `/health` | ~100 B | ~390k rps | client PPS |
| `/json?n=10` | ~1.6 KB | ~65k rps | client PPS |
| **`/json?n=100`** | **~16 KB** | **~7,259 rps** | **the framework** |
| `/json?n=1000` | ~160 KB | ~734 rps | the network |
| `/db/simple` | ~130 B | ~356k rps | PostgreSQL |
| `/db/complex` | ~13 KB | ~8,900 rps | PostgreSQL |
| `/cache` | ~150 B | ~336k rps | Redis / PPS |

**`/json?n=100` is the serialization ranking.** At n=1000 the link saturates
around 734 rps and every implementation converges there — that number ranks
the switch, not the framework. n=1000 is still measured and reported, labelled
as network-bound.

Where a scenario is bound by something other than the framework, **CPU cores
per 1000 requests** is the metric that still discriminates. The runner records
it.

## Metrics

**Performance** — requests/sec; latency p50, p90, p95, p99, p99.9, max; error
rate; non-2xx count; timeouts.

**Resources** — CPU mean/max (cores), CPU throttled seconds, RSS mean/max,
working set, network rx/tx, pod restarts, OOM kills.

**Derived** — CPU cores per 1000 rps.

**Infrastructure** — thread/process/worker count, image size, build time, cold
start, time to ready, first-request latency.

**Environment** — UTC timestamp, CPU frequency, load average, **CPU steal**
(a Proxmox host that overcommits makes "7 dedicated cores" fiction), node
name, image git SHA, K3s version, kernel version.

## Statistics

- **Primary**: median of the 5 repetitions.
- **Reported alongside**: mean, standard deviation, min, max. A result without
  a spread across repetitions is not reportable — a single sample has no error
  bar, and every previously published number was a single sample.
- Outliers are not dropped automatically; if one is excluded, it is named and
  justified in the results.

## What is not done

- Reporting the best of several runs.
- Comparing REST JSON throughput directly with gRPC Protobuf throughput.
- Comparing partial GraphQL responses with full REST responses.
- Mixing results from different replica counts or resource profiles.
- Mixing measured and estimated values.
- Comparing a warm JVM with a cold-start native image.
- **Ranking an implementation that failed the parity gate.**
- **Publishing a throughput number from a scenario known to be network-bound
  without saying so.**
