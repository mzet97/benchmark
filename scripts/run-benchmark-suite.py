#!/usr/bin/env python3
"""Benchmark suite runner.

Implements the protocol in docs/BENCHMARK_METHODOLOGY.md. The previous runner
(run_all_benchmarks.py) did not: it ran a single 5-second wrk pass with a
2-second warm-up, in alphabetical order, from a Job inside the same
single-node cluster as the server -- so the generator competed with the
subject for the same CPUs, and every published number came from one 5-second
sample.

Topology
--------
The generator runs here, on the workstation, against the NodePort on the K3s
node. Cluster operations go over SSH. That split is the point: a single-node
cluster has nowhere else to put an in-cluster generator.

Requirements
------------
  * SSH key access to the K3s node (no password prompt). Set up with
    ssh-copy-id; this runner never handles a password.
  * bombardier on PATH (throughput) and oha (fixed-rate latency).
  * The parity gate: scripts/validate-parity.py, run against every
    implementation before it is measured.

Usage
-----
    python scripts/run-benchmark-suite.py --host 192.168.1.51 --user k8s1
    python scripts/run-benchmark-suite.py --only go-rest-fiber --repetitions 1
    python scripts/run-benchmark-suite.py --dry-run
"""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import shutil
import statistics
import subprocess
import sys
import time
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OVERLAYS = REPO / "deploy" / "k3s" / "overlays"
NODE_PORT = 30080
NAMESPACE = "benchmark"

# Scenario -> request path. n=100 for /json: at n=1000 a 1 GbE link saturates
# around 734 rps and the measurement stops being about the framework. See
# contracts/rest/canonical-payloads.md.
REST_SCENARIOS = {
    "health": "/health",
    "json-n10": "/json?n=10",
    "json-n100": "/json?n=100",
    "json-n1000": "/json?n=1000",
    "db-simple": "/db/simple?id=1",
    "db-complex": "/db/complex?days=30",
    "cache": "/cache?key=benchmark",
}

# The ranking scenario. The others are reported but carry a bound label.
PRIMARY_JSON_SCENARIO = "json-n100"


# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------

@dataclass
class Config:
    host: str
    user: str
    repetitions: int = 5
    duration: int = 60
    warmup: int = 30
    settle: int = 10
    connections: int = 100
    seed: int | None = None
    protocols: tuple[str, ...] = ("rest",)
    only: tuple[str, ...] = ()
    dry_run: bool = False
    skip_parity: bool = False
    out_dir: Path = REPO / "results"

    @property
    def base_url(self) -> str:
        return f"http://{self.host}:{NODE_PORT}"


# --------------------------------------------------------------------------
# Shell helpers
# --------------------------------------------------------------------------

class CommandError(RuntimeError):
    pass


def run(cmd: list[str], timeout: int = 120, check: bool = True) -> str:
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    if check and proc.returncode != 0:
        raise CommandError(
            f"{' '.join(cmd[:4])}... exited {proc.returncode}\n"
            f"stdout: {proc.stdout.strip()[:400]}\n"
            f"stderr: {proc.stderr.strip()[:400]}"
        )
    return proc.stdout


