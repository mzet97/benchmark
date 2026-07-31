#!/usr/bin/env python3
"""Fix and deploy the 2 remaining Rust implementations."""
import os
import paramiko
import sys

SERVER = "192.168.1.51"
USER = "k8s1"
PASSWORD = os.environ["K3S_SSH_PASSWORD"]

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


def fix_and_deploy(client, impl_id, impl_path):
    print(f"\n{'='*60}")
    print(f"Fixing and deploying: {impl_id}")
    print(f"{'='*60}")

    base = f"/home/k8s1/benchmark/{impl_path}"

    # Step 1: Generate Cargo.lock with rust:latest
    print(f"\n[1] Generate Cargo.lock")
    cmd = f"cd {base} && rm -f Cargo.lock && docker run --rm -v $(pwd):/app -w /app rust:latest cargo generate-lockfile"
    code, out, err = run_cmd(client, cmd, timeout=180)
    if code != 0:
        print(f"  WARNING: Cargo.lock generation returned {code}")

    # Verify
    code, out, err = run_cmd(client, f"test -f {base}/Cargo.lock && echo 'EXISTS' || echo 'MISSING'", timeout=5)
    if "MISSING" in out:
        print(f"  ERROR: Cargo.lock still missing!")
        return False

    # Step 2: Docker build
    print(f"\n[2] Docker build")
    cmd = f"cd {base} && docker build -t benchmark/{impl_id}:latest ."
    code, out, err = run_cmd(client, cmd, timeout=600)
    if code != 0:
        print(f"  BUILD FAILED")
        return False

    # Step 3: Docker save
    print(f"\n[3] Docker save")
    cmd = f"docker save benchmark/{impl_id}:latest -o /tmp/{impl_id}.tar"
    code, out, err = run_cmd(client, cmd, timeout=300)
    if code != 0:
        return False

    # Step 4: K3s import
    print(f"\n[4] K3s import")
    cmd = f'bash -c "echo {PASSWORD} | sudo -S k3s ctr images import /tmp/{impl_id}.tar"'
    code, out, err = run_cmd(client, cmd, timeout=300)
    if code != 0:
        run_cmd(client, f"rm -f /tmp/{impl_id}.tar", timeout=30)
        return False

    # Cleanup
    run_cmd(client, f"rm -f /tmp/{impl_id}.tar", timeout=30)

    # Step 5: Kubectl apply
    print(f"\n[5] kubectl apply")
    cmd = f"cd /home/k8s1/benchmark && kubectl apply -k deploy/k3s/overlays/rest/{impl_id}/"
    code, out, err = run_cmd(client, cmd, timeout=60)
    if code != 0:
        print(f"  KUBECTL APPLY FAILED")
        return False

    # Step 6: Check pods
    print(f"\n[6] Check pods")
    cmd = f"sleep 10 && kubectl get pods -l app={impl_id} -n benchmark"
    code, out, err = run_cmd(client, cmd, timeout=30)

    print(f"\n  >>> {impl_id}: DEPLOYED SUCCESSFULLY")
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
            ok = fix_and_deploy(client, impl_id, impl_path)
            results[impl_id] = "SUCCESS" if ok else "FAILED"
        except Exception as e:
            print(f"  EXCEPTION: {e}")
            import traceback
            traceback.print_exc()
            results[impl_id] = "FAILED"

    print(f"\n{'='*60}")
    print("FINAL SUMMARY")
    print(f"{'='*60}")
    for impl_id, status in results.items():
        symbol = "OK" if status == "SUCCESS" else "FAIL"
        print(f"  [{symbol}] {impl_id}: {status}")

    client.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
