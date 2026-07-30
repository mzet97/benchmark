#!/usr/bin/env python3
"""Save, import, and deploy all 6 fixed gRPC images to K3s."""
import paramiko
import sys

IMAGES = [
    "bun-grpc-nice-grpc",
    "deno-grpc-nice-grpc",
    "nodejs-grpc-nice-grpc",
    "nodejs-grpc-connectrpc",
    "python-grpc-grpclib",
    "python-grpc-betterproto",
]

def run(client, cmd, timeout=300):
    """Run command via SSH and return (stdout, stderr, exit_code)."""
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    code = stdout.channel.recv_exit_status()
    return out, err, code

def main():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect('192.168.1.51', username='k8s1', password='Admin@123', timeout=15)

    # Step 1: Save all images and import to K3s
    for img in IMAGES:
        image_name = f"benchmark/{img}:latest"
        tar_path = f"/tmp/{img}.tar"
        print(f"\n=== Processing {img} ===")

        print(f"  Saving {image_name}...")
        out, err, code = run(client, f"docker save {image_name} -o {tar_path}")
        if code != 0:
            print(f"  ERROR saving: {err}")
            continue

        print(f"  Importing to K3s...")
        out, err, code = run(client, f"echo Admin@123 | sudo -S k3s ctr images import {tar_path}")
        if code != 0:
            print(f"  ERROR importing: {err}")
        else:
            print(f"  OK: {out.strip()}")

        print(f"  Cleaning up tar...")
        run(client, f"rm -f {tar_path}")

    # Step 2: Create deployment manifests for all 6
    print("\n=== Creating Deployments ===")

    # Define runtime/framework/protocol for each
    deploy_configs = {
        "bun-grpc-nice-grpc": {
            "runtime": "bun", "framework": "nice-grpc", "protocol": "grpc",
            "configmap": "bun-grpc-nice-grpc-config",
        },
        "deno-grpc-nice-grpc": {
            "runtime": "deno", "framework": "nice-grpc", "protocol": "grpc",
            "configmap": "deno-grpc-nice-grpc-config",
        },
        "nodejs-grpc-nice-grpc": {
            "runtime": "nodejs", "framework": "nice-grpc", "protocol": "grpc",
            "configmap": "nodejs-grpc-nice-grpc-config",
        },
        "nodejs-grpc-connectrpc": {
            "runtime": "nodejs", "framework": "connectrpc", "protocol": "grpc",
            "configmap": "nodejs-grpc-connectrpc-config",
        },
        "python-grpc-grpclib": {
            "runtime": "python", "framework": "grpclib", "protocol": "grpc",
            "configmap": "python-grpc-grpclib-config",
        },
        "python-grpc-betterproto": {
            "runtime": "python", "framework": "betterproto", "protocol": "grpc",
            "configmap": "python-grpc-betterproto-config",
        },
    }

    for name, cfg in deploy_configs.items():
        runtime = cfg["runtime"]
        framework = cfg["framework"]
        protocol = cfg["protocol"]
        configmap = cfg["configmap"]

        # Check if deployment already exists
        out, err, code = run(client, f"kubectl get deployment {name} -n benchmark 2>/dev/null")
        if code == 0:
            print(f"  {name}: deployment exists, restarting pod...")
            run(client, f"kubectl delete pod -l app={name} -n benchmark --force 2>/dev/null")
            continue

        print(f"  {name}: creating deployment...")

        # Create configmap if not exists
        cm_out, _, cm_code = run(client, f"kubectl get configmap {configmap} -n benchmark 2>/dev/null")
        if cm_code != 0:
            cm_yaml = f"""apiVersion: v1
kind: ConfigMap
metadata:
  name: {configmap}
  namespace: benchmark
  labels:
    app: {name}
data:
  PORT: "50051"
  GRPC_PORT: "50051"
  DB_HOST: "postgres.benchmark.svc.cluster.local"
  DB_PORT: "5432"
  DB_NAME: "benchmark"
  DB_USER: "benchmark"
  REDIS_HOST: "redis.benchmark.svc.cluster.local"
  REDIS_PORT: "6379"
"""
            run(client, f"kubectl apply -f - <<'CMEOF'\n{cm_yaml}\nCMEOF")

        # Create deployment
        deploy_yaml = f"""apiVersion: apps/v1
kind: Deployment
metadata:
  name: {name}
  namespace: benchmark
  labels:
    app: {name}
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/part-of: benchmark
    benchmark-environment: {runtime}
    benchmark-framework: {framework}
    benchmark-protocol: {protocol}
    benchmark-role: server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {name}
      app.kubernetes.io/managed-by: kustomize
      app.kubernetes.io/part-of: benchmark
      benchmark-environment: {runtime}
      benchmark-framework: {framework}
      benchmark-protocol: {protocol}
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: {name}
        app.kubernetes.io/managed-by: kustomize
        app.kubernetes.io/part-of: benchmark
        benchmark-environment: {runtime}
        benchmark-framework: {framework}
        benchmark-protocol: {protocol}
        benchmark-role: server
    spec:
      containers:
      - name: app
        image: benchmark/{name}:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 50051
          name: grpc
          protocol: TCP
        envFrom:
        - configMapRef:
            name: {configmap}
        - secretRef:
            name: benchmark-secrets
            optional: true
        livenessProbe:
          tcpSocket:
            port: grpc
          initialDelaySeconds: 15
          periodSeconds: 20
        readinessProbe:
          tcpSocket:
            port: grpc
          initialDelaySeconds: 10
          periodSeconds: 10
        resources:
          requests:
            cpu: 250m
            memory: 128Mi
          limits:
            cpu: "2"
            memory: 1Gi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
      securityContext:
        runAsGroup: 1001
        runAsNonRoot: true
        runAsUser: 1001
      terminationGracePeriodSeconds: 30
"""
        out, err, code = run(client, f"kubectl apply -f - <<'DEPLOYEOF'\n{deploy_yaml}\nDEPLOYEOF")
        if code != 0:
            print(f"  ERROR creating deployment: {err}")
        else:
            print(f"  OK: {out.strip()}")

    # Step 3: Wait for pods to start
    print("\n=== Waiting for pods (30s) ===")
    import time
    time.sleep(30)

    # Step 4: Check status
    print("\n=== Pod Status ===")
    out, _, _ = run(client, "kubectl get pods -n benchmark --no-headers | grep -E 'nice-grpc|grpclib|betterproto|nodejs-grpc-connect'")
    print(out)

    client.close()
    print("\nDone!")

if __name__ == '__main__':
    main()
