#!/usr/bin/env python3
"""gRPC server for the benchmark service using grpcio."""

import logging
import os
import signal
import sys
from concurrent import futures

import sys
import os

# Add generated/ to sys.path so benchmark_pb2_grpc can find benchmark_pb2
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "generated"))

import grpc

# Generated stubs
from generated import benchmark_pb2_grpc

from cache import close_pool as close_cache
from db import close_pool as close_db
from service import BenchmarkServiceServicer


def serve():
    # Was GRPC_PORT, a variable the ConfigMap does not set, so this server
    # listened on 50051 while the Service targeted 8080.
    port = os.environ.get("PORT", "8080")
    # The pool used to be sized from GRPC_MAX_WORKERS, which is not in the
    # ConfigMap, so every implementation got the hardcoded 10. It is sized
    # from BENCH_CPUS now, like every other implementation.
    # See docs/ACTION_PLAN.md, Fase 3.1.
    max_workers = int(os.environ.get("BENCH_CPUS") or os.cpu_count() or 4)

    server = grpc.server(
        futures.ThreadPoolExecutor(max_workers=max_workers),
        options=[
            ("grpc.max_send_message_length", 64 * 1024 * 1024),
            ("grpc.max_receive_message_length", 64 * 1024 * 1024),
        ],
    )

    benchmark_pb2_grpc.add_BenchmarkServiceServicer_to_server(
        BenchmarkServiceServicer(), server
    )

    address = f"0.0.0.0:{port}"
    server.add_insecure_port(address)
    logging.info("Starting gRPC server on %s with %d workers", address, max_workers)
    server.start()

    def graceful_shutdown(signum, frame):
        logging.info("Received signal %d, shutting down gracefully...", signum)
        server.stop(grace=10)
        close_db()
        close_cache()
        logging.info("Server stopped.")
        sys.exit(0)

    signal.signal(signal.SIGTERM, graceful_shutdown)
    signal.signal(signal.SIGINT, graceful_shutdown)

    server.wait_for_termination()


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )
    serve()
