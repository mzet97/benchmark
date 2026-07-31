#!/usr/bin/env python3
"""
Run benchmarks on ALL 23 REST implementations across ALL 5 scenarios.
K3s server: 192.168.1.51 (user: k8s1, password: <from $K3S_SSH_PASSWORD>)
"""

import os
import paramiko
import time
import re
import sys

SERVER = "192.168.1.51"
USER = "k8s1"
PASSWORD = os.environ["K3S_SSH_PASSWORD"]
NAMESPACE = "benchmark"

IMPLEMENTATIONS = [
    "bun-rest-bun-serve",
    "bun-rest-elysia",
    "bun-rest-hono",
    "csharp-rest-controllers",
    "csharp-rest-minimal-api",
    "deno-rest-deno-serve",
    "deno-rest-fresh",
    "deno-rest-hono",
    "deno-rest-oak",
    "go-rest-echo",
    "go-rest-fiber",
    "go-rest-gin",
    "graalvm-rest-vertx",
    "kotlin-rest-ktor",
    "nodejs-rest-express",
    "nodejs-rest-fastify",
    "nodejs-rest-nestjs",
    "python-rest-django",
    "python-rest-fastapi",
    "python-rest-flask",
    "rust-rest-actix-web",
    "rust-rest-axum",
    "rust-rest-rocket",
]

SCENARIOS = {
    "health": "/health",
    "json": "/json",
    "db-simple": "/db/simple?id=1",
    "db-complex": "/db/complex?days=30",
    "cache": "/cache?key=benchmark",
}


def ssh_exec(ssh, command, timeout=15):
    stdin, stdout, stderr = ssh.exec_command(command, timeout=timeout)
    stdout.channel.settimeout(timeout)
    try:
        out = stdout.read().decode("utf-8", errors="replace")
    except Exception:
        out = ""
    try:
        err = stderr.read().decode("utf-8", errors="replace")
    except Exception:
        err = ""
    try:
        code = stdout.channel.recv_exit_status()
    except Exception:
        code = -1
    return out, err, code


def make_job_name(impl, scenario):
    # Kubernetes job names: max 63 chars, lowercase, alphanumeric + hyphens
    name = f"bench-{impl}-{scenario}"
    # Truncate to 62 chars to be safe
    name = name[:62].lower()
    return name


def make_job_yaml(job_name, url):
    return f"""apiVersion: batch/v1
kind: Job
metadata:
  name: {job_name}
  namespace: {NAMESPACE}
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: w
        image: williamyeh/wrk:latest
        command: ["/bin/sh", "-c"]
        args: ["wrk -t1 -c20 -d2s {url} > /dev/null 2>&1 && sleep 1 && wrk -t2 -c50 -d5s --latency {url}"]
        resources:
          requests: {{ cpu: "500m", memory: "128Mi" }}
          limits: {{ cpu: "1", memory: "256Mi" }}
"""


def parse_requests_per_sec(output):
    match = re.search(r"Requests/sec:\s+([\d.]+)", output)
    if match:
        return float(match.group(1))
    return None


