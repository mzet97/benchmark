#!/bin/bash
set -e
DJANGO_DIR=/home/k8s1/benchmark/src/python/django

echo '=== fixing Dockerfile CMD to use app:application on port 8080 ==='
sed -i 's#CMD \["gunicorn", "-b", "0.0.0.0:8000", "--workers", "4", "--threads", "2", "app.wsgi:application"\]#CMD ["gunicorn", "-b", "0.0.0.0:8080", "--workers", "4", "--threads", "2", "app:application"]#' "$DJANGO_DIR/Dockerfile"
# Also fix healthcheck port to 8080
sed -i 's#curl -f http://localhost:8000/health#curl -f http://localhost:8080/health#' "$DJANGO_DIR/Dockerfile"
grep -E 'CMD|curl' "$DJANGO_DIR/Dockerfile"

echo '=== rebuilding image with :fixed tag ==='
cd "$DJANGO_DIR"
docker build -t benchmark/python-rest-django:fixed . 2>&1 | tail -4
docker save benchmark/python-rest-django:fixed -o /tmp/django-fixed.tar
echo '=== importing into containerd ==='
sudo -S k3s ctr images import --no-unpack /tmp/django-fixed.tar <<< 'Admin@123' 2>&1 | tail -2

echo '=== ensure deployment uses :fixed tag + Never pull ==='
kubectl -n benchmark patch deploy python-rest-django --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"benchmark/python-rest-django:fixed"},{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]' 2>&1 | head -1
kubectl -n benchmark rollout status deploy/python-rest-django --timeout=120s
sleep 6
echo '=== pod state ==='
kubectl get pods -n benchmark -l app=python-rest-django --no-headers
echo '=== logs ==='
kubectl -n benchmark logs deploy/python-rest-django --tail=8 2>&1 | tail -8
echo 'FIX_DJANGO_DONE'
