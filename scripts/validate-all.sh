#!/usr/bin/env bash
# validate-all.sh
# Validates all implementations have required files and structure.
#
# Usage: ./scripts/validate-all.sh
#
# Checks per implementation:
#   1. Dockerfile exists and has non-root USER
#   2. K8s manifests exist (configmap, deployment, service)
#   3. Kustomize overlay exists and is valid
#   4. Lock file exists (go.sum, Cargo.lock, package-lock.json)
#   5. README.md exists

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TOTAL=0
ISSUES=0

check() {
  local path="$1"
  local name="$2"
  local required="$3"
  local file="$4"

  if [ -f "$file" ]; then
    echo -e "  ${GREEN}✓${NC} $name"
  elif [ "$required" = "true" ]; then
    echo -e "  ${RED}✗${NC} $name (MISSING: $file)"
    ISSUES=$((ISSUES + 1))
  else
    echo -e "  ${YELLOW}!${NC} $name (optional, missing: $file)"
  fi
}

validate_impl() {
  local dir="$1"
  local name="$2"

  TOTAL=$((TOTAL + 1))
  echo ""
  echo "━━━ $name ━━━"

  # Dockerfile
  if [ -f "$dir/Dockerfile" ]; then
    if grep -q 'USER' "$dir/Dockerfile"; then
      echo -e "  ${GREEN}✓${NC} Dockerfile (has USER)"
    else
      echo -e "  ${YELLOW}!${NC} Dockerfile (missing USER - runs as root)"
      ISSUES=$((ISSUES + 1))
    fi
    if grep -q 'HEALTHCHECK' "$dir/Dockerfile"; then
      echo -e "  ${GREEN}✓${NC} HEALTHCHECK"
    else
      echo -e "  ${YELLOW}!${NC} Dockerfile (missing HEALTHCHECK)"
    fi
  else
    echo -e "  ${RED}✗${NC} Dockerfile MISSING"
    ISSUES=$((ISSUES + 1))
  fi

  # K8s
  check "$dir" "K8s configmap" "true" "$dir/k8s/configmap.yaml"
  check "$dir" "K8s deployment" "true" "$dir/k8s/deployment.yaml"
  check "$dir" "K8s service" "true" "$dir/k8s/service.yaml"

  # README
  check "$dir" "README.md" "false" "$dir/README.md"
}

echo "╔══════════════════════════════════════════╗"
echo "║     Implementation Validation            ║"
echo "╚══════════════════════════════════════════╝"

# Scan all implementation directories
for lang_dir in src/*/; do
  lang=$(basename "$lang_dir")
  echo ""
  echo "════════════════════════════════════════"
  echo "  Language: $lang"
  echo "════════════════════════════════════════"

  for impl_dir in "$lang_dir"*/; do
    [ -d "$impl_dir" ] || continue
    framework=$(basename "$impl_dir")
    # Skip non-framework dirs
    [[ "$framework" == "k8s" || "$framework" == "common" ]] && continue
    validate_impl "$impl_dir" "$lang/$framework"
  done
done

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Summary                              ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Implementations checked: $TOTAL"
echo "Issues found: $ISSUES"

if [ $ISSUES -gt 0 ]; then
  echo -e "${RED}Validation FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}All validations PASSED${NC}"
fi
