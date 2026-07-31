#!/bin/bash
# Triage: get error bodies for failing impls/scenarios
cat <<'EOF' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata:
  name: triage
  namespace: benchmark
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 60
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: c
        image: curlimages/curl:latest
        command: ["/bin/sh","-c"]
        args:
        - |
          probe() { curl -s -m 8 "$2" | head -c 160; echo; }
          echo '### nodejs-nestjs /health'; probe x http://nodejs-rest-nestjs.benchmark.svc.cluster.local/health
          echo '### nodejs-nestjs /db/simple'; probe x 'http://nodejs-rest-nestjs.benchmark.svc.cluster.local/db/simple?id=3'
          echo '### csharp-minimal-api /db/simple'; probe x 'http://csharp-rest-minimal-api.benchmark.svc.cluster.local/db/simple?id=3'
          echo '### csharp-minimal-api /cache'; probe x 'http://csharp-rest-minimal-api.benchmark.svc.cluster.local/cache?key=benchmark'
          echo '### go-echo /db/simple'; probe x 'http://go-rest-echo.benchmark.svc.cluster.local/db/simple?id=3'
          echo '### go-echo /health'; probe x 'http://go-rest-echo.benchmark.svc.cluster.local/health'
          echo '### deno-hono /health'; probe x 'http://deno-rest-hono.benchmark.svc.cluster.local/health'
          echo '### deno-hono /db/complex'; probe x 'http://deno-rest-hono.benchmark.svc.cluster.local/db/complex?days=30'
          echo '### python-fastapi /db/simple'; probe x 'http://python-rest-fastapi.benchmark.svc.cluster.local/db/simple?id=3'
          echo '### rust-axum /db/complex'; probe x 'http://rust-rest-axum.benchmark.svc.cluster.local/db/complex?days=30'
          echo '### rust-rocket /db/simple'; probe x 'http://rust-rest-rocket.benchmark.svc.cluster.local/db/simple?id=3'
          echo '### bun-bun-serve /db/complex'; probe x 'http://bun-rest-bun-serve.benchmark.svc.cluster.local/db/complex?days=30'
          echo '### bun-elysia /cache'; probe x 'http://bun-rest-elysia.benchmark.svc.cluster.local/cache?key=benchmark'
EOF
sleep 3
kubectl wait --for=condition=complete job/triage -n benchmark --timeout=120s
kubectl logs job/triage -n benchmark
kubectl delete job triage -n benchmark --ignore-not-found
