#!/bin/bash
set -e
NS=benchmark
# Append sslmode=disable to DATABASE_URL in secret. This is safe for all drivers (pgx, lib/pq, asyncpg, npgsql).
DBURL_ENC='postgresql://db_admin:Admin%40123@192.168.1.52:5432/benchmark_api?sslmode=disable'

kubectl -n "$NS" create secret generic benchmark-secrets --dry-run=client -o yaml \
  --from-literal=database-url="$DBURL_ENC" \
  --from-literal=DATABASE_URL="$DBURL_ENC" \
  --from-literal=DB_HOST='192.168.1.52' --from-literal=DB_PORT='5432' \
  --from-literal=DB_USER='db_admin' --from-literal=DB_PASSWORD='Admin@123' --from-literal=DB_NAME='benchmark_api' \
  --from-literal=POSTGRES_HOST='192.168.1.52' --from-literal=POSTGRES_PORT='5432' \
  --from-literal=POSTGRES_USER='db_admin' --from-literal=POSTGRES_PASSWORD='Admin@123' --from-literal=POSTGRES_DB='benchmark_api' \
  --from-literal=PGHOST='192.168.1.52' --from-literal=PGPORT='5432' --from-literal=PGUSER='db_admin' --from-literal=PGPASSWORD='Admin@123' --from-literal=PGDATABASE='benchmark_api' \
  --from-literal=redis-url='redis://:Admin@123@redis-master.redis.svc.cluster.local:6379' \
  --from-literal=REDIS_URL='redis://:Admin%40123@redis-master.redis.svc.cluster.local:6379' \
  --from-literal=REDIS_HOST='redis-master.redis.svc.cluster.local' --from-literal=REDIS_PORT='6379' --from-literal=REDIS_PASSWORD='Admin@123' \
  | kubectl apply -f -

echo 'Secret updated with sslmode=disable. Restarting go-echo, go-gin (lib/pq SSL issue)...'
for impl in go-rest-echo go-rest-gin; do
  kubectl -n "$NS" rollout restart deploy/"$impl" >/dev/null 2>&1
done
for impl in go-rest-echo go-rest-gin; do
  kubectl -n "$NS" rollout status deploy/"$impl" --timeout=120s >/dev/null 2>&1 && echo "OK $impl" || echo "FAIL $impl"
done
sleep 3
echo '=== test go-echo/gin after sslmode ==='
cat <<'EOF' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata: {name: ssl-test, namespace: benchmark}
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
        - "for impl in go-rest-echo go-rest-gin; do for p in /health /db/simple?id=3 /db/complex?days=30; do code=$(curl -s -o /dev/null -w '%{http_code}' -m 8 http://$impl.benchmark.svc.cluster.local$p); echo \"$impl $p -> $code\"; done; done"
EOF
sleep 3; kubectl wait --for=condition=complete job/ssl-test -n benchmark --timeout=60s; kubectl logs job/ssl-test -n benchmark; kubectl delete job ssl-test -n benchmark --ignore-not-found
echo 'SSLMODE_TEST_DONE'
