package com.benchmark.api.resource;

import com.benchmark.api.service.CacheService;
import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Path("/cache")
@Produces(MediaType.APPLICATION_JSON)
public class CacheResource {

    // The TTL is part of the response contract and must match what is written
    // to Redis. See contracts/rest/canonical-payloads.md.
    private static final int CACHE_TTL_SECONDS = 300;

    @Inject
    CacheService cacheService;

    @GET
    public Uni<Response> handle(@QueryParam("key") String keyParam) {
        final String key = (keyParam == null || keyParam.isEmpty()) ? "test" : keyParam;

        String newValue = "cached-value-" + UUID.randomUUID();

        return cacheService.getOrSet(key, () -> newValue, CACHE_TTL_SECONDS)
                .map(value -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("key", key);
                    response.put("value", value);
                    // The contract carries a boolean plus the TTL, not a
                    // free-form "source" string.
                    response.put("cached", !value.equals(newValue));
                    response.put("ttl", CACHE_TTL_SECONDS);
                    response.put("timestamp", Instant.now().toString());
                    return Response.ok(response).build();
                })
                .onFailure().recoverWithItem(t -> {
                    Map<String, Object> error = new HashMap<>();
                    error.put("error", "Cache error: " + t.getMessage());
                    return Response.status(500).entity(error).build();
                });
    }
}
