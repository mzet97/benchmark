from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import structlog
import os

from app.routes import health, json, database, cache
from app.services.database import DatabaseService
from app.services.cache import CacheService


logger = structlog.get_logger()

# Global service instances
db_service = DatabaseService()
cache_service = CacheService()

# Create FastAPI application
app = FastAPI(
    title="Benchmark API",
    description="High-performance REST API benchmark",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# Add middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]
)


# No request logging middleware.
#
# It timed every request and emitted a structlog record with method, url, status
# and duration. LOG_LEVEL=error from the ConfigMap suppresses the output but not
# the middleware, and an @app.middleware("http") in Starlette is not free: it
# wraps every request in an extra ASGI layer regardless of whether anything is
# logged. Only 7 of the 100 implementations carried request logging at all, so
# the ranking rewarded whoever left it out. Invariante 1 in
# docs/ACTION_PLAN.md; the same was removed from nodejs/express, bun/hono,
# bun/elysia and bun/bun_serve, and disabled in nodejs/fastify.


# Event handlers
@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info("Starting Benchmark API...")
    await db_service.init_pool()
    await cache_service.init_redis()
    logger.info("Services initialized successfully")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup services on shutdown"""
    logger.info("Shutting down Benchmark API...")
    await db_service.close_pool()
    await cache_service.close_redis()
    logger.info("Shutdown complete")


# Exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error("Unhandled exception", error=str(exc), url=str(request.url))
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "message": str(exc) if os.getenv("DEBUG") == "true" else "An error occurred"
        }
    )


# Register routes
app.include_router(health.router)
app.include_router(json.router)
app.include_router(database.router)
app.include_router(cache.router)


# Root endpoint
@app.get("/", tags=["root"])
async def root():
    """Root endpoint with API information"""
    return {
        "name": "Benchmark API",
        "version": "1.0.0",
        "description": "High-performance REST API benchmark",
        "endpoints": {
            "health": "/health",
            "json": "/json",
            "db_simple": "/db/simple?id=1",
            "db_complex": "/db/complex?days=30",
            "cache": "/cache?key=test",
            "docs": "/docs",
            "redoc": "/redoc"
        },
        "status": "running"
    }


# Health check for load balancers
@app.get("/healthz", tags=["health"])
async def healthz():
    """Kubernetes health check endpoint"""
    return {"status": "ok"}
