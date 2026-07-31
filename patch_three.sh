#!/bin/bash
# Patch python-fastapi, kotlin-ktor, rust-actix-web with a literal-password DATABASE_URL env var.
# These libs do NOT URL-decode userinfo so they need the literal '@' form.
set -e
NS=benchmark
DBURL_LITERAL='postgresql://db_admin:Admin@123@192.168.1.52:5432/benchmark_api'
REDIS_LITERAL='redis://:Admin@123@redis-master.redis.svc.cluster.local:6379'

for impl in python-rest-fastapi kotlin-rest-ktor rust-rest-actix-web; do
  echo "=== patching $impl ==="
  # Build strategic merge patch JSON with explicit env (overrides envFrom)
  PATCH=$(python3 -c "
import json
env=[{'name':'DATABASE_URL','value':'$DBURL_LITERAL'},{'name':'REDIS_URL','value':'$REDIS_LITERAL'}]
print(json.dumps({'spec':{'template':{'spec':{'containers':[{'name':'app','env':env}]}}}}))
")
  kubectl -n "$NS" patch deploy "$impl" --type=strategic -p "$PATCH" 2>&1 | head -2
done

echo '=== restarting the 3 deployments ==='
for impl in python-rest-fastapi kotlin-rest-ktor rust-rest-actix-web; do
  kubectl -n "$NS" rollout restart deploy/"$impl" >/dev/null 2>&1
done
echo '=== waiting for rollouts ==='
for impl in python-rest-fastapi kotlin-rest-ktor rust-rest-actix-web; do
  kubectl -n "$NS" rollout status deploy/"$impl" --timeout=180s >/dev/null 2>&1 && echo "  OK $impl" || echo "  FAIL $impl"
done
echo 'PATCH_THREE_DONE'
