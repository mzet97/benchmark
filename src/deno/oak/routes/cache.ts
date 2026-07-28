import { Router, Context } from "../deps.ts";
import { cacheService } from "../services/cache.ts";
import { CacheResponse } from "../types.ts";

const router = new Router({
  base: "/cache",
});

router.get("/", async (ctx: Context) => {
  const url = ctx.request.url;
  const key = url.searchParams.get("key");

  if (!key) {
    ctx.response.status = 400;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({
      error: "Bad Request",
      message: "key parameter is required",
    });
    return;
  }

  const ttl = parseInt(Deno.env.get("CACHE_TTL") || "300");

  // Try to get from cache
  const cached = await cacheService.get(key);

  if (cached) {
    const response: CacheResponse = {
      key,
      value: cached,
      cached: true,
      ttl,
    };

    ctx.response.status = 200;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify(response);
    return;
  }

  // Generate new value
  const value = `cached_data_${key}_${Date.now()}`;

  // Store in cache
  await cacheService.set(key, value, ttl);

  const response: CacheResponse = {
    key,
    value,
    cached: false,
    ttl,
  };

  ctx.response.status = 200;
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify(response);
});

export { router as cacheRouter };
