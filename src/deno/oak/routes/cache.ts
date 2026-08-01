import { Router, Context } from "../deps.ts";
import { cacheService } from "../services/cache.ts";

// The TTL is part of the response contract and must match what is written
// to Redis. See contracts/rest/canonical-payloads.md.
const CACHE_TTL_SECONDS = 300;

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
    ctx.response.body = JSON.stringify({ key, value: cached, cached: true, ttl: CACHE_TTL_SECONDS, timestamp: new Date().toISOString() });
    return;
  }
  const value = `Cached value for ${key} at ${new Date().toISOString()}`;
  await cacheService.set(key, value, CACHE_TTL_SECONDS);
  ctx.response.status = 200;
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify({ key, value, cached: false, ttl: CACHE_TTL_SECONDS, timestamp: new Date().toISOString() });
});

export { router as cacheRouter };