class Cluster:
    """kubectl on the K3s node, over SSH.

    Key-based authentication only. The old runner read a password from
    K3S_SSH_PASSWORD and passed it to paramiko; a benchmark runner has no
    business handling one.
    """

    def __init__(self, cfg: Config):
        self.cfg = cfg
        self._ssh = [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "ConnectTimeout=10",
            f"{cfg.user}@{cfg.host}",
        ]

    def sh(self, command: str, timeout: int = 120, check: bool = True) -> str:
        if self.cfg.dry_run:
            print(f"      [dry-run] ssh: {command[:110]}")
            return ""
        return run(self._ssh + [command], timeout=timeout, check=check)

    def check_access(self) -> None:
        out = self.sh("kubectl get nodes -o name", timeout=30)
        if not self.cfg.dry_run and "node/" not in out:
            raise CommandError(f"kubectl on {self.cfg.host} returned no nodes:\n{out}")

    def apply(self, overlay: Path) -> None:
        # The overlay is rendered here and piped in, so the repository does not
        # have to be present on the node.
        if self.cfg.dry_run:
            print(f"      [dry-run] render {overlay.name} | kubectl apply -f -")
            return
        self._apply_stdin(render_overlay(overlay))

    def _apply_stdin(self, manifest: str) -> None:
        if self.cfg.dry_run:
            print("      [dry-run] kubectl apply -f - (manifest piped)")
            return
        proc = subprocess.run(
            self._ssh + ["kubectl apply -f - --timeout=60s"],
            input=manifest, capture_output=True, text=True, timeout=120,
        )
        if proc.returncode != 0:
            raise CommandError(f"kubectl apply failed:\n{proc.stderr.strip()[:600]}")

    def wait_ready(self, name: str, timeout: int = 180) -> None:
        self.sh(
            f"kubectl rollout status deployment/{name} -n {NAMESPACE} --timeout={timeout}s",
            timeout=timeout + 30,
        )

    def delete(self, name: str) -> None:
        self.sh(
            f"kubectl delete deployment,service,configmap -l app={name} "
            f"-n {NAMESPACE} --ignore-not-found --timeout=60s",
            timeout=90, check=False,
        )

    def competing_pods(self, expected: str) -> list[str]:
        out = self.sh(
            f"kubectl get pods -n {NAMESPACE} "
            "-o jsonpath='{range .items[*]}{.metadata.labels.app}{\"\\n\"}{end}'",
            timeout=30, check=False,
        )
        apps = {line.strip().strip("'") for line in out.splitlines() if line.strip()}
        return sorted(apps - {expected, ""})

    def pod_cpu_seconds(self, name: str) -> float | None:
        """Total CPU seconds consumed, for cost-per-request.

        Throughput alone cannot separate "the framework is fast" from "the
        network saturated". CPU per request can, and it is the metric that
        survives a saturated link.
        """
        out = self.sh(
            f"kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/{NAMESPACE}/pods "
            f"2>/dev/null || true",
            timeout=30, check=False,
        )
        try:
            payload = json.loads(out) if out.strip() else {}
        except json.JSONDecodeError:
            return None
        total = 0.0
        found = False
        for item in payload.get("items", []):
            if item.get("metadata", {}).get("labels", {}).get("app") != name:
                continue
            for container in item.get("containers", []):
                cpu = container.get("usage", {}).get("cpu", "")
                total += parse_cpu_quantity(cpu)
                found = True
        return total if found else None


def parse_cpu_quantity(value: str) -> float:
    """Kubernetes CPU quantity -> cores. Accepts n, u, m suffixes."""
    if not value:
        return 0.0
    for suffix, scale in (("n", 1e-9), ("u", 1e-6), ("m", 1e-3)):
        if value.endswith(suffix):
            return float(value[:-1]) * scale
    return float(value)


def render_overlay(overlay: Path) -> str:
    """Render a kustomize overlay to a manifest.

    kustomize is not on this machine's PATH, so this shells out to `kubectl
    kustomize` if available and otherwise raises with an actionable message
    rather than silently deploying something else.
    """
    if shutil.which("kubectl"):
        return run(["kubectl", "kustomize", str(overlay)], timeout=60)
    if shutil.which("kustomize"):
        return run(["kustomize", "build", str(overlay)], timeout=60)
    raise CommandError(
        "Neither kubectl nor kustomize is on PATH, so overlays cannot be "
        "rendered locally. Install one of them, or run this script from a "
        "machine that has it."
    )


# --------------------------------------------------------------------------
# Load generation
# --------------------------------------------------------------------------

@dataclass
class Sample:
    repetition: int
    requests_per_sec: float
    latency_p50_ms: float | None
    latency_p99_ms: float | None
    bytes_per_sec: float | None
    non_2xx: int
    cpu_seconds: float | None = None


BOMBARDIER_RPS = re.compile(r"Reqs/sec\s+([\d.]+)")
BOMBARDIER_P50 = re.compile(r"50%\s+([\d.]+)(us|ms|s)")
BOMBARDIER_P99 = re.compile(r"99%\s+([\d.]+)(us|ms|s)")
BOMBARDIER_THROUGHPUT = re.compile(r"Throughput:\s+([\d.]+)(KB|MB|GB)/s")
BOMBARDIER_NON2XX = re.compile(r"non-2xx or 3xx responses:\s+(\d+)")


def to_ms(value: float, unit: str) -> float:
    return {"us": value / 1000.0, "ms": value, "s": value * 1000.0}[unit]


def to_bytes_per_sec(value: float, unit: str) -> float:
    return {"KB": value * 1e3, "MB": value * 1e6, "GB": value * 1e9}[unit]


