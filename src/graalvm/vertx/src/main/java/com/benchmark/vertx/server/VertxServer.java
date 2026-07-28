package com.benchmark.vertx.server;

import com.benchmark.vertx.config.Config;
import com.benchmark.vertx.handlers.HealthHandler;
import com.benchmark.vertx.handlers.JsonHandler;
import com.benchmark.vertx.handlers.DatabaseHandler;
import com.benchmark.vertx.handlers.CacheHandler;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
import io.vertx.core.Vertx;
import io.vertx.core.http.HttpServer;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.BodyHandler;
import io.vertx.ext.web.handler.CorsHandler;
import io.vertx.ext.web.handler.LoggerHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Vert.x HTTP server implementation.
 */
public class VertxServer extends AbstractVerticle {
    private static final Logger logger = LoggerFactory.getLogger(VertxServer.class);

    private final Config config;
    private HttpServer server;

    public VertxServer(Config config) {
        this.config = config;
    }

    @Override
    public void start(Promise<Void> startPromise) {
        // Create HTTP server options
        HttpServerOptions options = new HttpServerOptions()
            .setHost(config.getHost())
            .setPort(config.getPort())
            .setCompressionSupported(true);

        // Create router
        Router router = Router.router(vertx);

        // Add middleware
        router.route().handler(LoggerHandler.create());
        router.route().handler(CorsHandler.create("*")
            .allowedMethod(io.vertx.core.http.HttpMethod.GET)
            .allowedMethod(io.vertx.core.http.HttpMethod.POST)
            .allowedMethod(io.vertx.core.http.HttpMethod.PUT)
            .allowedMethod(io.vertx.core.http.HttpMethod.DELETE)
            .allowedMethod(io.vertx.core.http.HttpMethod.OPTIONS)
            .allowedHeader("Content-Type")
            .allowedHeader("Authorization"));
        router.route().handler(BodyHandler.create());

        // Add routes
        router.get("/health").handler(HealthHandler.create(config));
        router.get("/healthz").handler(HealthHandler.createHealthz());
        router.get("/json").handler(JsonHandler.create());
        router.get("/db/simple").handler(DatabaseHandler.createSimple(config));
        router.get("/db/complex").handler(DatabaseHandler.createComplex(config));
        router.get("/cache").handler(CacheHandler.create(config));

        // Root endpoint
        router.get("/").handler(ctx -> {
            ctx.response()
                .putHeader("Content-Type", "application/json")
                .end(new io.vertx.core.json.JsonObject()
                    .put("name", "Benchmark API - GraalVM Vert.x")
                    .put("version", "1.0.0")
                    .put("description", "High-performance REST API benchmark")
                    .put("runtime", "GraalVM")
                    .put("framework", "Vert.x")
                    .put("endpoints", new io.vertx.core.json.JsonObject()
                        .put("health", "/health")
                        .put("json", "/json")
                        .put("db_simple", "/db/simple?id=1")
                        .put("db_complex", "/db/complex?days=30")
                        .put("cache", "/cache?key=test"))
                    .put("status", "running")
                    .encode());
        });

        // Create and start server
        vertx.createHttpServer(options)
            .requestHandler(router)
            .listen(result -> {
                if (result.succeeded()) {
                    this.server = result.result();
                    logger.info("Server started on port {}", config.getPort());
                    startPromise.complete();
                } else {
                    logger.error("Failed to start server", result.cause());
                    startPromise.fail(result.cause());
                }
            });
    }

    @Override
    public void stop(Promise<Void> stopPromise) {
        if (server != null) {
            server.close(result -> {
                if (result.succeeded()) {
                    logger.info("Server stopped");
                    stopPromise.complete();
                } else {
                    logger.error("Failed to stop server", result.cause());
                    stopPromise.fail(result.cause());
                }
            });
        } else {
            stopPromise.complete();
        }
    }

    public void start() {
        Vertx vertx = Vertx.vertx();
        vertx.deployVerticle(this);
    }

    public void stop() {
        if (server != null) {
            server.close();
        }
    }
}
