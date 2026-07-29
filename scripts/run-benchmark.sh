#!/usr/bin/env bash
# run-benchmark.sh
# Automated benchmark runner for a single implementation.
#
# Usage:
#   ./scripts/run-benchmark.sh <implementation-id> <scenario> <mode> [concurrency]
#
# Examples:
#   ./scripts/run-benchmark.sh rust-rest-actix-web health single-pod
#   ./scripts/run-benchmark.sh go-grpc-grpc-go health clusterip 100
#   ./scripts/run-benchmark.sh nodejs-graphql-mercurius json single-pod 200
#
# Scenarios: health, json, db-simple, db-complex, cache
# Modes: single-pod, clusterip, scale-out
# Concurrency: 1, 10, 50, 100, 200 (default: 200)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

IMPL_ID="${1:?Usage: $0 <implementation-id> <scenario> <mode> [concurrency]}"
SCENARIO="${2:?Scenario required: health, json, db-simple, db-complex, cache}"
MODE="${3:?Mode required: single-pod, clusterip, scale-out}"
CONCURRENCY="${4:-200}"
NAMESPACE="benchmark"
DURATION=60
WARMUP=30
REPETITIONS=5

echo "========================================="
echo "  Benchmark Runner"
echo "========================================="
echo "Implementation: $IMPL_ID"
echo "Scenario:       $SCENARIO"
echo "Mode:           $MODE"
echo "Concurrency:    $CONCURRENCY"
echo "Duration:       ${DURATION}s"
echo "Warmup:         ${WARMUP}s"
echo "Repetitions:    $REPETITIONS"
echo "========================================="

# Determine protocol from ID
if [[ "$IMPL_ID" == *"-grpc-"* ]]; then
  PROTOCOL="grpc"
elif [[ "$IMPL_ID" == *"-graphql-"* ]]; then
  PROTOCOL="graphql"
else
  PROTOCOL="rest"
fi

echo "Protocol:       $PROTOCOL"

# Determine endpoint based on scenario and protocol
case "$SCENARIO" in
  health)
    REST_PATH="/health"
    GRPC_CALL="benchmark.BenchmarkService.Health"
    GRAPHQL_QUERY='{"query":"{ health { status timestamp } }"}'
    ;;
  json)
    REST_PATH="/json"
    GRPC_CALL="benchmark.BenchmarkService.GetJsonItems"
    GRAPHQL_QUERY='{"query":"{ jsonItems(limit: 1000) { id uuid name email createdAt isActive } }"}'
    ;;
  db-simple)
    REST_PATH="/db/simple?id=1"
    GRPC_CALL="benchmark.BenchmarkService.GetUser"
    GRAPHQL_QUERY='{"query":"{ user(id: 1) { id email firstName lastName age createdAt } }"}'
    ;;
  db-complex)
    REST_PATH="/db/complex?days=30"
    GRPC_CALL="benchmark.BenchmarkService.GetComplexOrders"
    GRAPHQL_QUERY='{"query":"{ complexOrders(days: 30) { periodDays totalUsers data { userId userName totalOrders totalValue averageOrderValue } } }"}'
    ;;
  cache)
    REST_PATH="/cache?key=benchmark"
    GRPC_CALL="benchmark.BenchmarkService.GetCacheValue"
    GRAPHQL_QUERY='{"query":"{ cache(key: \"benchmark\") { key value cached ttl } }"}'
    ;;
  *)
    echo "ERROR: Unknown scenario: $SCENARIO"
    exit 1
    ;;
esac

# Get service IP
SVC_IP=$(kubectl get svc "$IMPL_ID" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
SVC_PORT=$(kubectl get svc "$IMPL_ID" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)

if [ -z "$SVC_IP" ]; then
  echo "ERROR: Service $IMPL_ID not found"
  exit 1
fi

echo "Service: $SVC_IP:$SVC_PORT"
echo ""

# Create results directory
RESULTS_DIR="$ROOT_DIR/results/raw/$(date +%Y%m%d-%H%M%S)/$IMPL_ID/$SCENARIO/$MODE/$CONCURRENCY"
mkdir -p "$RESULTS_DIR"

# Warm-up
echo "--- Warm-up (${WARMUP}s) ---"
case "$PROTOCOL" in
  rest|graphql)
    kubectl run benchmark-warmup --rm -i --restart=Never \
      --image=curlimages/curl:latest -n "$NAMESPACE" -- \
      sh -c "for i in \$(seq 1 100); do curl -s http://$SVC_IP:$SVC_PORT/health > /dev/null; done" 2>/dev/null || true
    ;;
  grpc)
    echo "gRPC warmup skipped (requires ghz image)"
    ;;
