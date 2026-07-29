#!/usr/bin/env bash
# deploy.sh
# Deploys a specific implementation to K3s.
#
# Usage:
#   ./scripts/deploy.sh <implementation-id> [mode]
#   ./scripts/deploy.sh rust-rest-actix-web single-pod
#   ./scripts/deploy.sh rust-rest-actix-web clusterip
#   ./scripts/deploy.sh rust-rest-actix-web scale-out
#
# Modes:
#   single-pod  - 1 replica, direct pod access (Mode A)
#   clusterip   - 1 replica, ClusterIP service (Mode B)
#   scale-out   - 5 replicas, ClusterIP service (Mode C)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

IMPL_ID="${1:?Usage: $0 <implementation-id> [mode]}"
MODE="${2:-single-pod}"
NAMESPACE="benchmark"

echo "========================================="
echo "  Deploying Implementation"
echo "========================================="
echo "Implementation: $IMPL_ID"
echo "Mode:           $MODE"
echo "Namespace:      $NAMESPACE"
echo "========================================="

# Ensure namespace exists
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Ensure secrets exist
if kubectl get secret benchmark-secrets -n "$NAMESPACE" > /dev/null 2>&1; then
  echo "Secrets: already exist"
else
  echo "WARNING: benchmark-secrets not found in namespace $NAMESPACE"
  echo "Create it with: kubectl create secret generic benchmark-secrets -n $NAMESPACE --from-literal=database-url='...' --from-literal=redis-url='...'"
  exit 1
fi

# Undeploy first if exists
echo "Cleaning previous deployment..."
kubectl delete deployment "$IMPL_ID" -n "$NAMESPACE" --ignore-not-found=true
kubectl delete service "$IMPL_ID" -n "$NAMESPACE" --ignore-not-found=true
sleep 3

# Determine replicas based on mode
case "$MODE" in
  single-pod)  REPLICAS=1 ;;
  clusterip)   REPLICAS=1 ;;
  scale-out)   REPLICAS=5 ;;
  *)           echo "Unknown mode: $MODE"; exit 1 ;;
esac

# Apply Kustomize overlay if exists
OVERLAY_DIR="$ROOT_DIR/deploy/k3s/overlays"
# Try to find the overlay
OVERLAY_PATH=""
for proto in rest grpc graphql; do
  if [ -d "$OVERLAY_DIR/$proto/$IMPL_ID" ]; then
    OVERLAY_PATH="$OVERLAY_DIR/$proto/$IMPL_ID"
    break
  fi
done

if [ -n "$OVERLAY_PATH" ]; then
  echo "Applying Kustomize overlay from $OVERLAY_PATH"
  kubectl apply -k "$OVERLAY_PATH"
else
  echo "No Kustomize overlay found, using per-framework k8s manifests"
  # Fallback to existing k8s manifests
  IMPL_DIR=""
  # Search for the implementation directory
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-\ id:\ $IMPL_ID$ ]]; then
      FOUND_ID=true
    elif [ "${FOUND_ID:-}" = true ] && [[ "$line" =~ ^[[:space:]]*path:\ (.+)$ ]]; then
      IMPL_DIR="$(echo "${BASH_REMATCH[1]}" | xargs)"
      break
    fi
  done < "$ROOT_DIR/config/implementations.yaml"

  if [ -z "$IMPL_DIR" ] || [ ! -d "$ROOT_DIR/$IMPL_DIR/k8s" ]; then
    echo "ERROR: No k8s manifests found for $IMPL_ID"
    exit 1
  fi

  kubectl apply -f "$ROOT_DIR/$IMPL_DIR/k8s/configmap.yaml" -n "$NAMESPACE" || true
  kubectl apply -f "$ROOT_DIR/$IMPL_DIR/k8s/deployment.yaml" -n "$NAMESPACE" || true
  kubectl apply -f "$ROOT_DIR/$IMPL_DIR/k8s/service.yaml" -n "$NAMESPACE" || true
fi

# Scale to desired replicas
echo "Scaling to $REPLICAS replicas..."
kubectl scale deployment "$IMPL_ID" -n "$NAMESPACE" --replicas="$REPLICAS" 2>/dev/null || true

# Wait for readiness
echo "Waiting for pods to be ready (timeout: 120s)..."
kubectl wait --for=condition=ready pod -l "app=$IMPL_ID" -n "$NAMESPACE" --timeout=120s || {
  echo "WARNING: Pods not ready within timeout"
  kubectl get pods -l "app=$IMPL_ID" -n "$NAMESPACE"
}

echo ""
echo "✅ Deployment complete"
kubectl get pods -l "app=$IMPL_ID" -n "$NAMESPACE"
kubectl get svc "$IMPL_ID" -n "$NAMESPACE" 2>/dev/null || true
