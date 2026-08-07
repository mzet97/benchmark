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
                    response.put("status", (dbOk && cacheOk) ? "healthy" : "unhealthy");
                    response.put("version", "1.0.0");
                    response.put("database", dbOk ? "connected" : "disconnected");
                    response.put("cache", cacheOk ? "connected" : "disconnected");
                    response.put("timestamp", Instant.now().toString());

                    if (dbOk && cacheOk) {
                        return Uni.createFrom().item(Response.ok(response).build());
                    } else {
                        return Uni.createFrom().item(Response.status(503).entity(response).build());
                    }
                });
    }
}
