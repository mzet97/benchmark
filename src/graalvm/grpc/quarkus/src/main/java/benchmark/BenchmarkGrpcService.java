package benchmark;

import dev.benchmark.grpc.Benchmark.*;
import dev.benchmark.grpc.MutinyBenchmarkServiceGrpc;
import io.quarkus.grpc.GrpcService;
import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@GrpcService
public class BenchmarkGrpcService extends MutinyBenchmarkServiceGrpc.BenchmarkServiceImplBase {

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
