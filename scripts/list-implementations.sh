#!/usr/bin/env bash
# list-implementations.sh
# Lists all implementations from config/implementations.yaml
#
# Usage:
#   ./scripts/list-implementations.sh
#   ./scripts/list-implementations.sh --protocol rest
#   ./scripts/list-implementations.sh --environment rust
#   ./scripts/list-implementations.sh --maturity stable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$ROOT_DIR/config/implementations.yaml"

if [ ! -f "$CONFIG" ]; then
  echo "ERROR: $CONFIG not found"
  exit 1
fi

# Parse filters
FILTER_PROTOCOL=""
FILTER_ENV=""
FILTER_MATURITY=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --protocol)    FILTER_PROTOCOL="$2"; shift 2 ;;
    --environment) FILTER_ENV="$2"; shift 2 ;;
    --maturity)    FILTER_MATURITY="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "================================================================="
echo "  Benchmark Implementations"
echo "================================================================="
echo ""
printf "%-40s %-10s %-10s %-15s\n" "ID" "PROTOCOL" "ENV" "MATURITY"
echo "-----------------------------------------------------------------"

# Simple YAML parser (works with the flat format in implementations.yaml)
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*-\ id:\ (.+)$ ]]; then
    id="${BASH_REMATCH[1]}"
    id="$(echo "$id" | xargs)"
  elif [[ "$line" =~ ^[[:space:]]*environment:\ (.+)$ ]]; then
    env="$(echo "${BASH_REMATCH[1]}" | xargs)"
  elif [[ "$line" =~ ^[[:space:]]*protocol:\ (.+)$ ]]; then
    protocol="$(echo "${BASH_REMATCH[1]}" | xargs)"
  elif [[ "$line" =~ ^[[:space:]]*maturity:\ (.+)$ ]]; then
    maturity="$(echo "${BASH_REMATCH[1]}" | xargs)"

    # Apply filters
    if [ -n "$FILTER_PROTOCOL" ] && [ "$protocol" != "$FILTER_PROTOCOL" ]; then
      continue
    fi
    if [ -n "$FILTER_ENV" ] && [ "$env" != "$FILTER_ENV" ]; then
      continue
    fi
    if [ -n "$FILTER_MATURITY" ] && [ "$maturity" != "$FILTER_MATURITY" ]; then
      continue
    fi

    printf "%-40s %-10s %-10s %-15s\n" "$id" "$protocol" "$env" "$maturity"
  fi
done < "$CONFIG"

echo ""
echo "Use --protocol, --environment, or --maturity to filter."
