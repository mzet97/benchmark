#!/bin/bash
set -e
NS=benchmark

echo '=== patch django: unset DATABASE_URL (force individual DB_* vars, avoids @ parsing) ==='
# Set DB_* individual vars and override DATABASE_URL to empty so settings.py uses DB_* branch.
# But settings.py checks `if DATABASE_URL:` - we keep DATABASE_URL empty string -> uses DB_* vars.
PATCH=$(python3 -c "
import json
env=[
  {'name':'DATABASE_URL','value':''},
  {'name':'DB_USER','value':'db_admin'},
  {'name':'DB_PASSWORD','value':'Admin@123'},
  {'name':'DB_HOST','value':'192.168.1.52'},
  {'name':'DB_PORT','value':'5432'},
  {'name':'DB_NAME','value':'benchmark_api'},
  {'name':'REDIS_URL','value':'redis://:Admin@123@redis-master.redis.svc.cluster.local:6379'},
]
print(json.dumps({'spec':{'template':{'spec':{'containers':[{'name':'app','env':env}]}}}}))
")
kubectl -n "$NS" patch deploy python-rest-django --type=strategic -p "$PATCH" 2>&1 | head -1
kubectl -n "$NS" rollout status deploy/python-rest-django --timeout=120s
sleep 5
echo '=== django pod env check ==='
DPOD=$(kubectl get pod -n "$NS" -l app=python-rest-django -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n "$NS" "$DPOD" -- sh -c 'echo DB_URL=[$DATABASE_URL] DB_USER=$DB_USER DB_HOST=$DB_HOST' 2>&1
echo '=== test django ==='
cat <<'EOF' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata: {name: dj-test3, namespace: benchmark}
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
        - "for p in /health /json /db/simple?id=3 /db/complex?days=30 /cache?key=benchmark; do code=$(curl -s -o /dev/null -w '%{http_code}' -m 8 http://python-rest-django.benchmark.svc.cluster.local$p); echo \"$p -> $code\"; done"
EOF
sleep 3; kubectl wait --for=condition=complete job/dj-test3 -n benchmark --timeout=60s; kubectl logs job/dj-test3 -n benchmark; kubectl delete job dj-test3 -n benchmark --ignore-not-found
echo 'PATCH_DJANGO_DONE'
