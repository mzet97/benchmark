#!/bin/bash
set -e
# Re-tag the rebuilt image with a unique tag and force k3s to use it
NEWTAG=benchmark/python-rest-django:fixed
echo '=== retag in docker ==='
docker tag benchmark/python-rest-django:latest $NEWTAG 2>&1 | tail -1
docker save $NEWTAG -o /tmp/django-fixed.tar 2>&1 | tail -1
echo '=== import into containerd ==='
sudo -S k3s ctr images import --no-unpack /tmp/django-fixed.tar <<< 'Admin@123' 2>&1 | tail -3
echo '=== set django deployment to use fixed tag + imagePullPolicy Never ==='
kubectl -n benchmark patch deploy python-rest-django --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"benchmark/python-rest-django:fixed"},{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]' 2>&1 | head -1
kubectl -n benchmark rollout status deploy/python-rest-django --timeout=90s
sleep 5
echo '=== pod image id ==='
kubectl get pod -n benchmark -l app=python-rest-django -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.containerStatuses[0].imageID}{"\n"}{end}'
echo '=== logs ==='
kubectl -n benchmark logs deploy/python-rest-django --tail=6 2>&1 | tail -6
echo 'LOAD_DJANGO_DONE'
