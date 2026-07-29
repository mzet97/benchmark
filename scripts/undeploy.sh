#!/usr/bin/env bash
# undeploy.sh
# Removes a specific implementation from K3s.
#
# Usage:
#   ./scripts/undeploy.sh <implementation-id>
#   ./scripts/undeploy.sh rust-rest-actix-web

set -euo pipefail

IMPL_ID="${1:?Usage: $0 <implementation-id>}"
NAMESPACE="benchmark"

echo "========================================="
echo "  Undeploying: $IMPL_ID"
echo "========================================="

kubectl delete deployment "$IMPL_ID" -n "$NAMESPACE" --ignore-not-found=true
kubectl delete service "$IMPL_ID" -n "$NAMESPACE" --ignore-not-found=true
kubectl delete configmap "${IMPL_ID}-config" -n "$NAMESPACE" --ignore-not-found=true
kubectl delete pods -l "app=$IMPL_ID" -n "$NAMESPACE" --force --ignore-not-found=true

echo ""
echo "✅ Undeployed: $IMPL_ID"
