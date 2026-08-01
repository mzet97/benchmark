package com.benchmark.vertx;

import com.benchmark.vertx.config.Config;
import com.benchmark.vertx.server.VertxServer;

/**
 * Entry point.
 *
 * <p>This class used to be a second, parallel server built on
 * {@code com.sun.net.httpserver.HttpServer} -- not Vert.x at all -- and it is
 * the one pom.xml names as {@code main.class}, so it is what actually ran.
 * It answered /health with a hardcoded "connected" without touching Postgres
 * or Redis, /db/simple with an invented user, /db/complex with an empty data
 * array, and /cache with a fabricated value. None of those numbers measured
 * anything, and the real Vert.x server next to it -- VertxServer, its router,
 * its handlers and its services -- was never started.
 */
public class Main {
    public static void main(String[] args) {
        Config config = Config.load();
        new VertxServer(config).start();
    }
}
