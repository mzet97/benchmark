package com.benchmark.vertx.config;

import io.vertx.core.json.JsonObject;

import java.util.Map;

/**
 * Configuration class for the application.
 */
public class Config {
    private final String host;
    private final int port;
    private final String environment;
    private final String databaseUrl;
    private final String dbHost;
    private final int dbPort;
    private final String dbName;
    private final String dbUser;
    private final String dbPassword;
    private final String redisUrl;
    private final boolean debug;
    private final String logLevel;
    private final int dbPoolMin;
    private final int dbPoolMax;
    private final int cacheTtl;

    private Config(Builder builder) {
        this.host = builder.host;
        this.port = builder.port;
        this.environment = builder.environment;
        this.databaseUrl = builder.databaseUrl;
        this.dbHost = builder.dbHost;
        this.dbPort = builder.dbPort;
        this.dbName = builder.dbName;
        this.dbUser = builder.dbUser;
        this.dbPassword = builder.dbPassword;
        this.redisUrl = builder.redisUrl;
        this.debug = builder.debug;
        this.logLevel = builder.logLevel;
        this.dbPoolMin = builder.dbPoolMin;
        this.dbPoolMax = builder.dbPoolMax;
        this.cacheTtl = builder.cacheTtl;
    }

    private static String requireEnv(String name) {
        String value = System.getenv(name);
        if (value == null || value.isEmpty()) {
            throw new IllegalStateException(name + " is required");
        }
        return value;
    }

    public static Config load() {
        Builder builder = new Builder();

        // Load from environment variables
        builder.host(System.getenv().getOrDefault("HOST", "0.0.0.0"));
        builder.port(Integer.parseInt(System.getenv().getOrDefault("PORT", "8080")));
        builder.environment(System.getenv().getOrDefault("ENVIRONMENT", "production"));

        // Prefer the component ConfigMap/Secret variables (DB_HOST, DB_PORT,
        // DB_NAME, DB_USER, DB_PASSWORD): DATABASE_URL is percent-encoded, so
        // parsing its userinfo yields a literally-encoded password (e.g.
        // "Admin%40123" instead of "Admin@123") and auth fails. Keep
        // DATABASE_URL as a fallback source.
        builder.dbHost(System.getenv("DB_HOST"));
        builder.dbPort(Integer.parseInt(System.getenv().getOrDefault("DB_PORT", "5432")));
        builder.dbName(System.getenv("DB_NAME"));
        builder.dbUser(System.getenv("DB_USER"));
        builder.dbPassword(System.getenv("DB_PASSWORD"));
        builder.databaseUrl(System.getenv("DATABASE_URL"));

        builder.redisUrl(requireEnv("REDIS_URL"));
        builder.debug(Boolean.parseBoolean(System.getenv().getOrDefault("DEBUG", "false")));
        builder.logLevel(System.getenv().getOrDefault("LOG_LEVEL", "error"));
        // Pool size is part of the benchmark contract: every
        // implementation reads DB_POOL_MAX from the same ConfigMap.
        int dbPoolMax = Integer.parseInt(System.getenv().getOrDefault("DB_POOL_MAX", "32"));
        builder.dbPoolMin(dbPoolMax);
        builder.dbPoolMax(dbPoolMax);
        builder.cacheTtl(Integer.parseInt(System.getenv().getOrDefault("CACHE_TTL", "300")));

        return builder.build();
    }

    public static Config fromJson(JsonObject json) {
        Builder builder = new Builder();

        builder.host(json.getString("host", "0.0.0.0"));
        builder.port(json.getInteger("port", 8080));
        builder.environment(json.getString("environment", "production"));
        builder.databaseUrl(json.getString("databaseUrl", ""));
        builder.dbHost(json.getString("dbHost", null));
        builder.dbPort(json.getInteger("dbPort", 5432));
        builder.dbName(json.getString("dbName", null));
        builder.dbUser(json.getString("dbUser", null));
        builder.dbPassword(json.getString("dbPassword", null));
        builder.redisUrl(json.getString("redisUrl", ""));
        builder.debug(json.getBoolean("debug", false));
        builder.logLevel(json.getString("logLevel", "error"));
        builder.dbPoolMin(json.getInteger("dbPoolMin", 32));
        builder.dbPoolMax(json.getInteger("dbPoolMax", 32));
        builder.cacheTtl(json.getInteger("cacheTtl", 300));

        return builder.build();
    }

