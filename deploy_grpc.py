#!/usr/bin/env python3
"""Build and deploy gRPC implementations on K3s server via SSH (paramiko)."""

import os
import paramiko
import sys
import time

SERVER = "192.168.1.51"
USER = "k8s1"
PASSWORD = os.environ["K3S_SSH_PASSWORD"]
BENCHMARK_DIR = "/home/k8s1/benchmark"

# (impl_id, src_path_relative_to_benchmark, needs_project_root_context)
# needs_project_root_context = True when Dockerfile references contracts/grpc/ or src/<env>/grpc/<fw>/
IMPLEMENTATIONS = [
    # rust
    ("rust-grpc-volo", "src/rust/grpc/volo", True),
    ("rust-grpc-grpcio", "src/rust/grpc/grpcio", True),
    # go
    ("go-grpc-connectrpc", "src/go/grpc/connectrpc", True),
    ("go-grpc-kitex", "src/go/grpc/kitex", True),
    # csharp
    ("csharp-grpc-grpc-dotnet", "src/csharp/grpc/grpc-dotnet", False),
    ("csharp-grpc-protobuf-net-grpc", "src/csharp/grpc/protobuf-net-grpc", False),
    ("csharp-grpc-magiconion", "src/csharp/grpc/magiconion", False),
    # nodejs
    ("nodejs-grpc-nice-grpc", "src/nodejs/grpc/nice-grpc", False),
    ("nodejs-grpc-connectrpc", "src/nodejs/grpc/connectrpc", False),
    # bun
    ("bun-grpc-grpc-js", "src/bun/grpc/grpc-js", False),
    ("bun-grpc-nice-grpc", "src/bun/grpc/nice-grpc", False),
    ("bun-grpc-connectrpc", "src/bun/grpc/connectrpc", False),
    # deno
    ("deno-grpc-grpc-js", "src/deno/grpc/grpc-js", False),
    ("deno-grpc-nice-grpc", "src/deno/grpc/nice-grpc", False),
    ("deno-grpc-connectrpc", "src/deno/grpc/connectrpc", False),
    # python
    ("python-grpc-grpclib", "src/python/grpc/grpclib", False),
    ("python-grpc-betterproto", "src/python/grpc/betterproto", False),
    # dart
    ("dart-grpc-grpc-dart", "src/dart/grpc/grpc-dart", False),
    # java
    ("java-grpc-grpc-java", "src/java/grpc/grpc-java", False),
    ("java-grpc-armeria", "src/java/grpc/armeria", False),
    ("java-grpc-quarkus", "src/java/grpc/quarkus", False),
    # kotlin
    ("kotlin-grpc-grpc-kotlin", "src/kotlin/grpc/grpc-kotlin", False),
    ("kotlin-grpc-spring-grpc", "src/kotlin/grpc/spring-grpc", False),
    ("kotlin-grpc-armeria", "src/kotlin/grpc/armeria", False),
    # graalvm
    ("graalvm-grpc-quarkus", "src/graalvm/grpc/quarkus", True),
    ("graalvm-grpc-micronaut", "src/graalvm/grpc/micronaut", False),
    ("graalvm-grpc-grpc-java", "src/graalvm/grpc/grpc-java", False),
]


def ssh_exec(ssh, cmd, timeout=600, print_output=True):
    """Execute a command over SSH and return (exit_code, stdout, stderr)."""
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdout_str = stdout.read().decode("utf-8", errors="replace")
    stderr_str = stderr.read().decode("utf-8", errors="replace")
    exit_code = stdout.channel.recv_exit_status()
    if print_output:
        if stdout_str.strip():
            for line in stdout_str.strip().split("\n"):
                print(f"  OUT: {line}")
        if stderr_str.strip():
            for line in stderr_str.strip().split("\n"):
                print(f"  ERR: {line}")
    return exit_code, stdout_str, stderr_str


def check_deployment_exists(ssh, impl_id):
    """Check if a k8s deployment already exists."""
    code, out, _ = ssh_exec(
        ssh,
        f"kubectl get deployment {impl_id} -n benchmark -o name 2>/dev/null",
        print_output=False,
    )
    return code == 0 and "deployment" in out


