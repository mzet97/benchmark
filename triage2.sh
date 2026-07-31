#!/bin/bash
cat <<'EOF' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata:
  name: triage2
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
          p() { echo "### $1 $2"; curl -s -m 8 "$2" | head -c 200; echo; }
          p deno-hono-health http://deno-rest-hono.benchmark.svc.cluster.local/health
          p bun-elysia-dbc http://bun-rest-elysia.benchmark.svc.cluster.local/db/complex?days=30
          p rust-axum-dbc http://rust-rest-axum.benchmark.svc.cluster.local/db/complex?days=30
          p rust-rocket-db http://rust-rest-rocket.benchmark.svc.cluster.local/db/simple?id=3
          p csharp-min-db http://csharp-rest-minimal-api.benchmark.svc.cluster.local/db/simple?id=3
          p csharp-min-cache http://csharp-rest-minimal-api.benchmark.svc.cluster.local/cache?key=benchmark
          p fastapi-db http://python-rest-fastapi.benchmark.svc.cluster.local/db/simple?id=3
EOF
sleep 3
kubectl wait --for=condition=complete job/triage2 -n benchmark --timeout=90s
kubectl logs job/triage2 -n benchmark
kubectl delete job triage2 -n benchmark --ignore-not-found
