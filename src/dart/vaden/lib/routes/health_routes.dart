// Health routes are implemented in bin/server.dart
// using shelf_router directly.
//
// Endpoints:
// - GET /health  - Full health check with DB and Redis status
// - GET /healthz - Simple liveness probe
// - GET /readyz  - Readiness probe with dependency checks
