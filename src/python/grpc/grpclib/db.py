"""PostgreSQL connection management for the benchmark service."""

import os

import psycopg2
import psycopg2.pool


_pool: psycopg2.pool.ThreadedConnectionPool | None = None


def _pool_max() -> int:
    """Connections this process may open.

    DB_POOL_MAX comes from the ConfigMap; the size was hardcoded here, so every
    implementation ran with a pool of 10 regardless of the contract. No division
    by BENCH_CPUS: this server is a single process with a thread pool, not one
    process per core. See docs/ACTION_PLAN.md, Fase 3.2.
    """
    return max(1, int(os.environ.get("DB_POOL_MAX", "32")))


def get_pool() -> psycopg2.pool.ThreadedConnectionPool:
    """Get or create the connection pool."""
    global _pool
    if _pool is None:
        database_url = os.environ.get(
            "DATABASE_URL",
            "postgresql://benchmark:benchmark@localhost:5432/benchmark",
        )
        _pool = psycopg2.pool.ThreadedConnectionPool(
            minconn=1,
            maxconn=_pool_max(),
            dsn=database_url,
        )
    return _pool


def get_connection():
    """Get a connection from the pool."""
    pool = get_pool()
    return pool.getconn()


def release_connection(conn):
    """Release a connection back to the pool."""
    pool = get_pool()
    pool.putconn(conn)


def check_database() -> str:
    """Check database connectivity and return status."""
    try:
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
            return "connected"
        finally:
            release_connection(conn)
    except Exception as e:
        return f"error: {e}"


def close_pool():
    """Close all connections in the pool."""
    global _pool
    if _pool is not None:
        _pool.closeall()
        _pool = None
