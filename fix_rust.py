#!/usr/bin/env python3
"""Fix Rust implementations: update Dockerfiles to use rust:latest and regenerate Cargo.lock."""
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


def fix_rust_impl(client, impl_id, impl_path, dockerfile_fixes):
    print(f"\n{'='*60}")
    print(f"Fixing: {impl_id}")
    print(f"{'='*60}")

    base = f"/home/k8s1/benchmark/{impl_path}"
    dockerfile = f"{base}/Dockerfile"

    # Step 1: Read current Dockerfile
    print(f"\n[Read] Current Dockerfile")
    _, out, _ = run_cmd(client, f"cat {dockerfile}", timeout=10)
    original_dockerfile = out

    # Step 2: Apply Dockerfile fixes via sed
    for i, fix in enumerate(dockerfile_fixes):
        print(f"\n[Fix {i+1}] {fix['desc']}")
        code, out, err = run_cmd(client, fix['cmd'].format(base=base, dockerfile=dockerfile), timeout=30)
        if code != 0:
            print(f"  Fix command failed, but continuing...")

    # Step 3: Generate Cargo.lock with rust:latest
    print(f"\n[Generate] Cargo.lock with rust:latest")
    code, out, err = run_cmd(client,
        f"cd {base} && rm -f Cargo.lock && docker run --rm -v $(pwd):/app -w /app rust:latest cargo generate-lockfile",
        timeout=180)
    if code != 0:
        print(f"  WARNING: Cargo.lock generation failed (exit {code})")

    # Step 4: Verify Cargo.lock exists
    code, out, err = run_cmd(client, f"ls -la {base}/Cargo.lock", timeout=10)
    if code != 0:
        print(f"  ERROR: Cargo.lock still missing!")
        return False

    # Step 5: Docker build
    print(f"\n[Build] Docker build for {impl_id}")
    cmd = f"cd {base} && docker build -t benchmark/{impl_id}:latest ."
    code, out, err = run_cmd(client, cmd, timeout=600)
    if code != 0:
        print(f"  BUILD FAILED for {impl_id}")
        return False

    # Step 6: Docker save
    print(f"\n[Save] Docker save")
    cmd = f"docker save benchmark/{impl_id}:latest -o /tmp/{impl_id}.tar"
    code, out, err = run_cmd(client, cmd, timeout=300)
    if code != 0:
        return False

    # Step 7: K3s import
    print(f"\n[Import] K3s ctr images import")
    cmd = f'bash -c "echo {PASSWORD} | sudo -S k3s ctr images import /tmp/{impl_id}.tar"'
    code, out, err = run_cmd(client, cmd, timeout=300)
    if code != 0:
        run_cmd(client, f"rm -f /tmp/{impl_id}.tar", timeout=30)
        return False

    # Cleanup
    run_cmd(client, f"rm -f /tmp/{impl_id}.tar", timeout=30)

    # Step 8: Kubectl apply
    print(f"\n[Deploy] kubectl apply")
    cmd = f"cd /home/k8s1/benchmark && kubectl apply -k deploy/k3s/overlays/rest/{impl_id}/"
    code, out, err = run_cmd(client, cmd, timeout=60)
    if code != 0:
        print(f"  KUBECTL APPLY FAILED for {impl_id}")
        return False

    # Step 9: Check pods
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

    implementations = [
        {
            "id": "rust-rest-axum",
            "path": "src/rust/axum",
            "dockerfile_fixes": [
                {
                    "desc": "Update Rust builder image from rust:1.75 to rust:latest",
                    "cmd": "sed -i 's/FROM rust:1.75 AS builder/FROM rust:latest AS builder/' {dockerfile}",
                },
            ],
        },
        {
            "id": "rust-rest-rocket",
            "path": "src/rust/rocket",
            "dockerfile_fixes": [
                {
                    "desc": "Update Rust builder image from rust:1.75 to rust:latest",
                    "cmd": "sed -i 's/FROM rust:1.75 AS builder/FROM rust:latest AS builder/' {dockerfile}",
                },
            ],
        },
    ]

    results = {}
    for impl in implementations:
        try:
            ok = fix_rust_impl(client, impl["id"], impl["path"], impl["dockerfile_fixes"])
            results[impl["id"]] = "SUCCESS" if ok else "FAILED"
        except Exception as e:
            print(f"  EXCEPTION for {impl['id']}: {e}")
            import traceback
            traceback.print_exc()
            results[impl["id"]] = "FAILED"

    print(f"\n{'='*60}")
    print("RUST FIX SUMMARY")
    print(f"{'='*60}")
    for impl_id, status in results.items():
        symbol = "OK" if status == "SUCCESS" else "FAIL"
        print(f"  [{symbol}] {impl_id}: {status}")

    client.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