def bombardier(url: str, duration: int, connections: int, dry_run: bool) -> Sample:
    cmd = [
        "bombardier",
        "--duration", f"{duration}s",
        "--connections", str(connections),
        "--print", "result",
        "--latencies",
        url,
    ]
    if dry_run:
        print(f"      [dry-run] {' '.join(cmd)}")
        return Sample(0, 0.0, None, None, None, 0)
    out = run(cmd, timeout=duration + 60)

    rps = BOMBARDIER_RPS.search(out)
    p50 = BOMBARDIER_P50.search(out)
    p99 = BOMBARDIER_P99.search(out)
    thr = BOMBARDIER_THROUGHPUT.search(out)
    bad = BOMBARDIER_NON2XX.search(out)
    if not rps:
        raise CommandError(f"could not parse bombardier output:\n{out[:600]}")
    return Sample(
        repetition=0,
        requests_per_sec=float(rps.group(1)),
        latency_p50_ms=to_ms(float(p50.group(1)), p50.group(2)) if p50 else None,
        latency_p99_ms=to_ms(float(p99.group(1)), p99.group(2)) if p99 else None,
        bytes_per_sec=to_bytes_per_sec(float(thr.group(1)), thr.group(2)) if thr else None,
        non_2xx=int(bad.group(1)) if bad else 0,
    )


# --------------------------------------------------------------------------
# Parity gate
# --------------------------------------------------------------------------

def parity_ok(base_url: str, dry_run: bool) -> tuple[bool, str]:
    """Refuse to measure an implementation that is off-contract.

    A number produced by an implementation serving a different payload is not
    comparable to the others, and publishing it is exactly how the previous
    results went wrong.
    """
    if dry_run:
        return True, "dry-run"
    gate = REPO / "scripts" / "validate-parity.py"
    proc = subprocess.run(
        [sys.executable, str(gate), "--url", base_url],
        capture_output=True, text=True, timeout=180,
    )
    return proc.returncode == 0, (proc.stdout + proc.stderr).strip()


# --------------------------------------------------------------------------
# Suite
# --------------------------------------------------------------------------

@dataclass
class ScenarioResult:
    scenario: str
    path: str
    samples: list[Sample] = field(default_factory=list)

    def summary(self) -> dict:
        rps = [s.requests_per_sec for s in self.samples]
        if not rps:
            return {}
        body = {
            "repetitions": len(rps),
            "rps_median": statistics.median(rps),
            "rps_mean": statistics.fmean(rps),
            "rps_min": min(rps),
            "rps_max": max(rps),
            # Spread across repetitions is the honest error bar. A single
            # 5-second sample cannot report one at all.
            "rps_stdev": statistics.stdev(rps) if len(rps) > 1 else 0.0,
        }
        p99 = [s.latency_p99_ms for s in self.samples if s.latency_p99_ms is not None]
        if p99:
            body["latency_p99_ms_median"] = statistics.median(p99)
        cpu = [s.cpu_seconds for s in self.samples if s.cpu_seconds]
        if cpu and body["rps_median"]:
            body["cpu_cores_per_1k_rps"] = statistics.median(cpu) / body["rps_median"] * 1000
        return body


def discover(cfg: Config) -> list[tuple[str, str, Path]]:
    found: list[tuple[str, str, Path]] = []
    for protocol in cfg.protocols:
        root = OVERLAYS / protocol
        if not root.is_dir():
            print(f"[warn] no overlays for protocol {protocol!r} at {root}")
            continue
        for overlay in sorted(p for p in root.iterdir() if p.is_dir()):
            if cfg.only and overlay.name not in cfg.only:
                continue
            found.append((protocol, overlay.name, overlay))
    return found


