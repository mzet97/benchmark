#!/usr/bin/env bash
# collect-metrics.sh
# Collects resource metrics from a running benchmark implementation.
#
# Usage:
#   ./scripts/collect-metrics.sh <implementation-id> [duration-seconds]
#
# Example:
#   ./scripts/collect-metrics.sh rust-rest-actix-web 60

set -euo pipefail

IMPL_ID="${1:?Usage: $0 <implementation-id> [duration-seconds]}"
DURATION="${2:-60}"
NAMESPACE="benchmark"
INTERVAL=5

echo "========================================="
echo "  Metrics Collection"
echo "========================================="
echo "Implementation: $IMPL_ID"
echo "Duration:       ${DURATION}s"
echo "Interval:       ${INTERVAL}s"
echo "========================================="

# Get pod names
PODS=$(kubectl get pods -l "app=$IMPL_ID" -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

if [ -z "$PODS" ]; then
  echo "ERROR: No pods found for $IMPL_ID"
  exit 1
fi

echo "Pods: $PODS"
echo ""

# Create output directory
OUTPUT_DIR="results/metrics/$(date +%Y%m%d-%H%M%S)/$IMPL_ID"
mkdir -p "$OUTPUT_DIR"

# Collect metrics
echo "timestamp,pod,cpu_cores,memory_bytes" > "$OUTPUT_DIR/metrics.csv"

END_TIME=$(($(date +%s) + DURATION))
while [ "$(date +%s)" -lt "$END_TIME" ]; do
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  for pod in $PODS; do
    METRICS=$(kubectl top pod "$pod" -n "$NAMESPACE" --no-headers 2>/dev/null || echo "")
    if [ -n "$METRICS" ]; then
      CPU=$(echo "$METRICS" | awk '{print $2}')
      MEMORY=$(echo "$METRICS" | awk '{print $3}')
      echo "$TIMESTAMP,$pod,$CPU,$MEMORY" >> "$OUTPUT_DIR/metrics.csv"
    fi
  done

  sleep "$INTERVAL"
done

echo ""
echo "========================================="
echo "  Collection Complete"
echo "========================================="
echo "Output: $OUTPUT_DIR/metrics.csv"
echo ""
echo "Sample data:"
head -10 "$OUTPUT_DIR/metrics.csv"

# Collect pod info
kubectl describe pods -l "app=$IMPL_ID" -n "$NAMESPACE" > "$OUTPUT_DIR/pod-description.txt" 2>/dev/null || true
kubectl get pods -l "app=$IMPL_ID" -n "$NAMESPACE" -o wide > "$OUTPUT_DIR/pod-status.txt" 2>/dev/null || true
kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' > "$OUTPUT_DIR/events.txt" 2>/dev/null || true

echo "All metrics saved to: $OUTPUT_DIR/"
