#!/bin/bash
set -e
NS=benchmark
# Temporarily set DEBUG=True to surface the real request error
PATCH=$(python3 -c "
import json
env=[{'name':'DATABASE_URL','value':''},{'name':'DB_USER','value':'db_admin'},{'name':'DB_PASSWORD','value':'Admin@123'},{'name':'DB_HOST','value':'192.168.1.52'},{'name':'DB_PORT','value':'5432'},{'name':'DB_NAME','value':'benchmark_api'},{'name':'REDIS_URL','value':'redis://:Admin@123@redis-master.redis.svc.cluster.local:6379'},{'name':'DEBUG','value':'True'}]
print(json.dumps({'spec':{'template':{'spec':{'containers':[{'name':'app','env':env}]}}}}))
")
kubectl -n "$NS" patch deploy python-rest-django --type=strategic -p "$PATCH" 2>&1 | head -1
kubectl -n "$NS" rollout status deploy/python-rest-django --timeout=120s
sleep 4
echo '=== request with DEBUG=True, capture technical response ==='
cat <<'EOF' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata: {name: dj-debug, namespace: benchmark}
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
        - "curl -s -m 8 http://python-rest-django.benchmark.svc.cluster.local/health | grep -oE 'Exception Value[^<]*|Exception Type[^<]*|[A-Z][a-zA-Z]*Error[^<]{0,80}' | head -10"
EOF
sleep 3; kubectl wait --for=condition=complete job/dj-debug -n benchmark --timeout=60s; kubectl logs job/dj-debug -n benchmark; kubectl delete job dj-debug -n benchmark --ignore-not-found
DJANGO_DEBUG_DONE
