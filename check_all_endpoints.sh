#!/bin/bash
# Check all 23 REST endpoints current status with the encoded DB password
NS=benchmark
IMPLS='bun-rest-bun-serve bun-rest-elysia bun-rest-hono csharp-rest-controllers csharp-rest-minimal-api deno-rest-deno-serve deno-rest-fresh deno-rest-hono deno-rest-oak go-rest-echo go-rest-fiber go-rest-gin graalvm-rest-vertx kotlin-rest-ktor nodejs-rest-express nodejs-rest-fastify nodejs-rest-nestjs python-rest-django python-rest-fastapi python-rest-flask rust-rest-actix-web rust-rest-axum rust-rest-rocket'

cat <<'EOF' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata:
  name: all-ep-check
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
          IMPLS='bun-rest-bun-serve bun-rest-elysia bun-rest-hono csharp-rest-controllers csharp-rest-minimal-api deno-rest-deno-serve deno-rest-fresh deno-rest-hono deno-rest-oak go-rest-echo go-rest-fiber go-rest-gin graalvm-rest-vertx kotlin-rest-ktor nodejs-rest-express nodejs-rest-fastify nodejs-rest-nestjs python-rest-django python-rest-fastapi python-rest-flask rust-rest-actix-web rust-rest-axum rust-rest-rocket'
          for impl in $IMPLS; do
            H=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://$impl.benchmark.svc.cluster.local/health")
            J=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://$impl.benchmark.svc.cluster.local/json")
            D=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://$impl.benchmark.svc.cluster.local/db/simple?id=3")
            DC=$(curl -s -o /dev/null -w '%{http_code}' -m 8 "http://$impl.benchmark.svc.cluster.local/db/complex?days=30")
            C=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://$impl.benchmark.svc.cluster.local/cache?key=benchmark")
            echo "$impl H=$H J=$J DB=$D DBC=$DC C=$C"
          done
EOF
sleep 3
kubectl wait --for=condition=complete job/all-ep-check -n benchmark --timeout=180s
kubectl logs job/all-ep-check -n benchmark
kubectl delete job all-ep-check -n benchmark --ignore-not-found
