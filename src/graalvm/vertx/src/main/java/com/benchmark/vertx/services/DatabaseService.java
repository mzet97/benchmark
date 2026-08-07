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

        // Create pool options. Vert.x 4 PoolOptions has no setMinSize: the
        // pool lazily opens connections up to maxSize, so the min/max from the
        // contract collapse to a single maxSize.
        PoolOptions poolOptions = new PoolOptions()
            .setMaxSize(config.getDbPoolMax());

        // Create pool
        pool = PgPool.pool(connectOptions, poolOptions);
    }

    public Future<Row> getUser(int userId) {
        Promise<Row> promise = Promise.promise();

        // The normative SQL aliases its columns to the contract names, so the row
        // encodes straight to the response body.
        // See contracts/rest/canonical-payloads.md.
        String query = "SELECT id, email, first_name AS \"firstName\", "
            + "last_name AS \"lastName\", age, created_at AS \"createdAt\" "
            + "FROM users WHERE id = $1";

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

        // Normative SQL. The previous query returned individual order rows --
        // order_id, items_count, joined through order_items -- which the
        // handler then aggregated in Java, while every other implementation
        // aggregates in the database. It also concatenated `days` straight
        // into the SQL.
        String query = "SELECT "
            + "u.id AS \"userId\", "
            + "u.first_name || ' ' || u.last_name AS \"userName\", "
            + "COUNT(o.id) AS \"totalOrders\", "
            + "COALESCE(SUM(o.total_amount), 0)::float8 AS \"totalValue\", "
            + "COALESCE(AVG(o.total_amount), 0)::float8 AS \"averageOrderValue\" "
            + "FROM users u "
            + "INNER JOIN orders o ON u.id = o.user_id "
            + "WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1 "
            + "GROUP BY u.id, u.first_name, u.last_name "
            + "ORDER BY \"totalOrders\" DESC, u.id "
            + "LIMIT 100";

        pool.preparedQuery(query)
            .execute(io.vertx.sqlclient.Tuple.of(days))
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
