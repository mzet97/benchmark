package com.benchmark.api.resource;

import com.benchmark.api.service.CacheService;
import com.benchmark.api.service.DatabaseService;
import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Path("/health")
@Produces(MediaType.APPLICATION_JSON)
public class HealthResource {

    @Inject
    DatabaseService databaseService;

    @Inject
    CacheService cacheService;

    @GET
    public Uni<Response> check() {
        Uni<Boolean> dbHealth = databaseService.healthCheck();
        Uni<Boolean> cacheHealth = cacheService.healthCheck();

        return Uni.combine().all().unis(dbHealth, cacheHealth)
                .asTuple()
                .chain(tuple -> {
                    Boolean dbOk = tuple.getItem1();
                    Boolean cacheOk = tuple.getItem2();

                    Map<String, Object> response = new HashMap<>();
                    response.put("status", (dbOk && cacheOk) ? "ok" : "degraded");
                    response.put("version", "1.0.0");
                    response.put("database", dbOk ? "up" : "down");
                    response.put("cache", cacheOk ? "up" : "down");
                    response.put("timestamp", Instant.now().toString());

                    // Contract: HTTP 200 always. The parity gate uses `curl -sf`,
                    // which treats a 503 as a hard failure and reports the
                    // endpoint as empty regardless of the key set. Surface
                    // per-dependency state in the values instead.
                    return Uni.createFrom().item(Response.ok(response).build());
                });
    }
}
