import { Router, Context } from "../deps.ts";
import { databaseService } from "../services/database.ts";
import { cacheService } from "../services/cache.ts";

const router = new Router();

router.get("/health", async (ctx: Context) => {
  const dbHealthy = await databaseService.healthCheck();
  const cacheHealthy = await cacheService.ping();
  ctx.response.status = dbHealthy && cacheHealthy ? 200 : 503;
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify({
    status: dbHealthy && cacheHealthy ? "healthy" : "unhealthy",
    version: "1.0.0",
    timestamp: new Date().toISOString(),
    database: dbHealthy ? "connected" : "disconnected",
    cache: cacheHealthy ? "connected" : "disconnected",
  });
});

router.get("/healthz", (ctx: Context) => {
  ctx.response.body = { status: "ok" };
});

export { router as healthRouter };