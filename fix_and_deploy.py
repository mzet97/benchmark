#!/usr/bin/env python3
"""Fix build issues and retry deployment for failed implementations."""
import paramiko
import sys

SERVER = "192.168.1.51"
USER = "k8s1"
PASSWORD = "Admin@123"

def run_cmd(client, cmd, timeout=120):
    print(f"  >> {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    exit_code = stdout.channel.recv_exit_status()
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    if out.strip():
        for line in out.strip().splitlines():
            print(f"     {line}")
    if err.strip():
        for line in err.strip().splitlines():
            print(f"     [stderr] {line}")
    return exit_code, out, err


def fix_and_build(client, impl_id, impl_path, fixes):
    print(f"\n{'='*60}")
    print(f"Fixing and deploying: {impl_id}")
    print(f"{'='*60}")

    base = f"/home/k8s1/benchmark/{impl_path}"

    # Apply fixes
    for i, fix in enumerate(fixes):
        print(f"\n[Fix {i+1}] {fix['desc']}")
        code, out, err = run_cmd(client, fix['cmd'].format(base=base), timeout=fix.get('timeout', 120))
        if code != 0 and not fix.get('allow_fail', False):
            print(f"  Fix failed (exit {code}), continuing anyway...")

    # Docker build
    print(f"\n[Build] Docker build for {impl_id}")
    cmd = f"cd {base} && docker build -t benchmark/{impl_id}:latest ."
    code, out, err = run_cmd(client, cmd, timeout=600)
    if code != 0:
        print(f"  BUILD FAILED for {impl_id}")
        return False

    # Docker save
    print(f"\n[Save] Docker save")
    cmd = f"docker save benchmark/{impl_id}:latest -o /tmp/{impl_id}.tar"
    code, out, err = run_cmd(client, cmd, timeout=300)
    if code != 0:
        return False

    # K3s import
    print(f"\n[Import] K3s ctr images import")
    cmd = f'bash -c "echo {PASSWORD} | sudo -S k3s ctr images import /tmp/{impl_id}.tar"'
    code, out, err = run_cmd(client, cmd, timeout=300)
    if code != 0:
        run_cmd(client, f"rm -f /tmp/{impl_id}.tar", timeout=30)
        return False

    # Cleanup
    run_cmd(client, f"rm -f /tmp/{impl_id}.tar", timeout=30)

    # Kubectl apply
    print(f"\n[Deploy] kubectl apply")
    cmd = f"cd /home/k8s1/benchmark && kubectl apply -k deploy/k3s/overlays/rest/{impl_id}/"
    code, out, err = run_cmd(client, cmd, timeout=60)
    if code != 0:
        print(f"  KUBECTL APPLY FAILED for {impl_id}")
        return False

    # Check pods
    print(f"\n[Check] Pod status")
    cmd = f"sleep 10 && kubectl get pods -l app={impl_id} -n benchmark"
    code, out, err = run_cmd(client, cmd, timeout=30)

    print(f"\n  >>> {impl_id}: DEPLOYED SUCCESSFULLY")
    return True


def main():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(SERVER, username=USER, password=PASSWORD, timeout=30)
    print("Connected.\n")

    # Define fixes for each failed implementation
    implementations = [
        {
            "id": "rust-rest-axum",
            "path": "src/rust/axum",
            "fixes": [
                {
                    "desc": "Generate Cargo.lock (run cargo generate-lockfile inside Docker-compatible Rust)",
                    "cmd": "cd {base} && docker run --rm -v $(pwd):/app -w /app rust:1.75 cargo generate-lockfile",
                    "timeout": 120,
                },
            ],
        },
        {
            "id": "rust-rest-rocket",
            "path": "src/rust/rocket",
            "fixes": [
                {
                    "desc": "Regenerate Cargo.lock with Rust 1.75 compatible format (delete existing v4 lock first)",
                    "cmd": "cd {base} && rm -f Cargo.lock && docker run --rm -v $(pwd):/app -w /app rust:1.75 cargo generate-lockfile",
                    "timeout": 120,
                },
            ],
        },
        {
            "id": "go-rest-fiber",
            "path": "src/go/fiber",
            "fixes": [
                {
                    "desc": "Run go mod tidy to fix missing go.sum entries",
                    "cmd": "cd {base} && docker run --rm -v $(pwd):/app -w /app golang:1.23-alpine sh -c 'apk add --no-cache git && go mod tidy'",
                    "timeout": 120,
                },
            ],
        },
        {
            "id": "go-rest-gin",
            "path": "src/go/gin",
            "fixes": [
                {
                    "desc": "Run go mod tidy to update go.mod",
                    "cmd": "cd {base} && docker run --rm -v $(pwd):/app -w /app golang:1.23-alpine sh -c 'apk add --no-cache git && go mod tidy'",
                    "timeout": 120,
                },
            ],
        },
    ]

    results = {}
    for impl in implementations:
        try:
            ok = fix_and_build(client, impl["id"], impl["path"], impl["fixes"])
            results[impl["id"]] = "SUCCESS" if ok else "FAILED"
        except Exception as e:
            print(f"  EXCEPTION for {impl['id']}: {e}")
            results[impl["id"]] = "FAILED"

    print(f"\n{'='*60}")
    print("RETRY SUMMARY")
    print(f"{'='*60}")
    for impl_id, status in results.items():
        symbol = "OK" if status == "SUCCESS" else "FAIL"
        print(f"  [{symbol}] {impl_id}: {status}")

    ok_count = sum(1 for v in results.values() if v == "SUCCESS")
    print(f"\n  Retried: {len(results)} | OK: {ok_count} | Failed: {len(results) - ok_count}")

    client.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
