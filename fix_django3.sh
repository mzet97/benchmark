#!/bin/bash
set -e
DJANGO_DIR=/home/k8s1/benchmark/src/python/django

echo '=== fixing views/__init__.py to NOT shadow submodules (empty pkg) ==='
echo '# Views package' > "$DJANGO_DIR/benchmark/views/__init__.py"

echo '=== fixing urls.py to import submodules explicitly ==='
cat > "$DJANGO_DIR/benchmark/urls.py" <<'PYEOF'
from django.urls import path
from .views import health, json, database, cache

urlpatterns = [
    path('', health.health, name='root'),
    path('health', health.health, name='health'),
    path('healthz', health.healthz, name='healthz'),
    path('json', json.json_endpoint, name='json'),
    path('db/simple', database.db_simple, name='db_simple'),
    path('db/complex', database.db_complex, name='db_complex'),
    path('cache', cache.cache, name='cache'),
]
PYEOF
cat "$DJANGO_DIR/benchmark/urls.py"

echo '=== rebuild :fixed3 ==='
cd "$DJANGO_DIR"
docker build -t benchmark/python-rest-django:fixed3 . 2>&1 | tail -3
docker save benchmark/python-rest-django:fixed3 -o /tmp/django-fixed3.tar
sudo -S k3s ctr images import --no-unpack /tmp/django-fixed3.tar <<< 'Admin@123' 2>&1 | tail -2

kubectl -n benchmark patch deploy python-rest-django --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"benchmark/python-rest-django:fixed3"},{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]' 2>&1 | head -1
kubectl -n benchmark rollout status deploy/python-rest-django --timeout=90s
sleep 5
echo '=== pod state ==='
kubectl get pods -n benchmark -l app=python-rest-django --no-headers
echo '=== test django endpoints ==='
cat <<'EOF2' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata: {name: dj-test, namespace: benchmark}
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
EOF2
sleep 3; kubectl wait --for=condition=complete job/dj-test -n benchmark --timeout=60s; kubectl logs job/dj-test -n benchmark; kubectl delete job dj-test -n benchmark --ignore-not-found
echo 'FIX_DJANGO3_DONE'
