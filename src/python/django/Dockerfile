FROM python:3.12-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim

# Install curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r app && useradd -r -g app -d /app -s /sbin/nologin app

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R app:app /app
USER app

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Port and worker count are contract-level, not per-implementation choices.
# Previously: Flask/Django ran gunicorn with 4 workers x 2 threads while
# FastAPI ran uvicorn with a single worker, which is what produced the
# "Flask beats FastAPI" result. BENCH_CPUS comes from the shared ConfigMap.
# Shell form (not exec form) so the variable is expanded at runtime.
# See docs/ACTION_PLAN.md, Fase 3.1.
CMD gunicorn -b 0.0.0.0:8080 --workers ${BENCH_CPUS:-4} --threads 1 app.wsgi:application
