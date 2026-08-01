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
            .onSuccess(rows -> {
                // The database does the aggregation now; this used to sum and
                // average 100 order rows in Java on every request.
                io.vertx.core.json.JsonArray data = new io.vertx.core.json.JsonArray();
                for (Row row : rows) {
                    data.add(new io.vertx.core.json.JsonObject()
                        .put("userId", row.getInteger("userId"))
                        .put("userName", row.getString("userName"))
                        .put("totalOrders", row.getLong("totalOrders"))
                        .put("totalValue", row.getDouble("totalValue"))
                        .put("averageOrderValue", row.getDouble("averageOrderValue")));
                }

                io.vertx.core.json.JsonObject result = new io.vertx.core.json.JsonObject()
                    .put("periodDays", days)
                    .put("totalUsers", data.size())
                    .put("data", data);

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