def build_and_deploy(ssh, impl_id, src_path, needs_root_context):
    """Build Docker image, save, import into K3s, and apply kustomize."""
    print(f"\n{'='*70}")
    print(f"  Processing: {impl_id}")
    print(f"  Source: {src_path}")
    print(f"  Root context: {needs_root_context}")
    print(f"{'='*70}")

    # Step 0: Check if already deployed
    if check_deployment_exists(ssh, impl_id):
        print(f"  SKIP: Deployment {impl_id} already exists.")
        return "skipped"

    dockerfile = f"src/{src_path.split('/', 1)[1] if '/' in src_path else src_path}/Dockerfile"
    # Reconstruct dockerfile path from src_path
    dockerfile = f"{src_path}/Dockerfile"
    image_name = f"benchmark/{impl_id}:latest"
    tar_name = f"/tmp/{impl_id}.tar"

    if needs_root_context:
        # Dockerfile references paths relative to project root
        build_cmd = (
            f"cd {BENCHMARK_DIR} && docker build --no-cache "
            f"-f {dockerfile} "
            f"-t {image_name} "
            f"{BENCHMARK_DIR}"
        )
    else:
        # Build from impl directory
        build_cmd = (
            f"cd {BENCHMARK_DIR} && docker build --no-cache "
            f"-f {src_path}/Dockerfile "
            f"-t {image_name} "
            f"{BENCHMARK_DIR}/{src_path}"
        )

    # Step 1: Docker build
    print(f"  [1/4] Building Docker image...")
    print(f"  CMD: {build_cmd}")
    code, out, err = ssh_exec(ssh, build_cmd, timeout=600)
    if code != 0:
        print(f"  FAIL: Docker build failed for {impl_id} (exit code {code})")
        # If impl dir context failed, retry with project root
        if not needs_root_context:
            print(f"  RETRY: Trying with project root as context...")
            build_cmd_retry = (
                f"cd {BENCHMARK_DIR} && docker build --no-cache "
                f"-f {src_path}/Dockerfile "
                f"-t {image_name} "
                f"{BENCHMARK_DIR}"
            )
            print(f"  CMD: {build_cmd_retry}")
            code, out, err = ssh_exec(ssh, build_cmd_retry, timeout=600)
            if code != 0:
                print(f"  FAIL: Retry also failed for {impl_id} (exit code {code})")
                return "failed"
        else:
            return "failed"

    # Step 2: Docker save
    print(f"  [2/4] Saving Docker image to tar...")
    code, _, _ = ssh_exec(ssh, f"docker save {image_name} -o {tar_name}", timeout=120)
    if code != 0:
        print(f"  FAIL: Docker save failed for {impl_id}")
        return "failed"

    # Step 3: Import into K3s
    print(f"  [3/4] Importing image into K3s...")
    code, _, _ = ssh_exec(
        ssh,
        f'bash -c "echo {PASSWORD} | sudo -S k3s ctr images import {tar_name}"',
        timeout=120,
    )
    if code != 0:
        print(f"  FAIL: K3s image import failed for {impl_id}")
        return "failed"

    # Step 4: Cleanup tar
    ssh_exec(ssh, f"rm -f {tar_name}", print_output=False)

    # Step 5: Apply kustomize
    print(f"  [4/4] Applying kustomize deployment...")
    code, out, err = ssh_exec(
        ssh,
        f"cd {BENCHMARK_DIR} && kubectl apply -k deploy/k3s/overlays/grpc/{impl_id}/",
        timeout=60,
    )
    if code != 0:
        print(f"  FAIL: kubectl apply failed for {impl_id}")
        return "failed"

    print(f"  DONE: {impl_id} deployed successfully!")
    return "success"


def main():
    print("Connecting to K3s server...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USER, password=PASSWORD, timeout=30)
    print("Connected!")

    results = {"success": [], "skipped": [], "failed": []}

    try:
        for impl_id, src_path, needs_root in IMPLEMENTATIONS:
            try:
                status = build_and_deploy(ssh, impl_id, src_path, needs_root)
                results[status].append(impl_id)
            except Exception as e:
                print(f"  ERROR: Exception for {impl_id}: {e}")
                results["failed"].append(impl_id)
    finally:
        ssh.close()

    # Summary
    print(f"\n{'='*70}")
    print("DEPLOYMENT SUMMARY")
    print(f"{'='*70}")
    print(f"  Success ({len(results['success'])}): {', '.join(results['success']) or 'none'}")
    print(f"  Skipped ({len(results['skipped'])}): {', '.join(results['skipped']) or 'none'}")
    print(f"  Failed  ({len(results['failed'])}): {', '.join(results['failed']) or 'none'}")
    print(f"{'='*70}")

    return 0 if not results["failed"] else 1


if __name__ == "__main__":
    sys.exit(main())
