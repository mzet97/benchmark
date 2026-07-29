package benchmark;

import benchmark.BenchmarkServiceGrpc;
import benchmark.Benchmark.*;
import io.grpc.stub.StreamObserver;

import java.time.Instant;
import java.util.UUID;

public class BenchmarkServiceImpl extends BenchmarkServiceGrpc.BenchmarkServiceImplBase {

    private static final String VERSION = "1.0.0";

    private final DatabaseService databaseService;
    private final CacheService cacheService;

    public BenchmarkServiceImpl(DatabaseService databaseService, CacheService cacheService) {
        this.databaseService = databaseService;
        this.cacheService = cacheService;
    }

    @Override
    public void health(HealthRequest request, StreamObserver<HealthResponse> responseObserver) {
        HealthResponse response = HealthResponse.newBuilder()
                .setStatus("ok")
                .setVersion(VERSION)
                .setTimestamp(Instant.now().toString())
                .setDatabase(databaseService.isConnected() ? "connected" : "disconnected")
                .setCache(cacheService.isConnected() ? "connected" : "disconnected")
                .build();
        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }

    @Override
    public void getJsonItems(JsonItemsRequest request, StreamObserver<JsonItemsResponse> responseObserver) {
        int limit = request.getLimit() > 0 ? request.getLimit() : 1000;
        JsonItemsResponse.Builder builder = JsonItemsResponse.newBuilder();

        for (int i = 0; i < limit; i++) {
            builder.addItems(JsonItem.newBuilder()
                    .setId(i)
                    .setUuid(UUID.randomUUID().toString())
                    .setName("User_" + i)
                    .setEmail("user" + i + "@example.com")
                    .setCreatedAt(Instant.now().toString())
                    .setIsActive(i % 2 == 0)
                    .build());
        }

        builder.setCount(limit);
        builder.setTimestamp(Instant.now().toString());
        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    @Override
    public void getUser(GetUserRequest request, StreamObserver<UserResponse> responseObserver) {
        try {
            UserResponse response = databaseService.getUser(request.getId());
            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }

    @Override
    public void getComplexOrders(ComplexOrdersRequest request, StreamObserver<ComplexOrdersResponse> responseObserver) {
        try {
            int days = request.getDays() > 0 ? request.getDays() : 30;
            ComplexOrdersResponse response = databaseService.getComplexOrders(days);
            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }

    @Override
    public void getCacheValue(CacheRequest request, StreamObserver<CacheResponse> responseObserver) {
        try {
            CacheResponse response = cacheService.get(request.getKey());
            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }
}
