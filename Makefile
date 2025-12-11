# Makefile for API Benchmark Project - 11 Language Implementations

.PHONY: help setup-database \
	build-csharp test-csharp deploy-csharp benchmark-csharp undeploy-csharp \
	build-rust test-rust deploy-rust benchmark-rust undeploy-rust \
	build-java test-java deploy-java benchmark-java undeploy-java \
	build-go test-go deploy-go benchmark-go undeploy-go \
	build-kotlin test-kotlin deploy-kotlin benchmark-kotlin undeploy-kotlin \
	build-nodejs test-nodejs deploy-nodejs benchmark-nodejs undeploy-nodejs \
	build-python test-python deploy-python benchmark-python undeploy-python \
	build-bun test-bun deploy-bun benchmark-bun undeploy-bun \
	build-deno test-deno deploy-deno benchmark-deno undeploy-deno \
	build-dart test-dart deploy-dart benchmark-dart undeploy-dart \
	build-graalvm test-graalvm deploy-graalvm benchmark-graalvm undeploy-graalvm \
	build-all deploy-all benchmark-all clean-all collect-metrics status \
	docker-build-all docker-push-all

# Default target
help:
	@echo "=========================================="
	@echo "  API Benchmark - 11 Language Implementations"
	@echo "=========================================="
	@echo ""
	@echo "Database Setup:"
	@echo "  setup-database        - Setup PostgreSQL database with schema and seed data"
	@echo ""
	@echo "Individual Language Targets:"
	@echo "  [csharp]  build|test|deploy|benchmark|undeploy"
	@echo "  [rust]    build|test|deploy|benchmark|undeploy"
	@echo "  [java]    build|test|deploy|benchmark|undeploy"
	@echo "  [go]      build|test|deploy|benchmark|undeploy"
	@echo "  [kotlin]  build|test|deploy|benchmark|undeploy"
	@echo "  [nodejs]  build|test|deploy|benchmark|undeploy"
	@echo "  [python]  build|test|deploy|benchmark|undeploy"
	@echo "  [bun]     build|test|deploy|benchmark|undeploy"
	@echo "  [deno]    build|test|deploy|benchmark|undeploy"
	@echo "  [dart]    build|test|deploy|benchmark|undeploy"
	@echo "  [graalvm] build|test|deploy|benchmark|undeploy"
	@echo ""
	@echo "Bulk Operations:"
	@echo "  build-all             - Build all 11 implementations"
	@echo "  deploy-all            - Deploy all to Kubernetes"
	@echo "  benchmark-all         - Run all benchmarks (long-running)"
	@echo "  undeploy-all          - Remove all from Kubernetes"
	@echo "  clean-all             - Clean all builds and results"
	@echo ""
	@echo "Docker Operations:"
	@echo "  docker-build-all      - Build all Docker images"
	@echo "  docker-push-all       - Push all Docker images"
	@echo ""
	@echo "Utilities:"
	@echo "  status                - Show Kubernetes status"
	@echo "  collect-metrics       - Collect system and database metrics"
	@echo ""
	@echo "=========================================="

# Database setup
setup-database:
	@echo "Setting up database..."
	@chmod +x scripts/setup-database.sh
	@./scripts/setup-database.sh

# ================================
# C# (.NET 9) - Minimal API
# ================================
build-csharp:
	@echo "Building C# (.NET 9) Minimal API..."
	@cd src/csharp/MinimalApi && \
		./build.sh local

test-csharp:
	@echo "Testing C# application..."
	@cd src/csharp/MinimalApi && \
		DATABASE_URL="Host=spsql.home.arpa;Port=5432;Database=benchmark_api;Username=app;Password=Admin@123;Maximum Pool Size=25;Connection Timeout=30;" \
		REDIS_CONNECTIONSTRING="redis.home.arpa:30379,password=Admin@123,defaultDatabase=0,ssl=false" \
		dotnet run --urls "http://localhost:8080"