    public String getHost() {
        return host;
    }

    public int getPort() {
        return port;
    }

    public String getEnvironment() {
        return environment;
    }

    public String getDatabaseUrl() {
        return databaseUrl;
    }

    public String getDbHost() {
        return dbHost;
    }

    public int getDbPort() {
        return dbPort;
    }

    public String getDbName() {
        return dbName;
    }

    public String getDbUser() {
        return dbUser;
    }

    public String getDbPassword() {
        return dbPassword;
    }

    public String getRedisUrl() {
        return redisUrl;
    }

    public boolean isDebug() {
        return debug;
    }

    public String getLogLevel() {
        return logLevel;
    }

    public int getDbPoolMin() {
        return dbPoolMin;
    }

    public int getDbPoolMax() {
        return dbPoolMax;
    }

    public int getCacheTtl() {
        return cacheTtl;
    }

    public JsonObject toJson() {
        JsonObject json = new JsonObject();
        json.put("host", host);
        json.put("port", port);
        json.put("environment", environment);
        json.put("databaseUrl", databaseUrl);
        json.put("dbHost", dbHost);
        json.put("dbPort", dbPort);
        json.put("dbName", dbName);
        json.put("dbUser", dbUser);
        json.put("dbPassword", dbPassword);
        json.put("redisUrl", redisUrl);
        json.put("debug", debug);
        json.put("logLevel", logLevel);
        json.put("dbPoolMin", dbPoolMin);
        json.put("dbPoolMax", dbPoolMax);
        json.put("cacheTtl", cacheTtl);
        return json;
    }

    public static class Builder {
        private String host;
        private int port;
        private String environment;
        private String databaseUrl;
        private String dbHost;
        private int dbPort = 5432;
        private String dbName;
        private String dbUser;
        private String dbPassword;
        private String redisUrl;
        private boolean debug;
        private String logLevel;
        private int dbPoolMin;
        private int dbPoolMax;
        private int cacheTtl;

        public Builder host(String host) {
            this.host = host;
            return this;
        }

        public Builder port(int port) {
            this.port = port;
            return this;
        }

        public Builder environment(String environment) {
            this.environment = environment;
            return this;
        }

        public Builder databaseUrl(String databaseUrl) {
            this.databaseUrl = databaseUrl;
            return this;
        }

        public Builder dbHost(String dbHost) {
            this.dbHost = dbHost;
            return this;
        }

        public Builder dbPort(int dbPort) {
            this.dbPort = dbPort;
            return this;
        }

        public Builder dbName(String dbName) {
            this.dbName = dbName;
            return this;
        }

        public Builder dbUser(String dbUser) {
            this.dbUser = dbUser;
            return this;
        }

        public Builder dbPassword(String dbPassword) {
            this.dbPassword = dbPassword;
            return this;
        }

        public Builder redisUrl(String redisUrl) {
            this.redisUrl = redisUrl;
            return this;
        }

        public Builder debug(boolean debug) {
            this.debug = debug;
            return this;
        }

        public Builder logLevel(String logLevel) {
            this.logLevel = logLevel;
            return this;
        }

        public Builder dbPoolMin(int dbPoolMin) {
            this.dbPoolMin = dbPoolMin;
            return this;
        }

        public Builder dbPoolMax(int dbPoolMax) {
            this.dbPoolMax = dbPoolMax;
            return this;
        }

        public Builder cacheTtl(int cacheTtl) {
            this.cacheTtl = cacheTtl;
            return this;
        }

        public Config build() {
            return new Config(this);
        }
    }
}
