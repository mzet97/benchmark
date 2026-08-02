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
app.use(async (ctx: Context, next: () => Promise<void>) => {
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
app.use(async (ctx: Context, next: () => Promise<void>) => {
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
app.use(async (ctx: Context, next: () => Promise<void>) => {
  try {
    await next();
  } catch (error) {
    console.error("Unhandled error:", error);

    ctx.response.status = 500;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({
      error: "Internal server error",
      message: Deno.env.get("DEBUG") === "true" ? error.message : "An error occurred",
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

    // reusePort sets SO_REUSEPORT, which is what lets the BENCH_CPUS workers
    // forked by index.ts share this socket instead of fighting over it.
    // oak's ListenOptions does not declare the field, but its default server
    // spreads the options straight into Deno.serve (http_server_native.ts),
    // so it reaches the socket. The cast is for the type checker only.
    app.listen(
      { port: PORT, hostname: HOST, reusePort: true } as Parameters<
        typeof app.listen
      >[0],
    );

    console.log(`Server listening on http://${HOST}:${PORT}`);
  } catch (error) {
    console.error("Failed to start server:", error);
    Deno.exit(1);
  }
};

start();

export default app;
