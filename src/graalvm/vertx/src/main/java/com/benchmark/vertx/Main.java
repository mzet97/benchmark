package com.benchmark.vertx;

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import java.io.*;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;

public class Main {
    private static final int PORT = Integer.parseInt(System.getenv().getOrDefault("PORT", "3000"));

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(PORT), 0);

        server.createContext("/health", exchange -> respond(exchange, 200,
            "{\"status\":\"healthy\",\"database\":\"connected\",\"cache\":\"connected\",\"timestamp\":\"" + Instant.now() + "\"}"));

        server.createContext("/healthz", exchange -> respond(exchange, 200, "{\"status\":\"ok\"}"));

        server.createContext("/json", exchange -> {
            StringBuilder sb = new StringBuilder("{\"items\":[");
            String ts = Instant.now().toString();
            for (int i = 0; i < 1000; i++) {
                if (i > 0) sb.append(",");
                sb.append("{\"id\":").append(i + 1)
                  .append(",\"name\":\"Item ").append(i + 1).append("\"")
                  .append(",\"description\":\"This is item number ").append(i + 1).append("\"")
                  .append(",\"timestamp\":\"").append(ts).append("\"")
                  .append(",\"random\":\"data-").append(UUID.randomUUID()).append("\"}");
            }
            sb.append("],\"count\":1000,\"timestamp\":\"").append(ts).append("\"}");
            respond(exchange, 200, sb.toString());
        });

        server.createContext("/db/simple", exchange -> {
            String query = exchange.getRequestURI().getQuery();
            int id = 1;
            if (query != null) {
                for (String param : query.split("&")) {
                    if (param.startsWith("id=")) {
                        try { id = Integer.parseInt(param.substring(3)); } catch (NumberFormatException e) {}
                    }
                }
            }
            respond(exchange, 200, "{\"id\":" + id + ",\"email\":\"user" + id + "@example.com\",\"first_name\":\"User\",\"last_name\":\"" + id + "\",\"age\":30,\"created_at\":\"" + Instant.now() + "\"}");
        });

        server.createContext("/db/complex", exchange -> {
            String query = exchange.getRequestURI().getQuery();
            int days = 30;
            if (query != null) {
                for (String param : query.split("&")) {
                    if (param.startsWith("days=")) {
                        try { days = Integer.parseInt(param.substring(5)); } catch (NumberFormatException e) {}
                    }
                }
            }
            respond(exchange, 200, "{\"period_days\":" + days + ",\"total_users\":0,\"data\":[],\"timestamp\":\"" + Instant.now() + "\"}");
        });

        server.createContext("/cache", exchange -> {
            String query = exchange.getRequestURI().getQuery();
            String key = "test";
            if (query != null) {
                for (String param : query.split("&")) {
                    if (param.startsWith("key=")) key = param.substring(4);
                }
            }
            respond(exchange, 200, "{\"key\":\"" + key + "\",\"value\":\"Cached value for " + key + " at " + Instant.now() + "\",\"cached\":false,\"timestamp\":\"" + Instant.now() + "\"}");
        });

        server.setExecutor(null);
        server.start();
        System.out.println("GraalVM server listening on port " + PORT);
    }

    private static void respond(HttpExchange exchange, int status, String body) throws IOException {
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, body.length());
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(body.getBytes(StandardCharsets.UTF_8));
        }
    }
}
