package com.benchmark.vertx.handlers;

import com.benchmark.vertx.config.Config;
import com.benchmark.vertx.services.DatabaseService;
import io.vertx.core.Handler;
import io.vertx.ext.web.RoutingContext;
import io.vertx.pgclient.PgPool;
import io.vertx.sqlclient.Row;
import io.vertx.sqlclient.RowSet;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

/**
 * Database endpoint handlers.
 */
public class DatabaseHandler implements Handler<RoutingContext> {
    private static final Logger logger = LoggerFactory.getLogger(DatabaseHandler.class);

    private final Config config;
    private final DatabaseService databaseService;

    private DatabaseHandler(Config config) {
        this.config = config;
        this.databaseService = new DatabaseService(config);
    }

    public static Handler<RoutingContext> createSimple(Config config) {
        return new DatabaseHandler(config);
    }

    public static Handler<RoutingContext> createComplex(Config config) {
        return new DatabaseHandler(config);
    }

    @Override
    public void handle(RoutingContext ctx) {
        if (ctx.request().uri().startsWith("/db/simple")) {
            handleSimple(ctx);
        } else if (ctx.request().uri().startsWith("/db/complex")) {
            handleComplex(ctx);
        } else {
            ctx.response().setStatusCode(404).end();
        }
    }

    private void handleSimple(RoutingContext ctx) {
        String idParam = ctx.request().getParam("id");

        if (idParam == null) {
            ctx.response()
                .setStatusCode(400)
                .putHeader("Content-Type", "application/json")
                .end(new io.vertx.core.json.JsonObject()
                    .put("error", "Bad Request")
                    .put("message", "id parameter is required")
                    .encode());
            return;
        }

        try {
            int userId = Integer.parseInt(idParam);

            databaseService.getUser(userId)
                .onSuccess(user -> {
                    if (user == null) {
                        ctx.response()
                            .setStatusCode(404)
                            .putHeader("Content-Type", "application/json")
                            .end(new io.vertx.core.json.JsonObject()
                                .put("error", "Not Found")
                                .put("message", "User not found")
                                .encode());
                    } else {
                        ctx.response()
                            .putHeader("Content-Type", "application/json")
                            .end(user.encode());
                    }
                })
                .onFailure(err -> {
                    logger.error("Failed to get user", err);
                    ctx.response()
                        .setStatusCode(500)
                        .putHeader("Content-Type", "application/json")
                        .end(new io.vertx.core.json.JsonObject()
                            .put("error", "Internal Server Error")
                            .put("message", err.getMessage())
                            .encode());
                });

        } catch (NumberFormatException e) {
            ctx.response()
                .setStatusCode(400)
                .putHeader("Content-Type", "application/json")
                .end(new io.vertx.core.json.JsonObject()
                    .put("error", "Bad Request")
                    .put("message", "id must be a number")
                    .encode());
        }
    }

    private void handleComplex(RoutingContext ctx) {
        String daysParam = ctx.request().getParam("days");
        int days = daysParam != null ? Integer.parseInt(daysParam) : 30;

        if (days < 0) {
            ctx.response()
                .setStatusCode(400)
                .putHeader("Content-Type", "application/json")
                .end(new io.vertx.core.json.JsonObject()
                    .put("error", "Bad Request")
                    .put("message", "days must be a positive number")
                    .encode());
            return;
        }

        databaseService.getComplexOrders(days)
            .onSuccess(orders -> {
                // Calculate aggregates
                int totalOrders = orders.size();
                double totalRevenue = orders.stream()
                    .mapToDouble(row -> ((BigDecimal) row.getValue("total_amount")).doubleValue())
                    .sum();
                double averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

                io.vertx.core.json.JsonObject result = new io.vertx.core.json.JsonObject();
                result.put("period_days", days);
                result.put("total_orders", totalOrders);
                result.put("total_revenue", Math.round(totalRevenue * 100.0) / 100.0);
                result.put("average_order_value", Math.round(averageOrderValue * 100.0) / 100.0);

                io.vertx.core.json.JsonArray ordersArray = new io.vertx.core.json.JsonArray();
                for (Row row : orders) {
                    io.vertx.core.json.JsonObject order = new io.vertx.core.json.JsonObject();
                    order.put("order_id", row.getInteger("order_id"));
                    order.put("user_id", row.getInteger("user_id"));
                    order.put("user_email", row.getString("user_email"));
                    order.put("total_amount", ((BigDecimal) row.getValue("total_amount")).doubleValue());
                    order.put("items_count", row.getInteger("items_count"));
                    order.put("created_at", row.getLocalDateTime("created_at")
                        .atZone(ZoneOffset.UTC)
                        .toInstant()
                        .toString());
                    ordersArray.add(order);
                }
                result.put("orders", ordersArray);

                ctx.response()
                    .putHeader("Content-Type", "application/json")
                    .end(result.encode());
            })
            .onFailure(err -> {
                logger.error("Failed to get complex orders", err);
                ctx.response()
                    .setStatusCode(500)
                    .putHeader("Content-Type", "application/json")
                    .end(new io.vertx.core.json.JsonObject()
                        .put("error", "Internal Server Error")
                        .put("message", err.getMessage())
                        .encode());
            });
    }
}
