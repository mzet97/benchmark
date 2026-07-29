#!/usr/bin/env bash
# smoke-test-local.sh
# Local Docker-based smoke tests for benchmark implementations.
#
# Usage:
#   ./scripts/smoke-test-local.sh <language> <framework>
#   ./scripts/smoke-test-local.sh python fastapi
#   ./scripts/smoke-test-local.sh all
#
# Requirements:
#   - Docker running
#   - PostgreSQL running on localhost:5432 (or set DATABASE_URL)
#   - Redis running on localhost:6379 (or set REDIS_URL)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
PG_PASSWORD="${PG_PASSWORD:-Admin@123}"
REDIS_URL="${REDIS_URL:-redis://localhost:6379}"
STARTUP_TIMEOUT="${STARTUP_TIMEOUT:-60}"

# ─────────────────────────────────────────────
# Implementation registry: name -> path:port:health
# ─────────────────────────────────────────────
declare -A IMPLS=(
  # Python
  ["python:fastapi"]="src/python/fastapi:8000:/health"
  ["python:django"]="src/python/django:8000:/health/"
  ["python:flask"]="src/python/flask:5000:/health"
  # Go
  ["go:fiber"]="src/go/fiber:8080:/health"
  # Rust
  ["rust:actix-web"]="src/rust/actix-web:8080:/health"
  # Node.js
  ["nodejs:fastify"]="src/nodejs/fastify:3000:/health"
  # Bun
  ["bun:elysia"]="src/bun/elysia:3000:/health"
  # Deno
  ["deno:oak"]="src/deno/oak:8000:/health"
  # Java
  ["java:spring"]="src/java/spring:8080:/health"
  # Kotlin
  ["kotlin:ktor"]="src/kotlin/ktor:8080:/health"
  # C#
  ["csharp:MinimalApi"]="src/csharp/MinimalApi:8080:/health"
)

# Stats
TOTAL=0
PASSED=0
FAILED=0
RESULTS=()

# ─────────────────────────────────────────────
# Functions
# ─────────────────────────────────────────────
log_info() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

test_impl() {
  local key="$1"
  local IFS=':'
  read -r lang framework <<< "$key"
  IFS=':'
  read -r path port health <<< "${IMPLS[$key]}"
  local image="benchmark/${lang}-${framework}:smoke"
  local container="smoke-${lang}-${framework}"

  TOTAL=$((TOTAL + 1))
  echo ""
  echo -e "${CYAN}━━━ $lang/$framework (port $port) ━━━${NC}"

  # Build
  printf "  Building... "
  if ! docker build -t "$image" "$path" -q > /dev/null 2>&1; then
    echo -e "${RED}BUILD FAILED${NC}"
    FAILED=$((FAILED + 1))
    RESULTS+=("❌ $key: BUILD FAILED")
    return 1
  fi
  echo -e "${GREEN}OK${NC}"

  # Run
  docker rm -f "$container" 2>/dev/null || true
  printf "  Starting... "
  docker run -d \
    --name "$container" \
    -p "$port:$port" \
    -e DATABASE_URL="postgresql://benchmark:${PG_PASSWORD}@host.docker.internal:5432/benchmark" \
    -e REDIS_URL="$REDIS_URL" \
    -e PORT="$port" \
    "$image" > /dev/null 2>&1

  # Wait for health
  local start_time=$(date +%s)
  local healthy=false

  while [ $(($(date +%s) - start_time)) -lt $STARTUP_TIMEOUT ]; do
    if curl -sf "http://localhost:$port$health" > /dev/null 2>&1; then
      healthy=true
      break
    fi
    sleep 2
  done

  if [ "$healthy" = true ]; then
    local elapsed=$(($(date +%s) - start_time))
    echo -e "${GREEN}Healthy (${elapsed}s)${NC}"

    # Test endpoints
    for ep in "/api/json" "/api/users?limit=1"; do
      STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:$port$ep" 2>/dev/null || echo "000")
      if [ "$STATUS" = "200" ]; then
        echo -e "  ${GREEN}✓${NC} GET $ep -> $STATUS"
      else
        echo -e "  ${YELLOW}!${NC} GET $ep -> $STATUS"
      fi
    done

    PASSED=$((PASSED + 1))
    RESULTS+=("✅ $key: PASSED (${elapsed}s)")
  else
    echo -e "${RED}HEALTH CHECK FAILED${NC}"
    docker logs "$container" 2>&1 | tail -5
    FAILED=$((FAILED + 1))
    RESULTS+=("❌ $key: HEALTH CHECK FAILED")
  fi

  # Cleanup
  docker rm -f "$container" > /dev/null 2>&1 || true
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
LANGUAGE="${1:-all}"
FRAMEWORK="${2:-}"

echo "╔══════════════════════════════════════════╗"
echo "║     Benchmark Smoke Tests (Local)        ║"
echo "╚══════════════════════════════════════════╝"

if [ "$LANGUAGE" = "all" ]; then
  for key in $(echo "${!IMPLS[@]}" | tr ' ' '\n' | sort); do
    test_impl "$key" || true
  done
elif [ -n "$FRAMEWORK" ]; then
  key="${LANGUAGE}:${FRAMEWORK}"
  if [ -n "${IMPLS[$key]+x}" ]; then
    test_impl "$key" || true
  else
    log_error "Unknown: $key"
    echo "Available: $(echo "${!IMPLS[@]}" | tr ' ' '\n' | sort | tr '\n' ' ')"
    exit 1
  fi
else
  for key in $(echo "${!IMPLS[@]}" | tr ' ' '\n' | sort | grep "^${LANGUAGE}:"); do
    test_impl "$key" || true
  done
fi

# Summary
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Results                              ║"
echo "╚══════════════════════════════════════════╝"
for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo ""
echo "Total: $TOTAL | Passed: $PASSED | Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
  exit 1
fi
