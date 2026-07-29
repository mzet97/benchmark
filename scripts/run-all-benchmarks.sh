#!/usr/bin/env bash
# run-all-benchmarks.sh
# Executes benchmarks for ALL running implementations on K3s.
#
# Usage: ./scripts/run-all-benchmarks.sh [scenario] [mode] [concurrency]
# Example: ./scripts/run-all-benchmarks.sh health single-pod 200

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

SCENARIO="${1:-health}"
MODE="${2:-single-pod}"
CONCURRENCY="${3:-200}"
DURATION=60
WARMUP=30
REPETITIONS=5
NAMESPACE="benchmark"

echo "========================================="
echo "  Full Benchmark Suite"
echo "========================================="
echo "Scenario:    $SCENARIO"
echo "Mode:        $MODE"
echo "Concurrency: $CONCURRENCY"
echo "Duration:    ${DURATION}s"
echo "Repetitions: $REPETITIONS"
echo "========================================="

# Get all running deployments
IMPLS=$(kubectl get deployments -n "$NAMESPACE" --no-headers 2>/dev/null | awk '$2 ~ /1\/1/ {print $1}' | grep -v postgres)

if [ -z "$IMPLS" ]; then
  echo "ERROR: No running implementations found"
  exit 1
fi

TOTAL=$(echo "$IMPLS" | wc -l)
echo "Found $TOTAL running implementations"
echo ""

# Create results directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="$ROOT_DIR/results/raw/$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

# Randomize order
IMPLS=$(echo "$IMPLS" | shuf)

COUNTER=0
for IMPL in $IMPLS; do
  COUNTER=$((COUNTER + 1))
  echo ""
  echo "========================================="
  echo "  [$COUNTER/$TOTAL] $IMPL"
  echo "========================================="

  # Get service endpoint
  SVC_IP=$(kubectl get svc "$IMPL" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
  SVC_PORT=$(kubectl get svc "$IMPL" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)

  if [ -z "$SVC_IP" ]; then
    echo "WARNING: No service found for $IMPL, skipping"
    continue
  fi

  # Determine protocol and endpoint
  if [[ "$IMPL" == *"-grpc-"* ]]; then
    PROTOCOL="grpc"
    ENDPOINT="$SVC_IP:$SVC_PORT"
  elif [[ "$IMPL" == *"-graphql-"* ]]; then
    PROTOCOL="graphql"
    ENDPOINT="http://$SVC_IP:$SVC_PORT/graphql"
  else
    PROTOCOL="rest"
    ENDPOINT="http://$SVC_IP:$SVC_PORT"
  fi

  echo "Protocol: $PROTOCOL"
  echo "Endpoint: $ENDPOINT"

  # Determine scenario path
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
      echo "Unknown scenario: $SCENARIO"
      continue
      ;;
  esac

  IMPL_DIR="$RESULTS_DIR/$IMPL/$SCENARIO/$MODE"
  mkdir -p "$IMPL_DIR"

  # Smoke test first
  echo "--- Smoke test ---"
  if [[ "$PROTOCOL" == "rest" ]]; then
    SMOKE=$(kubectl run smoke-$COUNTER --rm -i --restart=Never --image=curlimages/curl:latest -n "$NAMESPACE" -- curl -s "$ENDPOINT$REST_PATH" 2>&1 || echo "SMOKE_FAILED")
  elif [[ "$PROTOCOL" == "graphql" ]]; then
    SMOKE=$(kubectl run smoke-$COUNTER --rm -i --restart=Never --image=curlimages/curl:latest -n "$NAMESPACE" -- curl -s -X POST -H "Content-Type: application/json" -d "$GRAPHQL_QUERY" "$ENDPOINT" 2>&1 || echo "SMOKE_FAILED")
  else
    SMOKE="gRPC (skipped)"
  fi
  echo "Result: ${SMOKE:0:100}"

  # Run benchmark for each concurrency level
  for CONC in 1 10 50 100 200; do
    echo "--- Concurrency: $CONC ---"

    if [[ "$PROTOCOL" == "rest" ]]; then
      TARGET="$ENDPOINT$REST_PATH"
      JOB_NAME="bench-${IMPL}-${SCENARIO}-${CONC}"

      cat <<EOF | kubectl apply -f - -n "$NAMESPACE" 2>/dev/null
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
      - name: w
        image: williamyeh/wrk:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          wrk -t4 -c$CONC -d${WARMUP}s $TARGET > /dev/null 2>&1
          sleep 3
          wrk -t4 -c$CONC -d${DURATION}s --latency $TARGET
        resources:
          requests: { cpu: "1", memory: "256Mi" }
          limits:   { cpu: "2", memory: "512Mi" }
EOF

    elif [[ "$PROTOCOL" == "graphql" ]]; then
      JOB_NAME="bench-${IMPL}-${SCENARIO}-${CONC}"

      cat <<EOF | kubectl apply -f - -n "$NAMESPACE" 2>/dev/null
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
      - name: k
        image: grafana/k6:latest
        command: ["k6", "run", "--vus", "$CONC", "--duration", "${DURATION}s", "-"]
        stdin: |
          import http from 'k6/http';
          import { check } from 'k6';
          const payload = JSON.stringify($GRAPHQL_QUERY);
          const params = { headers: { 'Content-Type': 'application/json' } };
          export default function () {
            const res = http.post('$ENDPOINT', payload, params);
            check(res, { 'status is 200': (r) => r.status === 200 });
          }
        resources:
          requests: { cpu: "1", memory: "256Mi" }
          limits:   { cpu: "2", memory: "512Mi" }
EOF

    else
      # gRPC - use ghz
      JOB_NAME="bench-${IMPL}-${SCENARIO}-${CONC}"

      cat <<EOF | kubectl apply -f - -n "$NAMESPACE" 2>/dev/null
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
      - name: g
        image: ghcr.io/bojand/ghz:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          ghz --insecure --duration ${DURATION}s --connections 10 --concurrency $CONC --call $GRPC_CALL --format json $ENDPOINT
        resources:
          requests: { cpu: "1", memory: "256Mi" }
          limits:   { cpu: "2", memory: "512Mi" }
EOF
    fi

    # Wait for job
    kubectl wait --for=condition=complete "job/$JOB_NAME" -n "$NAMESPACE" --timeout=300s 2>/dev/null || true

    # Collect results
    kubectl logs "job/$JOB_NAME" -n "$NAMESPACE" > "$IMPL_DIR/c${CONC}.txt" 2>/dev/null || true

    # Cleanup
    kubectl delete job "$JOB_NAME" -n "$NAMESPACE" --ignore-not-found 2>/dev/null || true

    # Brief pause
    sleep 5
  done

  echo "Results saved to: $IMPL_DIR/"
done

echo ""
echo "========================================="
echo "  Benchmark Complete!"
echo "========================================="
echo "Results: $RESULTS_DIR"
echo ""
echo "Summary:"
ls -la "$RESULTS_DIR/"