deploy-csharp:
	@echo "Deploying C# to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/csharp/MinimalApi/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/csharp/MinimalApi/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/csharp/MinimalApi/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=csharp-minimalapi -n benchmark
	@echo "Waiting for pods to be ready..."
	@kubectl wait --for=condition=ready pod -l app=csharp-minimalapi -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-csharp: deploy-csharp
	@echo "Running benchmarks for C#..."
	@mkdir -p results/wrk results/k6
	@chmod +x scripts/benchmark-wrk-csharp.sh
	@sleep 10
	@./scripts/benchmark-wrk-csharp.sh

undeploy-csharp:
	@echo "Removing C# from Kubernetes..."
	@kubectl delete -f src/csharp/MinimalApi/k8s/service.yaml -n benchmark || true
	@kubectl delete -f src/csharp/MinimalApi/k8s/deployment.yaml -n benchmark || true
	@kubectl delete -f src/csharp/MinimalApi/k8s/configmap.yaml -n benchmark || true
	@kubectl delete pods -l app=csharp-minimalapi -n benchmark --force || true

# ================================
# Rust - Actix Web
# ================================
build-rust:
	@echo "Building Rust (Actix Web)..."
	@cd src/rust/actix-web && ./build.sh local

test-rust:
	@echo "Testing Rust application..."
	@cd src/rust/actix-web && ./run.sh

deploy-rust:
	@echo "Deploying Rust to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/rust/actix-web/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/rust/actix-web/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/rust/actix-web/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=rust-actix-web -n benchmark
	@kubectl wait --for=condition=ready pod -l app=rust-actix-web -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-rust: deploy-rust
	@echo "Running benchmarks for Rust..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-rust.sh
	@sleep 10
	@./scripts/benchmark-wrk-rust.sh

undeploy-rust:
	@echo "Removing Rust from Kubernetes..."
	@kubectl delete -f src/rust/actix-web/k8s/ -n benchmark || true

# ================================
# Java - Quarkus + Native
# ================================
build-java:
	@echo "Building Java (Quarkus)..."
	@cd src/java/quarkus && ./build.sh local

test-java:
	@echo "Testing Java application..."
	@cd src/java/quarkus && ./run.sh

deploy-java:
	@echo "Deploying Java to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/java/quarkus/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/java/quarkus/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/java/quarkus/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=java-quarkus -n benchmark
	@kubectl wait --for=condition=ready pod -l app=java-quarkus -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-java: deploy-java
	@echo "Running benchmarks for Java..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-java.sh
	@sleep 10
	@./scripts/benchmark-wrk-java.sh

undeploy-java:
	@echo "Removing Java from Kubernetes..."
	@kubectl delete -f src/java/quarkus/k8s/ -n benchmark || true

# ================================
# Go - Fiber
# ================================
build-go:
	@echo "Building Go (Fiber)..."
	@cd src/go/fiber && ./build.sh local

test-go:
	@echo "Testing Go application..."
	@cd src/go/fiber && ./run.sh

deploy-go:
	@echo "Deploying Go to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/go/fiber/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/go/fiber/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/go/fiber/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=go-fiber -n benchmark
	@kubectl wait --for=condition=ready pod -l app=go-fiber -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-go: deploy-go
	@echo "Running benchmarks for Go..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-go.sh
	@sleep 10
	@./scripts/benchmark-wrk-go.sh

undeploy-go:
	@echo "Removing Go from Kubernetes..."
	@kubectl delete -f src/go/fiber/k8s/ -n benchmark || true

# ================================
# Kotlin - Ktor
# ================================
build-kotlin:
	@echo "Building Kotlin (Ktor)..."
	@cd src/kotlin/ktor && ./build.sh local

test-kotlin:
	@echo "Testing Kotlin application..."
	@cd src/kotlin/ktor && ./run.sh

deploy-kotlin:
	@echo "Deploying Kotlin to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/kotlin/ktor/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/kotlin/ktor/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/kotlin/ktor/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=kotlin-ktor -n benchmark
	@kubectl wait --for=condition=ready pod -l app=kotlin-ktor -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-kotlin: deploy-kotlin
	@echo "Running benchmarks for Kotlin..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-kotlin.sh
	@sleep 10
	@./scripts/benchmark-wrk-kotlin.sh

