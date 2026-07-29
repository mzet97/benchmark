package benchmark;

import dev.benchmark.grpc.BenchmarkServiceGrpc;
import dev.benchmark.grpc.BenchmarkProto;
import io.grpc.Status;
import io.grpc.StatusException;
import io.grpc.stub.StreamObserver;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public class BenchmarkServiceImpl extends BenchmarkServiceGrpc.BenchmarkServiceImplBase {

    private final DatabaseService dbService;
    private final CacheService cacheService;
    private final String version;

    public BenchmarkServiceImpl(DatabaseService dbService, CacheService cacheService) {
        this.dbService = dbService;
        this.cacheService = cacheService;
        this.version = System.getenv().getOrDefault("APP_VERSION", "1.0.0");
    }

    // Scenario 1: Health check
    @Override
    public void health(BenchmarkProto.HealthRequest request,
                       StreamObserver<BenchmarkProto.HealthResponse> responseObserver) {
        String dbStatus = dbService.healthCheck();
        String cacheStatus = cacheService.healthCheck();

        BenchmarkProto.HealthResponse response = BenchmarkProto.HealthResponse.newBuilder()
                .setStatus("ok")
                .setVersion(version)
                .setTimestamp(Instant.now().toString())
                .setDatabase(dbStatus)
                .setCache(cacheStatus)
                .build();

        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }

    // Scenario 2: JSON serialization (1000 items)
    @Override
    public void getJsonItems(BenchmarkProto.JsonItemsRequest request,
                             StreamObserver<BenchmarkProto.JsonItemsResponse> responseObserver) {
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

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    // Scenario 3: Simple database query
    @Override
    public void getUser(BenchmarkProto.GetUserRequest request,
                        StreamObserver<BenchmarkProto.UserResponse> responseObserver) {
        try {
            DatabaseService.User user = dbService.getUser(request.getId());
            if (user == null) {
                responseObserver.onError(new StatusException(
                        Status.NOT_FOUND.withDescription("User with id " + request.getId() + " not found")));
                return;
            }

            BenchmarkProto.UserResponse response = BenchmarkProto.UserResponse.newBuilder()
                    .setId(user.getId())
                    .setEmail(user.getEmail())
                    .setFirstName(user.getFirstName())
                    .setLastName(user.getLastName())
                    .setAge(user.getAge())
                    .setCreatedAt(user.getCreatedAt())
                    .build();

            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(new StatusException(
                    Status.INTERNAL.withDescription("Database error: " + e.getMessage())));
        }
    }

    // Scenario 4: Complex database query (JOIN + aggregation)
    @Override
    public void getComplexOrders(BenchmarkProto.ComplexOrdersRequest request,
                                 StreamObserver<BenchmarkProto.ComplexOrdersResponse> responseObserver) {
        try {
            int days = request.getDays() > 0 ? request.getDays() : 30;
            List<DatabaseService.UserOrderStat> data = dbService.getComplexOrders(days);

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

            responseObserver.onNext(builder.build());
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(new StatusException(
                    Status.INTERNAL.withDescription("Database error: " + e.getMessage())));
        }
    }

    // Scenario 5: Cache hit/miss
    @Override
    public void getCacheValue(BenchmarkProto.CacheRequest request,
                              StreamObserver<BenchmarkProto.CacheResponse> responseObserver) {
        String key = request.getKey();
        CacheService.CacheResult result = cacheService.get(key);

        if (result.isHit()) {
            BenchmarkProto.CacheResponse response = BenchmarkProto.CacheResponse.newBuilder()
                    .setKey(key)
                    .setValue(result.getValue())
                    .setCached(true)
                    .setTtl(300)
                    .setTimestamp(Instant.now().toString())
                    .build();

            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } else {
            String value = "value-" + System.currentTimeMillis();
            cacheService.set(key, value, 300);

            BenchmarkProto.CacheResponse response = BenchmarkProto.CacheResponse.newBuilder()
                    .setKey(key)
                    .setValue(value)
                    .setCached(false)
                    .setTtl(300)
                    .setTimestamp(Instant.now().toString())
                    .build();

            responseObserver.onNext(response);
            responseObserver.onCompleted();
        }
    }
}
