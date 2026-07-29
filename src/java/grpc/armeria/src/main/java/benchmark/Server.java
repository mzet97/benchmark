package benchmark;

import com.linecorp.armeria.common.grpc.GrpcSerializationFormats;
import com.linecorp.armeria.server.Server;
import com.linecorp.armeria.server.ServerBuilder;
import com.linecorp.armeria.server.grpc.GrpcService;
import com.linecorp.armeria.server.grpc.GrpcServiceBuilder;
import io.grpc.protobuf.services.ProtoReflectionService;

public class Server {

    public static void main(String[] args) throws Exception {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "50051"));

        DatabaseService dbService = new DatabaseService();
        CacheService cacheService = new CacheService();

        BenchmarkServiceImpl serviceImpl = new BenchmarkServiceImpl(dbService, cacheService);

        GrpcService grpcService = GrpcService.builder()
                .addService(serviceImpl)
                .addService(ProtoReflectionService.newInstance())
                .supportedSerializationFormats(GrpcSerializationFormats.values())
                .enableUnframedRequests(true)
                .build();

        ServerBuilder serverBuilder = Server.builder()
                .http(port)
                .service(grpcService);

        Server server = serverBuilder.build();

        // Graceful shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("Shutting down Armeria gRPC server...");
            try {
                cacheService.close();
            } catch (Exception e) {
                System.err.println("Error closing cache: " + e.getMessage());
            }
            System.out.println("Server stopped");
        }));

        server.start();
        System.out.println("Armeria gRPC server listening on port " + port);
        System.out.println("Version: " + System.getenv().getOrDefault("APP_VERSION", "1.0.0"));

        // Block the main thread
        server.blockUntilShutdown();
    }
}
