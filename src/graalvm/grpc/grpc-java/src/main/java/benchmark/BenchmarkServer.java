package benchmark;

import io.grpc.Grpc;
import io.grpc.InsecureServerCredentials;
import io.grpc.Server;
import io.grpc.ServerBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

public class BenchmarkServer {

    private static final Logger logger = LoggerFactory.getLogger(BenchmarkServer.class);
    private static final int DEFAULT_PORT = 3000;

    private Server server;

    private void start() throws IOException {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", String.valueOf(DEFAULT_PORT)));

        DatabaseService databaseService = new DatabaseService();
        CacheService cacheService = new CacheService();

        server = Grpc.newServerBuilderForPort(port, InsecureServerCredentials.create())
                .addService(new BenchmarkServiceImpl(databaseService, cacheService))
                .build()
                .start();

        logger.info("gRPC server started on port {}", port);

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            logger.info("Shutting down gRPC server...");
            try {
                server.shutdown().awaitTermination(30, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                server.shutdownNow();
            }
            databaseService.close();
            cacheService.close();
            logger.info("Server shut down.");
        }));
    }

    private void blockUntilShutdown() throws InterruptedException {
        if (server != null) {
            server.awaitTermination();
        }
    }

    public static void main(String[] args) throws IOException, InterruptedException {
        logger.info("Starting GraalVM grpc-java Native Benchmark Server...");
        BenchmarkServer server = new BenchmarkServer();
        server.start();
        server.blockUntilShutdown();
    }
}
