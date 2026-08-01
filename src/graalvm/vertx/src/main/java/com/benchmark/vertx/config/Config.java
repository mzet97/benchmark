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
        // No default: an empty URL would have the benchmark measure a
        // connection failure instead of a database.
        builder.databaseUrl(requireEnv("DATABASE_URL"));
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
