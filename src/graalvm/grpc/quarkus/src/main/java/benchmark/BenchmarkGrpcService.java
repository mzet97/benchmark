package benchmark;

import benchmark.BenchmarkServiceGrpc;
import benchmark.Benchmark.*;
import io.quarkus.grpc.GrpcService;
import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@GrpcService
public class BenchmarkGrpcService extends BenchmarkServiceGrpc.BenchmarkServiceImplBase {

    private static final String VERSION = "1.0.0";

    @Inject
    DatabaseService databaseService;

    @Inject
    CacheService cacheService;

    @Override
    public Uni<HealthResponse> health(HealthRequest request) {
        HealthResponse response = HealthResponse.newBuilder()
                .setStatus("ok")
                .setVersion(VERSION)
                .setTimestamp(Instant.now().toString())
                .setDatabase("connected")
                .setCache("connected")
                .build();
        return Uni.createFrom().item(response);
    }

    @Override
    public Uni<JsonItemsResponse> getJsonItems(JsonItemsRequest request) {
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
        return Uni.createFrom().item(builder.build());
    }

    @Override
    public Uni<UserResponse> getUser(GetUserRequest request) {
        return databaseService.getUser(request.getId());
    }

    @Override
    public Uni<ComplexOrdersResponse> getComplexOrders(ComplexOrdersRequest request) {
        int days = request.getDays() > 0 ? request.getDays() : 30;
        return databaseService.getComplexOrders(days);
    }

    @Override
    public Uni<CacheResponse> getCacheValue(CacheRequest request) {
        return cacheService.get(request.getKey());
    }
}
