package com.benchmark.vertx;

import com.benchmark.vertx.config.Config;
import com.benchmark.vertx.server.VertxServer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Main entry point for the GraalVM Vert.x Benchmark application.
 */
public class Main {
    private static final Logger logger = LoggerFactory.getLogger(Main.class);

    public static void main(String[] args) {
        logger.info("Starting Benchmark API (GraalVM + Vert.x)...");

        try {
            // Load configuration
            Config config = Config.load();

            // Create and start server
            VertxServer server = new VertxServer(config);
            server.start();

            logger.info("Server started successfully");
            logger.info("Listening on http://{}:{}", config.getHost(), config.getPort());
            logger.info("Environment: {}", config.getEnvironment());

            // Setup graceful shutdown
            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                logger.info("Shutting down server...");
                server.stop();
            }));

        } catch (Exception e) {
            logger.error("Failed to start server", e);
            System.exit(1);
        }
    }
}