esac
sleep 5

# Run repetitions
echo ""
echo "--- Measurements ($REPETITIONS repetitions) ---"

for run in $(seq 1 "$REPETITIONS"); do
  echo ""
  echo "=== Run $run/$REPETITIONS ==="

  case "$PROTOCOL" in
    rest)
      # Use wrk
      TARGET_URL="http://$SVC_IP:$SVC_PORT$REST_PATH"
      echo "Target: $TARGET_URL"

      JOB_NAME="benchmark-wrk-${IMPL_ID}-${run}"
      cat <<EOF | kubectl apply -f - -n "$NAMESPACE"
apiVersion: batch/v1
kind: Job
metadata:
  name: $JOB_NAME
  namespace: $NAMESPACE
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: wrk
          image: williamyeh/wrk:latest
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Running wrk..."
              wrk -t4 -c$CONCURRENCY -d${DURATION}s --latency $TARGET_URL
          resources:
            requests: { cpu: "2", memory: "512Mi" }
            limits:   { cpu: "2", memory: "512Mi" }
EOF
      ;;

    grpc)
      # Use ghz
      TARGET="$SVC_IP:$SVC_PORT"
      echo "Target: $TARGET"

      JOB_NAME="benchmark-ghz-${IMPL_ID}-${run}"
      cat <<EOF | kubectl apply -f - -n "$NAMESPACE"
apiVersion: batch/v1
kind: Job
metadata:
  name: $JOB_NAME
  namespace: $NAMESPACE
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: ghz
          image: ghcr.io/bojand/ghz:latest
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Running ghz..."
              ghz --insecure \\
                --duration ${DURATION}s \\
                --connections 10 \\
                --concurrency $CONCURRENCY \\
                --call $GRPC_CALL \\
                --format json \\
                $TARGET
          resources:
            requests: { cpu: "2", memory: "512Mi" }
            limits:   { cpu: "2", memory: "512Mi" }
EOF
      ;;

    graphql)
      # Use k6 or curl-based load test
      TARGET_URL="http://$SVC_IP:$SVC_PORT/graphql"
      echo "Target: $TARGET_URL"

      JOB_NAME="benchmark-k6-${IMPL_ID}-${run}"
      cat <<EOF | kubectl apply -f - -n "$NAMESPACE"
apiVersion: batch/v1
kind: Job
metadata:
  name: $JOB_NAME
  namespace: $NAMESPACE
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: k6
          image: grafana/k6:latest
          command: ["k6", "run", "--vus", "$CONCURRENCY", "--duration", "${DURATION}s", "-"]
          stdin: |
            import http from 'k6/http';
            import { check } from 'k6';

            const payload = JSON.stringify($GRAPHQL_QUERY);
            const params = { headers: { 'Content-Type': 'application/json' } };

            export default function () {
              const res = http.post('$TARGET_URL', payload, params);
              check(res, { 'status is 200': (r) => r.status === 200 });
            }
          resources:
            requests: { cpu: "2", memory: "512Mi" }
            limits:   { cpu: "2", memory: "512Mi" }
EOF
      ;;
  esac

  # Wait for job completion
  echo "Waiting for benchmark job to complete (timeout: 300s)..."
  kubectl wait --for=condition=complete "job/$JOB_NAME" -n "$NAMESPACE" --timeout=300s 2>/dev/null || {
    echo "WARNING: Job did not complete within timeout"
  }

  # Collect output
  echo "Collecting results..."
  kubectl logs "job/$JOB_NAME" -n "$NAMESPACE" > "$RESULTS_DIR/run-${run}.txt" 2>/dev/null || true

  # Cleanup job
  kubectl delete job "$JOB_NAME" -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true

  # Pause between runs
  if [ "$run" -lt "$REPETITIONS" ]; then
    echo "Cooling down for 10s..."
    sleep 10
  fi
done

echo ""
echo "========================================="
echo "  Benchmark Complete"
echo "========================================="
echo "Results saved to: $RESULTS_DIR"
echo ""
echo "Files:"
ls -la "$RESULTS_DIR/"
echo ""
echo "Review results with:"
echo "  cat $RESULTS_DIR/run-1.txt"
