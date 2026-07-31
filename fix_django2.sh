#!/bin/bash
set -e
DJANGO_DIR=/home/k8s1/benchmark/src/python/django

echo '=== fixing views/__init__.py to import view functions ==='
cat > "$DJANGO_DIR/benchmark/views/__init__.py" <<'PYEOF'
from .health import health, healthz
from .json import json_endpoint
from .database import db_simple, db_complex
from .cache import cache

__all__ = ['health', 'healthz', 'json_endpoint', 'db_simple', 'db_complex', 'cache']
PYEOF
cat "$DJANGO_DIR/benchmark/views/__init__.py"

echo '=== rebuild :fixed2 (unique tag forces fresh image) ==='
cd "$DJANGO_DIR"
docker build -t benchmark/python-rest-django:fixed2 . 2>&1 | tail -3
docker save benchmark/python-rest-django:fixed2 -o /tmp/django-fixed2.tar
sudo -S k3s ctr images import --no-unpack /tmp/django-fixed2.tar <<< 'Admin@123' 2>&1 | tail -2

echo '=== point deployment at :fixed2 + Never pull ==='
kubectl -n benchmark patch deploy python-rest-django --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"benchmark/python-rest-django:fixed2"},{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]' 2>&1 | head -1
sleep 8
kubectl -n benchmark rollout status deploy/python-rest-django --timeout=90s
sleep 5
echo '=== pod state ==='
kubectl get pods -n benchmark -l app=python-rest-django --no-headers
echo '=== logs ==='
kubectl -n benchmark logs deploy/python-rest-django --tail=6 2>&1 | tail -6
echo 'FIX_DJANGO2_DONE'
