# Makefile for the API Benchmark project.
#
# Every target here either runs or does not exist. The previous Makefile
# referenced 13 retired scripts (11 benchmark-wrk-*.sh plus deploy.sh and
# undeploy.sh) and every deploy-<lang> target pointed at src/*/k8s directories
# that Fase 4 removed. Both are gone now: deploy goes through overlays, and
# benchmarking goes through run-benchmark-suite.py. See docs/ACTION_PLAN.md,
# Fase 4 and Fase 8.1.

SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

PY := python3
SCRIPTS := scripts
OVERLAYS := deploy/k3s/overlays
BASE := deploy/k3s/base
PROTOCOLS := rest grpc graphql

# Implementation ID (e.g. rust-rest-actix-web). Required by the per-impl targets.
IMPL ?=
MODE ?= single-pod

# K3s node access for the runner. Override via env or args.
K3S_HOST ?= 192.168.1.51
K3S_USER ?= k8s1
NODE_PORT ?= 30080

.PHONY: help inventory \
        overlays overlays-check \
        parity parity-reference \
        build image deploy undeploy smoke \
        suite suite-rest suite-grpc suite-graphql \
        preflight status collect-metrics setup-database \
        clean

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\n"} \
	  /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# --------------------------------------------------------------------------
# Source-of-truth gates (Fase 3 + Fase 4). These must pass before any build.
# --------------------------------------------------------------------------

overlays: ## Regenerate Kustomize overlays from src/
	@$(PY) $(SCRIPTS)/generate-overlays.py

overlays-check: ## CI gate: fail if overlays are stale vs src/
	@$(PY) $(SCRIPTS)/generate-overlays.py --check

parity: ## Validate a running REST impl against the contract (needs URL=)
	@$(PY) $(SCRIPTS)/validate-parity.py $(if $(URL),--url $(URL),)

parity-reference: ## Print the canonical /json payload and its hash
	@$(PY) $(SCRIPTS)/validate-parity.py --reference --n 2

# --------------------------------------------------------------------------
# Inventory
# --------------------------------------------------------------------------

inventory: ## List all implementations derived from overlays
	@echo "Overlays by protocol:"
	@for p in $(PROTOCOLS); do \
	  n=$$(find $(OVERLAYS)/$$p -mindepth 1 -maxdepth 1 -type d | wc -l); \
	  printf "  %-10s %3d\n" "$$p" "$$n"; \
	done
	@n=$$(find $(OVERLAYS) -mindepth 2 -maxdepth 2 -type d | wc -l); \
	echo "  total       $$n"

# --------------------------------------------------------------------------
# Per-implementation lifecycle (IMPL=<env>-<proto>-<framework>)
# --------------------------------------------------------------------------

build image: ## Build the Docker image for IMPL=
	@$(PY) $(SCRIPTS)/build-image.sh $(IMPL)

deploy: ## Apply the overlay for IMPL= to the cluster
	@test -n "$(IMPL)" || { echo "ERROR: make deploy IMPL=<id>"; exit 2; }
	proto=$$(echo "$(IMPL)" | awk -F- '{print $$2}'); \
	dir="$(OVERLAYS)/$$proto/$(IMPL)"; \
	test -d "$$dir" || { echo "ERROR: overlay not found: $$dir"; exit 1; }; \
	echo "Applying $$dir"; \
	kubectl apply -k "$$dir"

undeploy: ## Remove IMPL= from the cluster
	@test -n "$(IMPL)" || { echo "ERROR: make undeploy IMPL=<id>"; exit 2; }
	@kubectl delete deployment,service,configmap -l app=$(IMPL) \
		-n benchmark --ignore-not-found --timeout=60s || true

smoke: ## Run the contract smoke test against a deployed IMPL=
	@test -n "$(IMPL)" || { echo "ERROR: make smoke IMPL=<id>"; exit 2; }
	@$(SCRIPTS)/smoke-test.sh $(IMPL)

# --------------------------------------------------------------------------
# Benchmark suite (Fase 5). Replaces the retired run_all_benchmarks.py.
# Generator runs on this workstation against the NodePort; the suite applies
# each overlay over SSH, gates on parity, then measures. See Fase 5.
# --------------------------------------------------------------------------

suite: ## Run the full REST benchmark suite
	@$(PY) $(SCRIPTS)/run-benchmark-suite.py --host $(K3S_HOST) --user $(K3S_USER)

suite-rest: ## REST only
	@$(PY) $(SCRIPTS)/run-benchmark-suite.py --host $(K3S_HOST) --user $(K3S_USER) --protocol rest

suite-grpc: ## gRPC only (runner covers REST today; gRPC pending Fase 6)
	@echo "NOTE: gRPC measurement support is part of Fase 6 (not yet implemented)."
	@exit 1

suite-graphql: ## GraphQL only (runner covers REST today; GraphQL pending Fase 6)
	@echo "NOTE: GraphQL measurement support is part of Fase 6 (not yet implemented)."
	@exit 1

# --------------------------------------------------------------------------
# Cluster & infra helpers
# --------------------------------------------------------------------------

preflight: ## Run the K3s preflight job (checks PostgreSQL + Redis reachability)
	@kubectl apply -f deploy/k3s/preflight/job.yaml -n benchmark
	@kubectl wait --for=condition=complete job/benchmark-preflight -n benchmark --timeout=120s || true
	@kubectl logs job/benchmark-preflight -n benchmark

status: ## Show Kubernetes status for the benchmark namespace
	@echo "=== Pods ==="
	@kubectl get pods -n benchmark 2>/dev/null || echo "(cluster not reachable)"
	@echo "=== Services ==="
	@kubectl get svc -n benchmark 2>/dev/null || true
	@echo "=== ConfigMaps ==="
	@kubectl get cm -n benchmark 2>/dev/null || true

collect-metrics: ## Collect system and database metrics from the node
	@$(SCRIPTS)/collect-metrics.sh

setup-database: ## Apply schema and seed data to PostgreSQL
	@$(SCRIPTS)/setup-database.sh

clean: ## Remove local results (does not touch the cluster)
	@rm -rf results
	@echo "Removed results/"