def measure(cfg: Config, cluster: Cluster, name: str) -> dict:
    results: dict[str, ScenarioResult] = {}
    for scenario, path in REST_SCENARIOS.items():
        url = cfg.base_url + path
        res = ScenarioResult(scenario=scenario, path=path)

        print(f"    {scenario}: warm-up {cfg.warmup}s", flush=True)
        bombardier(url, cfg.warmup, cfg.connections, cfg.dry_run)
        if not cfg.dry_run:
            time.sleep(cfg.settle)

        for rep in range(1, cfg.repetitions + 1):
            sample = bombardier(url, cfg.duration, cfg.connections, cfg.dry_run)
            sample.repetition = rep
            sample.cpu_seconds = cluster.pod_cpu_seconds(name)
            res.samples.append(sample)
            print(
                f"      rep {rep}/{cfg.repetitions}: "
                f"{sample.requests_per_sec:,.0f} rps"
                + (f", p99 {sample.latency_p99_ms:.2f} ms" if sample.latency_p99_ms else "")
                + (f", {sample.non_2xx} non-2xx" if sample.non_2xx else ""),
                flush=True,
            )
            if not cfg.dry_run:
                time.sleep(cfg.settle)
        results[scenario] = res
    return {k: {"path": v.path, "samples": [asdict(s) for s in v.samples],
                "summary": v.summary()} for k, v in results.items()}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--host", default=os.environ.get("K3S_HOST", "192.168.1.51"))
    ap.add_argument("--user", default=os.environ.get("K3S_USER", "k8s1"))
    ap.add_argument("--repetitions", type=int, default=5)
    ap.add_argument("--duration", type=int, default=60)
    ap.add_argument("--warmup", type=int, default=30)
    ap.add_argument("--settle", type=int, default=10)
    ap.add_argument("--connections", type=int, default=100)
    ap.add_argument("--seed", type=int, default=None,
                    help="RNG seed for the run order; recorded in the output")
    ap.add_argument("--protocol", action="append", dest="protocols",
                    choices=["rest", "grpc", "graphql"], default=None)
    ap.add_argument("--only", action="append", default=[],
                    help="implementation id; repeatable")
    ap.add_argument("--skip-parity", action="store_true",
                    help="measure even if the parity gate fails (results are "
                         "then not comparable and are marked as such)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    cfg = Config(
        host=args.host, user=args.user, repetitions=args.repetitions,
        duration=args.duration, warmup=args.warmup, settle=args.settle,
        connections=args.connections, seed=args.seed,
        protocols=tuple(args.protocols or ["rest"]),
        only=tuple(args.only), dry_run=args.dry_run,
        skip_parity=args.skip_parity,
    )

    if not cfg.dry_run:
        for tool in ("bombardier",):
            if not shutil.which(tool):
                print(f"[fatal] {tool} is not on PATH. Install it before running "
                      f"the suite; see docs/ACTION_PLAN.md, Fase 2.")
                return 2

    targets = discover(cfg)
    if not targets:
        print("[fatal] no overlays matched")
        return 2

    seed = cfg.seed if cfg.seed is not None else random.randrange(2**32)
    rng = random.Random(seed)
    rng.shuffle(targets)
    print(f"Run order randomized with seed {seed} "
          f"({len(targets)} implementations)\n")

    cluster = Cluster(cfg)
    cluster.check_access()

    started = datetime.now(timezone.utc)
    run_record = {
        "started_utc": started.isoformat(),
        "host": cfg.host,
        "seed": seed,
        "order": [name for _, name, _ in targets],
        "parameters": {
            "repetitions": cfg.repetitions, "duration_s": cfg.duration,
            "warmup_s": cfg.warmup, "settle_s": cfg.settle,
            "connections": cfg.connections, "node_port": NODE_PORT,
            "generator": "bombardier", "generator_location": "workstation",
        },
        "primary_json_scenario": PRIMARY_JSON_SCENARIO,
        "implementations": {},
    }

    cfg.out_dir.mkdir(parents=True, exist_ok=True)
    out_path = cfg.out_dir / f"run-{started:%Y%m%dT%H%M%SZ}.json"

    for idx, (protocol, name, overlay) in enumerate(targets, 1):
        print(f"[{idx}/{len(targets)}] {name} ({protocol})", flush=True)
        record: dict = {"protocol": protocol, "overlay": str(overlay.relative_to(REPO))}
        try:
            cluster.apply(overlay)
            cluster.wait_ready(name)

            competing = cluster.competing_pods(name)
            if competing:
                # Another implementation still running means the CPUs are
                # shared and the number is not a measurement of this one.
                record["status"] = "skipped"
                record["reason"] = f"competing pods: {', '.join(competing)}"
                print(f"    [skip] {record['reason']}", flush=True)
                run_record["implementations"][name] = record
                continue

            ok, detail = parity_ok(cfg.base_url, cfg.dry_run)
            record["parity"] = {"passed": ok, "detail": detail[-2000:]}
            if not ok and not cfg.skip_parity:
                record["status"] = "skipped"
                record["reason"] = "parity gate failed"
                print("    [skip] parity gate failed; not comparable", flush=True)
                run_record["implementations"][name] = record
                continue

            record["scenarios"] = measure(cfg, cluster, name)
            record["status"] = "measured" if ok else "measured-off-contract"
        except (CommandError, subprocess.TimeoutExpired) as exc:
            record["status"] = "error"
            record["reason"] = str(exc)[:1500]
            print(f"    [error] {str(exc)[:200]}", flush=True)
        finally:
            cluster.delete(name)
            if not cfg.dry_run:
                time.sleep(cfg.settle)
            run_record["implementations"][name] = record
            out_path.write_text(json.dumps(run_record, indent=2), encoding="utf-8")

    run_record["finished_utc"] = datetime.now(timezone.utc).isoformat()
    out_path.write_text(json.dumps(run_record, indent=2), encoding="utf-8")
    print(f"\nWrote {out_path}")

    measured = sum(1 for r in run_record["implementations"].values()
                   if r.get("status", "").startswith("measured"))
    print(f"{measured}/{len(targets)} implementations measured")
    return 0


if __name__ == "__main__":
    sys.exit(main())
