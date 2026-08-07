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

        // Prefer the component ConfigMap/Secret variables (DB_HOST, DB_PORT,
        // DB_NAME, DB_USER, DB_PASSWORD). DATABASE_URL is percent-encoded, so
        // URI.getUserInfo() returns a literally-encoded password (e.g.
        // "Admin%40123" instead of "Admin@123") and auth fails. The component
        // variables carry the raw, un-encoded values.
        PgConnectOptions connectOptions;
        String dbHost = config.getDbHost();
        String dbName = config.getDbName();
        String dbUser = config.getDbUser();
        String dbPassword = config.getDbPassword();
        if (dbHost != null && dbName != null && dbUser != null && dbPassword != null) {
            connectOptions = new PgConnectOptions()
                .setHost(dbHost)
                .setPort(config.getDbPort())
                .setDatabase(dbName)
                .setUser(dbUser)
                .setPassword(dbPassword)
                .setCachePreparedStatements(true);
        } else {
            // Fallback: parse postgresql://user:password@host:port/database from
            // DATABASE_URL and percent-decode the userinfo so an encoded
            // password (e.g. %40 for @) is restored before it reaches Postgres.
            String databaseUrl = config.getDatabaseUrl();
            if (databaseUrl == null || databaseUrl.isEmpty()) {
                throw new IllegalStateException(
                    "DB_HOST/DB_NAME/DB_USER/DB_PASSWORD (or DATABASE_URL) is required");
            }
            URI dbUri = URI.create(databaseUrl);
            String userInfo = dbUri.getUserInfo();
            if (userInfo == null) {
                throw new IllegalStateException("DATABASE_URL must contain user:password userinfo");
            }
            String[] parts = userInfo.split(":", 2);
            String user = java.net.URLDecoder.decode(parts[0], java.nio.charset.StandardCharsets.UTF_8);
            String pass = parts.length > 1
                ? java.net.URLDecoder.decode(parts[1], java.nio.charset.StandardCharsets.UTF_8)
                : "";
            int port = dbUri.getPort() > 0 ? dbUri.getPort() : 5432;
            String db = dbUri.getPath() != null && dbUri.getPath().startsWith("/")
                ? dbUri.getPath().substring(1) : "";
            connectOptions = new PgConnectOptions()
                .setHost(dbUri.getHost())
                .setPort(port)
                .setDatabase(db)
                .setUser(user)
                .setPassword(pass)
                .setCachePreparedStatements(true);
        }

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