undeploy-kotlin:
	@echo "Removing Kotlin from Kubernetes..."
	@kubectl delete -f src/kotlin/ktor/k8s/ -n benchmark || true

# ================================
# Node.js - Fastify
# ================================
build-nodejs:
	@echo "Building Node.js (Fastify)..."
	@cd src/nodejs/fastify && ./build.sh local

test-nodejs:
	@echo "Testing Node.js application..."
	@cd src/nodejs/fastify && ./run.sh

deploy-nodejs:
	@echo "Deploying Node.js to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/nodejs/fastify/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/nodejs/fastify/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/nodejs/fastify/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=nodejs-fastify -n benchmark
	@kubectl wait --for=condition=ready pod -l app=nodejs-fastify -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-nodejs: deploy-nodejs
	@echo "Running benchmarks for Node.js..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-nodejs.sh
	@sleep 10
	@./scripts/benchmark-wrk-nodejs.sh

undeploy-nodejs:
	@echo "Removing Node.js from Kubernetes..."
	@kubectl delete -f src/nodejs/fastify/k8s/ -n benchmark || true

# ================================
# Python - FastAPI
# ================================
build-python:
	@echo "Building Python (FastAPI)..."
	@cd src/python/fastapi && ./build.sh local

test-python:
	@echo "Testing Python application..."
	@cd src/python/fastapi && ./run.sh

deploy-python:
	@echo "Deploying Python to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/python/fastapi/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/python/fastapi/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/python/fastapi/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=python-fastapi -n benchmark
	@kubectl wait --for=condition=ready pod -l app=python-fastapi -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-python: deploy-python
	@echo "Running benchmarks for Python..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-python.sh
	@sleep 10
	@./scripts/benchmark-wrk-python.sh

undeploy-python:
	@echo "Removing Python from Kubernetes..."
	@kubectl delete -f src/python/fastapi/k8s/ -n benchmark || true

# ================================
# Bun - Elysia
# ================================
build-bun:
	@echo "Building Bun (Elysia)..."
	@cd src/bun/elysia && ./build.sh local

test-bun:
	@echo "Testing Bun application..."
	@cd src/bun/elysia && ./run.sh

deploy-bun:
	@echo "Deploying Bun to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/bun/elysia/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/bun/elysia/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/bun/elysia/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=bun-elysia -n benchmark
	@kubectl wait --for=condition=ready pod -l app=bun-elysia -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-bun: deploy-bun
	@echo "Running benchmarks for Bun..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-bun.sh
	@sleep 10
	@./scripts/benchmark-wrk-bun.sh

undeploy-bun:
	@echo "Removing Bun from Kubernetes..."
	@kubectl delete -f src/bun/elysia/k8s/ -n benchmark || true

# ================================
# Deno - Oak
# ================================
build-deno:
	@echo "Building Deno (Oak)..."
	@cd src/deno/oak && ./build.sh local

test-deno:
	@echo "Testing Deno application..."
	@cd src/deno/oak && ./run.sh

deploy-deno:
	@echo "Deploying Deno to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/deno/oak/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/deno/oak/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/deno/oak/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=deno-oak -n benchmark
	@kubectl wait --for=condition=ready pod -l app=deno-oak -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-deno: deploy-deno
	@echo "Running benchmarks for Deno..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-deno.sh
	@sleep 10
	@./scripts/benchmark-wrk-deno.sh

undeploy-deno:
	@echo "Removing Deno from Kubernetes..."
	@kubectl delete -f src/deno/oak/k8s/ -n benchmark || true

# ================================
# Dart - Vaden
# ================================
build-dart:
	@echo "Building Dart (Vaden)..."
	@cd src/dart/vaden && ./build.sh local

test-dart:
	@echo "Testing Dart application..."
	@cd src/dart/vaden && ./run.sh

deploy-dart:
	@echo "Deploying Dart to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/dart/vaden/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/dart/vaden/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/dart/vaden/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=dart-vaden -n benchmark
	@kubectl wait --for=condition=ready pod -l app=dart-vaden -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-dart: deploy-dart
	@echo "Running benchmarks for Dart..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-dart.sh
	@sleep 10
	@./scripts/benchmark-wrk-dart.sh

