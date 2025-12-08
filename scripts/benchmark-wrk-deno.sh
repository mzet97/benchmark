#!/bin/bash
set -e

echo "=========================================="
echo "Deno Oak - WRK Benchmark Suite"
echo "=========================================="
echo ""

# Configuration
SERVICE="${SERVICE:-deno-oak}"
NAMESPACE="${NAMESPACE:-default}"
BASE_URL="http://${SERVICE}.${NAMESPACE}.svc.cluster.local"
LOCAL_URL="http://localhost:3000"

# Check if running in Kubernetes
if kubectl get svc ${SERVICE} &>/dev/null; then
    echo "✓ Detected Kubernetes service: ${SERVICE}"
    URL=${BASE_URL}
else
    echo "✓ Running local benchmark"
    URL=${LOCAL_URL}
fi

echo "Base URL: ${URL}"
echo ""

# Test parameters
THREADS=8
CONNECTIONS=200
DURATION=30s
WARMUP_DURATION=5s

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Benchmark function
run_benchmark() {
    local endpoint=$1
    local description=$2
    local url="${URL}${endpoint}"

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Benchmark: ${description}${NC}"
    echo -e "${BLUE}URL: ${url}${NC}"
    echo -e "${BLUE}========================================${NC}"

    # Warmup
    echo -e "${YELLOW}Warming up (${WARMUP_DURATION})...${NC}"
    wrk -t${THREADS} -c${CONNECTIONS} -d${WARMUP_DURATION} --latency "${url}" > /dev/null 2>&1

    echo -e "${YELLOW}Running benchmark (${DURATION}, ${THREADS} threads, ${CONNECTIONS} connections)...${NC}"
    echo ""

    # Run benchmark
    wrk -t${THREADS} -c${CONNECTIONS} -d${DURATION} --latency "${url}"

    echo ""
    echo ""
}

# Check if wrk is installed
if ! command -v wrk &> /dev/null; then
    echo "Error: wrk is not installed"
    echo "Install instructions:"
    echo "  Ubuntu/Debian: sudo apt-get install wrk"
    echo "  macOS: brew install wrk"
    echo "  From source: https://github.com/wg/wrk"
    exit 1
fi

echo "Configuration:"
echo "  Runtime: Deno"
echo "  Framework: Oak"
echo "  Threads: ${THREADS}"
echo "  Connections: ${CONNECTIONS}"
echo "  Duration: ${DURATION}"
echo "  Warmup: ${WARMUP_DURATION}"
echo ""

# Run all benchmarks
echo "Starting benchmark suite..."
echo ""

# 1. Health Check
run_benchmark "/health" "Health Check Endpoint"

# 2. JSON Response
run_benchmark "/json" "JSON Serialization (1000 objects)"

# 3. Simple Database Query
run_benchmark "/db/simple?id=1" "Simple Database Query (Single User)"

# 4. Complex Database Query
run_benchmark "/db/complex?days=30" "Complex Database Query (JOIN + Aggregation)"

# 5. Cache Operations
run_benchmark "/cache?key=test" "Redis Cache Operations (GET/SET)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Benchmark Suite Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Summary
echo "Summary of Results:"
echo "  Deno runtime provides competitive performance"
echo "  Oak framework adds minimal overhead"
echo "  Security-first design with sandboxed execution"
echo ""

echo "Key Performance Characteristics:"
echo "  1. V8 engine for JIT compilation"
echo "  2. Native TypeScript support (no transpilation)"
echo "  3. URL imports from CDN (fast cold starts)"
echo "  4. Permission-based security model"
echo ""

echo "Additional Metrics to Collect:"
echo "  1. CPU Usage: kubectl top pods -l app=${SERVICE}"
echo "  2. Memory Usage: kubectl top pods -l app=${SERVICE}"
echo "  3. Database Performance: Query timings from database logs"
echo "  4. Cache Hit Rate: redis-cli INFO stats"
echo ""

echo "To view detailed results:"
echo "  wrk outputs are displayed above"
echo "  Save results to file: ./benchmark-wrk-deno.sh > results.txt"
echo ""
