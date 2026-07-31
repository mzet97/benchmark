#!/bin/bash
set -e
NS=benchmark

# Rewrite secret: ALL db-related keys point to the working external DB (192.168.1.52, db_admin, benchmark_api)
# Password Admin@123 URL-encoded as Admin%40123
kubectl -n "$NS" create secret generic benchmark-secrets --dry-run=client -o yaml \
  --from-literal=database-url='postgresql://db_admin:Admin%40123@192.168.1.52:5432/benchmark_api' \
  --from-literal=DATABASE_URL='postgresql://db_admin:Admin%40123@192.168.1.52:5432/benchmark_api' \
  --from-literal=DB_HOST='192.168.1.52' \
  --from-literal=DB_PORT='5432' \
  --from-literal=DB_USER='db_admin' \
  --from-literal=DB_PASSWORD='Admin@123' \
  --from-literal=DB_NAME='benchmark_api' \
  --from-literal=POSTGRES_HOST='192.168.1.52' \
  --from-literal=POSTGRES_PORT='5432' \
  --from-literal=POSTGRES_USER='db_admin' \
  --from-literal=POSTGRES_PASSWORD='Admin@123' \
  --from-literal=POSTGRES_DB='benchmark_api' \
  --from-literal=PGHOST='192.168.1.52' \
  --from-literal=PGPORT='5432' \
  --from-literal=PGUSER='db_admin' \
  --from-literal=PGPASSWORD='Admin@123' \
  --from-literal=PGDATABASE='benchmark_api' \
  --from-literal=redis-url='redis://:Admin@123@redis-master.redis.svc.cluster.local:6379' \
  --from-literal=REDIS_URL='redis://:Admin%40123@redis-master.redis.svc.cluster.local:6379' \
  --from-literal=REDIS_HOST='redis-master.redis.svc.cluster.local' \
  --from-literal=REDIS_PORT='6379' \
  --from-literal=REDIS_PASSWORD='Admin@123' \
  | kubectl apply -f -

echo 'Secret rewritten. Forcing restart of all 23 REST deployments...'
IMPLS='bun-rest-bun-serve bun-rest-elysia bun-rest-hono csharp-rest-controllers csharp-rest-minimal-api deno-rest-deno-serve deno-rest-fresh deno-rest-hono deno-rest-oak go-rest-echo go-rest-fiber go-rest-gin graalvm-rest-vertx kotlin-rest-ktor nodejs-rest-express nodejs-rest-fastify nodejs-rest-nestjs python-rest-django python-rest-fastapi python-rest-flask rust-rest-actix-web rust-rest-axum rust-rest-rocket'

for impl in $IMPLS; do
  kubectl -n "$NS" rollout restart deploy/"$impl" >/dev/null 2>&1 && echo "  restarted $impl"
done

echo 'Waiting for rollouts to complete...'
for impl in $IMPLS; do
  kubectl -n "$NS" rollout status deploy/"$impl" --timeout=180s >/dev/null 2>&1 && echo "  OK $impl" || echo "  TIMEOUT/FAIL $impl"
done
echo 'ALL_RESTARTED'
