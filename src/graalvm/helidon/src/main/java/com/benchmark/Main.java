package com.benchmark;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import com.benchmark.service.CacheService;
import com.benchmark.service.DatabaseService;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import io.helidon.webserver.http.HttpRouting;
import io.helidon.webserver.http.ServerRequest;
import io.helidon.webserver.http.ServerResponse;
import io.helidon.webserver.WebServer;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

import java.sql.*;
import java.time.Instant;
import java.util.*;

public class Main {
    private static HikariDataSource dataSource;
    private static JedisPool jedisPool;
    private static DatabaseService databaseService;
    private static CacheService cacheService;

    private static String requireEnv(String name) {
        String value = System.getenv(name);
        if (value == null || value.isEmpty()) {
            throw new IllegalStateException(name + " is required");
        }
        return value;
    }

    private static int envInt(String name, int fallback) {
        String value = System.getenv(name);
        if (value == null || value.isEmpty()) {
            return fallback;
        }
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    public static void main(String[] args) {
        // A missing variable aborts startup: silently falling back to
        // localhost would have the benchmark measure a connection failure
        // instead of a database.
        String databaseUrl = requireEnv("DATABASE_URL");
        String dbUsername = requireEnv("DB_USERNAME");
        String dbPassword = requireEnv("DB_PASSWORD");

        // Redis configuration (format: host:port:password)
        String redisUrl = requireEnv("REDIS_URL");
        String[] redisParts = redisUrl.split(":");
        String redisHost = redisParts.length > 0 ? redisParts[0] : "localhost";
        int redisPort = redisParts.length > 1 ? Integer.parseInt(redisParts[1]) : 6379;
        String redisPassword = redisParts.length > 2 ? redisParts[2] : "";

        // Initialize PostgreSQL connection pool
        HikariConfig hikariConfig = new HikariConfig();
        hikariConfig.setJdbcUrl(databaseUrl);
        hikariConfig.setUsername(dbUsername);
        hikariConfig.setPassword(dbPassword);
        // Pool size is part of the benchmark contract, not a per-implementation
        // choice: every implementation reads DB_POOL_MAX from the same
        // ConfigMap so the data access layer stops being a hidden variable.
        int dbPoolMax = envInt("DB_POOL_MAX", 32);
        hikariConfig.setMaximumPoolSize(dbPoolMax);
        hikariConfig.setMinimumIdle(dbPoolMax);
        dataSource = new HikariDataSource(hikariConfig);

        // Initialize Redis connection pool
        JedisPoolConfig poolConfig = new JedisPoolConfig();
        poolConfig.setMaxTotal(envInt("REDIS_POOL_MAX", 32));
        jedisPool = new JedisPool(poolConfig, redisHost, redisPort, 2000, redisPassword.isEmpty() ? null : redisPassword);

        // Initialize services
        databaseService = new DatabaseService(dataSource);
        cacheService = new CacheService(jedisPool);

        WebServer server = WebServer.builder()
            .port(envInt("PORT", 8080))
            .routing(HttpRouting.builder()
                .get("/", Main::root)
                .get("/health", Main::health)
                .get("/healthz", Main::healthz)
                .get("/json", Main::json)
                .get("/db/simple", Main::dbSimple)
                .get("/db/complex", Main::dbComplex)
                .get("/cache", Main::cache)
            )
            .build();

        server.start();
        System.out.println("Server started on http://0.0.0.0:" + server.port());
    }

    private static void root(ServerRequest req, ServerResponse res) {
        res.send(toJson(Map.of(
            "status", "running"
        )));
    }

    private static void health(ServerRequest req, ServerResponse res) {
        String dbStatus = "disconnected";
        String cacheStatus = "disconnected";

        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            stmt.execute("SELECT 1");
            dbStatus = "connected";
        } catch (Exception e) {
            // Database not available
        }

        try (var jedis = jedisPool.getResource()) {
            jedis.ping();
            cacheStatus = "connected";
        } catch (Exception e) {
            // Cache not available
        }

        res.send(toJson(Map.of(
            "status", dbStatus.equals("connected") && cacheStatus.equals("connected") ? "healthy" : "unhealthy",
            "version", "1.0.0",
            "timestamp", Instant.now().toString(),
            "database", dbStatus,
            "cache", cacheStatus
        )));
    }

