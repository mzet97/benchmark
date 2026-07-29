#!/usr/bin/env python3
"""Rebuild and redeploy fixed Rust implementations."""
import paramiko
import time

SERVER = "192.168.1.51"
USER = "k8s1"
PASSWORD = "Admin@123"

def run_cmd(client, cmd, timeout=120):
    print(f"  >> {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    if out.strip():
        for line in out.strip().splitlines():
            print(f"     {line}")
    if err.strip():
        for line in err.strip().splitlines():
            print(f"     [stderr] {line}")
    return code, out, err


def rebuild_and_deploy(client, impl_id, impl_path):
    print(f"\n{'='*60}")
    print(f"Rebuilding: {impl_id}")
    print(f"{'='*60}")

    base = f"/home/k8s1/benchmark/{impl_path}"

    # Generate Cargo.lock
    print(f"\n[1] Generate Cargo.lock")
    code, out, err = run_cmd(client,
        f"cd {base} && rm -f Cargo.lock && docker run --rm -v $(pwd):/app -w /app rust:latest cargo generate-lockfile",
        timeout=180)

    # Docker build
    print(f"\n[2] Docker build")
    code, out, err = run_cmd(client,
        f"cd {base} && docker build --no-cache -t benchmark/{impl_id}:latest .",
        timeout=600)
    if code != 0:
        print(f"  BUILD FAILED for {impl_id}")
        return False

    # Docker save
    print(f"\n[3] Docker save")
    code, out, err = run_cmd(client,
        f"docker save benchmark/{impl_id}:latest -o /tmp/{impl_id}.tar",
        timeout=300)
    if code != 0:
        return False

    # K3s import
    print(f"\n[4] K3s import")
    code, out, err = run_cmd(client,
        f'bash -c "echo {PASSWORD} | sudo -S k3s ctr images import /tmp/{impl_id}.tar"',
        timeout=300)
    if code != 0:
        run_cmd(client, f"rm -f /tmp/{impl_id}.tar", timeout=30)
        return False

    # Cleanup
    run_cmd(client, f"rm -f /tmp/{impl_id}.tar", timeout=30)

    # Kubectl apply
    print(f"\n[5] kubectl apply")
    code, out, err = run_cmd(client,
        f"cd /home/k8s1/benchmark && kubectl apply -k deploy/k3s/overlays/rest/{impl_id}/",
        timeout=60)
    if code != 0:
        print(f"  KUBECTL APPLY FAILED")
        return False

    # Check pods
    print(f"\n[6] Check pods")
    time.sleep(15)
    code, out, err = run_cmd(client,
        f"kubectl get pods -l app={impl_id} -n benchmark",
        timeout=15)

    print(f"\n  >>> {impl_id}: DONE")
    return True


def main():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(SERVER, username=USER, password=PASSWORD, timeout=30)
    print("Connected.\n")

    implementations = [
        ("rust-rest-axum", "src/rust/axum"),
        ("rust-rest-rocket", "src/rust/rocket"),
    ]

    results = {}
    for impl_id, impl_path in implementations:
        try:
            ok = rebuild_and_deploy(client, impl_id, impl_path)
            results[impl_id] = "SUCCESS" if ok else "FAILED"
        except Exception as e:
            print(f"  EXCEPTION: {e}")
            import traceback
            traceback.print_exc()
            results[impl_id] = "FAILED"

    print(f"\n{'='*60}")
    print("REBUILD SUMMARY")
    print(f"{'='*60}")
    for impl_id, status in results.items():
        symbol = "OK" if status == "SUCCESS" else "FAIL"
        print(f"  [{symbol}] {impl_id}: {status}")

    client.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
