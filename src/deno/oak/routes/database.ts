import { Router, Context } from "../deps.ts";
import { databaseService } from "../services/database.ts";

const router = new Router();

router.get("/db/simple", async (ctx: Context) => {
  const url = ctx.request.url;
  const idParam = url.searchParams.get("id");
  if (!idParam) {
    ctx.response.status = 400;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({ error: "Invalid id parameter" });
    return;
  }
  const userId = parseInt(idParam);
  if (isNaN(userId)) {
    ctx.response.status = 400;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({ error: "Invalid id parameter" });
    return;
  }
  const user = await databaseService.getUser(userId);
  if (!user) {
    ctx.response.status = 404;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({ error: `User with id ${userId} not found` });
    return;
  }
  ctx.response.status = 200;
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify(user);
});

router.get("/db/complex", async (ctx: Context) => {
  const url = ctx.request.url;
  const daysParam = url.searchParams.get("days");
  const days = daysParam ? parseInt(daysParam) : 30;
  if (isNaN(days) || days <= 0 || days > 365) {
    ctx.response.status = 400;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({ error: "Days must be between 1 and 365" });
    return;
  }
  const results = await databaseService.getComplexQuery(days);
  ctx.response.status = 200;
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify({
    period_days: days,
    total_users: results.length,
    data: results,
    timestamp: new Date().toISOString(),
  });
});

export { router as databaseRouter };