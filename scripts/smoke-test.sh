#!/usr/bin/env bash
# smoke-test.sh
# Validates a deployed implementation against the benchmark contract.
#
# Usage:
#   ./scripts/smoke-test.sh <implementation-id>
#   ./scripts/smoke-test.sh rust-rest-actix-web
#
# Requirements:
#   - Implementation must be deployed and ready
#   - kubectl must be configured

set -euo pipefail

IMPL_ID="${1:?Usage: $0 <implementation-id>}"
NAMESPACE="benchmark"
PASSED=0
FAILED=0
TOTAL=0

echo "========================================="
echo "  Smoke Test: $IMPL_ID"
echo "========================================="

# Get service ClusterIP
SVC_IP=$(kubectl get svc "$IMPL_ID" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
SVC_PORT=$(kubectl get svc "$IMPL_ID" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)

if [ -z "$SVC_IP" ]; then
  echo "ERROR: Service $IMPL_ID not found"
  exit 1
fi

BASE_URL="http://$SVC_IP:$SVC_PORT"
echo "Target: $BASE_URL"
echo ""

# Test function
test_endpoint() {
  local name="$1"
  local method="$2"
  local path="$3"
  local expected_status="$4"
  local validation="$5"

  TOTAL=$((TOTAL + 1))
  printf "  %-30s " "$name"

  RESPONSE=$(kubectl exec -n "$NAMESPACE" deploy/"$IMPL_ID" -c app -- \
    curl -s -o /tmp/response.json -w "%{http_code}" \
    -X "$method" "$BASE_URL$path" 2>/dev/null || echo "000")

  BODY=$(kubectl exec -n "$NAMESPACE" deploy/"$IMPL_ID" -c app -- \
    cat /tmp/response.json 2>/dev/null || echo "{}")

  if [ "$RESPONSE" != "$expected_status" ]; then
    echo "FAIL (HTTP $RESPONSE, expected $expected_status)"
    FAILED=$((FAILED + 1))
    return
  fi

  if [ -n "$validation" ]; then
    if echo "$BODY" | grep -q "$validation"; then
      echo "PASS"
      PASSED=$((PASSED + 1))
    else
      echo "FAIL (validation: '$validation' not found)"
      FAILED=$((FAILED + 1))
    fi
  else
    echo "PASS"
    PASSED=$((PASSED + 1))
  fi
}

echo "--- Endpoint Tests ---"

# Health
test_endpoint "GET /health" GET "/health" "200" "status"
test_endpoint "GET /healthz" GET "/healthz" "200" "ok"
test_endpoint "GET /readyz" GET "/readyz" "200" "ready"

# JSON serialization
test_endpoint "GET /json" GET "/json" "200" "items"

# Database
test_endpoint "GET /db/simple?id=1" GET "/db/simple?id=1" "200" "id"
test_endpoint "GET /db/simple (no id)" GET "/db/simple" "400" "required"
test_endpoint "GET /db/complex?days=30" GET "/db/complex?days=30" "200" "data"

# Cache
test_endpoint "GET /cache?key=test" GET "/cache?key=test" "200" "key"
test_endpoint "GET /cache (no key)" GET "/cache" "400" "required"

echo ""
echo "========================================="
echo "  Results: $PASSED/$TOTAL passed, $FAILED failed"
echo "========================================="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
