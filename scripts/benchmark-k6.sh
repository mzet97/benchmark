#!/bin/bash

# Benchmark script using k6
# Usage: ./benchmark-k6.sh [service_name] [base_url]

set -e

SERVICE_NAME=${1:-"csharp-minimalapi"}
BASE_URL=${2:-"http://csharp-minimalapi.benchmark.svc.cluster.local"}
VU_COUNT=${3:-"50"}
DURATION=${4:-"60s"}
RAMPUP=${5:-"10s"}

OUTPUT_DIR="results/k6/$(date +%Y%m%d_%H%M%S)_${SERVICE_NAME}"
mkdir -p "$OUTPUT_DIR"

echo "=================================="
echo "Benchmark: k6"
echo "Service: $SERVICE_NAME"
echo "Base URL: $BASE_URL"
echo "VUs: $VU_COUNT"
echo "Duration: $DURATION"
echo "Ramp-up: $RAMPUP"
echo "Output: $OUTPUT_DIR"
echo "=================================="
echo ""

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "Error: k6 is not installed"
    echo "Install from: https://k6.io/docs/getting-started/installation/"
    exit 1
fi

# Run k6 benchmark
k6 run \
    --vus "$VU_COUNT" \
    --duration "$DURATION" \
    --ramp-up "$RAMPUP" \
    --out json="$OUTPUT_DIR/results.json" \
    --summary-export="$OUTPUT_DIR/summary.json" \
    scripts/k6-benchmark.js

# Generate human-readable summary
cat > "$OUTPUT_DIR/summary.txt" <<EOF
K6 Benchmark Summary - $SERVICE_NAME
Generated: $(date)
VUs: $VU_COUNT
Duration: $DURATION
Ramp-up: $RAMPUP

Results:
See $OUTPUT_DIR/results.json for detailed metrics
See $OUTPUT_DIR/summary.json for summary

EOF

echo ""
echo "=================================="
echo "Benchmark completed!"
echo "Results directory: $OUTPUT_DIR"
echo "=================================="
echo ""
cat "$OUTPUT_DIR/summary.txt"

# Save metadata
cat > "$OUTPUT_DIR/metadata.json" <<EOF
{
  "service": "$SERVICE_NAME",
  "base_url": "$BASE_URL",
  "vus": $VU_COUNT,
  "duration": "$DURATION",
  "ramp_up": "$RAMPUP",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo ""
echo "Metadata saved to: $OUTPUT_DIR/metadata.json"
