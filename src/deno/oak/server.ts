import { Application, Router, Context } from "./deps.ts";
import { healthRouter } from "./routes/health.ts";
import { jsonRouter } from "./routes/json.ts";
import { databaseRouter } from "./routes/database.ts";
import { cacheRouter } from "./routes/cache.ts";
import { databaseService } from "./services/database.ts";
import { cacheService } from "./services/cache.ts";

// Create main router
const rootRouter = new Router();

// Root endpoint
rootRouter.get("/", (ctx: Context) => {
  ctx.response.body = {
    name: "Benchmark API - Deno Oak",
    version: "1.0.0",
    description: "High-performance REST API benchmark",
    runtime: "Deno",
    framework: "Oak",
    endpoints: {
      health: "/health",
      json: "/json",
      db_simple: "/db/simple?id=1",
      db_complex: "/db/complex?days=30",
      cache: "/cache?key=test",
    },
    status: "running",
  };
});

// Register all route handlers
rootRouter.use(healthRouter.routes());
rootRouter.use(jsonRouter.routes());
rootRouter.use(databaseRouter.routes());
rootRouter.use(cacheRouter.routes());

// Create Oak application
const app = new Application();

// Logger middleware
app.use(async (ctx, next) => {
  const start = Date.now();
  await next();
  const processTime = Date.now() - start;

  console.log(JSON.stringify({
    method: ctx.request.method,
    url: ctx.request.url.toString(),
    status: ctx.response.status,
    processTime: `${processTime}ms`,
    timestamp: new Date().toISOString(),
  }));
});

// CORS middleware
app.use(async (ctx, next) => {
  ctx.response.headers.set("Access-Control-Allow-Origin", "*");
  ctx.response.headers.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  ctx.response.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  ctx.response.headers.set("Access-Control-Allow-Credentials", "true");

  if (ctx.request.method === "OPTIONS") {
    ctx.response.status = 204;
    return;
  }

  await next();
});

// Error handler
app.use(async (ctx, next) => {
  try {
    await next();
  } catch (error) {
    console.error("Unhandled error:", error);

    ctx.response.status = 500;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({
      error: "Internal server error",
      message: Deno.env.get("DEBUG") === "true"
        ? (error instanceof Error ? error.message : String(error))
        : "An error occurred",
    });
  }
});

// Mount main router
app.use(rootRouter.routes());
app.use(rootRouter.allowedMethods());

// Server configuration
const PORT = parseInt(Deno.env.get("PORT") || "8080");
const HOST = Deno.env.get("HOST") || "0.0.0.0";

// Graceful shutdown
const shutdown = async () => {
  console.log("Shutting down server...");

  try {
    await databaseService.close();
    await cacheService.close();
    console.log("Services closed successfully");
    Deno.exit(0);
  } catch (error) {
    console.error("Error during shutdown:", error);
    Deno.exit(1);
  }
};

Deno.addSignalListener("SIGINT", shutdown);
Deno.addSignalListener("SIGTERM", shutdown);

// Start server
const start = async () => {
  try {
    console.log("Initializing services...");

    await databaseService.init();
    await cacheService.init();

    console.log("Starting Benchmark API (Deno + Oak)...");

    // Served through Deno.serve, not app.listen().
    //
    // The previous code called app.listen({ ..., reusePort: true }) with a cast,
    // on the belief that oak spreads its listen options straight into Deno.serve.
    // That is not true of oak v17 (deno.json pins v17.1.4): it serves through
    // Deno's Node compatibility layer, and node:net's listen() has no reusePort
    // option at all, so SO_REUSEPORT was never set.
    //
    // The evidence, stated precisely. Running a minimal oak app under
    // app.listen({ reusePort: true }) produces
    //   Uncaught Error: listen EADDRINUSE: address already in use
    //   at Server._setupListenHandle (ext:deno_node/net.ts)
    // and the ext:deno_node frame shows the socket is opened by the Node
    // compatibility layer rather than by Deno.serve. node:net's listen() takes no
    // reusePort parameter, so the option cannot reach the socket regardless of the
    // cast. That is an API-surface argument, not a measurement: the two-instance
    // test it came from was run on Windows, where SO_REUSEPORT does not exist at
    // all (the second process fails with os error 10048 even through Deno.serve),
    // so it cannot by itself distinguish "oak drops the option" from "the platform
    // has no SO_REUSEPORT". The Linux container is the gate.
    //
    // If this is right, it explains every number this implementation produced. index.ts
    // spawns BENCH_CPUS workers; worker 1 bound the port and the other 39 crashed
    // with EADDRINUSE, leaving one single-threaded process to serve the whole pod.
    // /json?n=1000 measured 310 rps against a 19,475 rps field leader, /health 711
    // rps against 26,231 for deno-rest-hono on the same runtime, and /db/complex
    // 10 rps against a ~860 rps median -- that last one because a lone process
    // holds a lone DatabaseService Client, and deno-postgres serializes queries on
    // one connection, so ~100 ms per aggregate query is ~10 rps no matter how many
    // clients are waiting. The pod looked healthy throughout: the readiness probe
    // is a TCP check and one live worker satisfies it.
    //
    // Deno.serve accepts reusePort directly and bypasses the compatibility layer.
    // app.handle() is oak's documented way to turn a Request into a Response, so
    // the middleware stack is unchanged. With the workers restored, each one holds
    // one Client and the pod totals BENCH_CPUS connections -- which is what
    // index.ts's DB_POOL_MAX share already intends (32/40 floors to 1 per worker),
    // and the same shape as the deno-rest-hono sibling.
    Deno.serve(
      { port: PORT, hostname: HOST, reusePort: true },
      async (request: Request) =>
        (await app.handle(request)) ??
          new Response(
            JSON.stringify({ error: "Not Found" }),
            { status: 404, headers: { "Content-Type": "application/json" } },
          ),
    );

    console.log(`Server listening on http://${HOST}:${PORT}`);
  } catch (error) {
    console.error("Failed to start server:", error);
    Deno.exit(1);
  }
};

start();

export default app;
