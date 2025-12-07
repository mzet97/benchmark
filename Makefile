# Makefile for API Benchmark Project

.PHONY: help setup-database build-csharp test-csharp deploy-csharp benchmark-csharp clean-all

# Default target
help:
	@echo "API Benchmark - Available Commands:"
	@echo ""
	@echo "Database Setup:"
	@echo "  setup-database        - Setup PostgreSQL database with schema and seed data"
	@echo ""
	@echo "C# (.NET 9) - Minimal API:"
	@echo "  build-csharp          - Build C# application with Native AOT"
	@echo "  test-csharp           - Run C# application locally"
	@echo "  deploy-csharp         - Deploy to Kubernetes"
	@echo "  benchmark-csharp      - Run benchmarks (wrk + k6)"
	@echo "  undeploy-csharp       - Remove from Kubernetes"
	@echo ""
	@echo "All Languages:"
	@echo "  build-all             - Build all implementations"
	@echo "  deploy-all            - Deploy all to Kubernetes"
	@echo "  benchmark-all         - Run all benchmarks"
	@echo "  clean-all             - Clean all builds and results"
	@echo ""
	@echo "Metrics:"
	@echo "  collect-metrics       - Collect system and database metrics"

# Database setup
setup-database:
	@echo "Setting up database..."
	@chmod +x scripts/setup-database.sh
	@./scripts/setup-database.sh

# C# - Minimal API
build-csharp:
	@echo "Building C# application with Native AOT..."
	@cd src/csharp/MinimalApi && \
		dotnet restore && \
		dotnet build -c Release && \
		dotnet publish -c Release -o ./publish \
			-p:PublishAot=true \
			-p:PublishSingleFile=true \
			-p:PublishTrimmed=false \
			-p:EnableCompressionInSingleFile=true \
			-p:InvariantGlobalization=true && \
		echo "Build completed. Binary size:" && \
		ls -lh ./publish/benchmark-api || echo "Build may have failed"

test-csharp:
	@echo "Testing C# application..."
	@cd src/csharp/MinimalApi && \
		DATABASE_URL="Host=spsql.home.arpa;Port=5432;Database=benchmark_api;Username=app;Password=Admin@123;Maximum Pool Size=25;Connection Timeout=30;" \
		REDIS_CONNECTIONSTRING="redis.home.arpa:30379,password=Admin@123,defaultDatabase=0,ssl=false" \
		dotnet run --urls "http://localhost:8080"

deploy-csharp:
	@echo "Deploying C# to Kubernetes..."
	@kubectl apply -f src/csharp/MinimalApi/k8s/configmap.yaml
	@kubectl apply -f src/csharp/MinimalApi/k8s/deployment.yaml
	@kubectl apply -f src/csharp/MinimalApi/k8s/service.yaml
	@sleep 5
	@kubectl get pods -l app=csharp-minimalapi
	@echo "Waiting for pods to be ready..."
	@kubectl wait --for=condition=ready pod -l app=csharp-minimalapi --timeout=120s || echo "Pods may still be starting"

benchmark-csharp: build-csharp deploy-csharp
	@echo "Running benchmarks for C#..."
	@mkdir -p results/wrk results/k6
	@chmod +x scripts/benchmark-wrk.sh scripts/benchmark-k6.sh
	@sleep 10
	@echo "Running wrk benchmark..."
	@./scripts/benchmark-wrk.sh csharp-minimalapi "http://csharp-minimalapi.benchmark.svc.cluster.local"
	@echo ""
	@echo "Running k6 benchmark..."
	@./scripts/benchmark-k6.sh csharp-minimalapi "http://csharp-minimalapi.benchmark.svc.cluster.local"

undeploy-csharp:
	@echo "Removing C# from Kubernetes..."
	@kubectl delete -f src/csharp/MinimalApi/k8s/service.yaml || true
	@kubectl delete -f src/csharp/MinimalApi/k8s/deployment.yaml || true
	@kubectl delete -f src/csharp/MinimalApi/k8s/configmap.yaml || true
	@kubectl delete pods -l app=csharp-minimalapi --force || true

# All implementations
build-all: build-csharp
	@echo "Building all implementations..."
	@echo "Note: Currently only C# is implemented. Other languages coming soon."

deploy-all: deploy-csharp
	@echo "Deploying all implementations..."
	@echo "Note: Currently only C# is deployed."

benchmark-all: benchmark-csharp
	@echo "Running all benchmarks..."
	@echo "Note: Currently only C# benchmarked."

clean-all:
	@echo "Cleaning all builds and results..."
	@rm -rf src/csharp/MinimalApi/bin src/csharp/MinimalApi/obj src/csharp/MinimalApi/publish
	@rm -rf results
	@kubectl delete -f src/csharp/MinimalApi/k8s/ || true

collect-metrics:
	@echo "Collecting system and database metrics..."
	@chmod +x scripts/collect-metrics.sh
	@./scripts/collect-metrics.sh

# Docker commands
docker-build-csharp:
	@echo "Building C# Docker image..."
	@cd src/csharp/MinimalApi && \
		docker build -t benchmark/csharp-minimalapi:latest . && \
		echo "Docker image built successfully"

docker-push-csharp:
	@echo "Pushing C# Docker image..."
	@docker push benchmark/csharp-minimalapi:latest

# Development shortcuts
dev-setup: setup-database build-csharp
	@echo "Development setup complete!"

dev-test: test-csharp
	@echo "Development test running..."

# Show status
status:
	@echo "=== Kubernetes Status ==="
	@kubectl get pods -l app=csharp-minimalapi || echo "No pods found"
	@echo ""
	@echo "=== Services ==="
	@kubectl get svc -l app=csharp-minimalapi || echo "No services found"
	@echo ""
	@echo "=== ConfigMaps ==="
	@kubectl get cm -l app=csharp-minimalapi || echo "No configmaps found"
	@echo ""
	@echo "=== Results ==="
	@ls -la results/ 2>/dev/null || echo "No results directory"
