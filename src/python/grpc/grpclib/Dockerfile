FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

COPY benchmark.proto .
COPY generate.py .
COPY generated/ generated/
RUN pip install --no-cache-dir grpcio-tools grpclib && \
    python generate.py

FROM python:3.12-slim

WORKDIR /app

COPY --from=builder /install /usr/local
COPY --from=builder /app/generated/ generated/

COPY server.py service.py db.py cache.py ./

ENV GRPC_PORT=50051
ENV GRPC_MAX_WORKERS=10

EXPOSE 50051

CMD ["python", "server.py"]
