#!/bin/bash

# Test build script - verifies the project compiles
# This is useful for CI/CD pipelines

set -e

echo "=========================================="
echo "Rust Actix Web - Build Test"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check Rust version
print_info "Checking Rust version..."
rustc --version
cargo --version
echo ""

# Check formatting
print_info "Checking code formatting..."
if cargo fmt --all -- --check; then
    print_success "Code is properly formatted"
else
    print_error "Code formatting issues found"
    exit 1
fi

echo ""

# Run clippy
print_info "Running clippy lints..."
if cargo clippy --all-targets --all-features -- -D warnings; then
    print_success "Clippy checks passed"
else
    print_error "Clippy warnings found"
    exit 1
fi

echo ""

# Build release
print_info "Building release binary..."
if cargo build --release; then
    print_success "Release build successful"
else
    print_error "Release build failed"
    exit 1
fi

echo ""

# Check binary exists
if [ -f "./target/release/benchmark-actix" ]; then
    print_success "Binary created: ./target/release/benchmark-actix"
    ls -lh ./target/release/benchmark-actix
else
    print_error "Binary not found"
    exit 1
fi

echo ""

# Run tests
print_info "Running tests..."
if cargo test --release; then
    print_success "All tests passed"
else
    print_error "Tests failed"
    exit 1
fi

echo ""

# Test Docker build
print_info "Testing Docker build..."
if docker build -t benchmark/rust-actix-web:test . > /tmp/docker-build.log 2>&1; then
    print_success "Docker build successful"
    docker rmi benchmark/rust-actix-web:test > /dev/null 2>&1 || true
else
    print_error "Docker build failed"
    print_info "Check /tmp/docker-build.log for details"
    exit 1
fi

echo ""
print_success "All tests passed! ✅"
echo ""
echo "Summary:"
echo "  ✓ Code formatting check"
echo "  ✓ Clippy linting"
echo "  ✓ Release build"
echo "  ✓ Tests"
echo "  ✓ Docker build"
