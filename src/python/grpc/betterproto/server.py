#!/usr/bin/env python3
"""Async gRPC server for the benchmark service using betterproto + grpclib.

betterproto uses grpclib as its gRPC transport engine. This server is identical
in structure to a pure grpclib server -- the only difference is that the service
implementation uses betterproto-generated dataclass message types instead of
standard protobuf message classes.

Architecture:
  betterproto  --> generates Pythonic dataclass message types
  grpclib      --> provides the async gRPC server/client runtime
  This server  --> registers the betterproto service with grpclib
"""

import asyncio
import logging
import os
import signal

from grpclib.server import Server

# Generated stubs
from generated import benchmark_grpc

from cache import close_pool as close_cache
from db import close_pool as close_db
from service import BenchmarkService


async def serve():
    # Was GRPC_PORT, a variable the ConfigMap does not set, so this server
    # listened on 50051 while the Service targeted 8080.
    port = int(os.environ.get("PORT", "8080"))
    # The pool used to be sized from GRPC_MAX_WORKERS, which is not in the
    # ConfigMap, so every implementation got the hardcoded 10. It is sized
    # from BENCH_CPUS now, like every other implementation.
    # See docs/ACTION_PLAN.md, Fase 3.1.
    max_workers = int(os.environ.get("BENCH_CPUS") or os.cpu_count() or 4)

    service = BenchmarkService()
    server = Server([service])

    # Graceful shutdown handler
    loop = asyncio.get_running_loop()
    stop_event = asyncio.Event()

    def _shutdown_handler():
        logging.info("Received shutdown signal, stopping server...")
        stop_event.set()

    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, _shutdown_handler)

    await server.start("0.0.0.0", port)
    logging.info(
        "Starting betterproto+grpclib gRPC server on 0.0.0.0:%d with %d workers",
        port,
        max_workers,
    )

    # Wait for shutdown signal
    await stop_event.wait()

    logging.info("Shutting down server gracefully...")
    server.close()
    await server.wait_closed()
    close_db()
    close_cache()
    logging.info("Server stopped.")


def main():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )
    asyncio.run(serve())


if __name__ == "__main__":
    main()