def run_benchmark(ssh, impl, scenario, path):
    job_name = make_job_name(impl, scenario)
    url = f"http://{impl}.{NAMESPACE}.svc.cluster.local{path}"
    yaml = make_job_yaml(job_name, url)

    # Delete any existing job
    ssh_exec(ssh, f"kubectl delete job {job_name} -n {NAMESPACE} --ignore-not-found --timeout=10s", timeout=15)
    time.sleep(1)

    # Apply the job via stdin
    # Use python on remote to write the yaml and apply
    apply_cmd = f"cat <<'JOBEOF' | kubectl apply -f - --timeout=10s\n{yaml}JOBEOF"
    out, err, code = ssh_exec(ssh, apply_cmd, timeout=15)
    if code != 0:
        print(f"    [WARN] Apply failed: {err.strip()[:150]}", flush=True)
        return None

    # Wait for job to complete using kubectl wait (max 60s)
    out, err, code = ssh_exec(ssh, f"kubectl wait --for=condition=complete job/{job_name} -n {NAMESPACE} --timeout=60s", timeout=70)

    # Check if job failed instead
    if code != 0:
        # Check if it failed
        out_f, err_f, _ = ssh_exec(ssh, f"kubectl wait --for=condition=failed job/{job_name} -n {NAMESPACE} --timeout=5s", timeout=15)
        if "condition met" in out_f:
            print(f"    [SKIP] Job failed", flush=True)
        else:
            print(f"    [SKIP] Timeout waiting", flush=True)
        ssh_exec(ssh, f"kubectl delete job {job_name} -n {NAMESPACE} --ignore-not-found --timeout=10s", timeout=15)
        return None

    # Get logs
    logs, err, code = ssh_exec(ssh, f"kubectl logs job/{job_name} -n {NAMESPACE}", timeout=15)
    if code != 0 or not logs.strip():
        print(f"    [SKIP] No logs", flush=True)
        ssh_exec(ssh, f"kubectl delete job {job_name} -n {NAMESPACE} --ignore-not-found --timeout=10s", timeout=15)
        return None

    # Parse
    rps = parse_requests_per_sec(logs)

    # Cleanup
    ssh_exec(ssh, f"kubectl delete job {job_name} -n {NAMESPACE} --ignore-not-found --timeout=10s", timeout=15)

    return rps


def main():
    print("=" * 80)
    print("BENCHMARK RUNNER: 23 implementations x 5 scenarios = 115 tests")
    print("=" * 80, flush=True)

    # Connect
    print("\nConnecting to K3s server...", flush=True)
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USER, password=PASSWORD, timeout=15)
    print(f"Connected to {SERVER}", flush=True)

    # Verify namespace
    out, err, code = ssh_exec(ssh, f"kubectl get ns {NAMESPACE} --no-headers", timeout=15)
    if code != 0:
        print(f"FATAL: namespace {NAMESPACE} not found")
        sys.exit(1)

    # Clean up leftover bench jobs
    ssh_exec(ssh, "kubectl delete jobs -n benchmark --all --ignore-not-found --timeout=10s", timeout=15)
    time.sleep(2)

    results = {}
    total = len(IMPLEMENTATIONS) * len(SCENARIOS)
    done = 0
    failed = 0

    print(f"\nRunning {total} benchmarks...\n", flush=True)

    for impl in IMPLEMENTATIONS:
        results[impl] = {}
        print(f"--- {impl} ---", flush=True)
        for scenario, path in SCENARIOS.items():
            done += 1
            print(f"  [{done}/{total}] {scenario}...", end=" ", flush=True)
            rps = run_benchmark(ssh, impl, scenario, path)
            if rps is not None:
                results[impl][scenario] = rps
                print(f"{rps:,.1f} req/s", flush=True)
            else:
                results[impl][scenario] = None
                failed += 1
                print("FAILED/SKIPPED", flush=True)

    ssh.close()

    # Print results table
    print("\n" + "=" * 110)
    print("BENCHMARK RESULTS (Requests/sec)")
    print("=" * 110)

    scenarios_list = list(SCENARIOS.keys())
    header = f"{'IMPLEMENTATION':<30}"
    for s in scenarios_list:
        header += f" | {s:>12}"
    print(header)
    print("-" * len(header))

    for impl in IMPLEMENTATIONS:
        row = f"{impl:<30}"
        for s in scenarios_list:
            val = results[impl].get(s)
            if val is not None:
                row += f" | {val:>12,.1f}"
            else:
                row += f" | {'N/A':>12}"
        print(row)

    print("-" * len(header))
    print(f"\nCompleted: {done - failed}/{total} successful, {failed} failed/skipped")

    # Compact format
    print("\n\nCOMPACT FORMAT:")
    print("IMPLEMENTATION | health | json | db-simple | db-complex | cache")
    print("-" * 90)
    for impl in IMPLEMENTATIONS:
        vals = []
        for s in scenarios_list:
            val = results[impl].get(s)
            vals.append(f"{val:,.1f}" if val is not None else "N/A")
        print(f"{impl} | {' | '.join(vals)}")


if __name__ == "__main__":
    main()
