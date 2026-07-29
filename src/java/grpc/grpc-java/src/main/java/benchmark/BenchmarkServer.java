package benchmark;

import io.grpc.Grpc;
import io.grpc.InsecureServerCredentials;
import io.grpc.Server;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

public class BenchmarkServer {

    private static final int PORT = Integer.parseInt(System.getenv().getOrDefault("PORT", "50051"));

    private Server server;
    private final DatabaseService databaseService;
    private final CacheService cacheService;

    public BenchmarkServer() {
        this.databaseService = new DatabaseService();
        this.cacheService = new CacheService();
    }

    private void start() throws IOException {
        server = Grpc.newServerBuilderForPort(PORT, InsecureServerCredentials.create())
                .addService(new BenchmarkServiceImpl(databaseService, cacheService))
                .build()
                .start();

        System.out.println("gRPC server started on port " + PORT);

        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                System.err.println("Shutting down gRPC server...");
                try {
                    BenchmarkServer.this.stop();
                } catch (InterruptedException e) {
                    e.printStackTrace(System.err);
                }
                System.err.println("Server shut down gracefully");
            }
        });
    }

    private void stop() throws InterruptedException {
        if (server != null) {
            server.shutdown().awaitTermination(30, TimeUnit.SECONDS);
        }
        cacheService.close();
    }

    private void blockUntilShutdown() throws InterruptedException {
        if (server != null) {
            server.awaitTermination();
        }
    }

    public static void main(String[] args) throws IOException, InterruptedException {
        final BenchmarkServer benchmarkServer = new BenchmarkServer();
        benchmarkServer.start();
        benchmarkServer.blockUntilShutdown();
    }
}
