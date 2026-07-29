package benchmark;

import io.smallrye.mutiny.Uni;
import io.vertx.mutiny.redis.client.RedisAPI;
import io.vertx.mutiny.redis.client.Response;
import io.vertx.redis.client.ResponseType;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.util.List;

@ApplicationScoped
public class CacheService {

    @Inject
    RedisAPI redisAPI;

    public Uni<String> healthCheck() {
        return redisAPI.ping(List.of())
                .onItem().transform(response -> "PONG".equals(response.toString()) ? "connected" : "disconnected")
                .onFailure().recoverWithItem("disconnected");
    }

    public Uni<CacheResult> get(String key) {
        return redisAPI.get(key)
                .onItem().transform(response -> {
                    if (response != null && response.type() != ResponseType.NIL) {
                        return new CacheResult(response.toString(), true);
                    }
                    return new CacheResult(null, false);
                })
                .onFailure().recoverWithItem(new CacheResult(null, false));
    }

    public Uni<Boolean> set(String key, String value, int ttlSeconds) {
        return redisAPI.set(List.of(key, value, "EX", String.valueOf(ttlSeconds)))
                .onItem().transform(response -> true)
                .onFailure().recoverWithItem(false);
    }

    public static class CacheResult {
        private final String value;
        private final boolean hit;

        public CacheResult(String value, boolean hit) {
            this.value = value;
            this.hit = hit;
        }

        public String getValue() { return value; }
        public boolean isHit() { return hit; }
    }
}