undeploy-dart:
	@echo "Removing Dart from Kubernetes..."
	@kubectl delete -f src/dart/vaden/k8s/ -n benchmark || true

# ================================
# GraalVM - Vert.x
# ================================
build-graalvm:
	@echo "Building GraalVM (Vert.x)..."
	@cd src/graalvm/vertx && ./build.sh local

test-graalvm:
	@echo "Testing GraalVM application..."
	@cd src/graalvm/vertx && ./run.sh

deploy-graalvm:
	@echo "Deploying GraalVM to Kubernetes..."
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@kubectl apply -f src/graalvm/vertx/k8s/configmap.yaml -n benchmark
	@kubectl apply -f src/graalvm/vertx/k8s/deployment.yaml -n benchmark
	@kubectl apply -f src/graalvm/vertx/k8s/service.yaml -n benchmark
	@sleep 5
	@kubectl get pods -l app=graalvm-vertx -n benchmark
	@kubectl wait --for=condition=ready pod -l app=graalvm-vertx -n benchmark --timeout=120s || echo "Pods may still be starting"

benchmark-graalvm: deploy-graalvm
	@echo "Running benchmarks for GraalVM..."
	@mkdir -p results/wrk
	@chmod +x scripts/benchmark-wrk-graalvm.sh
	@sleep 10
	@./scripts/benchmark-wrk-graalvm.sh

undeploy-graalvm:
	@echo "Removing GraalVM from Kubernetes..."
	@kubectl delete -f src/graalvm/vertx/k8s/ -n benchmark || true

# ================================
# Bulk Operations
# ================================
build-all:
	@echo "=========================================="
	@echo "Building All 11 Implementations"
	@echo "=========================================="
	@$(MAKE) build-csharp
	@$(MAKE) build-rust
	@$(MAKE) build-java
	@$(MAKE) build-go
	@$(MAKE) build-kotlin
	@$(MAKE) build-nodejs
	@$(MAKE) build-python
	@$(MAKE) build-bun
	@$(MAKE) build-deno
	@$(MAKE) build-dart
	@$(MAKE) build-graalvm
	@echo "✅ All builds complete!"

deploy-all:
	@echo "=========================================="
	@echo "Deploying All 11 Implementations"
	@echo "=========================================="
	@kubectl apply -f kubernetes/secrets.yaml -n benchmark || true
	@$(MAKE) deploy-csharp
	@$(MAKE) deploy-rust
	@$(MAKE) deploy-java
	@$(MAKE) deploy-go
	@$(MAKE) deploy-kotlin
	@$(MAKE) deploy-nodejs
	@$(MAKE) deploy-python
	@$(MAKE) deploy-bun
	@$(MAKE) deploy-deno
	@$(MAKE) deploy-dart
	@$(MAKE) deploy-graalvm
	@echo "✅ All deployments complete!"
	@echo "Run 'make status' to see deployment status"

benchmark-all:
	@echo "=========================================="
	@echo "Running All Benchmarks (This will take hours!)"
	@echo "=========================================="
	@echo "⚠️  This is a long-running operation"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(MAKE) benchmark-csharp; \
		$(MAKE) benchmark-rust; \
		$(MAKE) benchmark-java; \
		$(MAKE) benchmark-go; \
		$(MAKE) benchmark-kotlin; \
		$(MAKE) benchmark-nodejs; \
		$(MAKE) benchmark-python; \
		$(MAKE) benchmark-bun; \
		$(MAKE) benchmark-deno; \
		$(MAKE) benchmark-dart; \
		$(MAKE) benchmark-graalvm; \
		echo "✅ All benchmarks complete!"; \
	else \
		echo "Benchmark cancelled"; \
	fi

