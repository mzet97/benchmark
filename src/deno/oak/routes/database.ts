import { Router, Context } from "../../deps.ts";
import { databaseService } from "../services/database.ts";
import { ComplexOrderResult } from "../types.ts";

const router = new Router({
  base: "/db",
});

router.get("/simple", async (ctx: Context) => {
  const url = ctx.request.url;
  const idParam = url.searchParams.get("id");

  if (!idParam) {
    ctx.response.status = 400;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({
      error: "Bad Request",
      message: "id parameter is required",
    });
    return;
  }

  const userId = parseInt(idParam);
  if (isNaN(userId)) {
    ctx.response.status = 400;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({
      error: "Bad Request",
      message: "id must be a number",
    });
    return;
  }

  const user = await databaseService.getUser(userId);

  if (!user) {
    ctx.response.status = 404;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({
      error: "Not Found",
      message: "User not found",
    });
    return;
  }

  ctx.response.status = 200;
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify(user);
});

router.get("/complex", async (ctx: Context) => {
  const url = ctx.request.url;
  const daysParam = url.searchParams.get("days");
  const days = daysParam ? parseInt(daysParam) : 30;

  if (isNaN(days) || days < 0) {
    ctx.response.status = 400;
    ctx.response.headers.set("Content-Type", "application/json");
    ctx.response.body = JSON.stringify({
      error: "Bad Request",
      message: "days must be a positive number",
    });
    return;
  }

  const orders = await databaseService.getComplexOrders(days);

  // Calculate aggregates
  const totalOrders = orders.length;
  const totalRevenue = orders.reduce(
    (sum, order) => sum + parseFloat(order.total_amount),
    0
  );
  const averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

  const result: ComplexOrderResult = {
    period_days: days,
    total_orders: totalOrders,
    total_revenue: parseFloat(totalRevenue.toFixed(2)),
    average_order_value: parseFloat(averageOrderValue.toFixed(2)),
    orders: orders.map((order) => ({
      order_id: parseInt(order.order_id),
      user_id: parseInt(order.user_id),
      user_email: order.user_email,
      total_amount: parseFloat(order.total_amount),
      items_count: parseInt(order.items_count),
      created_at: order.created_at,
    })),
  };

  ctx.response.status = 200;
  ctx.response.headers.set("Content-Type", "application/json");
  ctx.response.body = JSON.stringify(result);
});

export { router as databaseRouter };
