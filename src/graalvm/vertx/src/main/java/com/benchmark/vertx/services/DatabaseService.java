package com.benchmark.vertx.services;

import com.benchmark.vertx.config.Config;
import io.vertx.core.Future;
import io.vertx.core.Promise;
import io.vertx.core.json.JsonObject;
import io.vertx.pgclient.PgConnectOptions;
import io.vertx.pgclient.PgPool;
import io.vertx.sqlclient.PoolOptions;
import io.vertx.sqlclient.Row;
import io.vertx.sqlclient.RowSet;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;

/**
 * Database service for PostgreSQL operations.
 */
public class DatabaseService {
    private static final Logger logger = LoggerFactory.getLogger(DatabaseService.class);

    private final Config config;
    private final PgPool pool;

    public DatabaseService(Config config) {
        this.config = config;

        // Parse database URL
        URI dbUri = URI.create(config.getDatabaseUrl());

        // Create connection options
        PgConnectOptions connectOptions = new PgConnectOptions()
            .setHost(dbUri.getHost())
            .setPort(dbUri.getPort())
            .setDatabase(dbUri.getPath().substring(1))
            .setUser(dbUri.getUserInfo().split(":")[0])
            .setPassword(dbUri.getUserInfo().split(":")[1])
            .setCachePreparedStatements(true);

        // Create pool options
        PoolOptions poolOptions = new PoolOptions()
            .setMaxSize(config.getDbPoolMax())
            .setMinSize(config.getDbPoolMin());

        // Create pool
        pool = PgPool.pool(connectOptions, poolOptions);
    }

    public Future<Row> getUser(int userId) {
        Promise<Row> promise = Promise.promise();

        String query = "SELECT id, email, first_name, last_name, created_at FROM users WHERE id = $1";

        pool.preparedQuery(query)
            .execute(io.vertx.sqlclient.Tuple.of(userId))
            .onSuccess(rows -> {
                if (rows.size() > 0) {
                    promise.complete(rows.iterator().next());
                } else {
                    promise.complete(null);
                }
            })
            .onFailure(promise::fail);

        return promise.future();
    }

    public Future<RowSet<Row>> getComplexOrders(int days) {
        Promise<RowSet<Row>> promise = Promise.promise();

        String query = "SELECT " +
            "o.id as order_id, " +
            "o.user_id, " +
            "u.email as user_email, " +
            "o.total_amount, " +
            "o.created_at, " +
            "COUNT(oi.id) as items_count " +
            "FROM orders o " +
            "JOIN users u ON o.user_id = u.id " +
            "LEFT JOIN order_items oi ON o.id = oi.order_id " +
            "WHERE o.created_at >= NOW() - INTERVAL '" + days + " days' " +
            "GROUP BY o.id, u.email " +
            "ORDER BY o.created_at DESC " +
            "LIMIT 100";

        pool.preparedQuery(query)
            .execute()
            .onSuccess(promise::complete)
            .onFailure(promise::fail);

        return promise.future();
    }

    public Future<Boolean> healthCheck() {
        Promise<Boolean> promise = Promise.promise();

        pool.query("SELECT 1")
            .execute()
            .onSuccess(rows -> promise.complete(true))
            .onFailure(err -> {
                logger.error("Database health check failed", err);
                promise.complete(false);
            });

        return promise.future();
    }

    public void close() {
        pool.close();
    }
}
