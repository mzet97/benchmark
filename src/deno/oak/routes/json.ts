import { Router, Context } from "../deps.ts";
import { buildItems, itemCount } from "../canonical.ts";

const router = new Router();

router.get("/json", (ctx: Context) => {
  const n = itemCount(ctx.request.url.searchParams.get("n"));

  ctx.response.headers.set("Content-Type", "application/json");
  // The envelope timestamp is the only clock-dependent field and is excluded
  // from the parity hash.
  ctx.response.body = JSON.stringify({
    items: buildItems(n),
    count: n,
    timestamp: new Date().toISOString(),
  });
});

export { router as jsonRouter };