    private static void healthz(ServerRequest req, ServerResponse res) {
        res.send(toJson(Map.of("status", "ok")));
    }

    /**
     * The previous implementation emitted {id,name,email,timestamp} with a
     * fresh Instant.now() per item -- 1000 clock reads per request -- and
     * ignored ?n=, so the n=10/n=100 scenarios all returned 1000 items.
     */
    private static void json(ServerRequest req, ServerResponse res) {
        res.send(toJson(Canonical.response(req.query().first("n").orElse(null))));
    }

    private static void dbSimple(ServerRequest req, ServerResponse res) {
        String idParam = req.query().get("id");
        if (idParam == null || idParam.isEmpty()) {
            res.status(400).send(toJson(Map.of("error", "Bad Request", "message", "id parameter is required")));
            return;
        }

        int id;
        try {
            id = Integer.parseInt(idParam);
        } catch (NumberFormatException e) {
            res.status(400).send(toJson(Map.of("error", "Bad Request", "message", "id must be a number")));
            return;
        }

        Optional<User> userOpt = databaseService.getUserById(id);
        if (userOpt.isEmpty()) {
            res.status(404).send(toJson(Map.of("error", "Not Found", "message", "User with id " + id + " not found")));
            return;
        }

        User user = userOpt.get();
        res.send(toJson(Map.of(
            "id", user.getId(),
            "email", user.getEmail(),
            "first_name", user.getFirstName(),
            "last_name", user.getLastName(),
            "age", user.getAge(),
            "created_at", user.getCreatedAt().toString()
        )));
    }

    private static void dbComplex(ServerRequest req, ServerResponse res) {
        String daysParam = req.query().get("days");
        int days = 30;

        if (daysParam != null && !daysParam.isEmpty()) {
            try {
                days = Integer.parseInt(daysParam);
                if (days <= 0 || days > 365) {
                    res.status(400).send(toJson(Map.of("error", "Bad Request", "message", "days must be between 1 and 365")));
                    return;
                }
            } catch (NumberFormatException e) {
                res.status(400).send(toJson(Map.of("error", "Bad Request", "message", "days must be a number")));
                return;
            }
        }

        List<UserStats> stats = databaseService.getUserStats(days);

        List<Map<String, Object>> data = new ArrayList<>();
        for (UserStats stat : stats) {
            data.add(Map.of(
                "user_id", stat.getUserId(),
                "user_name", stat.getUserName(),
                "total_orders", stat.getTotalOrders(),
                "total_value", stat.getTotalValue(),
                "average_value", stat.getAverageValue()
            ));
        }

        res.send(toJson(Map.of(
            "period_days", days,
            "total_users", data.size(),
            "data", data,
            "timestamp", Instant.now().toString()
        )));
    }

    private static void cache(ServerRequest req, ServerResponse res) {
        String key = req.query().get("key");
        if (key == null || key.isEmpty()) {
            key = "test";
        }

        CacheService.CacheResult result = cacheService.getOrSet(key);

        res.send(toJson(Map.of(
            "key", result.getKey(),
            "value", result.getValue(),
            "cached", result.isCached(),
            "timestamp", Instant.now().toString()
        )));
    }

    private static String toJson(Map<String, Object> map) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (var entry : map.entrySet()) {
            if (!first) sb.append(",");
            first = false;
            sb.append("\"").append(entry.getKey()).append("\":");
            appendValue(sb, entry.getValue());
        }
        sb.append("}");
        return sb.toString();
    }

    @SuppressWarnings("unchecked")
    private static void appendValue(StringBuilder sb, Object value) {
        if (value == null) {
            sb.append("null");
        } else if (value instanceof String) {
            sb.append("\"").append(value).append("\"");
        } else if (value instanceof Number || value instanceof Boolean) {
            sb.append(value);
        } else if (value instanceof Map) {
            sb.append(toJson((Map<String, Object>) value));
        } else if (value instanceof List) {
            sb.append("[");
            boolean first = true;
            for (var item : (List<?>) value) {
                if (!first) sb.append(",");
                first = false;
                appendValue(sb, item);
            }
            sb.append("]");
        } else {
            sb.append("\"").append(value.toString()).append("\"");
        }
    }
}
