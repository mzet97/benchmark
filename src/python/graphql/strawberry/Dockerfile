FROM python:3.12-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY *.py .
ENV PORT=8080
RUN groupadd --gid 1001 app && useradd --uid 1001 --gid 1001 --shell /bin/false --create-home app

EXPOSE 8080

USER app

# Shell form on purpose: BENCH_CPUS has to expand at runtime. A single
# uvicorn worker uses one of the pod's 7 CPUs, which measures "is this
# runtime multi-process", not the framework.
# See docs/ACTION_PLAN.md, Fase 3.1.
CMD uvicorn server:app --host 0.0.0.0 --port 8080 --workers ${BENCH_CPUS:-4} --log-level ${LOG_LEVEL:-error}
