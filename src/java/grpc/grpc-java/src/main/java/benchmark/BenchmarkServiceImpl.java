package benchmark;

import dev.benchmark.grpc.BenchmarkServiceGrpc;
import dev.benchmark.grpc.Benchmark.*;
import io.grpc.Status;
import io.grpc.stub.StreamObserver;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public class BenchmarkServiceImpl extends BenchmarkServiceGrpc.BenchmarkServiceImplBase {

    private static final String VERSION = System.getenv().getOrDefault("APP_VERSION", "1.0.0");
    private final DatabaseService databaseService;
    private final CacheService cacheService;

    public BenchmarkServiceImpl(DatabaseService databaseService, CacheService cacheService) {
        this.databaseService = databaseService;
        this.cacheService = cacheService;
    }

    /**
     * Scenario 1: Health check
     */
    @Override
    public void health(HealthRequest request, StreamObserver<HealthResponse> responseObserver) {
        String dbStatus = databaseService.checkHealth();
        String cacheStatus = cacheService.checkHealth();

        HealthResponse response = HealthResponse.newBuilder()
                .setStatus("ok")
                .setVersion(VERSION)
                .setTimestamp(Instant.now().toString())
                .setDatabase(dbStatus)
                .setCache(cacheStatus)
                .build();

        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }

    /**
     * Scenario 2: JSON serialization (1000 items)
     */
    @Override
    public void getJsonItems(JsonItemsRequest request, StreamObserver<JsonItemsResponse> responseObserver) {
        int count = Canonical.itemCount(request.getLimit());

        JsonItemsResponse.Builder builder = JsonItemsResponse.newBuilder();
        for (int i = 0; i < count; i++) {
            builder.addItems(JsonItem.newBuilder()
                    .setId(i)
                    .setUuid(Canonical.uuid(i))
                    .setName(Canonical.name(i))
                    .setEmail(Canonical.email(i))
                    .setCreatedAt(Canonical.CREATED_AT)
                    .setIsActive(Canonical.isActive(i))
                    .build());
        }

        builder.setCount(count);
        builder.setTimestamp(Instant.now().toString());

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    /**
     * Scenario 3: Simple database query (single row)
     */
    @Override
    public void getUser(GetUserRequest request, StreamObserver<UserResponse> responseObserver) {
        try {
            DatabaseService.UserRecord user = databaseService.getUser(request.getId());
            if (user == null) {
                responseObserver.onError(Status.NOT_FOUND
                        .withDescription("User with id " + request.getId() + " not found")
                        .asException());
                return;
            }

            UserResponse response = UserResponse.newBuilder()
                    .setId(user.id)
                    .setEmail(user.email)
                    .setFirstName(user.firstName)
                    .setLastName(user.lastName)
                    .setAge(user.age)
                    .setCreatedAt(user.createdAt)
                    .build();

            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(Status.INTERNAL
                    .withDescription(e.getMessage())
                    .withCause(e)
                    .asException());
        }
    }

    /**
     * Scenario 4: Complex database query (JOIN + aggregation)
     */
    @Override
    public void getComplexOrders(ComplexOrdersRequest request, StreamObserver<ComplexOrdersResponse> responseObserver) {
        try {
            int days = request.getDays() > 0 ? request.getDays() : 30;
            List<DatabaseService.UserOrderStatsRecord> data = databaseService.getComplexOrders(days);

            ComplexOrdersResponse.Builder builder = ComplexOrdersResponse.newBuilder();
            builder.setPeriodDays(days);
            builder.setTotalUsers(data.size());

            for (DatabaseService.UserOrderStatsRecord record : data) {
                builder.addData(UserOrderStats.newBuilder()
                        .setUserId(record.userId)
                        .setUserName(record.userName)
                        .setTotalOrders(record.totalOrders)
                        .setTotalValue(record.totalValue)
                        .setAverageOrderValue(record.averageOrderValue)
                        .build());
            }

            responseObserver.onNext(builder.build());
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(Status.INTERNAL
                    .withDescription(e.getMessage())
                    .withCause(e)
                    .asException());
        }
    }

    /**
     * Scenario 5: Cache hit/miss
     */
    @Override
    public void getCacheValue(CacheRequest request, StreamObserver<CacheResponse> responseObserver) {
        try {
            String key = request.getKey();
            CacheService.CacheResult result = cacheService.getValue(key);

            CacheResponse response = CacheResponse.newBuilder()
                    .setKey(key)
                    .setValue(result.value)
                    .setCached(result.cached)
                    .setTtl(result.ttl)
                    .setTimestamp(Instant.now().toString())
                    .build();

            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(Status.INTERNAL
                    .withDescription(e.getMessage())
                    .withCause(e)
                    .asException());
        }
    }
}
