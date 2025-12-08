import { Router, Context } from "../../deps.ts";
import { JsonItem } from "../types.ts";

const router = new Router({
  base: "/json",
});

function generateJsonItems(): JsonItem[] {
  const items: JsonItem[] = [];
  const now = new Date().toISOString();

  for (let i = 0; i < 1000; i++) {
    items.push({
      id: i + 1,
      name: `Item ${i + 1}`,
      value: `Value ${i + 1}`,
      timestamp: now,
    });
  }

  return items;
}

router.get("/", (ctx: Context) => {
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify(generateJsonItems());
});

export { router as jsonRouter };
