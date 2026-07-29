package benchmark;

import benchmark.Benchmark.CacheResponse;
import io.smallrye.mutiny.Uni;
import io.vertx.mutiny.redis.client.RedisAPI;
import io.vertx.mutiny.redis.client.Response;
import io.vertx.redis.client.ResponseType;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class CacheService {

    private static final int DEFAULT_TTL_SECONDS = 300;

    @Inject
    RedisAPI redis;

    public Uni<CacheResponse> get(String key) {
        return redis.get(key)
                .onItem().transform(response -> {
                    if (response != null && response.type() != ResponseType.NIL) {
                        return CacheResponse.newBuilder()
                                .setKey(key)
                                .setValue(response.toString())
                                .setCached(true)
                                .setTtl(DEFAULT_TTL_SECONDS)
                                .setTimestamp(Instant.now().toString())
                                .build();
                    }
                    return null;
                })
                .onItem().ifNull().switchTo(() -> {
                    // Cache miss - generate value and store
                    String value = "value-" + UUID.randomUUID();
                    return redis.setex(key, String.valueOf(DEFAULT_TTL_SECONDS), value)
                            .onItem().transform(v -> CacheResponse.newBuilder()
                                    .setKey(key)
                                    .setValue(value)
                                    .setCached(false)
                                    .setTtl(DEFAULT_TTL_SECONDS)
                                    .setTimestamp(Instant.now().toString())
                                    .build());
                });
    }
}
