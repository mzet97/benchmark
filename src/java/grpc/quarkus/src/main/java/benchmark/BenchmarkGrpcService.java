package benchmark;

import dev.benchmark.grpc.BenchmarkServiceGrpc;
import dev.benchmark.grpc.BenchmarkProto;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.quarkus.grpc.GrpcService;
import io.smallrye.mutiny.Uni;

import jakarta.inject.Inject;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@GrpcService
public class BenchmarkGrpcService extends BenchmarkServiceGrpc.BenchmarkServiceImplBase {

    @Inject
    DatabaseService dbService;

    @Inject
    CacheService cacheService;

    private final String version = System.getenv().getOrDefault("APP_VERSION", "1.0.0");

    // Scenario 1: Health check
    @Override
    public Uni<BenchmarkProto.HealthResponse> health(BenchmarkProto.HealthRequest request) {
        return Uni.createFrom().item(() -> {
            String dbStatus = dbService.healthCheck().await().indefinitely();
            String cacheStatus = cacheService.healthCheck().await().indefinitely();

            return BenchmarkProto.HealthResponse.newBuilder()
                    .setStatus("ok")
                    .setVersion(version)
                    .setTimestamp(Instant.now().toString())
                    .setDatabase(dbStatus)
                    .setCache(cacheStatus)
                    .build();
        });
    }

    // Scenario 2: JSON serialization (1000 items)
    @Override
    public Uni<BenchmarkProto.JsonItemsResponse> getJsonItems(BenchmarkProto.JsonItemsRequest request) {
        return Uni.createFrom().item(() -> {
            int limit = request.getLimit() > 0 ? request.getLimit() : 1000;

            BenchmarkProto.JsonItemsResponse.Builder builder = BenchmarkProto.JsonItemsResponse.newBuilder();
            for (int i = 1; i <= limit; i++) {
                builder.addItems(BenchmarkProto.JsonItem.newBuilder()
                        .setId(i)
                        .setUuid(UUID.randomUUID().toString())
                        .setName("Item " + i)
                        .setEmail("user" + i + "@benchmark.com")
                        .setCreatedAt(Instant.now().toString())
                        .setIsActive(i % 2 == 0)
                        .build());
            }

            builder.setCount(limit);
            builder.setTimestamp(Instant.now().toString());

            return builder.build();
        });
    }

    // Scenario 3: Simple database query
    @Override
    public Uni<BenchmarkProto.UserResponse> getUser(BenchmarkProto.GetUserRequest request) {
        return dbService.getUser(request.getId())
                .onItem().ifNull().failWith(() -> new StatusRuntimeException(
                        Status.NOT_FOUND.withDescription("User with id " + request.getId() + " not found")))
                .onItem().transform(user -> BenchmarkProto.UserResponse.newBuilder()
                        .setId(user.getId())
                        .setEmail(user.getEmail())
                        .setFirstName(user.getFirstName())
                        .setLastName(user.getLastName())
                        .setAge(user.getAge())
                        .setCreatedAt(user.getCreatedAt())
                        .build());
    }

    // Scenario 4: Complex database query (JOIN + aggregation)
    @Override
    public Uni<BenchmarkProto.ComplexOrdersResponse> getComplexOrders(BenchmarkProto.ComplexOrdersRequest request) {
        int days = request.getDays() > 0 ? request.getDays() : 30;

        return dbService.getComplexOrders(days)
                .onItem().transform(data -> {
                    BenchmarkProto.ComplexOrdersResponse.Builder builder = BenchmarkProto.ComplexOrdersResponse.newBuilder();
                    builder.setPeriodDays(days);
                    builder.setTotalUsers(data.size());

                    for (DatabaseService.UserOrderStat stat : data) {
                        builder.addData(BenchmarkProto.UserOrderStats.newBuilder()
                                .setUserId(stat.getUserId())
                                .setUserName(stat.getUserName())
                                .setTotalOrders(stat.getTotalOrders())
                                .setTotalValue(stat.getTotalValue())
                                .setAverageOrderValue(stat.getAverageOrderValue())
                                .build());
                    }

                    return builder.build();
                });
    }

    // Scenario 5: Cache hit/miss
    @Override
    public Uni<BenchmarkProto.CacheResponse> getCacheValue(BenchmarkProto.CacheRequest request) {
        String key = request.getKey();

        return cacheService.get(key)
                .onItem().transform(result -> {
                    if (result.isHit()) {
                        return BenchmarkProto.CacheResponse.newBuilder()
                                .setKey(key)
                                .setValue(result.getValue())
                                .setCached(true)
                                .setTtl(300)
                                .setTimestamp(Instant.now().toString())
                                .build();
                    } else {
                        String value = "value-" + System.currentTimeMillis();
                        cacheService.set(key, value, 300).await().indefinitely();

                        return BenchmarkProto.CacheResponse.newBuilder()
                                .setKey(key)
                                .setValue(value)
                                .setCached(false)
                                .setTtl(300)
                                .setTimestamp(Instant.now().toString())
                                .build();
                    }
                });
    }
}