undeploy-all:
	@echo "Removing all implementations from Kubernetes..."
	@$(MAKE) undeploy-csharp
	@$(MAKE) undeploy-rust
	@$(MAKE) undeploy-java
	@$(MAKE) undeploy-go
	@$(MAKE) undeploy-kotlin
	@$(MAKE) undeploy-nodejs
	@$(MAKE) undeploy-python
	@$(MAKE) undeploy-bun
	@$(MAKE) undeploy-deno
	@$(MAKE) undeploy-dart
	@$(MAKE) undeploy-graalvm
	@echo "✅ All undeploys complete!"

clean-all:
	@echo "Cleaning all builds and results..."
	@cd src/csharp/MinimalApi && ./build.sh clean || true
	@cd src/rust/actix-web && ./build.sh clean || true
	@cd src/java/quarkus && ./build.sh clean || true
	@cd src/go/fiber && ./build.sh clean || true
	@cd src/kotlin/ktor && ./build.sh clean || true
	@cd src/nodejs/fastify && ./build.sh clean || true
	@cd src/python/fastapi && ./build.sh clean || true
	@cd src/bun/elysia && ./build.sh clean || true
	@cd src/deno/oak && ./build.sh clean || true
	@cd src/dart/vaden && ./build.sh clean || true
	@cd src/graalvm/vertx && ./build.sh clean || true
	@rm -rf results
	@kubectl delete -f kubernetes/secrets.yaml -n benchmark || true
	@echo "✅ Clean complete"

# ================================
# Docker Operations
# ================================
docker-build-all:
	@echo "Building all Docker images..."
	@cd src/csharp/MinimalApi && ./build.sh docker
	@cd src/rust/actix-web && ./build.sh docker
	@cd src/java/quarkus && ./build.sh docker
	@cd src/go/fiber && ./build.sh docker
	@cd src/kotlin/ktor && ./build.sh docker
	@cd src/nodejs/fastify && ./build.sh docker
	@cd src/python/fastapi && ./build.sh docker
	@cd src/bun/elysia && ./build.sh docker
	@cd src/deno/oak && ./build.sh docker
	@cd src/dart/vaden && ./build.sh docker
	@cd src/graalvm/vertx && ./build.sh docker
	@echo "✅ All Docker images built!"

docker-push-all:
	@echo "Pushing all Docker images..."
	@cd src/csharp/MinimalApi && ./build.sh docker-push
	@cd src/rust/actix-web && ./build.sh docker-push
	@cd src/java/quarkus && ./build.sh docker-push
	@cd src/go/fiber && ./build.sh docker-push
	@cd src/kotlin/ktor && ./build.sh docker-push
	@cd src/nodejs/fastify && ./build.sh docker-push
	@cd src/python/fastapi && ./build.sh docker-push
	@cd src/bun/elysia && ./build.sh docker-push
	@cd src/deno/oak && ./build.sh docker-push
	@cd src/dart/vaden && ./build.sh docker-push
	@cd src/graalvm/vertx && ./build.sh docker-push
	@echo "✅ All Docker images pushed!"

# ================================
# Utilities
# ================================
collect-metrics:
	@echo "Collecting system and database metrics..."
	@chmod +x scripts/collect-metrics.sh
	@./scripts/collect-metrics.sh

status:
	@echo "=========================================="
	@echo "  Kubernetes Status - All Implementations"
	@echo "=========================================="
	@echo ""
	@echo "Pods:"
	@kubectl get pods -n benchmark 2>/dev/null || echo "No pods found or cluster not accessible"
	@echo ""
	@echo "Services:"
	@kubectl get svc -n benchmark 2>/dev/null || echo "No services found or cluster not accessible"
	@echo ""
	@echo "ConfigMaps:"
	@kubectl get cm -n benchmark 2>/dev/null || echo "No configmaps found or cluster not accessible"
	@echo ""
	@echo "Secrets:"
	@kubectl get secrets -n benchmark 2>/dev/null || echo "No secrets found or cluster not accessible"
	@echo ""
	@echo "Results:"
	@ls -la results/ 2>/dev/null || echo "No results directory"

# Development shortcuts
dev-setup: setup-database build-all
	@echo "Development setup complete!"

dev-test-csharp: test-csharp
	@echo "Development test running..."

dev-test-rust: test-rust
	@echo "Development test running..."
