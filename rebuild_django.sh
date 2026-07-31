#!/bin/bash
set -e
DJANGO_DIR=/home/k8s1/benchmark/src/python/django

echo '=== removing broken views.py stub ==='
rm -f "$DJANGO_DIR/benchmark/views.py"
ls -la "$DJANGO_DIR/benchmark/" | head

echo '=== rebuilding image benchmark/python-rest-django:latest ==='
cd "$DJANGO_DIR"
docker build -t benchmark/python-rest-django:latest . 2>&1 | tail -8

echo '=== importing into k3s containerd ==='
docker save benchmark/python-rest-django:latest | k3s ctr images import - 2>&1 | tail -3

echo '=== restarting django deployment ==='
kubectl -n benchmark rollout restart deploy/python-rest-django
kubectl -n benchmark rollout status deploy/python-rest-django --timeout=120s

echo '=== django logs after restart ==='
sleep 5
kubectl -n benchmark logs deploy/python-rest-django --tail=10 2>&1 | tail -10
echo 'REBUILD_DJANGO_DONE'
