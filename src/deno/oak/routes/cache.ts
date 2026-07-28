import { Router, Context } from "../deps.ts";
import { cacheService } from "../services/cache.ts";

const router = new Router();

router.get("/cache", async (ctx: Context) => {
  const url = ctx.request.url;
  const key = url.searchParams.get("key");
  if (!key) {
    ctx.response.status = 400;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({ error: "Key parameter is required" });
    return;
  }
  const cached = await cacheService.get(key);
  if (cached) {
    ctx.response.status = 200;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({ key, value: cached, cached: true, timestamp: new Date().toISOString() });
    return;
  }
  const value = `Cached value for ${key} at ${new Date().toISOString()}`;
  await cacheService.set(key, value, 300);
  ctx.response.status = 200;
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify({ key, value, cached: false, timestamp: new Date().toISOString() });
});

export { router as cacheRouter };