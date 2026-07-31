# Multi-stage build for Python FastAPI with optimizations
FROM python:3.12-slim AS builder

# Set build arguments
ARG PYTHONUNBUFFERED=1
ARG PYTHONDONTWRITEBYTECODE=1

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.12-slim AS production

# Set environment variables
ARG PYTHONUNBUFFERED=1
ARG PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=$PYTHONUNBUFFERED
ENV PYTHONDONTWRITEBYTECODE=$PYTHONDONTWRITEBYTECODE
ENV PATH="/opt/venv/bin:$PATH"

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Create app user
RUN groupadd -r app && useradd -r -g app app

# Create app directory
WORKDIR /app

# Copy application code
COPY --chown=app:app . .

# Switch to non-root user
USER app

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
# Port and worker count are contract-level, not per-implementation choices.
# Previously: Flask/Django ran gunicorn with 4 workers x 2 threads while
# FastAPI ran uvicorn with a single worker, which is what produced the
# "Flask beats FastAPI" result. BENCH_CPUS comes from the shared ConfigMap.
# Shell form (not exec form) so the variable is expanded at runtime.
# See docs/ACTION_PLAN.md, Fase 3.1.
CMD uvicorn app.main:app --host 0.0.0.0 --port 8080 --workers ${BENCH_CPUS:-4}
