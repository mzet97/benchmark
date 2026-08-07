#!/usr/bin/env bash
# Build all benchmark implementation Docker images and import into k3s containerd.
# Run on the k3s node (.51). Requires docker + k3s.
#
# Usage: bash scripts/build-all-images.sh [protocol]
#   protocol: rest (default), grpc, graphql, or all
set -euo pipefail

REPO_DIR="${HOME}/benchmark"
OVERLAYS="${REPO_DIR}/deploy/k3s/overlays"
PROTO="${1:-rest}"
LOGDIR="/tmp/build-logs"
mkdir -p "$LOGDIR"

# Import helper: saves docker image, pipes to k3s containerd via privileged container
import_to_k3s() {
  local img="$1"
  docker save "$img" -o /tmp/_import.tar 2>/dev/null
  docker run --rm --privileged --pid=host \
    -v /run/k3s/containerd:/run/k3s/containerd \
    -v /tmp:/tmp \
    -v /usr/local/bin/k3s:/usr/local/bin/k3s:ro \
    alpine \
    /usr/local/bin/k3s ctr images import /tmp/_import.tar 2>/dev/null
  rm -f /tmp/_import.tar
}

# Discover implementations from overlays
discover() {
  local proto="$1"
  if [ "$proto" = "all" ]; then
    ls -1 "$OVERLAYS"/*/
  else
    ls -1 "$OVERLAYS/$proto/"
  fi
}

# Find the Dockerfile source dir for an implementation
find_src_dir() {
  local impl="$1"
  # Parse: <env>-<proto>-<framework>
  local env proto fw
  # Read from implementations.yaml-style path
  local path
  path=$(grep -A5 "id: ${impl}$" "${REPO_DIR}/config/implementations.yaml" 2>/dev/null \
    | grep 'path:' | head -1 | awk '{print $2}' | tr -d ' ')
  if [ -n "$path" ] && [ -d "${REPO_DIR}/${path}" ]; then
    echo "${REPO_DIR}/${path}"
    return
  fi
  # Fallback: derive from overlay name
  proto=$(echo "$impl" | awk -F- '{print $2}')
  env=$(echo "$impl" | awk -F- '{print $1}')
  fw=$(echo "$impl" | sed "s/^${env}-${proto}-//")
  if [ "$proto" = "rest" ]; then
    echo "${REPO_DIR}/src/${env}/${fw}"
  else
    echo "${REPO_DIR}/src/${env}/${proto}/${fw}"
  fi
}

main() {
  local proto="$1"
  local impls
  impls=$(discover "$proto")
  local total built failed skipped
  total=0; built=0; failed=0; skipped=0

  for impl_dir in $impls; do
    impl=$(basename "$impl_dir")
    total=$((total + 1))
    local src_dir
    src_dir=$(find_src_dir "$impl")
    local dockerfile="${src_dir}/Dockerfile"
    local img="benchmark/${impl}:latest"

    if [ ! -f "$dockerfile" ]; then
      echo "[$total] $impl: SKIP (no Dockerfile at $src_dir)"
      skipped=$((skipped + 1))
      continue
    fi

    local logfile="${LOGDIR}/${impl}.log"

    echo -n "[$total] $impl: building... "
    if docker build -t "$img" "$src_dir" > "$logfile" 2>&1; then
      echo -n "import... "
      if import_to_k3s "$img" 2>>"$logfile"; then
        echo "OK"
        built=$((built + 1))
      else
        echo "IMPORT FAILED"
        failed=$((failed + 1))
      fi
    else
      echo "BUILD FAILED (see $logfile)"
      failed=$((failed + 1))
    fi
  done

  echo ""
  echo "========================================"
  echo "  Summary: ${built}/${total} built, ${failed} failed, ${skipped} skipped"
  echo "  Logs: ${LOGDIR}/<impl>.log"
  echo "========================================"
}

main "$PROTO"
