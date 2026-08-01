package com.benchmark.api.resource;

import com.benchmark.api.Canonical;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

import java.util.Map;

@Path("/json")
@Produces(MediaType.APPLICATION_JSON)
public class JsonResource {

    /**
     * The previous implementation built a JsonItem carrying
     * {id,name,description,timestamp,random} with a fresh Instant.now() and a
     * UUID.randomUUID() per item -- 1000 clock reads and 1000 random UUIDs per
     * request -- and ignored ?n=.
     */
    @GET
    public Map<String, Object> get(@QueryParam("n") String n) {
        return Canonical.response(n);
    }
}
