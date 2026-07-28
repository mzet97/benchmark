import { Router, Context } from "../deps.ts";

const router = new Router();

router.get("/json", (ctx: Context) => {
  const timestamp = new Date().toISOString();
  const items = Array.from({ length: 1000 }, (_, i) => ({
    id: i + 1,
    uuid: crypto.randomUUID(),
    name: `Item ${i + 1}`,
    description: `This is item number ${i + 1}`,
    timestamp,
    random: `data-${crypto.randomUUID()}`,
  }));
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify({ items, count: 1000, timestamp });
});

export { router as jsonRouter };