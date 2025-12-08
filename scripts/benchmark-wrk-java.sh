#!/bin/bash

# Benchmark script for Java Quarkus
# Usage: ./scripts/benchmark-wrk-java.sh [namespace]

set -e

NAMESPACE=${1:-"benchmark"}
SERVICE="java-quarkus"
BASE_URL="http://${SERVICE}.${NAMESPACE}.svc.cluster.local"

echo "=========================================="
echo "Benchmark - Java Quarkus (GraalVM Native)"
echo "=========================================="
echo "Service: $SERVICE"
echo "URL: $BASE_URL"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Verify service is available
print_info "Verifying service availability..."
if kubectl get svc $SERVICE -n $NAMESPACE &> /dev/null; then
    print_success "Service found"
else
    echo "❌ Service not found. Deploy first with: kubectl apply -f src/java/quarkus/k8s/"
    exit 1
fi

# Wait for pods to be ready
print_info "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=$SERVICE --timeout=60s -n $NAMESPACE || true

# Test each endpoint
echo ""
print_header "Running Benchmarks"

endpoints=(
    "health"
    "json"
    "db/simple?id=1"
    "db/complex?days=30"
    "cache?key=test-java-$(date +%s)"
)

for endpoint in "${endpoints[@]}"; do
    print_header "Testing: /$endpoint"
    
    # Run wrk benchmark
    wrk -t8 -c200 -d30s --latency "$BASE_URL/$endpoint" 2>&1 | tee "/tmp/benchmark-java-${endpoint//\//_}.log"
    
    echo ""
done

# Summary
print_header "Benchmark Complete"
print_success "Results saved in /tmp/benchmark-java-*.log"

# Generate summary report
echo ""
print_info "Generating summary report..."
{
    echo "# Java Quarkus (GraalVM Native) - Benchmark Report"
    echo "Generated: $(date)"
    echo ""
    echo "## Service Information"
    echo "- Service: $SERVICE"
    echo "- Namespace: $NAMESPACE"
    echo "- URL: $BASE_URL"
    echo ""
    echo "## Test Configuration"
    echo "- Threads: 8"
    echo "- Connections: 200"
    echo "- Duration: 30 seconds"
    echo ""
    echo "## Results"
    for endpoint in "${endpoints[@]}"; do
        echo ""
        echo "### Endpoint: /$endpoint"
        cat "/tmp/benchmark-java-${endpoint//\//_}.log"
    done
} > /tmp/benchmark-java-report.md

print_success "Report saved to: /tmp/benchmark-java-report.md"
print_info "View report: cat /tmp/benchmark-java-report.md"

# Cleanup
rm -f /tmp/benchmark-java-*.log

print_success "Benchmark completed!"
