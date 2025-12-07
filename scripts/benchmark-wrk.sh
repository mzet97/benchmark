#!/bin/bash

# Benchmark script using wrk
# Usage: ./benchmark-wrk.sh [service_name] [base_url]

set -e

SERVICE_NAME=${1:-"csharp-minimalapi"}
BASE_URL=${2:-"http://csharp-minimalapi.benchmark.svc.cluster.local"}
DURATION=${3:-"30s"}
THREADS=${4:-"8"}
CONNECTIONS=${5:-"200"}

OUTPUT_DIR="results/wrk/$(date +%Y%m%d_%H%M%S)_${SERVICE_NAME}"
mkdir -p "$OUTPUT_DIR"

echo "=================================="
echo "Benchmark: wrk"
echo "Service: $SERVICE_NAME"
echo "Base URL: $BASE_URL"
echo "Duration: $DURATION"
echo "Threads: $THREADS"
echo "Connections: $CONNECTIONS"
echo "Output: $OUTPUT_DIR"
echo "=================================="
echo ""

# Check if wrk is installed
if ! command -v wrk &> /dev/null; then
    echo "Error: wrk is not installed"
    echo "Install with: sudo apt-get install wrk"
    exit 1
fi

# Test each endpoint
endpoints=(
    "health"
    "json"
    "db/simple?id=1"
    "db/complex?days=30"
    "cache?key=test"
)

for endpoint in "${endpoints[@]}"; do
    echo "=========================================="
    echo "Benchmarking: /$endpoint"
    echo "=========================================="

    wrk_output="$OUTPUT_DIR/${endpoint//\//_}.txt"

    wrk \
        --threads "$THREADS" \
        --connections "$CONNECTIONS" \
        --duration "$DURATION" \
        --latency \
        "$BASE_URL/$endpoint" \
        > "$wrk_output" 2>&1

    echo "Results saved to: $wrk_output"
    echo ""
done

# Generate summary report
echo "=================================="
echo "Generating summary report..."
echo "=================================="

cat > "$OUTPUT_DIR/summary.txt" <<EOF
Benchmark Summary - $SERVICE_NAME
Generated: $(date)
Duration: $DURATION
Threads: $THREADS
Connections: $CONNECTIONS

Endpoints tested:
$(for endpoint in "${endpoints[@]}"; do echo "  - /$endpoint"; done)

Files:
$(ls -lh "$OUTPUT_DIR"/*.txt | awk '{print "  " $9 " (" $5 ")"}')

EOF

echo ""
echo "=================================="
echo "Benchmark completed!"
echo "Results directory: $OUTPUT_DIR"
echo "=================================="
echo ""
echo "Summary:"
cat "$OUTPUT_DIR/summary.txt"

# Save metadata
cat > "$OUTPUT_DIR/metadata.json" <<EOF
{
  "service": "$SERVICE_NAME",
  "base_url": "$BASE_URL",
  "duration": "$DURATION",
  "threads": $THREADS,
  "connections": $CONNECTIONS,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "endpoints": [$(for endpoint in "${endpoints[@]}"; do echo "\"$endpoint\""; done | paste -sd,)]
}
EOF

echo ""
echo "Metadata saved to: $OUTPUT_DIR/metadata.json"
