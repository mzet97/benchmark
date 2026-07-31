#!/bin/bash
set -e
DJANGO_DIR=/home/k8s1/benchmark/src/python/django

echo '=== add missing django contrib apps to INSTALLED_APPS ==='
python3 - "$DJANGO_DIR/benchmark/settings.py" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
if 'django.contrib.contenttypes' not in s:
    s = s.replace(
        "INSTALLED_APPS = [\n    'rest_framework',\n    'benchmark',\n]",
        "INSTALLED_APPS = [\n    'django.contrib.contenttypes',\n    'django.contrib.auth',\n    'rest_framework',\n    'benchmark',\n]"
    )
    open(p,'w').write(s)
    print('patched INSTALLED_APPS')
else:
    print('already patched')
PY
grep -A6 'INSTALLED_APPS' "$DJANGO_DIR/benchmark/settings.py" | head -8

echo '=== rebuild :fixed4 ==='
cd "$DJANGO_DIR"
docker build -t benchmark/python-rest-django:fixed4 . 2>&1 | tail -3
docker save benchmark/python-rest-django:fixed4 -o /tmp/django-fixed4.tar
sudo -S k3s ctr images import --no-unpack /tmp/django-fixed4.tar <<< 'Admin@123' 2>&1 | tail -2

# Switch back to DEBUG=False in env (keep individual DB vars)
PATCH=$(python3 -c "
import json
env=[{'name':'DATABASE_URL','value':''},{'name':'DB_USER','value':'db_admin'},{'name':'DB_PASSWORD','value':'Admin@123'},{'name':'DB_HOST','value':'192.168.1.52'},{'name':'DB_PORT','value':'5432'},{'name':'DB_NAME','value':'benchmark_api'},{'name':'REDIS_URL','value':'redis://:Admin@123@redis-master.redis.svc.cluster.local:6379'},{'name':'DEBUG','value':'False'}]
print(json.dumps({'spec':{'template':{'spec':{'containers':[{'name':'app','image':'benchmark/python-rest-django:fixed4','env':env}]}}}}))
")
kubectl -n benchmark patch deploy python-rest-django --type=strategic -p "$PATCH" 2>&1 | head -1
kubectl -n benchmark patch deploy python-rest-django --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]' 2>&1 | head -1
kubectl -n benchmark rollout status deploy/python-rest-django --timeout=120s
sleep 5
echo '=== test django ==='
cat <<'EOF' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata: {name: dj-test4, namespace: benchmark}
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
sleep 3; kubectl wait --for=condition=complete job/dj-test4 -n benchmark --timeout=60s; kubectl logs job/dj-test4 -n benchmark; kubectl delete job dj-test4 -n benchmark --ignore-not-found
echo 'FIX_DJANGO4_DONE'
